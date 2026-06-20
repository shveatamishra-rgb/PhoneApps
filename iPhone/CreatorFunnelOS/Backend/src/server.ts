import Fastify, { type FastifyReply, type FastifyRequest } from "fastify";
import cors from "@fastify/cors";
import helmet from "@fastify/helmet";
import rateLimit from "@fastify/rate-limit";
import rawBody from "fastify-raw-body";
import { randomUUID } from "node:crypto";
import { config } from "./config.js";
import { pool, query } from "./db.js";
import { keywordMatches } from "./funnel.js";
import {
  decrypt,
  encrypt,
  hashPassword,
  newRefreshToken,
  sha256,
  signAccessToken,
  signOAuthState,
  verifyMetaSignature,
  verifyPassword,
  verifyToken
} from "./security.js";

type Auth = { userId: string; workspaceId: string };
type Row = Record<string, any>;

const app = Fastify({ logger: true, trustProxy: true });
await app.register(cors, { origin: false });
await app.register(helmet);
await app.register(rateLimit, { max: 120, timeWindow: "1 minute" });
await app.register(rawBody, { field: "rawBody", global: false, encoding: false, runFirst: true });

app.setErrorHandler((error, _request, reply) => {
  app.log.error(error);
  const status = (error as any).statusCode ?? 500;
  reply.code(status).send({
    message: status >= 500
      ? "The service is temporarily unavailable."
      : (error as Error).message
  });
});

async function authenticate(request: FastifyRequest, reply: FastifyReply) {
  const authorization = request.headers.authorization;
  if (!authorization?.startsWith("Bearer ")) {
    return reply.code(401).send({ message: "Authentication required." });
  }
  try {
    (request as any).auth = await verifyToken(authorization.slice(7));
  } catch {
    return reply.code(401).send({ message: "Session expired." });
  }
}

function auth(request: FastifyRequest): Auth {
  return (request as any).auth;
}

async function createSession(user: Row, workspaceId: string) {
  const refresh = newRefreshToken();
  await query(
    `INSERT INTO refresh_tokens(user_id, token_hash, expires_at)
     VALUES ($1, $2, now() + interval '30 days')`,
    [user.id, refresh.hash]
  );
  return {
    user: {
      id: user.id,
      fullName: user.full_name,
      email: user.email,
      avatarURL: null,
      createdAt: user.created_at
    },
    accessToken: await signAccessToken(user.id, workspaceId),
    refreshToken: refresh.token,
    isEmailVerified: user.email_verified
  };
}

app.get("/health", async () => {
  await query("SELECT 1");
  return { status: "ok", version: "1.0.0" };
});

app.post("/v1/auth/signup", {
  config: { rateLimit: { max: 8, timeWindow: "1 minute" } }
}, async (request: any, reply) => {
  const { fullName, email, password } = request.body ?? {};
  if (!fullName?.trim() || !email?.includes("@") || password?.length < 8) {
    return reply.code(400).send({ message: "Use a name, valid email, and an 8+ character password." });
  }
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const userResult = await client.query(
      `INSERT INTO users(full_name, email, password_hash, email_verified)
       VALUES ($1, lower($2), $3, $4)
       RETURNING *`,
      [fullName.trim(), email.trim(), await hashPassword(password), !config.REQUIRE_EMAIL_VERIFICATION]
    );
    const user = userResult.rows[0]!;
    const workspaceResult = await client.query(
      "INSERT INTO workspaces(name) VALUES ($1) RETURNING *",
      [`${fullName.trim()}'s Workspace`]
    );
    const workspace = workspaceResult.rows[0]!;
    await client.query(
      "INSERT INTO memberships(user_id, workspace_id, role) VALUES ($1, $2, 'owner')",
      [user.id, workspace.id]
    );
    await client.query(
      "INSERT INTO notification_preferences(user_id) VALUES ($1)",
      [user.id]
    );
    await client.query("COMMIT");
    return reply.code(201).send(await createSession(user, workspace.id));
  } catch (error: any) {
    await client.query("ROLLBACK");
    if (error.code === "23505") {
      return reply.code(409).send({ message: "An account already exists for this email." });
    }
    throw error;
  } finally {
    client.release();
  }
});

app.post("/v1/auth/signin", {
  config: { rateLimit: { max: 10, timeWindow: "1 minute" } }
}, async (request: any, reply) => {
  const { email, password } = request.body ?? {};
  const users = await query<Row>(
    `SELECT u.*, m.workspace_id
     FROM users u JOIN memberships m ON m.user_id = u.id
     WHERE u.email = lower($1)
     ORDER BY m.joined_at LIMIT 1`,
    [email]
  );
  const user = users[0];
  if (!user || !(await verifyPassword(password ?? "", user.password_hash))) {
    return reply.code(401).send({ message: "The email or password was not accepted." });
  }
  return createSession(user, user.workspace_id);
});

