// Turns a week pack into SQL for `wrangler d1 execute`, after the same checks as
// PUT /api/admin/week (validateWeek). For the owner's machine, which has wrangler
// access but need not hold ADMIN_KEY:
//   node scripts/week-sql.js week.json > week.sql
//   npx wrangler d1 execute pibbles --remote --file week.sql
// Like the upload, a week that is already stored is replaced (INSERT OR REPLACE).
import { readFileSync } from "node:fs";
import { validateWeek } from "../src/pack.js";

const file = process.argv[2];
if (!file) {
  console.error("usage: node scripts/week-sql.js week.json");
  process.exit(1);
}
const checked = validateWeek(JSON.parse(readFileSync(file, "utf8")));
if (checked.error) {
  console.error("refused: " + checked.error);
  process.exit(1);
}
const text = (s) => "'" + String(s).replaceAll("'", "''") + "'";
const { weekStart, days } = checked.week;
const lines = [`INSERT OR REPLACE INTO weeks (week_start, uploaded_at) VALUES (${text(weekStart)}, ${Date.now()});`];
for (const d of days) lines.push(`INSERT OR REPLACE INTO days (date, week_start, puzzles) VALUES (${text(d.date)}, ${text(weekStart)}, ${text(JSON.stringify(d.puzzles))});`);
console.log(lines.join("\n"));
console.error(`${weekStart}: 7 days, ${days.length * 7} puzzles checked`);
