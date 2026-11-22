import Foundation
import XCTest
@testable import PibblesCore

/// A 4×4 puzzle with exactly one solution, columns [1, 3, 0, 2]:
/// 0 0 1 1
/// 1 1 1 1
/// 2 2 2 2
/// 3 3 3 3
/// With rows as regions a 4×4 grid has two solutions, [1, 3, 0, 2] and [2, 0, 3, 1]; moving
/// cells 2 and 3 into region 1 puts two stars of the second one in region 1.
private let regions4 = [0, 0, 1, 1,
                        1, 1, 1, 1,
                        2, 2, 2, 2,
                        3, 3, 3, 3]

private func puzzle4() -> StarsPuzzle {
    return StarsPuzzle(size: 4, regions: regions4, solution: [1, 3, 0, 2])
}

/// Per cell 0, with 2 (star) at the given cells.
private func stars(_ cells: [Int], count: Int) -> [Int] {
    var grid = Array(repeating: 0, count: count)
    for cell in cells {
        grid[cell] = 2
    }
    return grid
}

/// Region ids by rows: region r is row r.
private func rowRegions(_ n: Int) -> [Int] {
    var list = [Int]()
    var cell = 0
    while cell < n * n {
        list.append(cell / n)
        cell += 1
    }
    return list
}

final class StarsRulesTests: XCTestCase {
    func testSolvedGrid() {
        let grid = stars([1, 7, 8, 14], count: 16)
        XCTAssertTrue(StarsRules.isSolved(puzzle4(), stars: grid))
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: grid), [Int]())
    }

    func testNoStarMarksDoNotMatter() {
        var grid = stars([1, 7, 8, 14], count: 16)
        grid[0] = 1
        grid[15] = 1
        XCTAssertTrue(StarsRules.isSolved(puzzle4(), stars: grid))
    }

    func testMissingStarIsNotSolved() {
        let grid = stars([1, 7, 8], count: 16)
        XCTAssertFalse(StarsRules.isSolved(puzzle4(), stars: grid))
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: grid), [Int]())
    }

    func testWrongLengthIsNotSolved() {
        XCTAssertFalse(StarsRules.isSolved(puzzle4(), stars: [2, 0, 0]))
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: [2, 2, 0]), [Int]())
        XCTAssertEqual(StarsRules.autoMarks(puzzle4(), stars: [2, 2, 0]), [Int]())
    }

    func testRulesNotTheStoredSolution() {
        // A valid placement is solved even when the stored solution says otherwise.
        let other = StarsPuzzle(size: 4, regions: rowRegions(4), solution: [1, 3, 0, 2])
        XCTAssertTrue(StarsRules.isSolved(other, stars: stars([2, 4, 11, 13], count: 16)))
    }

    func testOtherPlacementBreaksRegion() {
        // [2, 0, 3, 1]: cells 2 and 4 are both in region 1.
        let grid = stars([2, 4, 11, 13], count: 16)
        XCTAssertFalse(StarsRules.isSolved(puzzle4(), stars: grid))
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: grid), [2, 4])
    }

    func testConflicts() {
        // Touching diagonally.
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: stars([0, 5], count: 16)), [0, 5])
        // Same row (also same region).
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: stars([8, 10], count: 16)), [8, 10])
        // Same column, far apart.
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: stars([0, 8], count: 16)), [0, 8])
        // Same region only.
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: stars([3, 4], count: 16)), [3, 4])
        // Fine together, a third one clashes with one of them.
        XCTAssertEqual(StarsRules.conflicts(puzzle4(), stars: stars([1, 7, 9], count: 16)), [1, 9])
        // Too many stars is not solved.
        XCTAssertFalse(StarsRules.isSolved(puzzle4(), stars: stars([1, 7, 8, 14, 9], count: 16)))
    }

    func testAutoMarks() {
        // Star at cell 1 (row 0, column 1, region 0): row 0, column 1, region 0 and the
        // neighbours 0, 2, 4, 5, 6.
        XCTAssertEqual(StarsRules.autoMarks(puzzle4(), stars: stars([1], count: 16)), [0, 2, 3, 4, 5, 6, 9, 13])
        // Cells the player marked or starred are not empty, so not listed.
        var grid = stars([1], count: 16)
        grid[4] = 1
        XCTAssertEqual(StarsRules.autoMarks(puzzle4(), stars: grid), [0, 2, 3, 5, 6, 9, 13])
        // Star at cell 14 (row 3, column 2, region 3).
        XCTAssertEqual(StarsRules.autoMarks(puzzle4(), stars: stars([14], count: 16)),
                       [2, 6, 9, 10, 11, 12, 13, 15])
        XCTAssertEqual(StarsRules.autoMarks(puzzle4(), stars: Array(repeating: 0, count: 16)), [Int]())
    }

    func testAutoMarksOfRegion() {
        // Star at cell 3 (region 1): every other region-1 cell is marked.
        XCTAssertEqual(StarsRules.autoMarks(puzzle4(), stars: stars([3], count: 16)), [0, 1, 2, 4, 5, 6, 7, 11, 15])
    }
}