app.post("/v1/auth/refresh", async (request: any, reply) => {
  const supplied = request.body?.refreshToken;
  if (!supplied) return reply.code(401).send({ message: "Refresh token required." });
  const rows = await query<Row>(
    `SELECT rt.*, m.workspace_id
     FROM refresh_tokens rt
     JOIN memberships m ON m.user_id = rt.user_id
     WHERE rt.token_hash = $1 AND rt.revoked_at IS NULL AND rt.expires_at > now()
     ORDER BY m.joined_at LIMIT 1`,
    [sha256(supplied)]
  );
  const existing = rows[0];
  if (!existing) return reply.code(401).send({ message: "Session expired." });
  const replacement = newRefreshToken();
  await query("UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1", [existing.id]);
  await query(
    `INSERT INTO refresh_tokens(user_id, token_hash, expires_at)
     VALUES ($1, $2, now() + interval '30 days')`,
    [existing.user_id, replacement.hash]
  );
  return {
    accessToken: await signAccessToken(existing.user_id, existing.workspace_id),
    refreshToken: replacement.token
  };
});

app.post("/v1/auth/signout", { preHandler: authenticate }, async (request) => {
  const { userId } = auth(request);
  await query("UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1 AND revoked_at IS NULL", [userId]);
  return { ok: true };
});

app.post("/v1/auth/password-reset/request", async (_request, reply) => reply.code(204).send());
app.post("/v1/auth/email-verification/resend", { preHandler: authenticate }, async (_request, reply) => reply.code(204).send());

app.get("/v1/workspaces/current", { preHandler: authenticate }, async (request, reply) => {
  const rows = await query<Row>("SELECT * FROM workspaces WHERE id = $1", [auth(request).workspaceId]);
  if (!rows[0]) return reply.code(404).send({ message: "Workspace not found." });
  return mapWorkspace(rows[0]);
});

app.get("/v1/workspaces", { preHandler: authenticate }, async (request) => {
  const rows = await query<Row>(
    `SELECT w.* FROM workspaces w JOIN memberships m ON m.workspace_id = w.id
     WHERE m.user_id = $1 ORDER BY w.created_at`,
    [auth(request).userId]
  );
  return rows.map(mapWorkspace);
});

app.get("/v1/workspaces/:id/memberships", { preHandler: authenticate }, async (request: any) => {
  const rows = await query<Row>("SELECT * FROM memberships WHERE workspace_id = $1", [request.params.id]);
  return rows.map((row) => ({
    id: row.id, userId: row.user_id, workspaceId: row.workspace_id,
    role: row.role, joinedAt: row.joined_at
  }));
});

app.get("/v1/social-accounts", { preHandler: authenticate }, async (request) => {
  const rows = await query<Row>(
    "SELECT * FROM social_accounts WHERE workspace_id = $1 AND is_connected = true",
    [auth(request).workspaceId]
  );
  return { accounts: rows.map(mapSocialAccount) };
});

app.get("/v1/social-accounts/instagram/authorize", { preHandler: authenticate }, async (request, reply) => {
  if (!config.META_APP_ID || !config.META_APP_SECRET) {
    return reply.code(503).send({ message: "Meta credentials are not configured on the server." });
  }
  const current = auth(request);
  const state = await signOAuthState(current.userId, current.workspaceId);
  const url = new URL("https://www.instagram.com/oauth/authorize");
  url.searchParams.set("enable_fb_login", "0");
  url.searchParams.set("force_authentication", "1");
  url.searchParams.set("client_id", config.META_APP_ID);
  url.searchParams.set("redirect_uri", config.META_REDIRECT_URI);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("state", state);
  url.searchParams.set(
    "scope",
    [
      "instagram_business_basic",
      "instagram_business_manage_messages",
      "instagram_business_manage_comments",
      "instagram_business_content_publish"
    ].join(",")
  );
  return { url: url.toString() };
});

