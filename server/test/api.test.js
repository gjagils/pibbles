import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { testDb } from "./helpers/d1.js";
import { handle } from "../src/index.js";

const KEY = "test-admin-key-0123456789";
const NOW = Date.UTC(2026, 10, 23, 10, 0); // Monday 23 November 2026, 10:00 UTC
const week = () => JSON.parse(readFileSync(new URL("./fixtures/week-2026-11-23.json", import.meta.url), "utf8"));
const BASE = "https://pibbles.app";

let env;
beforeEach(() => {
  env = { DB: testDb(), ADMIN_KEY: KEY };
});

async function call(method, path, { body, key, now = NOW, ip } = {}) {
  const headers = {};
  if (ip) headers["cf-connecting-ip"] = ip;
  if (key) headers.authorization = `Bearer ${key}`;
  if (body !== undefined) headers["content-type"] = "application/json";
  const response = await handle(
    new Request(BASE + path, { method, headers, body: body === undefined ? undefined : typeof body === "string" ? body : JSON.stringify(body) }),
    env,
    now
  );
  const type = response.headers.get("content-type") || "";
  return { status: response.status, headers: response.headers, body: type.includes("json") ? await response.json() : await response.text() };
}

const upload = (pack = week(), extra = {}) => call("PUT", "/api/admin/week", { body: pack, key: KEY, ...extra });

const score = ({ now, ip, ...fields } = {}) => {
  const day = week().days[0];
  return call("POST", "/api/scores", {
    now, ip,
    body: { date: "2026-11-23", kind: "blocks", deviceId: "device-aaaa-0001", name: "Ann", ms: 60000, hints: 0, solution: day.blocks.solution, ...fields },
  });
};

test("health answers ok, with security headers", async () => {
  const r = await call("GET", "/api/health");
  assert.equal(r.status, 200);
  assert.deepEqual(r.body, { ok: true });
  assert.equal(r.headers.get("x-content-type-options"), "nosniff");
  assert.match(r.headers.get("content-security-policy"), /default-src 'none'/);
  assert.equal(r.headers.get("access-control-allow-origin"), null);
});

test("unknown API paths are 404 JSON, wrong methods 405", async () => {
  assert.equal((await call("GET", "/api/nope")).status, 404);
  assert.equal((await call("GET", "/api/admin/week")).status, 405);
  assert.equal((await call("GET", "/api/scores")).status, 405);
});

// ---- Admin upload ----

test("upload needs the right bearer key", async () => {
  assert.equal((await call("PUT", "/api/admin/week", { body: week() })).status, 401);
  assert.equal((await call("PUT", "/api/admin/week", { body: week(), key: "wrong-key-wrong-key-00" })).status, 401);
  assert.equal((await call("PUT", "/api/admin/week", { body: week(), key: KEY + "x" })).status, 401);
});

test("upload fails closed when the secret is missing or short", async () => {
  env.ADMIN_KEY = undefined;
  assert.equal((await call("PUT", "/api/admin/week", { body: week(), key: "anything-at-all-123" })).status, 401);
  env.ADMIN_KEY = "short";
  assert.equal((await call("PUT", "/api/admin/week", { body: week(), key: "short" })).status, 401);
});

test("a valid week is stored (201) and every day can be read back", async () => {
  const r = await upload();
  assert.equal(r.status, 201);
  assert.deepEqual(r.body, { ok: true, weekStart: "2026-11-23", replaced: false });
  const row = await env.DB.prepare("SELECT COUNT(*) AS n FROM days WHERE week_start = ?").bind("2026-11-23").first();
  assert.equal(row.n, 7);
});

test("upload validation: bad JSON, not a Monday, wrong solution", async () => {
  assert.equal((await call("PUT", "/api/admin/week", { body: "{not json", key: KEY })).status, 400);
  const notMonday = week();
  notMonday.weekStart = "2026-11-22";
  const r1 = await upload(notMonday);
  assert.equal(r1.status, 400);
  assert.match(r1.body.error, /Monday/);
  const wrong = week();
  wrong.days[4].logic.solution = wrong.days[4].logic.solution.map((v) => 1 - v);
  const r2 = await upload(wrong);
  assert.equal(r2.status, 400);
  assert.match(r2.body.error, /2026-11-27 logic: solution fails/);
  const nothing = await env.DB.prepare("SELECT COUNT(*) AS n FROM days").first();
  assert.equal(nothing.n, 0);
});

