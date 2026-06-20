import {
  createCipheriv,
  createDecipheriv,
  createHash,
  createHmac,
  randomBytes,
  scrypt as scryptCallback,
  timingSafeEqual
} from "node:crypto";
import { promisify } from "node:util";
import { SignJWT, jwtVerify } from "jose";
import { config } from "./config.js";

const scrypt = promisify(scryptCallback);
const jwtKey = new TextEncoder().encode(config.JWT_SECRET);
const encryptionKey = Buffer.from(config.TOKEN_ENCRYPTION_KEY, "hex");

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16);
  const derived = (await scrypt(password, salt, 64)) as Buffer;
  return `scrypt:${salt.toString("hex")}:${derived.toString("hex")}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [, saltHex, hashHex] = stored.split(":");
  if (!saltHex || !hashHex) return false;
  const expected = Buffer.from(hashHex, "hex");
  const actual = (await scrypt(password, Buffer.from(saltHex, "hex"), expected.length)) as Buffer;
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

export async function signAccessToken(userId: string, workspaceId: string): Promise<string> {
  return new SignJWT({ workspaceId })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime("15m")
    .sign(jwtKey);
}

export async function signOAuthState(userId: string, workspaceId: string): Promise<string> {
  return new SignJWT({ workspaceId, purpose: "instagram_oauth" })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime("10m")
    .sign(jwtKey);
}

export async function verifyToken(token: string) {
  const result = await jwtVerify(token, jwtKey);
  return {
    userId: result.payload.sub!,
    workspaceId: String(result.payload.workspaceId)
  };
}

export function newRefreshToken(): { token: string; hash: string } {
  const token = randomBytes(48).toString("base64url");
  return { token, hash: sha256(token) };
}

export function sha256(value: string | Buffer): string {
  return createHash("sha256").update(value).digest("hex");
}

export function encrypt(value: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", encryptionKey, iv);
  const ciphertext = Buffer.concat([cipher.update(value, "utf8"), cipher.final()]);
  return [iv, cipher.getAuthTag(), ciphertext].map((part) => part.toString("base64url")).join(".");
}

export function decrypt(value: string): string {
  const [iv, tag, ciphertext] = value.split(".").map((part) => Buffer.from(part!, "base64url"));
  const decipher = createDecipheriv("aes-256-gcm", encryptionKey, iv!);
  decipher.setAuthTag(tag!);
  return Buffer.concat([decipher.update(ciphertext!), decipher.final()]).toString("utf8");
}

export function verifyMetaSignature(rawBody: Buffer, signature: string | undefined): boolean {
  if (!signature?.startsWith("sha256=")) return false;
  const expected = createHmac("sha256", config.META_APP_SECRET).update(rawBody).digest("hex");
  const provided = signature.slice(7);
  return expected.length === provided.length &&
    timingSafeEqual(Buffer.from(expected), Buffer.from(provided));
}