app.get("/v1/social-accounts/instagram/callback", async (request: any, reply) => {
  const { code, state, error } = request.query ?? {};
  if (error || !code || !state) {
    return reply.redirect(`${config.IOS_CALLBACK_URL}?status=denied`);
  }
  try {
    const oauth = await verifyToken(state);
    const form = new URLSearchParams({
      client_id: config.META_APP_ID,
      client_secret: config.META_APP_SECRET,
      grant_type: "authorization_code",
      redirect_uri: config.META_REDIRECT_URI,
      code
    });
    const shortResponse = await fetch("https://api.instagram.com/oauth/access_token", {
      method: "POST",
      body: form
    });
    if (!shortResponse.ok) throw new Error(`Meta token exchange failed: ${shortResponse.status}`);
    const short = await shortResponse.json() as any;
    const longURL = new URL(`https://graph.instagram.com/access_token`);
    longURL.searchParams.set("grant_type", "ig_exchange_token");
    longURL.searchParams.set("client_secret", config.META_APP_SECRET);
    longURL.searchParams.set("access_token", short.access_token);
    const longResponse = await fetch(longURL);
    if (!longResponse.ok) throw new Error(`Meta long-lived token exchange failed: ${longResponse.status}`);
    const long = await longResponse.json() as any;
    const profileURL = new URL(`https://graph.instagram.com/${config.META_GRAPH_VERSION}/me`);
    profileURL.searchParams.set("fields", "user_id,username,account_type");
    profileURL.searchParams.set("access_token", long.access_token);
    const profileResponse = await fetch(profileURL);
    if (!profileResponse.ok) throw new Error(`Meta profile request failed: ${profileResponse.status}`);
    const profile = await profileResponse.json() as any;
    const savedAccounts = await query<Row>(
      `INSERT INTO social_accounts(
         workspace_id, platform_user_id, handle, account_type,
         access_token_ciphertext, token_expires_at, last_sync_at
       ) VALUES ($1,$2,$3,$4,$5,now() + ($6 || ' seconds')::interval,now())
       ON CONFLICT(workspace_id, platform_user_id) DO UPDATE SET
         handle=excluded.handle, account_type=excluded.account_type,
         access_token_ciphertext=excluded.access_token_ciphertext,
         token_expires_at=excluded.token_expires_at, is_connected=true, last_sync_at=now()
       RETURNING *`,
      [
        oauth.workspaceId,
        String(profile.user_id ?? profile.id ?? short.user_id),
        profile.username,
        String(profile.account_type ?? "creator").toLowerCase(),
        encrypt(long.access_token),
        String(long.expires_in ?? 5_184_000)
      ]
    );
    await syncInstagramPosts(savedAccounts[0]!);
    return reply.redirect(`${config.IOS_CALLBACK_URL}?status=success`);
  } catch (error) {
    app.log.error(error);
    return reply.redirect(`${config.IOS_CALLBACK_URL}?status=error`);
  }
});

app.delete("/v1/social-accounts/:id", { preHandler: authenticate }, async (request: any, reply) => {
  const result = await pool.query(
    "UPDATE social_accounts SET is_connected=false WHERE id=$1 AND workspace_id=$2",
    [request.params.id, auth(request).workspaceId]
  );
  return reply.code(result.rowCount ? 204 : 404).send();
});

app.post("/v1/social-accounts/:id/refresh", { preHandler: authenticate }, async (request: any, reply) => {
  const rows = await query<Row>(
    "UPDATE social_accounts SET last_sync_at=now() WHERE id=$1 AND workspace_id=$2 RETURNING *",
    [request.params.id, auth(request).workspaceId]
  );
  if (!rows[0]) return reply.code(404).send({ message: "Connected account not found." });
  await syncInstagramPosts(rows[0]);
  return mapSocialAccount(rows[0]);
});

app.get("/v1/social-accounts/:id/posts", { preHandler: authenticate }, async (request: any) => {
  const rows = await query<Row>("SELECT * FROM social_posts WHERE account_id=$1 ORDER BY published_at DESC NULLS LAST", [request.params.id]);
  return rows.map(mapPost);
});

app.get("/v1/funnels", { preHandler: authenticate }, async (request) => {
  return loadFunnels(auth(request).workspaceId);
});

