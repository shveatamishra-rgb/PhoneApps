import "dotenv/config";
import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().default(8080),
  PUBLIC_API_URL: z.string().url(),
  DATABASE_URL: z.string().min(1),
  JWT_SECRET: z.string().min(32),
  TOKEN_ENCRYPTION_KEY: z.string().regex(/^[a-fA-F0-9]{64}$/),
  META_APP_ID: z.string().default(""),
  META_APP_SECRET: z.string().default(""),
  META_REDIRECT_URI: z.string().url(),
  META_GRAPH_VERSION: z.string().default("v23.0"),
  META_WEBHOOK_VERIFY_TOKEN: z.string().min(16),
  IOS_CALLBACK_URL: z.string().default("creatorfunnelos://instagram-connected"),
  REQUIRE_EMAIL_VERIFICATION: z.coerce.boolean().default(false),
  PRIVACY_POLICY_URL: z.string().url(),
  TERMS_URL: z.string().url(),
  SUBSCRIPTION_TERMS_URL: z.string().url()
});

export const config = schema.parse(process.env);
