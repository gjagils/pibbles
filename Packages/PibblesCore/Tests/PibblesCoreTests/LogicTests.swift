import Foundation
import XCTest
@testable import PibblesCore

final class LogicRulesTests: XCTestCase {
    // A valid 4×4 grid:
    // 0 0 1 1
    // 1 1 0 0
    // 0 1 0 1
    // 1 0 1 0
    let solution4 = [0, 0, 1, 1,
                     1, 1, 0, 0,
                     0, 1, 0, 1,
                     1, 0, 1, 0]

    func puzzle4() -> LogicPuzzle {
        let givens = [0, -1, -1, -1,
                      -1, -1, -1, -1,
                      -1, -1, -1, -1,
                      -1, -1, -1, -1]
        return LogicPuzzle(size: 4, givens: givens, solution: solution4)
    }

    func testSolvedGridIsSolved() {
        XCTAssertTrue(LogicRules.isSolved(puzzle4(), values: solution4))
        XCTAssertEqual(LogicRules.conflicts(puzzle4(), values: solution4), [Int]())
    }

    func testIncompleteGridIsNotSolved() {
        var values = solution4
        values[5] = -1
        XCTAssertFalse(LogicRules.isSolved(puzzle4(), values: values))
        XCTAssertEqual(LogicRules.conflicts(puzzle4(), values: values), [Int]())
    }

    func testWrongLengthIsNotSolved() {
        XCTAssertFalse(LogicRules.isSolved(puzzle4(), values: [0, 1]))
    }

    func testChangedGivenIsNotSolved() {
        // Another valid grid that disagrees with the given 0 at cell 0.
        let other = [1, 1, 0, 0,
                     0, 0, 1, 1,
                     1, 0, 1, 0,
                     0, 1, 0, 1]
        XCTAssertTrue(LogicRules.conflicts(puzzle4(), values: other).isEmpty)
        XCTAssertFalse(LogicRules.isSolved(puzzle4(), values: other))
        let free = LogicPuzzle(size: 4, givens: Array(repeating: -1, count: 16), solution: solution4)
        XCTAssertTrue(LogicRules.isSolved(free, values: other))
    }

    func testThreeInARowIsAConflict() {
        var values = Array(repeating: -1, count: 36)
        values[6] = 1
        values[7] = 1
        values[8] = 1
        let puzzle = LogicPuzzle(size: 6, givens: Array(repeating: -1, count: 36),
                                 solution: Array(repeating: 0, count: 36))
        XCTAssertEqual(LogicRules.conflicts(puzzle, values: values), [6, 7, 8])
        XCTAssertFalse(LogicRules.isSolved(puzzle, values: values))
    }

    func testThreeInAColumnIsAConflict() {
        var values = Array(repeating: -1, count: 36)
        values[2] = 0
        values[8] = 0
        values[14] = 0
        values[20] = 0
        let puzzle = LogicPuzzle(size: 6, givens: Array(repeating: -1, count: 36),
                                 solution: Array(repeating: 0, count: 36))
        XCTAssertEqual(LogicRules.conflicts(puzzle, values: values), [2, 8, 14, 20])
    }

    func testTooManyOfOneValueInARowIsAConflict() {
        // Row 0: 1 1 0 1 — three ones in a row of four, no three adjacent.
        var values = Array(repeating: -1, count: 16)
        values[0] = 1
        values[1] = 1
        values[2] = 0
        values[3] = 1
        XCTAssertEqual(LogicRules.conflicts(puzzle4(), values: values), [0, 1, 3])
    }

    func testTooManyOfOneValueInAColumnIsAConflict() {
        var values = Array(repeating: -1, count: 16)
        values[1] = 0
        values[5] = 1
        values[9] = 0
        values[13] = 0
        XCTAssertEqual(LogicRules.conflicts(puzzle4(), values: values), [1, 9, 13])
    }

    func testBalancedTwoPairsAreNoConflict() {
        var values = Array(repeating: -1, count: 16)
        values[0] = 1
        values[1] = 1
        values[2] = 0
        values[3] = 0
        XCTAssertEqual(LogicRules.conflicts(puzzle4(), values: values), [Int]())
    }
}

final class LogicSolverTests: XCTestCase {
    func testFullValidGridHasOneSolution() {
        let grid = [0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0]
        XCTAssertEqual(LogicSolver.countSolutions(size: 4, givens: grid, limit: 2), 1)
    }