app.put("/v1/funnels", { preHandler: authenticate }, async (request: any, reply) => {
  const f = request.body;
  if (!f?.name?.trim() || !f?.triggerKeyword?.trim()) {
    return reply.code(400).send({ message: "A funnel needs a name and trigger keyword." });
  }
  await query(
    `INSERT INTO funnels(
       id,workspace_id,name,status,trigger_keyword,public_reply,direct_message,
       destination_link,conversations,leads,created_at,updated_at
     ) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,now())
     ON CONFLICT(id) DO UPDATE SET name=excluded.name,status=excluded.status,
       trigger_keyword=excluded.trigger_keyword,public_reply=excluded.public_reply,
       direct_message=excluded.direct_message,destination_link=excluded.destination_link,
       updated_at=now()
     WHERE funnels.workspace_id=excluded.workspace_id`,
    [
      f.id, auth(request).workspaceId, f.name.trim(), f.status,
      f.triggerKeyword.trim().toUpperCase(), f.publicReply, f.directMessage,
      f.destinationLink, f.conversations ?? 0, f.leads ?? 0, f.createdAt ?? new Date()
    ]
  );
  await setFunnelPosts(f.id, f.connectedPostIds ?? []);
  return (await loadFunnels(auth(request).workspaceId)).find((item) => item.id === f.id);
});

app.patch("/v1/funnels/:id/status", { preHandler: authenticate }, async (request: any, reply) => {
  const rows = await query<Row>(
    `UPDATE funnels SET status=$1,updated_at=now()
     WHERE id=$2 AND workspace_id=$3 RETURNING *`,
    [request.body?.status, request.params.id, auth(request).workspaceId]
  );
  if (!rows[0]) return reply.code(404).send({ message: "Funnel not found." });
  return (await loadFunnels(auth(request).workspaceId)).find((f) => f.id === request.params.id);
});

app.put("/v1/funnels/:id/posts", { preHandler: authenticate }, async (request: any, reply) => {
  const owns = await query("SELECT 1 FROM funnels WHERE id=$1 AND workspace_id=$2", [request.params.id, auth(request).workspaceId]);
  if (!owns[0]) return reply.code(404).send({ message: "Funnel not found." });
  await setFunnelPosts(request.params.id, request.body?.postIds ?? []);
  return (await loadFunnels(auth(request).workspaceId)).find((f) => f.id === request.params.id);
});

app.get("/v1/leads", { preHandler: authenticate }, async (request) => {
  const rows = await query<Row>(
    `SELECT l.*, f.name source_funnel FROM leads l
     LEFT JOIN funnels f ON f.id=l.source_funnel_id
     WHERE l.workspace_id=$1 ORDER BY l.captured_at DESC`,
    [auth(request).workspaceId]
  );
  return rows.map(mapLead);
});

app.get("/v1/leads/:id/events", { preHandler: authenticate }, async (request: any) => {
  const rows = await query<Row>(
    `SELECT e.* FROM lead_events e JOIN leads l ON l.id=e.lead_id
     WHERE e.lead_id=$1 AND l.workspace_id=$2 ORDER BY occurred_at DESC`,
    [request.params.id, auth(request).workspaceId]
  );
  return rows.map((r) => ({ id: r.id, leadId: r.lead_id, type: r.type, detail: r.detail, occurredAt: r.occurred_at }));
});

app.post("/v1/leads/:id/tags", { preHandler: authenticate }, async (request: any, reply) => {
  const name = request.body?.tag?.name;
  await query(
    `UPDATE leads SET tags=CASE WHEN tags ? $1 THEN tags ELSE tags || to_jsonb($1::text) END
     WHERE id=$2 AND workspace_id=$3`,
    [name, request.params.id, auth(request).workspaceId]
  );
  return reply.code(204).send();
});

app.post("/v1/leads/:id/notes", { preHandler: authenticate }, async (request: any, reply) => {
  const note = request.body;
  const rows = await query(
    "UPDATE leads SET notes=$1 WHERE id=$2 AND workspace_id=$3 RETURNING id",
    [note.body, request.params.id, auth(request).workspaceId]
  );
  if (!rows[0]) return reply.code(404).send({ message: "Lead not found." });
  return note;
});

app.post("/v1/leads/export", { preHandler: authenticate }, async (request) => {
  const rows = await query<Row>("SELECT count(*)::int count FROM leads WHERE workspace_id=$1", [auth(request).workspaceId]);
  return { downloadURL: null, rowCount: rows[0]?.count ?? 0, expiresAt: null, isPlaceholder: true };
});

app.get("/v1/planner/ideas", { preHandler: authenticate }, async (request) => loadContent(auth(request).workspaceId, "idea"));
app.get("/v1/planner/drafts", { preHandler: authenticate }, async (request) => loadContent(auth(request).workspaceId, "draft"));
app.get("/v1/planner/templates", { preHandler: authenticate }, async () => []);
app.put("/v1/planner/ideas", { preHandler: authenticate }, saveContent("idea"));
app.put("/v1/planner/drafts", { preHandler: authenticate }, saveContent("draft"));

