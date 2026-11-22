// Puzzle shapes and answer checks for the four kinds (docs/puzzels.md).
// Every check returns null when the answer is right, otherwise a short reason.
// Cells are row by row: index = row * size + col.

export const KINDS = ["blocks", "logic", "patterns", "numbers", "stars", "links", "sums"];

/** Names in the app and on the site; the JSON keys stay the kind ids (docs/puzzels.md) */
export const DISPLAY_NAMES = {
  blocks: "Blocks", logic: "Duo", patterns: "Pixels", numbers: "Signs", stars: "Stars", links: "Links", sums: "Sums",
};

// Copied from prototype/logic.js (SHAPES): keys and cells must stay identical,
// [row, col] offsets from the top-left of the piece's bounding box.
export const SHAPES = {
  I2: [[0, 0], [0, 1]], I2v: [[0, 0], [1, 0]],
  I3: [[0, 0], [0, 1], [0, 2]], I3v: [[0, 0], [1, 0], [2, 0]],
  L3a: [[0, 0], [1, 0], [1, 1]], L3b: [[0, 0], [0, 1], [1, 0]], L3c: [[0, 0], [0, 1], [1, 1]], L3d: [[0, 1], [1, 0], [1, 1]],
  O4: [[0, 0], [0, 1], [1, 0], [1, 1]],
  I4: [[0, 0], [0, 1], [0, 2], [0, 3]], I4v: [[0, 0], [1, 0], [2, 0], [3, 0]],
  L4a: [[0, 0], [1, 0], [2, 0], [2, 1]], L4b: [[0, 0], [0, 1], [0, 2], [1, 0]], L4c: [[0, 0], [0, 1], [1, 1], [2, 1]], L4d: [[0, 2], [1, 0], [1, 1], [1, 2]],
  J4a: [[0, 1], [1, 1], [2, 0], [2, 1]], J4b: [[0, 0], [1, 0], [1, 1], [1, 2]], J4c: [[0, 0], [0, 1], [1, 0], [2, 0]], J4d: [[0, 0], [0, 1], [0, 2], [1, 2]],
  T4a: [[0, 0], [0, 1], [0, 2], [1, 1]], T4b: [[0, 1], [1, 0], [1, 1], [2, 1]], T4c: [[0, 1], [1, 0], [1, 1], [1, 2]], T4d: [[0, 0], [1, 0], [1, 1], [2, 0]],
  S4a: [[0, 1], [0, 2], [1, 0], [1, 1]], S4b: [[0, 0], [1, 0], [1, 1], [2, 1]],
  Z4a: [[0, 0], [0, 1], [1, 1], [1, 2]], Z4b: [[0, 1], [1, 0], [1, 1], [2, 0]],
};

const isInt = (v) => Number.isInteger(v);
const intArray = (a, length, min, max) =>
  Array.isArray(a) && a.length === length && a.every((v) => isInt(v) && v >= min && v <= max);

/** Lengths of the runs of 1s in a line, in order ([] for an empty line) */
export function runs(line) {
  const out = [];
  let run = 0;
  for (const v of line) {
    if (v === 1) run++;
    else if (run) out.push(run), (run = 0);
  }
  if (run) out.push(run);
  return out;
}

const row = (cells, n, r) => cells.slice(r * n, r * n + n);
const col = (cells, n, c) => Array.from({ length: n }, (_, r) => cells[r * n + c]);
const sameList = (a, b) => a.length === b.length && a.every((v, i) => v === b[i]);

// ---- Answer checks ----

/** Blocks: solution[i] is the top-left cell of piece i's bounding box */
export function verifyBlocks(p, solution) {
  const n = p.size;
  if (!intArray(solution, p.pieces.length, 0, n * n - 1)) return "one position per piece";
  const grid = new Uint8Array(n * n);
  for (let i = 0; i < p.pieces.length; i++) {
    const r0 = Math.floor(solution[i] / n), c0 = solution[i] % n;
    for (const [dr, dc] of SHAPES[p.pieces[i]]) {
      const r = r0 + dr, c = c0 + dc;
      if (r >= n || c >= n) return "piece out of bounds";
      if (grid[r * n + c]) return "pieces overlap";
      grid[r * n + c] = 1;
    }
  }
  for (let i = 0; i < n; i++) {
    if (row(grid, n, i).reduce((a, b) => a + b, 0) !== p.rows[i]) return "row count wrong";
    if (col(grid, n, i).reduce((a, b) => a + b, 0) !== p.cols[i]) return "column count wrong";
  }
  return null;
}

