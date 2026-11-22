// Daily rankings per kind. Score = ms + 30000 per hint (Ranking.score), lowest
// wins. Only a device's first result for a date and kind counts.
import { KINDS, verifySolution } from "./verify.js";
import { isScoreDate, parseDate } from "./dates.js";
import { loadDay } from "./pack.js";

export const HINT_PENALTY_MS = 30000;
export const MIN_MS = 3000;
export const MAX_MS = 24 * 3600 * 1000;
export const MAX_HINTS = 99;
export const TOP = 50;
const DEVICE_ID = /^[A-Za-z0-9-]{8,64}$/;

export const scoreOf = (ms, hints) => ms + HINT_PENALTY_MS * hints;

/** A display name: trimmed, control characters out, at most 20 characters, "Player" when empty */
export function cleanName(name) {
  if (typeof name !== "string") return "Player";
  const clean = Array.from(name.replace(/[\u0000-\u001f\u007f-\u009f\u2028\u2029]/g, "").trim()).slice(0, 20).join("").trim();
  return clean || "Player";
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

/** GET /api/scores/:date/:kind?deviceId=... */
export async function ranking(env, date, kind, deviceId) {
  if (parseDate(date) === null) return bad("date must be yyyy-MM-dd");
  if (!KINDS.includes(kind)) return bad("kind must be one of " + KINDS.join(", "));
  const { results } = await env.DB.prepare(
    "SELECT name, ms, hints, score, verified FROM scores WHERE date = ? AND kind = ? ORDER BY score, id LIMIT ?"
  ).bind(date, kind, TOP).all();
  const total = await env.DB.prepare("SELECT COUNT(*) AS n FROM scores WHERE date = ? AND kind = ?").bind(date, kind).first();
  const body = {
    date, kind, total: total.n,
    top: results.map((r, i) => ({ rank: i + 1, name: r.name, ms: r.ms, hints: r.hints, score: r.score, verified: r.verified === 1 })),
    me: null,
  };
  if (typeof deviceId === "string" && DEVICE_ID.test(deviceId)) {
    const mine = await env.DB.prepare("SELECT * FROM scores WHERE date = ? AND kind = ? AND device_id = ?").bind(date, kind, deviceId).first();
    if (mine) body.me = {
      rank: await rankOf(env, date, kind, mine.score, mine.id),
      name: mine.name, ms: mine.ms, hints: mine.hints, score: mine.score, verified: mine.verified === 1,
    };
  }
  return { status: 200, body };
}
