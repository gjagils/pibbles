import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import {
  SHAPES, runs, validatePuzzle, verifyBlocks, verifyLinks, verifyLogic, verifyNumbers, verifyPatterns, verifyStars, verifySums,
} from "../src/verify.js";
import { validateWeek } from "../src/pack.js";
import { isOpen, isScoreDate, isMonday } from "../src/dates.js";

const week = () => JSON.parse(readFileSync(new URL("./fixtures/week-2026-11-23.json", import.meta.url), "utf8"));
const day0 = week().days[0];

test("the shape table is the prototype's, key for key and cell for cell", () => {
  const prototype = createRequire(import.meta.url)("../../prototype/logic.js");
  assert.deepEqual(SHAPES, prototype.SHAPES);
  assert.deepEqual(Object.keys(SHAPES), Object.keys(prototype.SHAPES));
});

test("runs counts the coloured stretches in order", () => {
  assert.deepEqual(runs([1, 1, 0, 1, 0]), [2, 1]);
  assert.deepEqual(runs([0, 0, 0]), []);
  assert.deepEqual(runs([1, 1, 1]), [3]);
});

// ---- Blocks ----
test("blocks: a right placement passes, also with equal pieces swapped", () => {
  const p = { size: 4, pieces: ["I2", "I2", "O4"], rows: [2, 2, 2, 2], cols: [2, 2, 2, 2] };
  // I2 at row 0 col 0, I2 at row 1 col 0, O4 at row 2 col 2 -> rows 2,2,2,2 cols 2,2,2,2
  assert.equal(verifyBlocks(p, [0, 4, 10]), null);
  assert.equal(verifyBlocks(p, [4, 0, 10]), null);
  assert.equal(verifyBlocks(day0.blocks, day0.blocks.solution), null);
});

test("blocks: out of bounds, overlap, wrong counts and bad input fail", () => {
  const p = { size: 4, pieces: ["I2", "I2", "O4"], rows: [2, 2, 2, 2], cols: [2, 2, 2, 2] };
  assert.equal(verifyBlocks(p, [3, 4, 10]), "piece out of bounds"); // I2 from col 3 sticks out
  assert.equal(verifyBlocks(p, [0, 0, 10]), "pieces overlap");
  assert.equal(verifyBlocks(p, [0, 4, 8]), "column count wrong"); // O4 at row 2 col 0: rows fine, column 0 has 4
  assert.match(verifyBlocks(p, [0, 8, 10]), /pieces overlap|count wrong/);
  assert.equal(verifyBlocks(p, [0, 4]), "one position per piece");
  assert.equal(verifyBlocks(p, [0, 4, 99]), "one position per piece");
  assert.equal(verifyBlocks(p, "0,4,10"), "one position per piece");
});

// ---- Logic ----
const logicSolution = [
  0, 0, 1, 1,
  1, 1, 0, 0,
  0, 1, 0, 1,
  1, 0, 1, 0,
];
const logic = { size: 4, givens: [0, -1, -1, 1, -1, -1, -1, -1, -1, 1, -1, -1, -1, -1, -1, 0] };

test("logic: a right grid passes", () => {
  assert.equal(verifyLogic(logic, logicSolution), null);
  assert.equal(verifyLogic(day0.logic, day0.logic.solution), null);
});

test("logic: changed givens, unbalanced lines, three in a row and bad cells fail", () => {
  const swapped = logicSolution.slice();
  [swapped[0], swapped[1]] = [1, 0]; // keeps row 0 balanced, breaks the given and the columns
  assert.equal(verifyLogic(logic, swapped), "given changed");
  const free = { size: 4, givens: new Array(16).fill(-1) };
  assert.equal(verifyLogic(free, swapped), "line not balanced");
  const six = { size: 6, givens: new Array(36).fill(-1) };
  const triple = [
    0, 0, 0, 1, 1, 1,
    1, 1, 1, 0, 0, 0,
    0, 0, 0, 1, 1, 1,
    1, 1, 1, 0, 0, 0,
    0, 0, 0, 1, 1, 1,
    1, 1, 1, 0, 0, 0,
  ];
  assert.equal(verifyLogic(six, triple), "three equal in a row");
  assert.equal(verifyLogic(logic, logicSolution.map((v) => v + 1)), "one 0 or 1 per cell");
  assert.equal(verifyLogic(logic, logicSolution.slice(1)), "one 0 or 1 per cell");
});