test("a week that has not started can be replaced; a started week needs force", async () => {
  const before = Date.UTC(2026, 10, 21, 12, 0); // Saturday: the week is still ahead everywhere
  assert.equal((await upload(week(), { now: before })).status, 201);
  const again = await upload(week(), { now: before });
  assert.equal(again.status, 200);
  assert.equal(again.body.replaced, true);
  assert.equal((await upload()).status, 409); // now = Monday
  const forced = await call("PUT", "/api/admin/week?force=1", { body: week(), key: KEY });
  assert.equal(forced.status, 200);
});

// ---- Day endpoint ----

test("a day of the pack comes without solutions", async () => {
  await upload();
  const r = await call("GET", "/api/day/2026-11-23");
  assert.equal(r.status, 200);
  const kinds = ["blocks", "logic", "patterns", "numbers", "stars", "links", "sums"];
  assert.deepEqual(Object.keys(r.body), ["date", ...kinds]);
  for (const kind of kinds) assert.equal(r.body[kind].solution, undefined, kind);
  const fixture = week().days[0];
  assert.deepEqual(r.body.blocks, { size: fixture.blocks.size, pieces: fixture.blocks.pieces, rows: fixture.blocks.rows, cols: fixture.blocks.cols });
  assert.deepEqual(r.body.numbers.relations, fixture.numbers.relations);
  assert.deepEqual(r.body.stars, { size: fixture.stars.size, regions: fixture.stars.regions });
  assert.deepEqual(r.body.links, { size: fixture.links.size, ends: fixture.links.ends });
  assert.deepEqual(r.body.sums, { size: fixture.sums.size, cages: fixture.sums.cages, sums: fixture.sums.sums });
  assert.doesNotMatch(JSON.stringify(r.body), /solution/);
});

test("the next day opens at UTC+14; later days are 403, unknown days 404", async () => {
  await upload();
  assert.equal((await call("GET", "/api/day/2026-11-24")).status, 200);
  const future = await call("GET", "/api/day/2026-11-25");
  assert.equal(future.status, 403);
  assert.equal(future.body.error, "this day has not started yet");
  assert.equal((await call("GET", "/api/day/2026-11-22")).status, 404);
  assert.equal((await call("GET", "/api/day/2026-13-01")).status, 400);
  assert.equal((await call("GET", "/api/day/2026-11-29", { now: Date.UTC(2026, 10, 28, 10, 0) })).status, 200);
});

// ---- Scores ----

test("a right answer is verified and ranked; score = ms + 30000 per hint", async () => {
  await upload();
  const r = await score({ hints: 2, ms: 45000 });
  assert.equal(r.status, 201);
  assert.deepEqual(r.body, { accepted: true, rank: 1, name: "Ann", ms: 45000, hints: 2, score: 105000, verified: true });
});

test("only the first result per device, date and kind counts", async () => {
  await upload();
  assert.equal((await score({ ms: 90000 })).status, 201);
  const second = await score({ ms: 10000, name: "Cheater" });
  assert.equal(second.status, 200);
  assert.equal(second.body.accepted, false);
  assert.equal(second.body.ms, 90000);
  assert.equal(second.body.name, "Ann");
  // Another kind on the same day is its own result
  const day = week().days[0];
  assert.equal((await score({ kind: "logic", solution: day.logic.solution })).status, 201);
  const board = await call("GET", "/api/scores/2026-11-23/blocks");
  assert.equal(board.body.total, 1);
  assert.equal(board.body.top[0].ms, 90000);
});

