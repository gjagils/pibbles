// pibbles.app: the website (static assets, public/) and the API. wrangler.toml
// sends only /api/* and /admin/* here; everything else is served as an asset.
import { validateWeek, storeWeek, publicDay, loadWeek } from "./pack.js";
import { submitScore, ranking, rename, scoresOfDate, moderate } from "./scores.js";
import { parseDate, isMonday } from "./dates.js";
import { adminWeekPage, adminMessagePage, adminScoresPage } from "./admin-page.js";

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

// `forms`: the page may post its own forms (the moderation page), nothing else
const html = (body, status = 200, forms = false) =>
  new Response(body, {
    status,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
      "x-robots-tag": "noindex, nofollow",
      "content-security-policy": `default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; script-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action ${forms ? "'self'" : "'none'"}`,
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

/**
 * True when this address sent more than RATE_LIMIT results or name changes in this
 * minute. Counted in D1 (rate_limits), exact also at low traffic, unlike Cloudflare's
 * rate limit binding, which is approximate per location.
 */
export const RATE_LIMIT = 20;
async function tooMany(env, request, now) {
  // Cloudflare always sets the address; without it (tests, local runs) there is no limit
  const address = request.headers.get("cf-connecting-ip");
  if (!address) return false;
  const minute = Math.floor(now / 60000);
  const [, counted] = await env.DB.batch([
    env.DB.prepare("DELETE FROM rate_limits WHERE minute < ?").bind(minute - 2),
    env.DB.prepare(
      "INSERT INTO rate_limits (key, minute, count) VALUES (?, ?, 1) ON CONFLICT (key, minute) DO UPDATE SET count = count + 1 RETURNING count"
    ).bind(address, minute),
  ]);
  return counted.results[0].count > RATE_LIMIT;
}

const slowDown = () => json({ error: "too many requests, try again in a minute" }, 429, { "retry-after": "60" });

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
    if (await tooMany(env, request, now)) return slowDown();
    const body = await readJson(request, MAX_SCORE_BODY);
    if (body === null) return json({ error: "body must be JSON, at most 8 KB" }, 400);
    return answer(await submitScore(env, body, now));
  }

  if (path === "/api/name") {
    if (method !== "POST") return json({ error: "use POST" }, 405, { allow: "POST" });
    if (await tooMany(env, request, now)) return slowDown();
    const body = await readJson(request, MAX_SCORE_BODY);
    if (body === null) return json({ error: "body must be JSON, at most 8 KB" }, 400);
    return answer(await rename(env, body, now));
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

  // Moderation: a date's results, each with "hide name" and "delete" (a form that posts
  // back here with the key, then returns to the list)
  if ((m = path.match(/^\/admin\/scores\/([^/]+)\/?$/))) {
    const date = m[1];
    if (parseDate(date) === null) return html(adminMessagePage("Not a date", "Use yyyy-MM-dd."), 400);
    if (method === "GET") {
      if (!sameKey(url.searchParams.get("key") || "", env.ADMIN_KEY))
        return html(adminMessagePage("Not allowed", "Add ?key=<ADMIN_KEY> to the address."), 401);
      return html(adminScoresPage(date, await scoresOfDate(env, date), url.searchParams.get("key"), url.searchParams.get("done")), 200, true);
    }
    if (method === "POST") {
      const form = await request.formData().catch(() => null);
      const key = form?.get("key");
      if (!sameKey(typeof key === "string" ? key : "", env.ADMIN_KEY)) return html(adminMessagePage("Not allowed", "The key is missing or wrong."), 401);
      const ok = await moderate(env, Number(form.get("id")), form.get("action"));
      const back = `/admin/scores/${date}?key=${encodeURIComponent(key)}&done=${ok ? form.get("action") : "none"}`;
      return new Response(null, { status: 303, headers: { location: back, "cache-control": "no-store", ...SECURITY } });
    }
    return html(adminMessagePage("Method not allowed", "Use GET or POST."), 405);
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