/** Logic: 0/1 cells, givens kept, balanced lines, never three equal in a row */
export function verifyLogic(p, solution) {
  const n = p.size;
  if (!intArray(solution, n * n, 0, 1)) return "one 0 or 1 per cell";
  if (p.givens.some((g, i) => g !== -1 && g !== solution[i])) return "given changed";
  for (let i = 0; i < n; i++) {
    for (const line of [row(solution, n, i), col(solution, n, i)]) {
      if (line.reduce((a, b) => a + b, 0) * 2 !== n) return "line not balanced";
      for (let j = 2; j < n; j++) if (line[j] === line[j - 1] && line[j] === line[j - 2]) return "three equal in a row";
    }
  }
  return null;
}

/** Patterns: 0/1 cells whose runs match the clues of every row and column */
export function verifyPatterns(p, solution) {
  const n = p.size;
  if (!intArray(solution, n * n, 0, 1)) return "one 0 or 1 per cell";
  for (let i = 0; i < n; i++) {
    if (!sameList(runs(row(solution, n, i)), p.rowClues[i])) return "row clue not met";
    if (!sameList(runs(col(solution, n, i)), p.colClues[i])) return "column clue not met";
  }
  return null;
}

/** Numbers: Latin square of 1..n, givens kept, every lo < hi */
export function verifyNumbers(p, solution) {
  const n = p.size;
  if (!intArray(solution, n * n, 1, n)) return "one number 1..n per cell";
  if (p.givens.some((g, i) => g !== 0 && g !== solution[i])) return "given changed";
  const wrong = latin(solution, n);
  if (wrong) return wrong;
  if (p.relations.some(({ lo, hi }) => !(solution[lo] < solution[hi]))) return "relation not met";
  return null;
}

/** Latin square of 1..n: null or a reason */
function latin(solution, n) {
  if (!intArray(solution, n * n, 1, n)) return "one number 1..n per cell";
  for (let i = 0; i < n; i++) {
    if (new Set(row(solution, n, i)).size !== n) return "number twice in a row";
    if (new Set(col(solution, n, i)).size !== n) return "number twice in a column";
  }
  return null;
}

/** Stars: solution[r] is the star's column in row r; one per row, column and region, never touching */
export function verifyStars(p, solution) {
  const n = p.size;
  if (!intArray(solution, n, 0, n - 1)) return "one column per row";
  if (new Set(solution).size !== n) return "two stars in a column";
  if (new Set(solution.map((c, r) => p.regions[r * n + c])).size !== n) return "two stars in a region";
  // Distinct columns already keep stars in one column apart; only the next row can touch
  for (let r = 1; r < n; r++) if (Math.abs(solution[r] - solution[r - 1]) <= 1) return "stars touch";
  return null;
}

const adjacent = (a, b, n) => (Math.abs(a - b) === 1 && Math.floor(a / n) === Math.floor(b / n)) || Math.abs(a - b) === n;

/** The two dot cells per colour, colour by colour */
export function linkColours(ends) {
  const colours = [];
  ends.forEach((c, i) => {
    if (c >= 0) (colours[c] ||= []).push(i);
  });
  return colours;
}

/** Links: one path per colour from dot to dot (either way round), through neighbours, filling the board without sharing cells */
export function verifyLinks(p, solution) {
  const n = p.size, colours = linkColours(p.ends);
  if (!Array.isArray(solution) || solution.length !== colours.length) return "one path per colour";
  const used = new Uint8Array(n * n);
  let total = 0;
  for (let c = 0; c < colours.length; c++) {
    const path = solution[c];
    if (!Array.isArray(path) || path.length < 2 || !intArray(path, path.length, 0, n * n - 1)) return "path needs cells";
    const [a, b] = colours[c], first = path[0], last = path[path.length - 1];
    if (!((first === a && last === b) || (first === b && last === a))) return "path does not join its dots";
    for (let i = 0; i < path.length; i++) {
      if (used[path[i]]) return "paths share a cell";
      used[path[i]] = 1;
      if (i > 0 && !adjacent(path[i - 1], path[i], n)) return "path jumps";
    }
    total += path.length;
  }
  return total === n * n ? null : "cells left empty";
}

/** Sums: Latin square of 1..n and every cage adds up to its sum */
export function verifySums(p, solution) {
  const wrong = latin(solution, p.size);
  if (wrong) return wrong;
  const totals = new Array(p.sums.length).fill(0);
  p.cages.forEach((cage, i) => (totals[cage] += solution[i]));
  return totals.every((t, i) => t === p.sums[i]) ? null : "cage sum wrong";
}

const VERIFIERS = {
  blocks: verifyBlocks, logic: verifyLogic, patterns: verifyPatterns, numbers: verifyNumbers,
  stars: verifyStars, links: verifyLinks, sums: verifySums,
};

/** Checks an answer for a puzzle of `kind` that passed validatePuzzle */
export function verifySolution(kind, puzzle, solution) {
  return VERIFIERS[kind](puzzle, solution);
}

// ---- Shape checks for uploaded puzzles ----