    func testUniquePuzzle() {
        // 4×4 with enough givens for exactly one solution (solution4 of the rules tests).
        let givens = [0, 0, -1, -1,
                      -1, -1, -1, 0,
                      0, -1, -1, -1,
                      -1, -1, 1, -1]
        XCTAssertEqual(LogicSolver.countSolutions(size: 4, givens: givens, limit: 5), 1)
    }

    func testEmptyGridIsAmbiguous() {
        let empty = Array(repeating: -1, count: 16)
        // A 4×4 binary grid without the uniqueness-of-rows rule has 90 fillings.
        XCTAssertEqual(LogicSolver.countSolutions(size: 4, givens: empty, limit: 1000), 90)
        XCTAssertEqual(LogicSolver.countSolutions(size: 4, givens: empty, limit: 2), 2)
        XCTAssertEqual(LogicSolver.countSolutions(size: 4, givens: empty, limit: 1), 1)
    }

    func testImpossiblePuzzleHasNoSolution() {
        // Three ones in row 0.
        var givens = Array(repeating: -1, count: 36)
        givens[0] = 1
        givens[1] = 1
        givens[2] = 1
        XCTAssertEqual(LogicSolver.countSolutions(size: 6, givens: givens, limit: 2), 0)
        // Row 0 of a 4×4 forced to three zeros without adjacency: 0 1 0 0 → too many zeros.
        let crowded = [0, 1, 0, 0,
                       -1, -1, -1, -1,
                       -1, -1, -1, -1,
                       -1, -1, -1, -1]
        XCTAssertEqual(LogicSolver.countSolutions(size: 4, givens: crowded, limit: 2), 0)
    }

    func testPropagationAloneCanBeContradictory() {
        // 0 _ 0 forces a 1 in the middle; the column then gets three ones.
        var givens = Array(repeating: -1, count: 36)
        givens[0] = 0
        givens[2] = 0
        givens[7] = 1
        givens[13] = 1
        XCTAssertEqual(LogicSolver.countSolutions(size: 6, givens: givens, limit: 2), 0)
    }
}

final class LogicGeneratorTests: XCTestCase {
    func assertValid(_ puzzle: LogicPuzzle, size: Int) {
        let count = size * size
        XCTAssertEqual(puzzle.size, size)
        XCTAssertEqual(puzzle.givens.count, count)
        XCTAssertEqual(puzzle.solution.count, count)
        for index in 0..<count {
            let given = puzzle.givens[index]
            XCTAssertTrue(given == -1 || given == puzzle.solution[index])
        }
        XCTAssertTrue(LogicRules.isSolved(puzzle, values: puzzle.solution))
        XCTAssertEqual(LogicSolver.countSolutions(size: size, givens: puzzle.givens, limit: 2), 1)
    }

    func testSizesPerWeekday() {
        XCTAssertEqual(LogicGenerator.sizes, [6, 6, 8, 8, 8, 10, 10])
    }

    func testGeneratedPuzzlesAreValidAndUnique() {
        let seeds = ["logic|2026-11-23", "logic|2026-01-05", "x"]
        for weekday in 0..<7 {
            for seed in seeds {
                let puzzle = LogicGenerator.generate(weekday: weekday, seed: seed)
                assertValid(puzzle, size: LogicGenerator.sizes[weekday])
                // Not a full grid: there is something to solve.
                var empty = 0
                for value in puzzle.givens { if value == -1 { empty += 1 } }
                XCTAssertTrue(empty > puzzle.givens.count / 3)
            }
        }
    }

    func testSameSeedGivesSamePuzzle() {
        let first = LogicGenerator.generate(weekday: 3, seed: "logic|2026-11-26")
        let second = LogicGenerator.generate(weekday: 3, seed: "logic|2026-11-26")
        XCTAssertEqual(first, second)
        let other = LogicGenerator.generate(weekday: 3, seed: "logic|2026-11-27")
        XCTAssertNotEqual(first, other)
    }

    func testEasyDaysKeepMoreGivens() {
        // Averaged over a few seeds: Monday (6×6) has more givens than Wednesday's share.
        var monday = 0
        var plain = 0
        for index in 0..<4 {
            let seed = "logic|easy\(index)"
            for value in LogicGenerator.generate(weekday: 0, seed: seed).givens { if value != -1 { monday += 1 } }
            for value in LogicGenerator.minimalGivens(size: 6, seed: seed).givens { if value != -1 { plain += 1 } }
        }
        XCTAssertTrue(monday > plain)
    }