app.get("/v1/analytics", { preHandler: authenticate }, async (request) => analytics(auth(request).workspaceId));
app.post("/v1/events", { preHandler: authenticate }, async (request: any, reply) => {
  const event = request.body?.event;
  await query(
    `INSERT INTO analytics_events(id,workspace_id,user_id,name,properties,occurred_at)
     VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING`,
    [event.id, auth(request).workspaceId, auth(request).userId, event.name, event.properties ?? {}, event.occurredAt]
  );
  return reply.code(204).send();
});

app.get("/v1/recommendations", { preHandler: authenticate }, async () => []);
app.get("/v1/feature-flags", { preHandler: authenticate }, async () => []);

app.get("/v1/notifications/preferences", { preHandler: authenticate }, async (request) => {
  const rows = await query<Row>("SELECT * FROM notification_preferences WHERE user_id=$1", [auth(request).userId]);
  return mapPreference(rows[0]!);
});
app.put("/v1/notifications/preferences", { preHandler: authenticate }, async (request: any) => {
  const p = request.body;
  const rows = await query<Row>(
    `UPDATE notification_preferences SET activity_alerts=$1,weekly_digest=$2,recommendation_alerts=$3
     WHERE user_id=$4 RETURNING *`,
    [p.activityAlerts, p.weeklyDigest, p.recommendationAlerts, auth(request).userId]
  );
  return mapPreference(rows[0]!);
});

app.get("/v1/policies/privacy", async () => policy("privacy", "Privacy Policy", config.PRIVACY_POLICY_URL));
app.get("/v1/policies/terms", async () => policy("terms", "Terms of Service", config.TERMS_URL));
app.get("/v1/policies/subscription", async () => policy("subscription", "Subscription Terms", config.SUBSCRIPTION_TERMS_URL));
app.get("/v1/policies/permissions", async () => policy(
  "permissions",
  "Connected Account Permissions",
  `${config.PUBLIC_API_URL}/permissions`
));

app.post("/v1/account/reauthenticate", { preHandler: authenticate }, async (request: any, reply) => {
  const rows = await query<Row>("SELECT password_hash FROM users WHERE id=$1", [auth(request).userId]);
  if (!rows[0] || !(await verifyPassword(request.body?.password ?? "", rows[0].password_hash))) {
    return reply.code(401).send({ message: "Password verification failed." });
  }
  return reply.code(204).send();
});
app.post("/v1/account/delete", { preHandler: authenticate }, async (request) => {
  const rows = await query<Row>(
    `INSERT INTO deletion_requests(user_id,scheduled_deletion_date)
     VALUES($1,now()+interval '30 days')
     ON CONFLICT(user_id) DO UPDATE SET requested_at=now(),scheduled_deletion_date=now()+interval '30 days'
     RETURNING *`,
    [auth(request).userId]
  );
  return mapDeletion(rows[0]!);
});
app.get("/v1/account/deletion-status", { preHandler: authenticate }, async (request) => {
  const rows = await query<Row>("SELECT * FROM deletion_requests WHERE user_id=$1", [auth(request).userId]);
  return { deletionRequest: rows[0] ? mapDeletion(rows[0]) : null };
});

app.post("/v1/billing/transactions", { preHandler: authenticate }, async (request: any, reply) => {
  const transaction = request.body;
  await query(
    `INSERT INTO subscriptions(workspace_id,product_id,original_transaction_id)
     VALUES($1,$2,$3) ON CONFLICT(workspace_id) DO UPDATE SET
       product_id=excluded.product_id,original_transaction_id=excluded.original_transaction_id,updated_at=now()`,
    [auth(request).workspaceId, transaction.productId, transaction.originalTransactionId]
  );
  return reply.code(202).send();
});

app.get("/webhooks/instagram", async (request: any, reply) => {
  if (request.query?.["hub.mode"] === "subscribe" &&
      request.query?.["hub.verify_token"] === config.META_WEBHOOK_VERIFY_TOKEN) {
    return reply.type("text/plain").send(request.query["hub.challenge"]);
  }
  return reply.code(403).send();
});

app.post("/webhooks/instagram", { config: { rawBody: true } }, async (request: any, reply) => {
  if (!verifyMetaSignature(request.rawBody, request.headers["x-hub-signature-256"])) {
    return reply.code(401).send({ message: "Invalid webhook signature." });
  }
  reply.code(200).send({ received: true });
  void processInstagramWebhook(request.body).catch((error) => app.log.error(error));
});