// ---- Patterns ----
const patternSolution = [
  1, 1, 0,
  0, 0, 0,
  1, 0, 1,
];
const patterns = { size: 3, rowClues: [[2], [], [1, 1]], colClues: [[1, 1], [1], [1]] };

test("patterns: a grid whose runs match passes", () => {
  assert.equal(verifyPatterns(patterns, patternSolution), null);
  assert.equal(verifyPatterns(day0.patterns, day0.patterns.solution), null);
});

test("patterns: wrong runs in a row or a column fail", () => {
  assert.equal(verifyPatterns(patterns, [1, 1, 1, 0, 0, 0, 1, 0, 1]), "row clue not met");
  assert.equal(verifyPatterns(patterns, [0, 1, 1, 0, 0, 0, 1, 0, 1]), "column clue not met");
  assert.equal(verifyPatterns(patterns, [1, 1, 0]), "one 0 or 1 per cell");
});

// ---- Numbers ----
const numberSolution = [
  1, 2, 3,
  2, 3, 1,
  3, 1, 2,
];
const numbers = { size: 3, givens: [1, 0, 0, 0, 0, 0, 0, 0, 2], relations: [{ lo: 1, hi: 2 }, { lo: 3, hi: 0 }] };

test("numbers: a Latin square that keeps givens and relations passes", () => {
  assert.equal(verifyNumbers({ ...numbers, relations: [{ lo: 0, hi: 1 }, { lo: 0, hi: 3 }] }, numberSolution), null);
  assert.equal(verifyNumbers(day0.numbers, day0.numbers.solution), null);
});

test("numbers: givens, repeats, relations and out-of-range values fail", () => {
  assert.equal(verifyNumbers(numbers, numberSolution), "relation not met"); // cell 3 (2) is not < cell 0 (1)
  const moved = [2, 1, 3, 1, 3, 2, 3, 2, 1];
  assert.equal(verifyNumbers(numbers, moved), "given changed");
  const free = { size: 3, givens: new Array(9).fill(0), relations: [] };
  assert.equal(verifyNumbers(free, [1, 2, 3, 1, 2, 3, 2, 3, 1]), "number twice in a column");
  assert.equal(verifyNumbers(free, [1, 1, 3, 2, 3, 1, 3, 2, 2]), "number twice in a row");
  assert.equal(verifyNumbers(free, [0, 2, 3, 2, 3, 1, 3, 1, 2]), "one number 1..n per cell");
});

// ---- Stars ----
// 4x4 with stars at columns 1, 3, 0, 2 (regions 0, 1, 3, 2)
const stars = {
  size: 4,
  regions: [
    0, 0, 1, 1,
    0, 2, 2, 1,
    3, 2, 2, 1,
    3, 3, 2, 2,
  ],
};

test("stars: one per row, column and region, not touching, passes", () => {
  assert.equal(verifyStars(stars, [1, 3, 0, 2]), null);
  assert.equal(verifyStars(day0.stars, day0.stars.solution), null);
});

