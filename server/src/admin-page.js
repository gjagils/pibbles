// The owner's preview of a week pack: all 28 puzzles as empty boards with their
// clues, and a switch that shows the solutions. Pure CSS (no scripts), so the
// page runs under a CSP with script-src 'none'.
import { SHAPES, DISPLAY_NAMES } from "./verify.js";
import { parseDate } from "./dates.js";
import { LOGO_SVG } from "./logo.js";

const esc = (s) => String(s).replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
const PIECE_COLORS = ["var(--purple)", "var(--orange)", "var(--teal)"];
const dayTitle = (date) =>
  new Date(parseDate(date)).toLocaleDateString("en-GB", { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" });
const cellSize = (n) => `${Math.min(30, Math.floor(220 / n))}px`;

function shapeSvg(key, color) {
  const cells = SHAPES[key];
  const h = Math.max(...cells.map((c) => c[0])) + 1, w = Math.max(...cells.map((c) => c[1])) + 1, u = 12;
  const rects = cells.map(([r, c]) => `<rect x="${c * u + 1}" y="${r * u + 1}" width="${u - 2}" height="${u - 2}" rx="3"/>`).join("");
  return `<svg class="piece" viewBox="0 0 ${w * u} ${h * u}" width="${w * u}" height="${h * u}" fill="${color}" role="img" aria-label="${esc(key)}"><title>${esc(key)}</title>${rects}</svg>`;
}

function blocks(p) {
  const n = p.size, owner = new Array(n * n).fill(-1);
  p.pieces.forEach((key, i) => {
    const r0 = Math.floor(p.solution[i] / n), c0 = p.solution[i] % n;
    for (const [dr, dc] of SHAPES[key]) owner[(r0 + dr) * n + c0 + dc] = i;
  });
  let html = `<div class="board" style="--n:${n};--c:${cellSize(n)}"><span></span>`;
  for (let c = 0; c < n; c++) html += `<span class="clue">${p.cols[c]}</span>`;
  for (let r = 0; r < n; r++) {
    html += `<span class="clue">${p.rows[r]}</span>`;
    for (let c = 0; c < n; c++) {
      const i = owner[r * n + c];
      html += i < 0 ? `<span class="cell"></span>` : `<span class="cell f" style="--fill:${PIECE_COLORS[i % 3]}"></span>`;
    }
  }
  html += `</div><div class="pieces">${p.pieces.map((k, i) => shapeSvg(k, PIECE_COLORS[i % 3])).join("")}</div>`;
  return html;
}

function logic(p) {
  const n = p.size;
  let html = `<div class="board noclue" style="--n:${n};--c:${cellSize(n)}">`;
  for (let i = 0; i < n * n; i++) {
    const g = p.givens[i];
    html += g === -1
      ? `<span class="cell"><span class="s bit b${p.solution[i]}">${p.solution[i]}</span></span>`
      : `<span class="cell given"><span class="bit b${g}">${g}</span></span>`;
  }
  return html + "</div>";
}

function patterns(p) {
  const n = p.size;
  let html = `<div class="board" style="--n:${n};--c:${cellSize(n)}"><span></span>`;
  for (let c = 0; c < n; c++) html += `<span class="clue colclue">${p.colClues[c].map((v) => `<b>${v}</b>`).join("") || "<b>0</b>"}</span>`;
  for (let r = 0; r < n; r++) {
    html += `<span class="clue rowclue">${p.rowClues[r].join(" ") || "0"}</span>`;
    for (let c = 0; c < n; c++) html += p.solution[r * n + c] ? `<span class="cell f" style="--fill:var(--ink)"></span>` : `<span class="cell"></span>`;
  }
  return html + "</div>";
}

function numbers(p) {
  const n = p.size, sign = new Map();
  for (const { lo, hi } of p.relations) {
    const a = Math.min(lo, hi), b = Math.max(lo, hi);
    const horizontal = b - a === 1;
    sign.set(`${a}-${b}`, horizontal ? (lo === a ? "<" : ">") : (lo === a ? "∧" : "∨"));
  }
  let html = `<div class="board numbers" style="--n:${n};--m:${2 * n - 1};--c:${cellSize(n)}">`;
  for (let r = 0; r < n; r++) {
    for (let c = 0; c < n; c++) {
      const i = r * n + c, g = p.givens[i];
      html += g ? `<span class="cell given">${g}</span>` : `<span class="cell"><span class="s">${p.solution[i]}</span></span>`;
      if (c < n - 1) html += `<span class="sign">${sign.get(`${i}-${i + 1}`) || ""}</span>`;
    }
    if (r < n - 1) for (let c = 0; c < n; c++) {
      html += `<span class="sign">${sign.get(`${r * n + c}-${r * n + c + n}`) || ""}</span>`;
      if (c < n - 1) html += "<span></span>";
    }
  }
  return html + "</div>";
}

/** Thick borders where the area id changes (regions, cages) and along the edge */
function areaBorders(ids, n, i) {
  const r = Math.floor(i / n), c = i % n, thick = "2px solid var(--ink)";
  const side = (same) => (same ? "" : thick);
  const b = [
    side(r > 0 && ids[i - n] === ids[i]),
    side(c < n - 1 && ids[i + 1] === ids[i]),
    side(r < n - 1 && ids[i + n] === ids[i]),
    side(c > 0 && ids[i - 1] === ids[i]),
  ];
  return ["top", "right", "bottom", "left"].map((s, k) => (b[k] ? `border-${s}:${b[k]};` : "")).join("");
}

const REGION_TINTS = ["var(--purple)", "var(--orange)", "var(--teal)", "var(--soft)"];
const LINK_COLORS = ["#6D5B8C", "#E9A36A", "#5E9E94", "#D9667A", "#5B8BD9", "#C9A93A", "#8BBF5A", "#B06DB0", "#7A7A8C", "#3AA9C9", "#C26B3A", "#4A6B5A"];

function stars(p) {
  const n = p.size;
  let html = `<div class="board noclue tight" style="--n:${n};--c:${cellSize(n)}">`;
  for (let i = 0; i < n * n; i++) {
    const region = p.regions[i];
    const tint = `color-mix(in srgb, ${REGION_TINTS[region % 4]} ${region % 8 < 4 ? 30 : 55}%, var(--bg))`;
    const star = p.solution[Math.floor(i / n)] === i % n ? `<span class="s star">★</span>` : "";
    html += `<span class="cell" style="background:${tint};${areaBorders(p.regions, n, i)}">${star}</span>`;
  }
  return html + "</div>";
}

function links(p) {
  const n = p.size, colourOf = new Array(n * n).fill(-1);
  p.solution.forEach((path, c) => path.forEach((cell) => (colourOf[cell] = c)));
  let html = `<div class="board noclue" style="--n:${n};--c:${cellSize(n)}">`;
  for (let i = 0; i < n * n; i++) {
    const colour = LINK_COLORS[colourOf[i] % LINK_COLORS.length];
    const dot = p.ends[i] >= 0 ? `<span class="dot" style="background:${LINK_COLORS[p.ends[i] % LINK_COLORS.length]}"></span>` : "";
    html += `<span class="cell f path" style="--fill:color-mix(in srgb, ${colour} 45%, var(--bg))">${dot}</span>`;
  }
  return html + "</div>";
}

function sums(p) {
  const n = p.size, labelled = new Set();
  let html = `<div class="board noclue tight" style="--n:${n};--c:${cellSize(n)}">`;
  for (let i = 0; i < n * n; i++) {
    const cage = p.cages[i];
    const label = labelled.has(cage) ? "" : `<span class="cage">${p.sums[cage]}</span>`;
    labelled.add(cage);
    html += `<span class="cell" style="${areaBorders(p.cages, n, i)}">${label}<span class="s">${p.solution[i]}</span></span>`;
  }
  return html + "</div>";
}

const KIND_VIEWS = [
  ["blocks", blocks],
  ["logic", logic],
  ["stars", stars],
  ["patterns", patterns],
  ["links", links],
  ["numbers", numbers],
  ["sums", sums],
].map(([kind, draw]) => [kind, DISPLAY_NAMES[kind], draw]);

export function adminWeekPage(weekStart, days) {
  const daysHtml = days.map((d, i) => `
    <section class="day">
      <h2><span class="num">${i + 1}</span>${esc(dayTitle(d.date))} <small>${esc(d.date)}</small></h2>
      <div class="kinds">${KIND_VIEWS.map(([kind, title, draw]) => {
        const p = d.puzzles[kind];
        return `<article class="puzzle ${kind}"><h3>${title} <small>${kind} · ${p.size}×${p.size}</small></h3>${draw(p)}</article>`;
      }).join("")}</div>
    </section>`).join("");
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow"><title>Week of ${esc(weekStart)} · Pibbles preview</title>
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<style>
:root{--bg:#FAF7F2;--surface:#FFFFFF;--line:#E8E1D9;--soft:#C9D8D1;--teal:#7CAEA6;--purple:#6D5B8C;--orange:#E9A36A;--ink:#2D2A41;--muted:#6f6a7d;
--font:ui-rounded,"SF Pro Rounded","Nunito","Varela Round",system-ui,-apple-system,"Segoe UI",sans-serif;color-scheme:light dark}
@media (prefers-color-scheme:dark){:root{--bg:#1F1E2E;--surface:#2D2A41;--line:#41565A;--soft:#41565A;--teal:#6EA79A;--purple:#8B7CB0;--orange:#E29A57;--ink:#EDE8F5;--muted:#a9a3ba}}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font-family:var(--font);line-height:1.4}
header{position:sticky;top:0;z-index:2;display:flex;align-items:center;gap:12px;padding:12px 16px;background:color-mix(in srgb,var(--bg) 88%,transparent);backdrop-filter:blur(8px);border-bottom:1px solid var(--line)}
header svg{width:40px;height:40px;flex:none}header h1{font-size:1.1rem;margin:0;flex:1}header h1 small{display:block;font-weight:500;color:var(--muted);font-size:.8rem}
.switch{display:inline-flex;align-items:center;gap:8px;cursor:pointer;font-weight:600;font-size:.9rem;user-select:none}
.switch i{width:44px;height:26px;border-radius:13px;background:var(--line);position:relative;transition:background .2s}
.switch i::after{content:"";position:absolute;top:3px;left:3px;width:20px;height:20px;border-radius:50%;background:var(--surface);box-shadow:0 1px 3px #0003;transition:transform .2s}
#sol{position:absolute;opacity:0;pointer-events:none}
#sol:checked ~ header .switch i{background:var(--teal)}#sol:checked ~ header .switch i::after{transform:translateX(18px)}
#sol:focus-visible ~ header .switch i{outline:2px solid var(--purple);outline-offset:2px}
main{max-width:1200px;margin:0 auto;padding:16px}
.day{margin:0 0 28px}.day h2{display:flex;align-items:center;gap:10px;font-size:1.15rem;margin:8px 0 12px}
.day h2 small{color:var(--muted);font-weight:500;font-size:.85rem}
.num{display:inline-grid;place-items:center;width:28px;height:28px;border-radius:9px;background:var(--purple);color:#fff;font-size:.9rem}
.kinds{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:12px}
.puzzle{background:var(--surface);border:1px solid var(--line);border-radius:18px;padding:14px;overflow-x:auto}
.puzzle h3{margin:0 0 10px;font-size:1rem}.puzzle h3 small{color:var(--muted);font-weight:500}
.board{display:inline-grid;grid-template-columns:auto repeat(var(--n),var(--c));grid-auto-rows:var(--c);gap:3px;align-items:center}
.board.noclue{grid-template-columns:repeat(var(--n),var(--c))}
.cell{width:var(--c);height:var(--c);border-radius:6px;background:var(--bg);border:1px solid var(--line);display:grid;place-items:center;font-weight:700;font-size:calc(var(--c)*.5);transition:background .2s}
.clue{font-weight:700;font-size:.8rem;color:var(--muted);text-align:center;padding:0 4px}
.rowclue{text-align:right;white-space:nowrap;letter-spacing:.05em}
.patterns .board{grid-auto-rows:auto}.patterns .cell{height:var(--c)}
.colclue{display:flex;flex-direction:column;justify-content:flex-end;align-self:end;line-height:1.15}.colclue b{font-weight:700}
.given{background:var(--line)}
.bit.b0{color:var(--teal)}.bit.b1{color:var(--orange)}
.board.numbers{grid-template-columns:repeat(var(--m),auto);grid-auto-rows:auto;gap:0}
.numbers .sign{display:grid;place-items:center;min-width:14px;min-height:14px;color:var(--purple);font-weight:800;font-size:.85rem}
.s{visibility:hidden;opacity:.55}
#sol:checked ~ main .s{visibility:visible}
#sol:checked ~ main .f{background:var(--fill);border-color:transparent}
.tight{gap:0}.tight .cell{border-radius:0;position:relative}
.star{color:var(--orange);font-size:calc(var(--c)*.6);opacity:1;text-shadow:0 1px 0 #0003}
.cage{position:absolute;top:1px;left:3px;font-size:9px;font-weight:800;color:var(--purple);line-height:1}
.path{position:relative}.dot{width:62%;height:62%;border-radius:50%;box-shadow:0 0 0 2px var(--surface)}
.pieces{display:flex;flex-wrap:wrap;gap:10px;margin-top:12px;align-items:flex-end}
@media (max-width:420px){.kinds{grid-template-columns:1fr}header h1{font-size:1rem}}
</style></head>
<body>
<input type="checkbox" id="sol">
<header>${LOGO_SVG}<h1>Week of ${esc(dayTitle(weekStart))}<small>Preview for the owner · not public</small></h1>
<label class="switch" for="sol"><i></i>Solutions</label></header>
<main>${daysHtml}</main>
</body></html>`;
}

export function adminMessagePage(title, message) {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta name="robots" content="noindex">
<title>${esc(title)} · Pibbles</title><style>body{font-family:ui-rounded,system-ui,sans-serif;background:#FAF7F2;color:#2D2A41;display:grid;place-items:center;min-height:100vh;margin:0;padding:16px;text-align:center}
@media (prefers-color-scheme:dark){body{background:#1F1E2E;color:#EDE8F5}}</style></head>
<body><div>${LOGO_SVG.replace("<svg", '<svg width="72" height="72"')}<h1>${esc(title)}</h1><p>${esc(message)}</p></div></body></html>`;
}