app.get("/v1/workspace/snapshot", { preHandler: authenticate }, async (request) => {
  const workspaceId = auth(request).workspaceId;
  const accounts = await query<Row>("SELECT * FROM social_accounts WHERE workspace_id=$1 AND is_connected=true LIMIT 1", [workspaceId]);
  const funnels = await loadFunnels(workspaceId);
  const leads = await query<Row>(
    `SELECT l.*, f.name source_funnel FROM leads l LEFT JOIN funnels f ON f.id=l.source_funnel_id
     WHERE l.workspace_id=$1 ORDER BY l.captured_at DESC`,
    [workspaceId]
  );
  const stats = await analytics(workspaceId);
  return {
    account: accounts[0] ? {
      id: accounts[0].id,
      username: accounts[0].handle,
      displayName: accounts[0].handle,
      followerCount: 0,
      isConnected: true
    } : null,
    metrics: [
      metric("Triggered comments", String(stats.triggerVolume), "Live total", "triggeredComments"),
      metric("Successful DMs", String(stats.successfulDMs), `${Math.round(stats.dmSuccessRate * 100)}% delivery rate`, "successfulDMs"),
      metric("Leads captured", String(stats.leadsCaptured), "Live total", "leads"),
      metric("Lead conversion", `${Math.round(stats.leadConversionRate * 1000) / 10}%`, "From triggers", "leadConversion"),
      metric("Active funnels", String(stats.activeFunnelCount), "Live", "activeFunnels")
    ],
    analytics: stats,
    funnels,
    contacts: leads.map(mapLead),
    content: [],
    activity: [],
    recommendations: [],
    contentIdeas: await loadContent(workspaceId, "idea"),
    contentDrafts: await loadContent(workspaceId, "draft"),
    contentTemplates: []
  };
});

app.get("/r/:funnelId", async (request: any, reply) => {
  const leadId = String(request.query?.lead ?? "");
  const rows = await query<Row>(
    `SELECT f.destination_link,l.id lead_id
     FROM funnels f JOIN leads l ON l.source_funnel_id=f.id
     WHERE f.id=$1 AND l.id=$2 LIMIT 1`,
    [request.params.funnelId, leadId]
  );
  const row = rows[0];
  if (!row) return reply.code(404).send({ message: "This destination is no longer available." });
  await query(
    "INSERT INTO lead_events(lead_id,type,detail) VALUES($1,'link_clicked','Opened the funnel destination link')",
    [row.lead_id]
  );
  return reply.redirect(row.destination_link);
});

async function processInstagramWebhook(payload: any) {
  for (const entry of payload?.entry ?? []) {
    for (const change of entry.changes ?? []) {
      if (change.field !== "comments") continue;
      const value = change.value ?? {};
      const commentId = String(value.id ?? value.comment_id ?? "");
      const text = String(value.text ?? "").trim();
      const instagramAccountId = String(entry.id ?? value.media?.owner?.id ?? "");
      if (!commentId || !text || !instagramAccountId) continue;
      const eventKey = `comment:${commentId}`;
      const inserted = await pool.query(
        `INSERT INTO webhook_events(event_key,payload) VALUES($1,$2)
         ON CONFLICT DO NOTHING`,
        [eventKey, payload]
      );
      if (!inserted.rowCount) continue;

      try {
        const accounts = await query<Row>(
        "SELECT * FROM social_accounts WHERE platform_user_id=$1 AND is_connected=true LIMIT 1",
        [instagramAccountId]
      );
      const account = accounts[0];
      if (!account) continue;
      const mediaId = String(value.media?.id ?? value.media_id ?? "");
      const funnels = await query<Row>(
        `SELECT DISTINCT f.* FROM funnels f
         LEFT JOIN funnel_posts fp ON fp.funnel_id=f.id
         LEFT JOIN social_posts sp ON sp.id=fp.post_id
         WHERE f.workspace_id=$1 AND f.status='active'
           AND (sp.platform_post_id=$2 OR NOT EXISTS (
             SELECT 1 FROM funnel_posts assigned WHERE assigned.funnel_id=f.id
           ))`,
        [account.workspace_id, mediaId]
      );
      const funnel = funnels.find((f) => keywordMatches(text, f.trigger_keyword));
      if (!funnel) continue;

      const accessToken = decrypt(account.access_token_ciphertext);
      const sender = value.from ?? {};
      const leadRows = await query<Row>(
        `INSERT INTO leads(
           workspace_id,instagram_user_id,name,instagram_handle,source_funnel_id,
           source_post_id,status,last_engaged_at
         ) VALUES($1,$2,$3,$4,$5,
           (SELECT id FROM social_posts WHERE account_id=$6 AND platform_post_id=$7 LIMIT 1),
           'New',now())
         ON CONFLICT(workspace_id,instagram_user_id) DO UPDATE SET
           last_engaged_at=now(),source_funnel_id=excluded.source_funnel_id,
           source_post_id=excluded.source_post_id
         RETURNING *, (xmax = 0) AS inserted`,
        [
          account.workspace_id,
          String(sender.id ?? value.from_id ?? `comment-${commentId}`),
          sender.username ?? "Instagram contact",
          sender.username ? `@${sender.username}` : "@instagram",
          funnel.id,
          account.id,
          mediaId
        ]
      );
      const lead = leadRows[0]!;
      if (funnel.public_reply) {
        await metaPost(`/${commentId}/replies`, accessToken, { message: funnel.public_reply });
      }
      const trackedDestination = funnel.destination_link
        ? `${config.PUBLIC_API_URL}/r/${funnel.id}?lead=${lead.id}`
        : "";
      const privateMessage = [funnel.direct_message, trackedDestination].filter(Boolean).join("\n\n");
      await metaPost(`/${commentId}/private_replies`, accessToken, { message: privateMessage });
      await query(
        `INSERT INTO lead_events(lead_id,type,detail) VALUES
         ($1,'keyword_triggered',$2),($1,'dm_sent',$3)`,
        [lead.id, `Matched keyword ${funnel.trigger_keyword}`, "Private reply sent through Meta"]
      );
      await query(
        `UPDATE funnels SET conversations=conversations+1,leads=leads+$2,updated_at=now()
         WHERE id=$1`,
        [funnel.id, lead.inserted ? 1 : 0]
      );
      } catch (error) {
        await query("DELETE FROM webhook_events WHERE event_key=$1", [eventKey]);
        throw error;
      }
    }
  }
}

