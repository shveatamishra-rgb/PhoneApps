import { pool } from "./db.js";

const result = await pool.query(
  `DELETE FROM users
   WHERE id IN (
     SELECT user_id FROM deletion_requests
     WHERE state='requested' AND scheduled_deletion_date <= now()
   )`
);
console.log(`Deleted ${result.rowCount ?? 0} due account(s).`);
await pool.end();
