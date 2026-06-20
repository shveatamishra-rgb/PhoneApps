import { beforeAll, describe, expect, it } from "vitest";

beforeAll(() => {
  process.env.PUBLIC_API_URL = "https://api.example.com";
  process.env.DATABASE_URL = "postgres://localhost/test";
  process.env.JWT_SECRET = "test-secret-that-is-longer-than-thirty-two-characters";
  process.env.TOKEN_ENCRYPTION_KEY = "11".repeat(32);
  process.env.META_REDIRECT_URI = "https://api.example.com/callback";
  process.env.META_WEBHOOK_VERIFY_TOKEN = "test-verification-token";
  process.env.PRIVACY_POLICY_URL = "https://example.com/privacy";
  process.env.TERMS_URL = "https://example.com/terms";
  process.env.SUBSCRIPTION_TERMS_URL = "https://example.com/subscriptions";
});

describe("security primitives", () => {
  it("hashes and verifies passwords", async () => {
    const { hashPassword, verifyPassword } = await import("./security.js");
    const hash = await hashPassword("correct horse battery staple");
    expect(await verifyPassword("correct horse battery staple", hash)).toBe(true);
    expect(await verifyPassword("wrong", hash)).toBe(false);
  });

  it("encrypts Meta access tokens at rest", async () => {
    const { encrypt, decrypt } = await import("./security.js");
    const encrypted = encrypt("meta-token");
    expect(encrypted).not.toContain("meta-token");
    expect(decrypt(encrypted)).toBe("meta-token");
  });
});
