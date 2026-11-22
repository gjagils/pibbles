import Foundation
import XCTest
@testable import PibblesCore

/// The same seed must give the same puzzle in Swift and in Skip's Kotlin; these values were
/// recorded from a Swift run and this test also runs in Kotlin. Changing the generator
/// (density, mirroring, checks, order of random draws) changes every puzzle: record anew.
final class PatternsGeneratorTests: XCTestCase {
    private func check(_ weekday: Int, _ dateKey: String, solution: [Int]) {
        let seed = PuzzleKind.patterns.seed(dateKey: dateKey)
        let puzzle = PatternsGenerator.generate(weekday: weekday, seed: seed)
        XCTAssertEqual(puzzle.size, PatternsGenerator.sizes[weekday], seed)
        XCTAssertEqual(puzzle.solution, solution, seed)
    }

    func testFingerprintMonday() {
        check(0, "2026-11-23", solution: [1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1])
        let puzzle = PatternsGenerator.generate(weekday: 0, seed: "patterns|2026-11-23")
        XCTAssertEqual(puzzle.rowClues, [[5], [1, 1], [2, 1], [2], [1, 2]])
        XCTAssertEqual(puzzle.colClues, [[1, 3], [4], [1], [1, 1], [3, 1]])
    }

    func testFingerprintTuesday() {
        check(1, "2026-11-24", solution: [1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 0])
    }

    func testFingerprintWednesday() {
        check(2, "2026-11-25", solution: [1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1,
                                          1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1])
    }

    func testFingerprintThursday() {
        check(3, "2026-11-26", solution: [0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0,
                                          0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0])
    }

    func testFingerprintFriday() {
        check(4, "2026-11-27", solution: [0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0,
                                          0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1,
                                          1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0])
    }

    func testFingerprintSaturday() {
        check(5, "2026-11-28", solution: [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0,
                                          1, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0,
                                          1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1,
                                          1, 0, 1, 0, 0, 0, 1, 0, 1])
    }

    func testFingerprintSunday() {
        check(6, "2026-11-29", solution: [1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 1,
                                          0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1,
                                          0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0,
                                          1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1,
                                          1, 1, 0, 1])
    }

    func testSizesRunFromMondayToSunday() {
        XCTAssertEqual(PatternsGenerator.sizes, [5, 5, 6, 7, 8, 9, 10])
    }

    func testSameSeedGivesTheSamePuzzle() {
        XCTAssertEqual(PatternsGenerator.generate(weekday: 4, seed: "abc"),
                       PatternsGenerator.generate(weekday: 4, seed: "abc"))
        XCTAssertNotEqual(PatternsGenerator.generate(weekday: 4, seed: "abc"),
                          PatternsGenerator.generate(weekday: 4, seed: "abd"))
    }

    func testWeekdayOutsideTheWeekIsClamped() {
        XCTAssertEqual(PatternsGenerator.generate(weekday: -3, seed: "x").size, 5)
        XCTAssertEqual(PatternsGenerator.generate(weekday: 9, seed: "x").size, 10)
    }

    /// Valid, unique and not dull, on fresh seeds for every weekday.
    func testGeneratedPuzzlesAreValidAndUnique() {
        for weekday in 0..<7 {
            let size = PatternsGenerator.sizes[weekday]
            for number in 0..<4 {
                let seed = "rules-\(number)"
                let puzzle = PatternsGenerator.generate(weekday: weekday, seed: seed)
                XCTAssertEqual(puzzle.size, size)
                XCTAssertEqual(puzzle.solution.count, size * size)
                XCTAssertEqual(puzzle.rowClues.count, size)
                XCTAssertEqual(puzzle.colClues.count, size)
                var filled = 0
                for value in puzzle.solution {
                    XCTAssertTrue(value == 0 || value == 1)
                    if value == 1 { filled += 1 }
                }
                // Not the fallback of a full grid.
                XCTAssertTrue(filled < size * size, seed)
                XCTAssertTrue(PatternsGenerator.hasFewDullLines(puzzle), seed)
                XCTAssertEqual(PatternsRules.puzzle(size: size, solution: puzzle.solution), puzzle)
                XCTAssertTrue(PatternsRules.isSolved(puzzle, cells: puzzle.solution))
                XCTAssertEqual(PatternsSolver.countSolutions(size: size, rowClues: puzzle.rowClues,
                                                             colClues: puzzle.colClues, limit: 2), 1, seed)
                XCTAssertTrue(PatternsSolver.isLineSolvable(size: size, rowClues: puzzle.rowClues,
                                                            colClues: puzzle.colClues), seed)
            }
        }
    }

    /// Generation stays fast; prints the average per size (debug build: about a millisecond).
    func testGenerationIsFast() {
        for weekday in 0..<7 {
            let start = Date()
            var number = 0
            while number < 5 {
                _ = PatternsGenerator.generate(weekday: weekday, seed: "speed-\(number)")
                number += 1
            }
            let average = Date().timeIntervalSince(start) / 5.0
            print("Patterns size \(PatternsGenerator.sizes[weekday]): \(Int(average * 1000000.0)) µs per puzzle")
            XCTAssertTrue(average < 2.0)
        }
    }
}
