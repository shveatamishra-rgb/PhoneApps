import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { pool } from "./db.js";

const sqlPath = fileURLToPath(new URL("../sql/001_initial.sql", import.meta.url));
const sql = await readFile(sqlPath, "utf8");
await pool.query(sql);
await pool.end();
console.log("Database migration complete.");
