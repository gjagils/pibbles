// pibbles.app: the website (static assets, public/) and the API. wrangler.toml
// sends only /api/* and /admin/* here; everything else is served as an asset.
import { validateWeek, storeWeek, publicDay, loadWeek } from "./pack.js";
import { submitScore, ranking } from "./scores.js";
import { parseDate, isMonday } from "./dates.js";
import { adminWeekPage, adminMessagePage } from "./admin-page.js";

const MAX_PACK_BODY = 512 * 1024;
const MAX_SCORE_BODY = 8 * 1024;

const SECURITY = {
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
  "strict-transport-security": "max-age=31536000",
  "x-frame-options": "DENY",
};

const json = (body, status = 200, headers = {}) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "content-security-policy": "default-src 'none'; frame-ancestors 'none'",
      ...SECURITY,
      ...headers,
    },
  });

const html = (body, status = 200) =>
  new Response(body, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "x-robots-tag": "noindex, nofollow",
      "content-security-policy": "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; script-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
      ...SECURITY,
    },
  });

const answer = (result, headers) => json(result.body, result.status, headers);

/** Constant-time comparison, so the key cannot be guessed byte by byte from timings */
function sameKey(given, expected) {
  if (typeof expected !== "string" || expected.length < 16 || typeof given !== "string") return false;
  const a = new TextEncoder().encode(given), b = new TextEncoder().encode(expected);
  let diff = a.length ^ b.length;
  for (let i = 0; i < b.length; i++) diff |= (a[i] ?? 0) ^ b[i];
  return diff === 0;
}

const bearer = (request) => {
  const header = request.headers.get("authorization") || "";
  return header.startsWith("Bearer ") ? header.slice(7) : "";
};

/** The JSON body, or null when too big or not JSON */
async function readJson(request, limit) {
  const text = await request.text();
  if (text.length > limit) return null;
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

/** The whole router; `now` (unix ms) is a parameter so tests can pick the day */
export async function handle(request, env, now = Date.now()) {
  const url = new URL(request.url);
  const path = url.pathname;
  const method = request.method;
  let m;

  if (path === "/api/health") return json({ ok: true });

  if (path === "/api/admin/week") {
    if (method !== "PUT") return json({ error: "use PUT" }, 405, { allow: "PUT" });
    if (!sameKey(bearer(request), env.ADMIN_KEY)) return json({ error: "unauthorized" }, 401);
    const body = await readJson(request, MAX_PACK_BODY);
    if (body === null) return json({ error: "body must be JSON, at most 512 KB" }, 400);
    const checked = validateWeek(body);
    if (checked.error) return json({ error: checked.error }, 400);
    return answer(await storeWeek(env, checked.week, now, url.searchParams.get("force") === "1"));
  }

  if ((m = path.match(/^\/api\/day\/([^/]+)$/))) {
    if (method !== "GET") return json({ error: "use GET" }, 405, { allow: "GET" });
    const result = await publicDay(env, m[1], now);
    // A day that is out does not change (unless the owner forces a replacement)
    return answer(result, result.status === 200 ? { "cache-control": "public, max-age=300" } : {});
  }

  if (path === "/api/scores") {
    if (method !== "POST") return json({ error: "use POST" }, 405, { allow: "POST" });
    const body = await readJson(request, MAX_SCORE_BODY);
    if (body === null) return json({ error: "body must be JSON, at most 8 KB" }, 400);
    return answer(await submitScore(env, body, now));
  }

  if ((m = path.match(/^\/api\/scores\/([^/]+)\/([^/]+)$/))) {
    if (method !== "GET") return json({ error: "use GET" }, 405, { allow: "GET" });
    return answer(await ranking(env, m[1], m[2], url.searchParams.get("deviceId")));
  }

  if ((m = path.match(/^\/admin\/week\/([^/]+)\/?$/))) {
    if (method !== "GET") return html(adminMessagePage("Method not allowed", "Use GET."), 405);
    if (!sameKey(url.searchParams.get("key") || "", env.ADMIN_KEY))
      return html(adminMessagePage("Not allowed", "Add ?key=<ADMIN_KEY> to the address."), 401);
    const weekStart = m[1];
    if (parseDate(weekStart) === null || !isMonday(weekStart))
      return html(adminMessagePage("Not a week", "Use the Monday of the week, as yyyy-MM-dd."), 400);
    const days = await loadWeek(env, weekStart);
    if (!days) return html(adminMessagePage("No pack yet", `No week pack for ${weekStart} has been uploaded.`), 404);
    return html(adminWeekPage(weekStart, days));
  }

  if (path.startsWith("/api/")) return json({ error: "not found" }, 404);
  if (path.startsWith("/admin/")) return html(adminMessagePage("Not found", "There is nothing here."), 404);
  // Not reached in production (wrangler.toml routes only /api/* and /admin/* here)
  return env.ASSETS ? env.ASSETS.fetch(request) : new Response("Not found", { status: 404 });
}

export default {
  async fetch(request, env) {
    try {
      return await handle(request, env);
    } catch (error) {
      console.error(error);
      return json({ error: "internal error" }, 500);
    }
  },
};