test("stars: same column, same region, touching and bad input fail", () => {
  assert.equal(verifyStars(stars, [1, 3, 0, 1]), "two stars in a column");
  const shared = { size: 4, regions: [0, 1, 1, 1, 0, 2, 2, 1, 3, 2, 2, 1, 3, 3, 2, 2] }; // stars 1 and 2 both in region 1
  assert.equal(verifyStars(shared, [1, 3, 0, 2]), "two stars in a region");
  assert.equal(verifyStars({ size: 4, regions: [0, 0, 1, 1, 0, 0, 1, 1, 2, 2, 3, 3, 2, 2, 3, 3] }, [0, 2, 1, 3]), "stars touch");
  assert.equal(verifyStars(stars, [1, 3, 0]), "one column per row");
  assert.equal(verifyStars(stars, [1, 3, 0, 4]), "one column per row");
});

// ---- Links ----
// 3x3: colour 0 runs down the left column, colour 1 snakes through the rest
//   0 1 1      paths: [0,3,6], [1,2,5,4,7,8]
//   0 1 1
//   0 1 1
const links = { size: 3, ends: [0, 1, -1, -1, -1, -1, 0, -1, 1] };

test("links: paths that join their dots and fill the board pass, either way round", () => {
  assert.equal(verifyLinks(links, [[0, 3, 6], [1, 2, 5, 4, 7, 8]]), null);
  assert.equal(verifyLinks(links, [[6, 3, 0], [8, 7, 4, 5, 2, 1]]), null);
  assert.equal(verifyLinks(day0.links, day0.links.solution), null);
});

test("links: wrong ends, jumps, shared cells, gaps and bad input fail", () => {
  assert.equal(verifyLinks(links, [[0, 3, 6]]), "one path per colour");
  assert.equal(verifyLinks(links, [[0, 3], [1, 2, 5, 4, 7, 8]]), "path does not join its dots");
  assert.equal(verifyLinks(links, [[0, 3, 6], [1, 2, 5, 8]]), "cells left empty");
  assert.equal(verifyLinks(links, [[0, 3, 6], [1, 4, 2, 5, 7, 8]]), "path jumps");
  assert.equal(verifyLinks(links, [[0, 3, 6], [1, 2, 5, 4, 3, 4, 7, 8]]), "paths share a cell");
  assert.equal(verifyLinks(links, [[0, 3, 6], [1, 2, 5, 4, 7, 9]]), "path needs cells");
  assert.equal(verifyLinks(links, [[0, 3, 6], "1,8"]), "path needs cells");
  assert.equal(verifyLinks(links, [[0], [1, 2, 5, 4, 7, 8]]), "path needs cells");
});

// ---- Sums ----
const sums = { size: 3, cages: [0, 0, 1, 2, 3, 1, 2, 3, 3], sums: [3, 4, 5, 6] };
// 1 2 3 / 2 3 1 / 3 1 2 -> cage0 1+2=3, cage1 3+1=4, cage2 2+3=5, cage3 3+1+2=6

test("sums: a Latin square whose cages add up passes", () => {
  assert.equal(verifySums(sums, numberSolution), null);
  assert.equal(verifySums(day0.sums, day0.sums.solution), null);
});

test("sums: a wrong cage sum or a broken square fails", () => {
  assert.equal(verifySums(sums, [2, 3, 1, 3, 1, 2, 1, 2, 3]), "cage sum wrong");
  assert.equal(verifySums(sums, [1, 2, 3, 1, 2, 3, 1, 2, 3]), "number twice in a column");
  assert.equal(verifySums(sums, [1, 2]), "one number 1..n per cell");
});

// ---- Uploaded shapes ----
test("validatePuzzle keeps exactly the documented fields", () => {
  const { puzzle } = validatePuzzle("blocks", { ...day0.blocks, attempts: 3, nodes: 99 });
  assert.deepEqual(Object.keys(puzzle), ["size", "pieces", "rows", "cols", "solution"]);
  assert.deepEqual(Object.keys(validatePuzzle("numbers", day0.numbers).puzzle), ["size", "givens", "relations", "solution"]);
});