final class StarsSolverTests: XCTestCase {
    func testUnique() {
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: regions4, limit: 10), 1)
        XCTAssertEqual(StarsSolver.firstSolution(size: 4, regions: regions4), [1, 3, 0, 2])
    }

    func testAmbiguousRowsAsRegions() {
        // Regions by rows add nothing: the count is the number of permutations without
        // neighbouring columns in consecutive rows (2, 14, 90, 646).
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: rowRegions(4), limit: 1000), 2)
        XCTAssertEqual(StarsSolver.countSolutions(size: 5, regions: rowRegions(5), limit: 1000), 14)
        XCTAssertEqual(StarsSolver.countSolutions(size: 6, regions: rowRegions(6), limit: 1000), 90)
        XCTAssertEqual(StarsSolver.countSolutions(size: 7, regions: rowRegions(7), limit: 1000), 646)
        XCTAssertEqual(StarsSolver.countSolutions(size: 5, regions: rowRegions(5), limit: 2), 2)
    }

    func testImpossible() {
        // No placement at all on 2×2 and 3×3.
        XCTAssertEqual(StarsSolver.countSolutions(size: 2, regions: rowRegions(2), limit: 10), 0)
        XCTAssertEqual(StarsSolver.countSolutions(size: 3, regions: rowRegions(3), limit: 10), 0)
        // Regions 0 and 1 are 2×1 blocks on top of each other: their stars always touch.
        let blocked = [0, 0, 2, 2,
                       1, 1, 2, 2,
                       3, 3, 3, 3,
                       3, 3, 3, 3]
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: blocked, limit: 10), 0)
        XCTAssertNil(StarsSolver.firstSolution(size: 4, regions: blocked))
    }

    func testMalformed() {
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: [0, 1, 2, 3], limit: 10), 0)
        var outOfRange = regions4
        outOfRange[15] = 4
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: outOfRange, limit: 10), 0)
        var negative = regions4
        negative[0] = -1
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: negative, limit: 10), 0)
        // Region 3 missing (only ids 0…2).
        var missing = regions4
        var cell = 12
        while cell < 16 {
            missing[cell] = 2
            cell += 1
        }
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: missing, limit: 10), 0)
        XCTAssertEqual(StarsSolver.countSolutions(size: 0, regions: [Int](), limit: 10), 0)
        XCTAssertEqual(StarsSolver.countSolutions(size: 4, regions: regions4, limit: 0), 0)
        XCTAssertEqual(StarsSolver.countSolutions(size: 1, regions: [0], limit: 10), 1)
    }
}