test("a wrong answer is refused when the pack holds the day", async () => {
  await upload();
  const day = week().days[0];
  const wrongBlocks = await score({ solution: day.blocks.solution.map(() => 0) });
  assert.equal(wrongBlocks.status, 422);
  for (const kind of ["logic", "patterns"]) {
    const wrong = await score({ kind, solution: day[kind].solution.map((v) => 1 - v) });
    assert.equal(wrong.status, 422, kind);
  }
  const numbers = day.numbers.solution.map((v) => (v % day.numbers.size) + 1); // still Latin, breaks givens/relations
  assert.equal((await score({ kind: "numbers", solution: numbers })).status, 422);
  assert.equal((await score({ kind: "numbers", solution: day.numbers.solution })).status, 201);
  assert.equal((await score({ kind: "stars", solution: day.stars.solution.map(() => 0) })).status, 422);
  assert.equal((await score({ kind: "stars", solution: day.stars.solution })).status, 201);
  assert.equal((await score({ kind: "links", solution: day.links.solution.slice(1) })).status, 422);
  // A path may be walked from either dot
  assert.equal((await score({ kind: "links", solution: day.links.solution.map((p) => p.slice().reverse()) })).status, 201);
  // A Latin square with the right cage sums but a number twice in a cage is refused
  const { verifySums } = await import("../src/verify.js");
  assert.equal(verifySums({ size: 2, cages: [0, 1, 1, 0], sums: [2, 4] }, [1, 2, 2, 1]), "number twice in a cage");
  const sums = day.sums.solution.map((v) => (v % day.sums.size) + 1);
  assert.equal((await score({ kind: "sums", solution: sums })).status, 422);
  assert.equal((await score({ kind: "sums", solution: day.sums.solution })).status, 201);
  // A refused answer does not take the device's one try
  assert.equal((await score({})).status, 201);
});

test("without a pack the score is kept unverified", async () => {
  const r = await score({ date: "2026-11-22", solution: [1, 2, 3] });
  assert.equal(r.status, 201);
  assert.equal(r.body.verified, false);
  const board = await call("GET", "/api/scores/2026-11-22/blocks");
  assert.equal(board.body.top[0].verified, false);
});

test("scores: implausible times, other dates and bad fields are refused", async () => {
  await upload();
  assert.equal((await score({ ms: 2999 })).status, 400);
  assert.equal((await score({ ms: 1.5e8 })).status, 400);
  assert.equal((await score({ ms: "60000" })).status, 400);
  assert.equal((await score({ hints: -1 })).status, 400);
  assert.equal((await score({ date: "2026-11-25" })).status, 403);
  assert.equal((await score({ date: "2026-11-20" })).status, 403);
  assert.equal((await score({ kind: "sudoku" })).status, 400);
  assert.equal((await score({ deviceId: "short" })).status, 400);
  assert.equal((await score({ deviceId: "has space in it" })).status, 400);
  assert.equal((await score({ deviceId: "x".repeat(65) })).status, 400);
  assert.equal((await score({ solution: "nope" })).status, 400);
  assert.equal((await call("POST", "/api/scores", { body: "[" })).status, 400);
});

test("names are trimmed, cut to 20 characters and default to Player", async () => {
  await upload();
  const day = week().days[0];
  assert.equal((await score({ name: "   " })).body.name, "Player");
  assert.equal((await score({ kind: "logic", solution: day.logic.solution, name: "  An extremely long display name  " })).body.name, "An extremely long di");
  assert.equal((await score({ kind: "patterns", solution: day.patterns.solution, name: 42 })).body.name, "Player");
});

test("a new name replaces the name on this device's results for today and yesterday", async () => {
  await score({ name: "Player" });
  await score({ deviceId: "device-bbbb-0002", name: "Bob" });
  const r = await call("POST", "/api/name", { body: { deviceId: "device-aaaa-0001", name: "  Nelleke  " } });
  assert.equal(r.status, 200);
  assert.deepEqual(r.body, { name: "Nelleke", updated: 1 });
  const board = await call("GET", "/api/scores/2026-11-23/blocks?deviceId=device-aaaa-0001");
  assert.deepEqual(board.body.top.map((e) => e.name).sort(), ["Bob", "Nelleke"]);
  assert.equal(board.body.me.name, "Nelleke");
});

test("name: bad device ids and wrong methods are refused", async () => {
  assert.equal((await call("POST", "/api/name", { body: { deviceId: "x", name: "Ann" } })).status, 400);
  assert.equal((await call("POST", "/api/name", { body: "[" })).status, 400);
  assert.equal((await call("GET", "/api/name")).status, 405);
  const none = await call("POST", "/api/name", { body: { deviceId: "device-cccc-0003", name: "" } });
  assert.deepEqual(none.body, { name: "Player", updated: 0 });
});

