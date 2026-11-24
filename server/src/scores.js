// Daily rankings per kind. Score = ms + 30000 per hint (Ranking.score), lowest
// wins. Only a device's first result for a date and kind counts.
import { KINDS, verifySolution } from "./verify.js";
import { isScoreDate, parseDate, scoreDates } from "./dates.js";
import { loadDay } from "./pack.js";

export const HINT_PENALTY_MS = 30000;
export const MIN_MS = 3000;
export const MAX_MS = 24 * 3600 * 1000;
export const MAX_HINTS = 99;
export const TOP = 50;
const DEVICE_ID = /^[A-Za-z0-9-]{8,64}$/;

/**
 * The fastest believable time for a puzzle: the moves a person has to make, times a
 * quick hand per move. Generous on purpose (a fast player is far slower), it only keeps
 * out scripts that solve the board and send a few seconds.
 */
const MS_PER_MOVE = { blocks: 600, logic: 150, patterns: 100, numbers: 250, stars: 300, links: 50, sums: 250 };
export function movesOf(kind, p) {
  const n = p.size;
  if (kind === "blocks") return p.pieces.length;
  if (kind === "logic") return p.givens.filter((g) => g === -1).length;
  if (kind === "patterns") return p.rowClues.flat().reduce((a, b) => a + b, 0);
  if (kind === "numbers") return p.givens.filter((g) => g === 0).length;
  if (kind === "stars") return n;
  return n * n; // links: every cell is walked; sums: every cell is filled
}
export const minimumMs = (kind, p) => Math.max(MIN_MS, movesOf(kind, p) * MS_PER_MOVE[kind]);

// Names that become "Player". Long words match anywhere (also spaced or with digits for
// letters), short ones only as a whole word, so ordinary names stay.
const BLOCKED_PARTS = ["kanker", "tering", "tyfus", "hoer", "neuk", "nigger", "nigga", "fuck", "shit", "cunt", "bitch", "whore", "hitler", "faggot", "flikker", "pedo"];
const BLOCKED_WORDS = ["kut", "lul", "nazi", "slet", "sex", "porn", "kkk"];
const LEET = { 0: "o", 1: "i", 3: "e", 4: "a", 5: "s", 7: "t", "@": "a", $: "s" };
export function isBlockedName(name) {
  const plain = name.toLowerCase().replace(/[013457@$]/g, (c) => LEET[c]).normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  const words = plain.split(/[^a-z]+/).filter(Boolean);
  const joined = words.join("");
  return BLOCKED_PARTS.some((part) => joined.includes(part)) || words.some((word) => BLOCKED_WORDS.includes(word));
}

export const scoreOf = (ms, hints) => ms + HINT_PENALTY_MS * hints;

/** A display name: trimmed, control characters out, at most 20 characters, "Player" when empty or rude */
export function cleanName(name) {
  if (typeof name !== "string") return "Player";
  const clean = Array.from(name.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g, "").trim()).slice(0, 20).join("").trim();
  return clean && !isBlockedName(clean) ? clean : "Player";
}

const bad = (error, status = 400) => ({ status, body: { error } });

/** Rank of a row: 1 + rows that score lower, or equal but came in earlier */
async function rankOf(env, date, kind, score, id) {
  const row = await env.DB.prepare(
    "SELECT COUNT(*) AS ahead FROM scores WHERE date = ? AND kind = ? AND (score < ? OR (score = ? AND id < ?))"
  ).bind(date, kind, score, score, id).first();
  return row.ahead + 1;
}

/** POST /api/scores */
export async function submitScore(env, body, now) {
  if (body === null || typeof body !== "object") return bad("body must be an object");
  const { date, kind, deviceId, ms, hints, solution } = body;
  if (parseDate(date) === null) return bad("date must be yyyy-MM-dd");
  if (!isScoreDate(date, now)) return bad("scores are only taken for today or yesterday", 403);
  if (!KINDS.includes(kind)) return bad("kind must be one of " + KINDS.join(", "));
  if (typeof deviceId !== "string" || !DEVICE_ID.test(deviceId)) return bad("deviceId must be 8-64 characters A-Z, a-z, 0-9 or -");
  if (!Number.isInteger(ms) || ms < MIN_MS || ms > MAX_MS) return bad("time not plausible");
  if (!Number.isInteger(hints) || hints < 0 || hints > MAX_HINTS) return bad("hints must be 0..99");
  if (!Array.isArray(solution) || solution.length > 400) return bad("solution must be an array");
  const name = cleanName(body.name);

  const existing = await env.DB.prepare("SELECT * FROM scores WHERE date = ? AND kind = ? AND device_id = ?").bind(date, kind, deviceId).first();
  if (existing) return result(env, existing, false);

  const puzzles = await loadDay(env, date);
  let verified = 0;
  if (puzzles) {
    const wrong = verifySolution(kind, puzzles[kind], solution);
    if (wrong) return bad("solution is not right: " + wrong, 422);
    if (ms < minimumMs(kind, puzzles[kind])) return bad("time not plausible for this puzzle", 422);
    verified = 1;
  }
  const score = scoreOf(ms, hints);
  const inserted = await env.DB.prepare(
    "INSERT OR IGNORE INTO scores (date, kind, device_id, name, ms, hints, score, verified, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
  ).bind(date, kind, deviceId, name, ms, hints, score, verified, now).run();
  // Read back: a parallel first submission may have won the race (then changes is 0)
  const row = await env.DB.prepare("SELECT * FROM scores WHERE date = ? AND kind = ? AND device_id = ?").bind(date, kind, deviceId).first();
  return result(env, row, inserted.meta.changes === 1);
}