test("validatePuzzle refuses broken shapes and wrong solutions", () => {
  assert.match(validatePuzzle("blocks", { ...day0.blocks, pieces: ["X9"] }).error, /shape keys/);
  assert.match(validatePuzzle("blocks", { ...day0.blocks, rows: [1] }).error, /rows\/cols/);
  assert.match(validatePuzzle("blocks", { ...day0.blocks, solution: day0.blocks.solution.map(() => 0) }).error, /solution fails/);
  assert.match(validatePuzzle("logic", { ...logic, size: 5 }).error, /even size/);
  assert.match(validatePuzzle("logic", { ...logic, solution: logicSolution.map((v) => 1 - v) }).error, /given changed/);
  assert.match(validatePuzzle("patterns", { ...patterns, rowClues: [[4], [], [1, 1]], solution: patternSolution }).error, /fit/);
  assert.match(validatePuzzle("numbers", { ...numbers, relations: [{ lo: 0, hi: 4 }], solution: numberSolution }).error, /neighbouring/);
  assert.match(validatePuzzle("numbers", { ...numbers, relations: [{ lo: 2, hi: 3 }], solution: numberSolution }).error, /neighbouring/);
  assert.match(validatePuzzle("logic", null).error, /not an object/);
  assert.equal(validatePuzzle("stars", { ...stars, solution: [1, 3, 0, 2] }).error, undefined);
  assert.match(validatePuzzle("stars", { ...stars, regions: stars.regions.map((r) => (r === 3 ? 0 : r)), solution: [1, 3, 0, 2] }).error, /each of 0..size-1/);
  assert.match(validatePuzzle("stars", { ...stars, solution: [0, 2, 1, 3] }).error, /solution fails/);
  assert.equal(validatePuzzle("links", { ...links, solution: [[0, 3, 6], [1, 2, 5, 4, 7, 8]] }).error, undefined);
  assert.match(validatePuzzle("links", { size: 3, ends: [0, 1, -1, -1, -1, -1, 0, -1, -1], solution: [] }).error, /exactly two dots/);
  assert.match(validatePuzzle("links", { size: 3, ends: [0, 2, -1, -1, -1, -1, 0, -1, 2], solution: [] }).error, /exactly two dots/);
  assert.match(validatePuzzle("links", { ...links, solution: [[0, 3, 6], [1, 2, 5, 8]] }).error, /cells left empty/);
  assert.equal(validatePuzzle("sums", { ...sums, solution: numberSolution }).error, undefined);
  assert.match(validatePuzzle("sums", { ...sums, sums: [3, 4, 5], solution: numberSolution }).error, /cage ids/);
  assert.match(validatePuzzle("sums", { ...sums, sums: [3, 4, 5, 7], solution: numberSolution }).error, /cage sum wrong/);
});

test("validateWeek: the fixture passes; dates, Monday and day count are checked", () => {
  assert.equal(validateWeek(week()).error, undefined);
  const notMonday = week();
  notMonday.weekStart = "2026-11-24";
  assert.match(validateWeek(notMonday).error, /Monday/);
  const gap = week();
  gap.days[3].date = "2026-11-27";
  assert.match(validateWeek(gap).error, /days\[3\]\.date must be 2026-11-26/);
  const short = week();
  short.days.pop();
  assert.match(validateWeek(short).error, /7 days/);
  const missing = week();
  delete missing.days[2].numbers;
  assert.match(validateWeek(missing).error, /2026-11-25 numbers/);
  assert.match(validateWeek([]).error, /object/);
});

test("dates: open from UTC+14, scores for today and yesterday anywhere", () => {
  const now = Date.UTC(2026, 10, 23, 10, 0); // Monday 23 Nov, 10:00 UTC
  assert.ok(isMonday("2026-11-23"));
  assert.ok(isOpen("2026-11-24", now)); // already the 24th in Kiritimati
  assert.ok(!isOpen("2026-11-25", now));
  assert.ok(isScoreDate("2026-11-21", now)); // yesterday in UTC-12
  assert.ok(!isScoreDate("2026-11-20", now));
  assert.ok(!isScoreDate("2026-11-25", now));
});