async function metaPost(path: string, accessToken: string, body: Record<string, string>) {
  const response = await fetch(`https://graph.instagram.com/${config.META_GRAPH_VERSION}${path}`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });
  if (!response.ok) {
    throw new Error(`Meta request ${path} failed: ${response.status} ${await response.text()}`);
  }
}

async function syncInstagramPosts(account: Row) {
  const url = new URL(`https://graph.instagram.com/${config.META_GRAPH_VERSION}/me/media`);
  url.searchParams.set("fields", "id,caption,media_type,timestamp,permalink");
  url.searchParams.set("limit", "50");
  url.searchParams.set("access_token", decrypt(account.access_token_ciphertext));
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Meta media sync failed: ${response.status} ${await response.text()}`);
  }
  const payload = await response.json() as any;
  for (const media of payload.data ?? []) {
    const firstLine = String(media.caption ?? `${media.media_type ?? "Instagram"} post`)
      .split("\n")[0] ?? "Instagram post";
    const title = firstLine.slice(0, 140);
    await query(
      `INSERT INTO social_posts(account_id,platform_post_id,title,published_at,status)
       VALUES($1,$2,$3,$4,'published')
       ON CONFLICT(account_id,platform_post_id) DO UPDATE SET
         title=excluded.title,published_at=excluded.published_at,status='published'`,
      [account.id, String(media.id), title, media.timestamp ?? new Date()]
    );
  }
  await query("UPDATE social_accounts SET last_sync_at=now() WHERE id=$1", [account.id]);
}

async function loadFunnels(workspaceId: string) {
  const rows = await query<Row>(
    `SELECT f.*, coalesce(array_agg(fp.post_id) FILTER (WHERE fp.post_id IS NOT NULL),'{}') post_ids
     FROM funnels f LEFT JOIN funnel_posts fp ON fp.funnel_id=f.id
     WHERE f.workspace_id=$1 GROUP BY f.id ORDER BY f.updated_at DESC`,
    [workspaceId]
  );
  return rows.map((f) => ({
    id: f.id, name: f.name, status: f.status, triggerKeyword: f.trigger_keyword,
    publicReply: f.public_reply, directMessage: f.direct_message,
    destinationLink: f.destination_link, connectedPostIds: f.post_ids,
    conversations: f.conversations, leads: f.leads,
    createdAt: f.created_at, updatedAt: f.updated_at
  }));
}

async function setFunnelPosts(funnelId: string, postIds: string[]) {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("DELETE FROM funnel_posts WHERE funnel_id=$1", [funnelId]);
    for (const postId of postIds) {
      await client.query(
        "INSERT INTO funnel_posts(funnel_id,post_id) VALUES($1,$2) ON CONFLICT DO NOTHING",
        [funnelId, postId]
      );
    }
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function loadContent(workspaceId: string, kind: string) {
  const rows = await query<Row>(
    "SELECT payload FROM content_items WHERE workspace_id=$1 AND kind=$2 ORDER BY updated_at DESC",
    [workspaceId, kind]
  );
  return rows.map((r) => r.payload);
}

function saveContent(kind: string) {
  return async (request: any) => {
    const item = request.body;
    await query(
      `INSERT INTO content_items(id,workspace_id,kind,payload) VALUES($1,$2,$3,$4)
       ON CONFLICT(id) DO UPDATE SET payload=excluded.payload,updated_at=now()`,
      [item.id, auth(request).workspaceId, kind, item]
    );
    return item;
  };
}

async function analytics(workspaceId: string) {
  const rows = await query<Row>(
    `SELECT
      count(*) FILTER (WHERE status='active')::int active_funnels,
      coalesce(sum(conversations),0)::int triggers,
      coalesce(sum(conversations),0)::int dms,
      coalesce(sum(leads),0)::int lead_count
     FROM funnels WHERE workspace_id=$1`,
    [workspaceId]
  );
  const leadRows = await query<Row>(
    "SELECT count(*)::int count FROM leads WHERE workspace_id=$1",
    [workspaceId]
  );
  const clickRows = await query<Row>(
    `SELECT count(*)::int count FROM lead_events e
     JOIN leads l ON l.id=e.lead_id
     WHERE l.workspace_id=$1 AND e.type='link_clicked'`,
    [workspaceId]
  );
  const r = rows[0]!;
  const leadCount = leadRows[0]?.count ?? 0;
  const clickCount = clickRows[0]?.count ?? 0;
  const now = new Date();
  const start = new Date(now.getTime() - 30 * 86_400_000);
  return {
    id: stableUUID(workspaceId),
    workspaceId,
    periodStart: start,
    periodEnd: now,
    activeFunnelCount: r.active_funnels,
    triggerVolume: r.triggers,
    successfulDMs: r.dms,
    dmSuccessRate: r.triggers ? r.dms / r.triggers : 0,
    linkClickThroughRate: r.dms ? clickCount / r.dms : 0,
    leadConversionRate: r.triggers ? leadCount / r.triggers : 0,
    leadsCaptured: leadCount,
    bestPerformingFunnelId: null,
    bestPerformingPostId: null,
    sevenDayTrend: [],
    thirtyDayTrend: []
  };
}

function stableUUID(seed: string): string {
  const hex = sha256(seed).slice(0, 32);
  return `${hex.slice(0,8)}-${hex.slice(8,12)}-4${hex.slice(13,16)}-a${hex.slice(17,20)}-${hex.slice(20,32)}`;
}

function mapWorkspace(r: Row) {
  return { id: r.id, name: r.name, planTier: r.plan_tier, createdAt: r.created_at };
}
function mapSocialAccount(r: Row) {
  return {
    id: r.id, platform: "instagram", handle: r.handle,
    accountType: r.account_type === "business" ? "business" : "creator",
    isConnected: r.is_connected, lastSyncAt: r.last_sync_at
  };
}
function mapPost(r: Row) {
  return {
    id: r.id, accountId: r.account_id, platformPostId: r.platform_post_id,
    title: r.title, publishedAt: r.published_at, status: r.status
  };
}
function mapLead(r: Row) {
  return {
    id: r.id, name: r.name, instagramHandle: r.instagram_handle, email: r.email,
    sourceFunnel: r.source_funnel ?? "Instagram funnel",
    sourcePostId: r.source_post_id, sourceFunnelId: r.source_funnel_id,
    status: r.status, tags: r.tags ?? [], notes: r.notes,
    capturedAt: r.captured_at, lastEngagedAt: r.last_engaged_at
  };
}
function mapPreference(r: Row) {
  return {
    id: r.id, userId: r.user_id, activityAlerts: r.activity_alerts,
    weeklyDigest: r.weekly_digest, recommendationAlerts: r.recommendation_alerts
  };
}
function mapDeletion(r: Row) {
  return {
    id: r.id, userId: r.user_id, requestedAt: r.requested_at,
    scheduledDeletionDate: r.scheduled_deletion_date, state: r.state
  };
}
function policy(id: string, title: string, publicURL: string) {
  return {
    id, title,
    body: "The current policy is published at the link below.",
    updatedAt: new Date(),
    publicURL
  };
}
function metric(title: string, value: string, change: string, kind: string) {
  return { id: randomUUID(), title, value, change, kind };
}

await app.listen({ port: config.PORT, host: "0.0.0.0" });
