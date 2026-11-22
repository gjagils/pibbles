import Foundation
import XCTest
@testable import PibblesCore

final class PatternsRulesTests: XCTestCase {
    /// 3 × 3:   X X .
    ///          . . .
    ///          X . X
    private let puzzle = PatternsPuzzle(size: 3, rowClues: [[2], [], [1, 1]],
                                        colClues: [[1, 1], [1], [1]],
                                        solution: [1, 1, 0, 0, 0, 0, 1, 0, 1])

    func testCluesAreTheRunsOfFilledCells() {
        XCTAssertEqual(PatternsRules.clues(of: [1, 1, 0, 1, 0]), [2, 1])
        XCTAssertEqual(PatternsRules.clues(of: [0, 0, 0]), [Int]())
        XCTAssertEqual(PatternsRules.clues(of: [Int]()), [Int]())
        XCTAssertEqual(PatternsRules.clues(of: [1, 1, 1, 1, 1]), [5])
        XCTAssertEqual(PatternsRules.clues(of: [0, 1, 0, 1, 1, 1, 0, 1]), [1, 3, 1])
    }

    func testMarkedCellsCountAsEmpty() {
        XCTAssertEqual(PatternsRules.clues(of: [1, 2, 1, 1, 2]), [1, 2])
        XCTAssertEqual(PatternsRules.clues(of: [2, 2, 2]), [Int]())
    }

    func testDerivedPuzzleHasTheCluesOfItsSolution() {
        let derived = PatternsRules.puzzle(size: 3, solution: puzzle.solution)
        XCTAssertEqual(derived, puzzle)
    }

    func testSolutionSolvesThePuzzle() {
        XCTAssertTrue(PatternsRules.isSolved(puzzle, cells: puzzle.solution))
        // Marks (2) instead of empty cells (0) count the same.
        XCTAssertTrue(PatternsRules.isSolved(puzzle, cells: [1, 1, 2, 2, 2, 2, 1, 2, 1]))
    }

    func testWrongCellsDoNotSolveThePuzzle() {
        XCTAssertFalse(PatternsRules.isSolved(puzzle, cells: [1, 1, 0, 0, 1, 0, 1, 0, 1]))
        XCTAssertFalse(PatternsRules.isSolved(puzzle, cells: Array(repeating: 0, count: 9)))
        XCTAssertFalse(PatternsRules.isSolved(puzzle, cells: [1, 1, 0]))
    }

    func testRowAndColumnMatchSeparately() {
        // Only the top row is done.
        let cells = [1, 1, 0, 0, 0, 0, 0, 0, 0]
        XCTAssertTrue(PatternsRules.rowMatches(puzzle, cells: cells, row: 0))
        XCTAssertTrue(PatternsRules.rowMatches(puzzle, cells: cells, row: 1))
        XCTAssertFalse(PatternsRules.rowMatches(puzzle, cells: cells, row: 2))
        XCTAssertFalse(PatternsRules.colMatches(puzzle, cells: cells, col: 0))
        XCTAssertTrue(PatternsRules.colMatches(puzzle, cells: cells, col: 1))
        XCTAssertFalse(PatternsRules.colMatches(puzzle, cells: cells, col: 2))
    }

    func testLinesOutsideTheGridDoNotMatch() {
        XCTAssertFalse(PatternsRules.rowMatches(puzzle, cells: puzzle.solution, row: -1))
        XCTAssertFalse(PatternsRules.rowMatches(puzzle, cells: puzzle.solution, row: 3))
        XCTAssertFalse(PatternsRules.colMatches(puzzle, cells: puzzle.solution, col: 3))
        XCTAssertFalse(PatternsRules.colMatches(puzzle, cells: [1, 1], col: 0))
    }

    func testJSONHasExactlyTheAgreedKeys() throws {
        let small = PatternsPuzzle(size: 2, rowClues: [[1], [1]], colClues: [[2], []], solution: [1, 0, 1, 0])
        let encoder = JSONEncoder()
        encoder.outputFormatting = JSONEncoder.OutputFormatting.sortedKeys
        let data = try encoder.encode(small)
        let text = String(data: data, encoding: String.Encoding.utf8)
        XCTAssertEqual(text, "{\"colClues\":[[2],[]],\"rowClues\":[[1],[1]],\"size\":2,\"solution\":[1,0,1,0]}")
        let decoded = try JSONDecoder().decode(PatternsPuzzle.self, from: data)
        XCTAssertEqual(decoded, small)
    }

    func testJSONFromTheServerDecodes() throws {
        let json = "{\"size\":3,\"rowClues\":[[2],[],[1,1]],\"colClues\":[[1,1],[1],[1]],\"solution\":[1,1,0,0,0,0,1,0,1]}"
        let data = try XCTUnwrap(json.data(using: String.Encoding.utf8))
        let decoded = try JSONDecoder().decode(PatternsPuzzle.self, from: data)
        XCTAssertEqual(decoded, puzzle)
        XCTAssertEqual(decoded.rowClues[1], [Int]())
        XCTAssertEqual(decoded.rowClues[2], [1, 1])
    }

    func testGeneratedPuzzleSurvivesAJSONRoundTrip() throws {
        let generated = PatternsGenerator.generate(weekday: 6, seed: "json")
        let data = try JSONEncoder().encode(generated)
        let decoded = try JSONDecoder().decode(PatternsPuzzle.self, from: data)
        XCTAssertEqual(decoded, generated)
    }
}
