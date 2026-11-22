import XCTest
@testable import PibblesCore

/// The generator must give the same puzzle as `prototype/logic.js` for the same seed,
/// so the app, the server and the prototype agree on the puzzle of a day.
final class PuzzleGeneratorTests: XCTestCase {
    private func check(_ weekday: Int, _ seed: String, pieces: [String], rows: [Int], cols: [Int],
                       solution: [Int], attempts: Int, nodes: Int) {
        let level = WeekSchedule.level(weekday: weekday)
        let puzzle = PuzzleGenerator.generate(level: level, seed: seed)
        XCTAssertNotNil(puzzle, seed)
        guard let puzzle else { return }
        XCTAssertEqual(puzzle.size, level.size, seed)
        XCTAssertEqual(puzzle.pieces, pieces, seed)
        XCTAssertEqual(puzzle.rows, rows, seed)
        XCTAssertEqual(puzzle.cols, cols, seed)
        XCTAssertEqual(puzzle.solution, solution, seed)
        XCTAssertEqual(puzzle.attempts, attempts, seed)
        XCTAssertEqual(puzzle.nodes, nodes, seed)
    }

    func testMondayMatchesThePrototype() {
        check(0, "d0", pieces: ["I4v", "I4", "I4v", "L3d"], rows: [2, 3, 4, 2, 4], cols: [4, 1, 5, 2, 3],
              solution: [0, 21, 2, 8], attempts: 1, nodes: 9)
        check(0, "2026-11-16", pieces: ["J4a", "J4a", "L3d", "I3"], rows: [1, 4, 3, 2, 4], cols: [2, 4, 2, 4, 2],
              solution: [2, 10, 18, 5], attempts: 2, nodes: 23)
    }

    func testTuesdayMatchesThePrototype() {
        check(1, "d0", pieces: ["Z4a", "L3c", "I3", "Z4a", "L3a"], rows: [4, 4, 4, 4, 1], cols: [3, 3, 4, 5, 2],
              solution: [0, 17, 12, 2, 10], attempts: 3, nodes: 66)
        check(1, "2026-11-17", pieces: ["I3v", "I2v", "J4a", "I2", "T4b"], rows: [1, 4, 4, 2, 4], cols: [4, 2, 4, 3, 2],
              solution: [5, 9, 12, 20, 1], attempts: 1, nodes: 20)
    }

    func testWednesdayMatchesThePrototype() {
        check(2, "d0", pieces: ["L4a", "L3a", "Z4a", "J4c", "S4b"], rows: [2, 4, 5, 4, 3, 1], cols: [4, 3, 1, 2, 6, 3],
              solution: [0, 9, 18, 22, 4], attempts: 3, nodes: 120)
        check(2, "2026-11-18", pieces: ["I3", "L4c", "T4d", "T4c", "L4a"], rows: [1, 5, 4, 4, 4, 1], cols: [3, 3, 3, 3, 6, 1],
              solution: [7, 21, 6, 19, 4], attempts: 1, nodes: 216)
    }

    func testThursdayMatchesThePrototype() {
        check(3, "d0", pieces: ["S4a", "T4b", "L4b", "I4", "L3b", "L3c"], rows: [5, 5, 3, 3, 2, 4], cols: [3, 3, 6, 4, 4, 2],
              solution: [19, 9, 0, 30, 8, 4], attempts: 1, nodes: 1088)
        check(3, "2026-11-19", pieces: ["J4a", "S4a", "I3", "L3c", "L3c", "T4c"], rows: [2, 5, 2, 5, 3, 4], cols: [2, 5, 4, 5, 3, 2],
              solution: [6, 2, 20, 26, 10, 24], attempts: 3, nodes: 926)
    }