const plainObject = (v) => v !== null && typeof v === "object" && !Array.isArray(v);
const clueList = (clues, n) =>
  Array.isArray(clues) && clues.length === n &&
  clues.every((c) => Array.isArray(c) && c.every((v) => isInt(v) && v >= 1) && c.reduce((a, b) => a + b, 0) + Math.max(0, c.length - 1) <= n);

/**
 * Checks the JSON shape of one puzzle and that its own `solution` is right.
 * Returns { puzzle } with exactly the documented fields, or { error }.
 */
export function validatePuzzle(kind, p) {
  if (!plainObject(p)) return { error: `${kind}: not an object` };
  const n = p.size;
  let puzzle;
  if (kind === "blocks") {
    if (!isInt(n) || n < 3 || n > 12) return { error: "blocks: size 3..12" };
    if (!Array.isArray(p.pieces) || p.pieces.length < 1 || p.pieces.length > 20 || !p.pieces.every((k) => Object.hasOwn(SHAPES, k)))
      return { error: "blocks: pieces must be known shape keys" };
    if (!intArray(p.rows, n, 0, n) || !intArray(p.cols, n, 0, n)) return { error: "blocks: rows/cols need size counts 0..size" };
    puzzle = { size: n, pieces: p.pieces, rows: p.rows, cols: p.cols, solution: p.solution };
  } else if (kind === "logic") {
    if (!isInt(n) || n < 4 || n > 14 || n % 2) return { error: "logic: even size 4..14" };
    if (!intArray(p.givens, n * n, -1, 1)) return { error: "logic: givens need size² values -1, 0 or 1" };
    puzzle = { size: n, givens: p.givens, solution: p.solution };
  } else if (kind === "patterns") {
    if (!isInt(n) || n < 3 || n > 15) return { error: "patterns: size 3..15" };
    if (!clueList(p.rowClues, n) || !clueList(p.colClues, n)) return { error: "patterns: rowClues/colClues need size lists of runs that fit" };
    puzzle = { size: n, rowClues: p.rowClues, colClues: p.colClues, solution: p.solution };
  } else if (kind === "numbers") {
    if (!isInt(n) || n < 3 || n > 9) return { error: "numbers: size 3..9" };
    if (!intArray(p.givens, n * n, 0, n)) return { error: "numbers: givens need size² values 0..size" };
    const neighbours = (a, b) => adjacent(a, b, n);
    if (!Array.isArray(p.relations) || !p.relations.every((r) =>
      plainObject(r) && isInt(r.lo) && isInt(r.hi) && r.lo >= 0 && r.hi >= 0 && r.lo < n * n && r.hi < n * n && neighbours(r.lo, r.hi)))
      return { error: "numbers: relations need {lo, hi} of neighbouring cells" };
    puzzle = { size: n, givens: p.givens, relations: p.relations.map(({ lo, hi }) => ({ lo, hi })), solution: p.solution };
  } else if (kind === "stars") {
    if (!isInt(n) || n < 4 || n > 12) return { error: "stars: size 4..12" };
    if (!intArray(p.regions, n * n, 0, n - 1) || new Set(p.regions).size !== n)
      return { error: "stars: regions need size² region ids, each of 0..size-1 used" };
    puzzle = { size: n, regions: p.regions, solution: p.solution };
  } else if (kind === "links") {
    if (!isInt(n) || n < 3 || n > 12) return { error: "links: size 3..12" };
    if (!intArray(p.ends, n * n, -1, n * n)) return { error: "links: ends need size² values, -1 for no dot" };
    const colours = linkColours(p.ends);
    // A hole in the colour numbers leaves an empty slot in the sparse array
    if (colours.length < 1 || Array.from(colours, (cells) => (cells ? cells.length : 0)).some((k) => k !== 2))
      return { error: "links: colours 0..k-1, each exactly two dots" };
    puzzle = { size: n, ends: p.ends, solution: p.solution };
  } else if (kind === "sums") {
    if (!isInt(n) || n < 3 || n > 9) return { error: "sums: size 3..9" };
    if (!Array.isArray(p.sums) || p.sums.length < 1 || !p.sums.every((v) => isInt(v) && v >= 1 && v <= n * n * n))
      return { error: "sums: sums need a positive number per cage" };
    if (!intArray(p.cages, n * n, 0, p.sums.length - 1) || new Set(p.cages).size !== p.sums.length)
      return { error: "sums: cages need size² cage ids, each of 0..k-1 used, k = sums.length" };
    puzzle = { size: n, cages: p.cages, sums: p.sums, solution: p.solution };
  } else {
    return { error: `unknown kind ${kind}` };
  }
  const wrong = verifySolution(kind, puzzle, p.solution);
  if (wrong) return { error: `${kind}: solution fails (${wrong})` };
  return { puzzle };
}

/** The puzzle without its solution, for the apps */
export function withoutSolution(puzzle) {
  const { solution, ...rest } = puzzle;
  return rest;
}
