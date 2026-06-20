import pg from "pg";
import { config } from "./config.js";

export const pool = new pg.Pool({
  connectionString: config.DATABASE_URL,
  ssl: config.NODE_ENV === "production" ? { rejectUnauthorized: false } : undefined,
  max: 10
});

export async function query<T extends pg.QueryResultRow>(
  text: string,
  values: unknown[] = []
): Promise<T[]> {
  const result = await pool.query<T>(text, values);
  return result.rows;
}