    func testTimingPerSize() {
        for weekday in [0, 2, 5] {
            let start = Date()
            _ = LogicGenerator.generate(weekday: weekday, seed: "logic|timing")
            let seconds = Date().timeIntervalSince(start)
            print("LOGIC_TIMING size \(LogicGenerator.sizes[weekday]): \(seconds) s")
        }
    }

    /// Recorded from a Swift run; the same test runs in Kotlin through Skip and proves the
    /// generator gives the same puzzles there. Seeds: Monday 23 … Sunday 29 November 2026.
    /// Changing the generator changes these values.
    func testFingerprintPerWeekday() {
        let expected: [[Int]] = [
            [-1, 1, 1, -1, 1, -1, -1, 1, 1, 0, -1, 0, -1, -1, -1, -1, -1, 1, -1, 1, -1, -1, 1, -1, -1, -1, -1, -1, -1, 0, 1, -1, -1, -1, -1, 1],
            [0, -1, -1, -1, -1, -1, -1, -1, 1, 1, 0, 1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1],
            [-1, -1, -1, -1, -1, 1, -1, -1, 1, -1, -1, -1, 0, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, 1, -1, -1, -1, -1, -1, -1, 0, -1, -1, 0, 0, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1],
            [-1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, 0, -1, -1, 1, -1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, 1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 1, 0, -1, -1, 0, 0, -1, -1, 1],
            [-1, 0, -1, -1, -1, -1, 0, -1, -1, 0, -1, -1, -1, 1, 0, -1, -1, -1, 1, -1, 0, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, -1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, -1, -1, -1, -1, -1, -1, 0, -1, -1, 0, -1, -1, -1, -1],
            [0, -1, 1, 0, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, 0, -1, -1, -1, -1, 1, -1, 0, -1, -1, 0, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, 1, 1, -1, -1, -1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, 0, 0, 1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, -1, 1, -1, -1, -1, -1, -1, -1],
            [-1, 1, -1, -1, -1, -1, 0, -1, -1, -1, 1, -1, -1, -1, -1, -1, 0, -1, -1, 1, -1, -1, -1, -1, -1, -1, -1, 1, -1, -1, -1, 1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 1, 1, -1, -1, -1, 1, -1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 0, -1, 1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 1, 1, -1, -1, -1, -1, -1, -1, 1, -1, -1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]
        ]
        for weekday in 0..<7 {
            let puzzle = LogicGenerator.generate(weekday: weekday, seed: "logic|2026-11-2\(3 + weekday)")
            XCTAssertEqual(puzzle.givens, expected[weekday], "weekday \(weekday)")
        }
    }
}

final class LogicPuzzleCodingTests: XCTestCase {
    func testJSONRoundTripWithExactKeys() throws {
        let puzzle = LogicPuzzle(size: 4, givens: [0, -1, -1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
                                 solution: [0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0])
        let data = try JSONEncoder().encode(puzzle)
        let decoded = try JSONDecoder().decode(LogicPuzzle.self, from: data)
        XCTAssertEqual(decoded, puzzle)

        let text = String(data: data, encoding: String.Encoding.utf8) ?? ""
        XCTAssertTrue(text.contains("\"size\":4"))
        XCTAssertTrue(text.contains("\"givens\":[0,-1,-1,1,"))
        XCTAssertTrue(text.contains("\"solution\":[0,0,1,1,"))
        // Only these three keys.
        var quotes = 0
        for character in text { if character == "\"" { quotes += 1 } }
        XCTAssertEqual(quotes, 6)
    }

    func testDecodesTheSpecExample() throws {
        let json = "{\"size\":4,\"givens\":[-1,0,1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],\"solution\":[1,0,1,0,0,1,0,1,1,1,0,0,0,0,1,1]}"
        guard let data = json.data(using: String.Encoding.utf8) else {
            XCTFail("no data")
            return
        }
        let puzzle = try JSONDecoder().decode(LogicPuzzle.self, from: data)
        XCTAssertEqual(puzzle.size, 4)
        XCTAssertEqual(puzzle.givens[1], 0)
        XCTAssertEqual(puzzle.solution.count, 16)
    }
}