    func testFridayMatchesThePrototype() {
        check(4, "d0", pieces: ["I4v", "T4b", "T4b", "L3c", "O4", "T4d", "J4b"], rows: [3, 4, 4, 5, 6, 5], cols: [3, 6, 5, 5, 3, 5],
              solution: [5, 12, 8, 26, 1, 22, 24], attempts: 8, nodes: 6607)
        check(4, "2026-11-20", pieces: ["T4b", "J4c", "L4c", "L3d", "Z4b", "I2", "L3d"], rows: [5, 5, 4, 4, 3, 3], cols: [2, 6, 3, 4, 4, 5],
              solution: [0, 9, 4, 13, 22, 2, 24], attempts: 3, nodes: 3565)
    }

    func testSaturdayMatchesThePrototype() {
        check(5, "d0", pieces: ["T4a", "L3a", "L4a", "O4", "L4a", "T4a", "L3d"], rows: [2, 3, 3, 6, 4, 6, 2], cols: [3, 7, 3, 3, 4, 5, 1],
              solution: [38, 25, 15, 0, 12, 35, 16], attempts: 5, nodes: 6085)
        check(5, "2026-11-21", pieces: ["L4a", "L4a", "J4a", "L4b", "Z4b", "L3b", "L3a"], rows: [2, 4, 7, 5, 3, 3, 2], cols: [5, 4, 6, 2, 1, 3, 5],
              solution: [30, 0, 26, 16, 12, 21, 1], attempts: 2, nodes: 1891)
    }

    func testSundayMatchesThePrototype() {
        check(6, "d0", pieces: ["L4d", "L3a", "S4a", "L3a", "I4v", "I4", "J4d", "L3d"], rows: [4, 5, 5, 1, 2, 6, 6], cols: [1, 4, 3, 7, 4, 5, 5],
              solution: [29, 12, 7, 32, 3, 43, 4, 40], attempts: 31, nodes: 11669)
        check(6, "2026-11-22", pieces: ["T4d", "L3c", "T4d", "L4c", "I3v", "L3b", "L3b", "L3c"], rows: [6, 6, 3, 4, 3, 3, 2], cols: [6, 1, 1, 4, 7, 5, 3],
              solution: [0, 24, 4, 2, 28, 39, 26, 5], attempts: 4, nodes: 8637)
    }

    func testSameSeedGivesTheSamePuzzle() {
        let level = WeekSchedule.level(weekday: 2)
        XCTAssertEqual(PuzzleGenerator.generate(level: level, seed: "abc"),
                       PuzzleGenerator.generate(level: level, seed: "abc"))
    }

    /// The rules of HANDOFF.md, checked on fresh seeds for every weekday.
    func testGeneratedPuzzlesFollowTheRules() {
        for weekday in 0..<7 {
            let level = WeekSchedule.level(weekday: weekday)
            for number in 0..<5 {
                let seed = "rules-\(number)"
                guard let puzzle = PuzzleGenerator.generate(level: level, seed: seed) else {
                    XCTFail("no puzzle for weekday \(weekday), seed \(seed)")
                    continue
                }
                XCTAssertEqual(puzzle.pieces.count, level.pieceCount)
                XCTAssertEqual(puzzle.rows.count, level.size)
                XCTAssertEqual(puzzle.cols.count, level.size)

                // At most twice the same shape.
                var perShape = [String: Int]()
                for key in puzzle.pieces { perShape[key] = (perShape[key] ?? 0) + 1 }
                for (key, count) in perShape { XCTAssertTrue(count <= 2, key) }

                // No empty row or column (with 4 pieces at most one).
                let empty = (puzzle.rows + puzzle.cols).filter { value in value == 0 }.count
                XCTAssertTrue(empty <= (level.pieceCount < 5 ? 1 : 0))

                // The stored solution solves the puzzle, and it is the only one.
                var positions = [Int?]()
                for position in puzzle.solution { positions.append(position) }
                XCTAssertTrue(PuzzleRules.isSolved(puzzle, positions: positions))
                let result = Solver.countSolutions(size: puzzle.size, shapeKeys: puzzle.pieces,
                                                   rows: puzzle.rows, cols: puzzle.cols,
                                                   limit: 2, budget: 1000000)
                XCTAssertEqual(result.count, 1)
                XCTAssertFalse(result.exhausted)
            }
        }
    }
}