test("ranking: lowest score first, ties by arrival, top 50 and your own rank", async () => {
  await upload();
  const results = [
    ["device-0000-0001", 80000, 0], // 80000
    ["device-0000-0002", 40000, 1], // 70000
    ["device-0000-0003", 50000, 0], // 50000
    ["device-0000-0004", 70000, 0], // 70000, after device 2
  ];
  for (const [deviceId, ms, hints] of results) assert.equal((await score({ deviceId, ms, hints, name: deviceId.slice(-1) })).status, 201);
  for (let i = 0; i < 55; i++) await score({ deviceId: `filler-device-${String(i).padStart(3, "0")}`, ms: 100000 + i, name: "F" });

  const r = await call("GET", "/api/scores/2026-11-23/blocks?deviceId=device-0000-0001");
  assert.equal(r.status, 200);
  assert.equal(r.body.total, 59);
  assert.equal(r.body.top.length, 50);
  assert.deepEqual(r.body.top.slice(0, 4).map((e) => [e.rank, e.name, e.score]), [
    [1, "3", 50000], [2, "2", 70000], [3, "4", 70000], [4, "1", 80000],
  ]);
  assert.deepEqual(Object.keys(r.body.top[0]), ["rank", "name", "ms", "hints", "score", "verified"]);
  assert.equal(r.body.me.rank, 4);

  const outside = await call("GET", "/api/scores/2026-11-23/blocks?deviceId=filler-device-054");
  assert.equal(outside.body.me.rank, 59);
  assert.equal((await call("GET", "/api/scores/2026-11-23/blocks?deviceId=unknown-device")).body.me, null);
  assert.equal((await call("GET", "/api/scores/2026-11-23/blocks")).body.me, null);
  assert.equal((await call("GET", "/api/scores/2026-11-23/chess")).status, 400);
  const accepted = await score({ deviceId: "device-0000-0005", ms: 60000 });
  assert.equal(accepted.body.rank, 2);
});

// ---- Preview page ----