async function result(env, row, accepted) {
  return {
    status: accepted ? 201 : 200,
    body: {
      accepted, // false: this device already had a result for this day and kind; that one stays
      rank: await rankOf(env, row.date, row.kind, row.score, row.id),
      name: row.name, ms: row.ms, hints: row.hints, score: row.score, verified: row.verified === 1,
    },
  };
}

/**
 * POST /api/name: a device's new display name, also on its results for the dates that
 * still take scores (today and yesterday). Older days keep the name they had.
 */
export async function rename(env, body, now) {
  if (body === null || typeof body !== "object") return bad("body must be an object");
  const { deviceId } = body;
  if (typeof deviceId !== "string" || !DEVICE_ID.test(deviceId)) return bad("deviceId must be 8-64 characters A-Z, a-z, 0-9 or -");
  const name = cleanName(body.name);
  const dates = scoreDates(now);
  const updated = await env.DB.prepare(
    `UPDATE scores SET name = ? WHERE device_id = ? AND date IN (${dates.map(() => "?").join(", ")})`
  ).bind(name, deviceId, ...dates).run();
  return { status: 200, body: { name, updated: updated.meta.changes } };
}

/**
 * GET /api/scores/:date/:kind?deviceId=...
 * One batch (a single transaction), so the top, the total and this device's rank come
 * from the same moment: a result that lands meanwhile is in all three or in none.
 */
export async function ranking(env, date, kind, deviceId) {
  if (parseDate(date) === null) return bad("date must be yyyy-MM-dd");
  if (!KINDS.includes(kind)) return bad("kind must be one of " + KINDS.join(", "));
  const device = typeof deviceId === "string" && DEVICE_ID.test(deviceId) ? deviceId : "";
  const [top, total, mine] = await env.DB.batch([
    env.DB.prepare("SELECT name, ms, hints, score, verified FROM scores WHERE date = ? AND kind = ? ORDER BY score, id LIMIT ?").bind(date, kind, TOP),
    env.DB.prepare("SELECT COUNT(*) AS n FROM scores WHERE date = ? AND kind = ?").bind(date, kind),
    env.DB.prepare(
      "SELECT s.name, s.ms, s.hints, s.score, s.verified, 1 + (SELECT COUNT(*) FROM scores o WHERE o.date = s.date AND o.kind = s.kind AND (o.score < s.score OR (o.score = s.score AND o.id < s.id))) AS rank FROM scores s WHERE s.date = ? AND s.kind = ? AND s.device_id = ?"
    ).bind(date, kind, device),
  ]);
  const me = mine.results[0];
  return {
    status: 200,
    body: {
      date, kind, total: total.results[0].n,
      top: top.results.map((r, i) => ({ rank: i + 1, name: r.name, ms: r.ms, hints: r.hints, score: r.score, verified: r.verified === 1 })),
      me: me ? { rank: me.rank, name: me.name, ms: me.ms, hints: me.hints, score: me.score, verified: me.verified === 1 } : null,
    },
  };
}

// ---- Owner: moderation (admin page) ----

/** Every result of a date, best first per kind, with the device id cut short */
export async function scoresOfDate(env, date) {
  const { results } = await env.DB.prepare(
    "SELECT id, kind, device_id, name, ms, hints, score, verified, created_at FROM scores WHERE date = ? ORDER BY kind, score, id"
  ).bind(date).all();
  return results;
}

/** "delete" removes a result; "hide" sets its name to Player. False when there was no such row */
export async function moderate(env, id, action) {
  if (!Number.isInteger(id) || id < 1) return false;
  const statement = action === "delete"
    ? env.DB.prepare("DELETE FROM scores WHERE id = ?").bind(id)
    : action === "hide" ? env.DB.prepare("UPDATE scores SET name = 'Player' WHERE id = ?").bind(id) : null;
  if (!statement) return false;
  return (await statement.run()).meta.changes === 1;
}
