CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  email_verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS workspaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  plan_tier text NOT NULL DEFAULT 'free',
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS memberships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'owner',
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, workspace_id)
);
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz
);
CREATE TABLE IF NOT EXISTS social_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  platform text NOT NULL DEFAULT 'instagram',
  platform_user_id text NOT NULL,
  handle text NOT NULL,
  account_type text NOT NULL DEFAULT 'creator',
  access_token_ciphertext text NOT NULL,
  token_expires_at timestamptz,
  is_connected boolean NOT NULL DEFAULT true,
  last_sync_at timestamptz,
  UNIQUE(workspace_id, platform_user_id)
);
CREATE TABLE IF NOT EXISTS social_posts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES social_accounts(id) ON DELETE CASCADE,
  platform_post_id text,
  title text NOT NULL DEFAULT '',
  published_at timestamptz,
  status text NOT NULL DEFAULT 'published',
  UNIQUE(account_id, platform_post_id)
);
CREATE TABLE IF NOT EXISTS funnels (
  id uuid PRIMARY KEY,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  name text NOT NULL,
  status text NOT NULL,
  trigger_keyword text NOT NULL,
  public_reply text NOT NULL,
  direct_message text NOT NULL,
  destination_link text NOT NULL,
  conversations integer NOT NULL DEFAULT 0,
  leads integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS funnel_posts (
  funnel_id uuid NOT NULL REFERENCES funnels(id) ON DELETE CASCADE,
  post_id uuid NOT NULL REFERENCES social_posts(id) ON DELETE CASCADE,
  PRIMARY KEY(funnel_id, post_id)
);
CREATE TABLE IF NOT EXISTS leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  instagram_user_id text,
  name text NOT NULL,
  instagram_handle text NOT NULL,
  email text,
  source_funnel_id uuid REFERENCES funnels(id) ON DELETE SET NULL,
  source_post_id uuid REFERENCES social_posts(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'New',
  tags jsonb NOT NULL DEFAULT '[]',
  notes text NOT NULL DEFAULT '',
  captured_at timestamptz NOT NULL DEFAULT now(),
  last_engaged_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(workspace_id, instagram_user_id)
);
CREATE TABLE IF NOT EXISTS lead_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  lead_id uuid NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  type text NOT NULL,
  detail text NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS content_items (
  id uuid PRIMARY KEY,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  kind text NOT NULL,
  payload jsonb NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS analytics_events (
  id uuid PRIMARY KEY,
  workspace_id uuid NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  name text NOT NULL,
  properties jsonb NOT NULL DEFAULT '{}',
  occurred_at timestamptz NOT NULL
);
CREATE TABLE IF NOT EXISTS notification_preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  activity_alerts boolean NOT NULL DEFAULT true,
  weekly_digest boolean NOT NULL DEFAULT true,
  recommendation_alerts boolean NOT NULL DEFAULT true
);
CREATE TABLE IF NOT EXISTS webhook_events (
  event_key text PRIMARY KEY,
  payload jsonb NOT NULL,
  processed_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS subscriptions (
  workspace_id uuid PRIMARY KEY REFERENCES workspaces(id) ON DELETE CASCADE,
  product_id text,
  original_transaction_id text,
  status text NOT NULL DEFAULT 'active',
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS deletion_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  requested_at timestamptz NOT NULL DEFAULT now(),
  scheduled_deletion_date timestamptz NOT NULL,
  state text NOT NULL DEFAULT 'requested'
);

CREATE INDEX IF NOT EXISTS idx_funnels_workspace_status ON funnels(workspace_id, status);
CREATE INDEX IF NOT EXISTS idx_leads_workspace_captured ON leads(workspace_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_workspace_occurred ON analytics_events(workspace_id, occurred_at DESC);