final class StarsGeneratorTests: XCTestCase {
    private func check(_ weekday: Int, regions: [Int], solution: [Int]) {
        let seed = PuzzleKind.stars.seed(dateKey: PuzzleCalendar.dateKey(day: PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 23 + weekday)))
        let puzzle = StarsGenerator.generate(weekday: weekday, seed: seed)
        XCTAssertEqual(puzzle.size, StarsGenerator.sizes[weekday], seed)
        XCTAssertEqual(puzzle.regions, regions, seed)
        XCTAssertEqual(puzzle.solution, solution, seed)
    }

    /// Recorded from a Swift run; the same test runs in Kotlin through Skip, so both agree.
    /// Seeds `stars|2026-11-23` (Monday) … `stars|2026-11-29` (Sunday).
    func testFingerprints() {
        check(0, regions: [1, 1, 2, 0, 0, 1, 1, 2, 2, 0, 1, 4, 2, 2, 2, 1, 4, 4, 2, 3, 1, 4, 3, 3, 3],
              solution: [3, 0, 2, 4, 1])
        check(1, regions: [1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 1, 1, 3, 2, 0, 2, 5, 3, 3, 2, 2, 2, 5, 3, 2, 2,
                           2, 4, 5, 5, 5, 2, 2, 4],
              solution: [4, 0, 3, 1, 5, 2])
        check(2, regions: [1, 1, 1, 1, 0, 2, 1, 1, 1, 1, 0, 2, 1, 1, 1, 1, 2, 2, 5, 3, 3, 4, 4, 2, 5, 3, 3, 4,
                           4, 2, 5, 5, 5, 5, 4, 2],
              solution: [4, 2, 5, 1, 3, 0])
        check(3, regions: [1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 3, 1, 1, 1, 2, 2, 3, 3, 3, 3, 3, 5, 2, 2, 3, 3, 3, 3,
                           5, 2, 3, 3, 4, 4, 6, 5, 5, 3, 3, 6, 6, 6, 5, 3, 3, 3, 6, 6, 6],
              solution: [6, 2, 0, 3, 5, 1, 4])
        check(4, regions: [0, 0, 0, 0, 1, 1, 1, 0, 0, 2, 1, 1, 1, 1, 0, 0, 2, 1, 3, 1, 1, 4, 0, 2, 3, 3, 3, 1,
                           4, 4, 3, 3, 3, 3, 5, 6, 4, 4, 3, 3, 3, 5, 6, 4, 5, 5, 5, 5, 5],
              solution: [3, 5, 2, 4, 1, 6, 0])
        check(5, regions: [1, 1, 2, 2, 2, 3, 0, 0, 1, 2, 2, 2, 3, 3, 3, 3, 4, 2, 2, 2, 2, 2, 3, 3, 4, 2, 4, 4,
                           2, 2, 3, 5, 4, 2, 2, 4, 4, 4, 5, 5, 4, 4, 4, 4, 7, 5, 5, 5, 6, 6, 4, 4, 7, 5, 5, 7,
                           6, 6, 7, 7, 7, 7, 7, 7],
              solution: [7, 0, 2, 6, 3, 5, 1, 4])
        check(6, regions: [3, 2, 2, 2, 0, 0, 0, 1, 3, 2, 2, 2, 4, 0, 0, 1, 3, 3, 2, 2, 4, 4, 4, 4, 3, 3, 3, 2,
                           2, 4, 4, 4, 3, 5, 5, 2, 2, 2, 4, 4, 3, 5, 5, 5, 2, 2, 4, 6, 5, 5, 5, 6, 6, 6, 6, 6,
                           5, 5, 5, 7, 7, 6, 6, 6],
              solution: [4, 7, 2, 0, 6, 1, 5, 3])
    }

    func testSizes() {
        XCTAssertEqual(StarsGenerator.sizes, [5, 6, 6, 7, 7, 8, 8])
    }

    func testSameSeedGivesTheSamePuzzle() {
        XCTAssertEqual(StarsGenerator.generate(weekday: 5, seed: "abc"), StarsGenerator.generate(weekday: 5, seed: "abc"))
        XCTAssertNotEqual(StarsGenerator.generate(weekday: 5, seed: "abc"), StarsGenerator.generate(weekday: 5, seed: "abd"))
    }

    /// Every region is one orthogonally connected piece.
    private func regionsConnected(_ size: Int, _ regions: [Int]) -> Bool {
        var region = 0
        while region < size {
            var start = -1
            var total = 0
            var cell = 0
            while cell < size * size {
                if regions[cell] == region {
                    total += 1
                    if start < 0 { start = cell }
                }
                cell += 1
            }
            if start < 0 { return false }
            var seen = Array(repeating: false, count: size * size)
            var stack = [start]
            seen[start] = true
            var reached = 0
            while !stack.isEmpty {
                let current = stack.removeLast()
                reached += 1
                let row = current / size
                let col = current % size
                var next = [Int]()
                if row > 0 { next.append(current - size) }
                if row + 1 < size { next.append(current + size) }
                if col > 0 { next.append(current - 1) }
                if col + 1 < size { next.append(current + 1) }
                for other in next {
                    if !seen[other] && regions[other] == region {
                        seen[other] = true
                        stack.append(other)
                    }
                }
            }
            if reached != total { return false }
            region += 1
        }
        return true
    }

    private func assertValid(_ puzzle: StarsPuzzle, _ label: String) {
        let n = puzzle.size
        XCTAssertEqual(puzzle.regions.count, n * n, label)
        XCTAssertEqual(puzzle.solution.count, n, label)
        var grid = Array(repeating: 0, count: n * n)
        var row = 0
        while row < n {
            grid[row * n + puzzle.solution[row]] = 2
            row += 1
        }
        XCTAssertTrue(StarsRules.isSolved(puzzle, stars: grid), label)
        XCTAssertTrue(regionsConnected(n, puzzle.regions), label)
        XCTAssertEqual(StarsSolver.countSolutions(size: n, regions: puzzle.regions, limit: 2), 1, label)
        XCTAssertEqual(StarsSolver.firstSolution(size: n, regions: puzzle.regions) ?? [Int](), puzzle.solution, label)
    }

    func testGeneratedPuzzlesAreValidAndUnique() {
        for weekday in 0..<7 {
            for seed in ["stars|2026-01-05", "stars|2027-03-14", "a", "b"] {
                let puzzle = StarsGenerator.generate(weekday: weekday, seed: seed)
                XCTAssertEqual(puzzle.size, StarsGenerator.sizes[weekday])
                assertValid(puzzle, "\(weekday) \(seed)")
            }
        }
    }

    func testFallbacksAreValidAndUnique() {
        for size in [5, 6, 7, 8] {
            assertValid(StarsGenerator.fallback(size: size), "fallback \(size)")
        }
    }

    func testGenerationTime() {
        var weekday = 0
        while weekday < 7 {
            let start = Date()
            var round = 0
            while round < 5 {
                _ = StarsGenerator.generate(weekday: weekday, seed: "time|\(round)")
                round += 1
            }
            let milliseconds = Int(Date().timeIntervalSince(start) * 1000.0) / 5
            print("STARS TIMING weekday \(weekday) size \(StarsGenerator.sizes[weekday]): \(milliseconds) ms per puzzle")
            XCTAssertLessThan(milliseconds, 5000)
            weekday += 1
        }
    }

    func testJSONRoundTripWithExactKeys() throws {
        let puzzle = puzzle4()
        let data = try JSONEncoder().encode(puzzle)
        let decoded = try JSONDecoder().decode(StarsPuzzle.self, from: data)
        XCTAssertEqual(decoded, puzzle)

        let json = "{\"size\":4,\"regions\":[0,0,1,1,1,1,1,1,2,2,2,2,3,3,3,3],\"solution\":[1,3,0,2]}"
        let parsed = try JSONDecoder().decode(StarsPuzzle.self, from: json.data(using: String.Encoding.utf8)!)
        XCTAssertEqual(parsed, puzzle)

        let text = String(data: data, encoding: String.Encoding.utf8) ?? ""
        for key in ["\"size\"", "\"regions\"", "\"solution\""] {
            XCTAssertTrue(text.contains(key), key)
        }
        XCTAssertFalse(text.contains("\"stars\""))
    }
}