test("the preview page needs the key and draws all 49 puzzles", async () => {
  assert.equal((await call("GET", "/admin/week/2026-11-23")).status, 401);
  assert.equal((await call("GET", "/admin/week/2026-11-23?key=nope")).status, 401);
  assert.equal((await call("GET", `/admin/week/2026-11-23?key=${KEY}`)).status, 404);
  assert.equal((await call("GET", `/admin/week/2026-11-24?key=${KEY}`)).status, 400);
  await upload();
  const r = await call("GET", `/admin/week/2026-11-23?key=${KEY}`);
  assert.equal(r.status, 200);
  assert.match(r.headers.get("content-type"), /text\/html/);
  assert.equal(r.headers.get("referrer-policy"), "no-referrer");
  assert.match(r.headers.get("content-security-policy"), /script-src 'none'/);
  assert.equal(r.body.match(/<article class="puzzle /g).length, 49);
  for (const name of ["Blocks", "Duo", "Stars", "Pixels", "Links", "Signs", "Sums"]) assert.match(r.body, new RegExp(`<h3>${name} <small>`));
  assert.equal(r.body.match(/class="dot"/g).length, week().days.reduce((n, d) => n + d.links.ends.filter((c) => c >= 0).length, 0));
  assert.equal(r.body.match(/<section class="day">/g).length, 7);
  assert.match(r.body, /Monday 23 November/);
  assert.match(r.body, /id="sol"/);
  assert.doesNotMatch(r.body, /<script/);
});

// ---- Security of the ranking ----

test("a time faster than a person can make the moves is refused for a checked answer", async () => {
  await upload();
  const day = week().days[0];
  const { minimumMs } = await import("../src/scores.js");
  for (const kind of ["blocks", "logic", "patterns", "numbers", "stars", "links", "sums"]) {
    const floor = minimumMs(kind, day[kind]);
    assert.ok(floor >= 3000, kind);
    const fast = await score({ kind, solution: day[kind].solution, ms: floor - 1, deviceId: "device-fast-0001" });
    assert.equal(fast.status, floor > 3000 ? 422 : 400, kind);
    // The refusal does not use up the try
    assert.equal((await score({ kind, solution: day[kind].solution, ms: floor, deviceId: "device-fast-0001" })).status, 201, kind);
  }
});

test("rude names become Player; ordinary names stay", async () => {
  const { cleanName } = await import("../src/scores.js");
  for (const rude of ["Kanker", "f u c k", "sh1t head", "Kut", "de nazi", "HOERTJE"]) assert.equal(cleanName(rude), "Player", rude);
  for (const fine of ["Nelleke", "Gerd-Jan", "Lulu", "Kutlu", "Sexton", "Ann 2"]) assert.equal(cleanName(fine), fine, fine);
  const r = await call("POST", "/api/name", { body: { deviceId: "device-aaaa-0001", name: "tyfus" } });
  assert.equal(r.body.name, "Player");
});

test("more than 20 results or names a minute from one address get 429", async () => {
  const IP = "203.0.113.9";
  // Another address has its own count
  assert.notEqual((await score({ ip: "198.51.100.1", deviceId: "device-other-0001" })).status, 429);
  for (let i = 0; i < 19; i++) assert.notEqual((await score({ ip: IP, deviceId: `device-many-${String(i).padStart(4, "0")}` })).status, 429);
  assert.notEqual((await call("POST", "/api/name", { ip: IP, body: { deviceId: "device-aaaa-0001", name: "Ann" } })).status, 429);
  const r = await score({ ip: IP, deviceId: "device-bbbb-0002" });
  assert.equal(r.status, 429);
  assert.equal(r.headers.get("retry-after"), "60");
  assert.equal((await call("POST", "/api/name", { ip: IP, body: { deviceId: "device-aaaa-0001", name: "Ann" } })).status, 429);
  // Reading the ranking is not limited; the next minute counts afresh
  assert.equal((await call("GET", "/api/scores/2026-11-23/blocks")).status, 200);
  assert.notEqual((await score({ ip: IP, deviceId: "device-bbbb-0002", now: NOW + 60000 })).status, 429);
  const left = await env.DB.prepare("SELECT COUNT(*) AS n FROM rate_limits").first();
  assert.equal(left.n, 3);
});

async function adminForm(date, fields) {
  const body = new URLSearchParams(fields);
  const response = await handle(new Request(`${BASE}/admin/scores/${date}`, { method: "POST", body, headers: { "content-type": "application/x-www-form-urlencoded" } }), env, NOW);
  return { status: response.status, location: response.headers.get("location"), body: await response.text() };
}

test("the owner sees a date's results and can hide a name or delete a result", async () => {
  await upload();
  await score({ name: "Ann" });
  await score({ deviceId: "device-bbbb-0002", name: "Bobby", ms: 70000 });
  assert.equal((await call("GET", "/admin/scores/2026-11-23")).status, 401);
  assert.equal((await call("GET", `/admin/scores/2026-11-23?key=wrong-key-0123456789`)).status, 401);
  const page = await call("GET", `/admin/scores/2026-11-23?key=${KEY}`);
  assert.equal(page.status, 200);
  assert.match(page.headers.get("content-security-policy"), /form-action 'self'/);
  assert.match(page.body, /Ann/);
  assert.match(page.body, /Bobby/);

  assert.equal((await adminForm("2026-11-23", { key: "wrong-key-0123456789", id: "2", action: "delete" })).status, 401);
  const rows = await env.DB.prepare("SELECT id, name FROM scores ORDER BY id").all();
  const bob = rows.results.find((r) => r.name === "Bobby").id, ann = rows.results.find((r) => r.name === "Ann").id;

  const hidden = await adminForm("2026-11-23", { key: KEY, id: String(bob), action: "hide" });
  assert.equal(hidden.status, 303);
  assert.match(hidden.location, /done=hide$/);
  const deleted = await adminForm("2026-11-23", { key: KEY, id: String(ann), action: "delete" });
  assert.match(deleted.location, /done=delete$/);
  assert.match((await adminForm("2026-11-23", { key: KEY, id: String(ann), action: "delete" })).location, /done=none$/);

  const board = await call("GET", "/api/scores/2026-11-23/blocks");
  assert.deepEqual(board.body.top.map((e) => e.name), ["Player"]);
  // A deleted device may send again while the day takes scores
  assert.equal((await score({ name: "Ann" })).status, 201);
  // Other pages keep forms off
  assert.match((await call("GET", "/admin/week/2026-11-23")).headers.get("content-security-policy"), /form-action 'none'/);
});
