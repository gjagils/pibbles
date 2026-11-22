// Week packs: seven days, four puzzles per day (docs/puzzels.md), uploaded by
// the owner and stored in D1 per day.
import { KINDS, validatePuzzle, withoutSolution } from "./verify.js";
import { addDays, isMonday, isOpen, parseDate } from "./dates.js";

/** Checks a week pack; returns { week: { weekStart, days } } with clean puzzles, or { error } */
export function validateWeek(body) {
  if (body === null || typeof body !== "object" || Array.isArray(body)) return { error: "body must be a week pack object" };
  const { weekStart, days } = body;
  if (parseDate(weekStart) === null) return { error: "weekStart must be a date yyyy-MM-dd" };
  if (!isMonday(weekStart)) return { error: "weekStart must be a Monday" };
  if (!Array.isArray(days) || days.length !== 7) return { error: "days must hold 7 days" };
  const clean = [];
  for (let i = 0; i < 7; i++) {
    const day = days[i];
    const expected = addDays(weekStart, i);
    if (day === null || typeof day !== "object" || day.date !== expected) return { error: `days[${i}].date must be ${expected}` };
    const puzzles = {};
    for (const kind of KINDS) {
      const result = validatePuzzle(kind, day[kind]);
      if (result.error) return { error: `${expected} ${result.error}` };
      puzzles[kind] = result.puzzle;
    }
    clean.push({ date: expected, puzzles });
  }
  return { week: { weekStart, days: clean } };
}

/**
 * Stores a checked week. Replacing a week that has already opened somewhere
 * would change puzzles people played, so that needs `force`.
 */
export async function storeWeek(env, week, now, force = false) {
  const existing = await env.DB.prepare("SELECT week_start FROM weeks WHERE week_start = ?").bind(week.weekStart).first();
  if (existing && isOpen(week.weekStart, now) && !force)
    return { status: 409, body: { error: "this week has already started; add ?force=1 to replace it" } };
  const statements = [
    env.DB.prepare("INSERT OR REPLACE INTO weeks (week_start, uploaded_at) VALUES (?, ?)").bind(week.weekStart, now),
    ...week.days.map((d) =>
      env.DB.prepare("INSERT OR REPLACE INTO days (date, week_start, puzzles) VALUES (?, ?, ?)").bind(d.date, week.weekStart, JSON.stringify(d.puzzles))
    ),
  ];
  await env.DB.batch(statements);
  return { status: existing ? 200 : 201, body: { ok: true, weekStart: week.weekStart, replaced: !!existing } };
}

/** The four puzzles of a date with solutions, or null */
export async function loadDay(env, date) {
  const row = await env.DB.prepare("SELECT puzzles FROM days WHERE date = ?").bind(date).first();
  return row ? JSON.parse(row.puzzles) : null;
}

/** GET /api/day/:date for the apps: no solutions, nothing from the future */
export async function publicDay(env, date, now) {
  if (parseDate(date) === null) return { status: 400, body: { error: "date must be yyyy-MM-dd" } };
  if (!isOpen(date, now)) return { status: 403, body: { error: "this day has not started yet" } };
  const puzzles = await loadDay(env, date);
  if (!puzzles) return { status: 404, body: { error: "no pack holds this day" } };
  const out = { date };
  for (const kind of KINDS) out[kind] = withoutSolution(puzzles[kind]);
  return { status: 200, body: out };
}

/** The days of a stored week with solutions, or null */
export async function loadWeek(env, weekStart) {
  const { results } = await env.DB.prepare("SELECT date, puzzles FROM days WHERE week_start = ? ORDER BY date").bind(weekStart).all();
  if (!results.length) return null;
  return results.map((r) => ({ date: r.date, puzzles: JSON.parse(r.puzzles) }));
}
