import Foundation
import XCTest
@testable import PibblesCore

final class SumsRulesTests: XCTestCase {
    /// 1 2 3 4
    /// 2 1 4 3
    /// 3 4 1 2
    /// 4 3 2 1
    /// Cages: {0,1,4}=5, {2,3}=7, {5,6,7}=8, {8,12}=7, {9,10,11}=7, {13,14,15}=6.
    private let solution = [1, 2, 3, 4, 2, 1, 4, 3, 3, 4, 1, 2, 4, 3, 2, 1]
    private let cages = [0, 0, 1, 1, 0, 2, 2, 2, 3, 4, 4, 4, 3, 5, 5, 5]
    private let sums = [5, 7, 8, 7, 7, 6]

    private func puzzle() -> SumsPuzzle {
        return SumsPuzzle(size: 4, cages: cages, sums: sums, solution: solution)
    }

    private func empty() -> [Int] {
        return [Int](repeating: 0, count: 16)
    }

    func testSolvedGrid() {
        XCTAssertTrue(SumsRules.isSolved(puzzle(), values: solution))
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: solution), [Int]())
    }

    func testEmptyCellIsNotSolved() {
        var values = solution
        values[6] = 0
        XCTAssertFalse(SumsRules.isSolved(puzzle(), values: values))
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [Int]())
        XCTAssertFalse(SumsRules.isSolved(puzzle(), values: [1, 2, 3]))
    }

    func testLatinSquareWithWrongSumsIsNotSolved() {
        // Rows 0 and 1 swapped: still a Latin square, but cage 0 adds up to 4.
        let values = [2, 1, 4, 3, 1, 2, 3, 4, 3, 4, 1, 2, 4, 3, 2, 1]
        XCTAssertFalse(SumsRules.isSolved(puzzle(), values: values))
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [0, 1, 4, 5, 6, 7])
    }

    func testSolvedDoesNotCompareWithSolution() {
        // Same cages and sums, a wrong stored solution: the grid itself decides.
        let other = SumsPuzzle(size: 4, cages: cages, sums: sums, solution: empty())
        XCTAssertTrue(SumsRules.isSolved(other, values: solution))
    }

    func testDuplicatesInRowAndColumn() {
        var values = empty()
        values[0] = 1
        values[2] = 1
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [0, 2])
        values = empty()
        values[1] = 2
        values[13] = 2
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [1, 13])
    }

    func testPartialCageOverItsSum() {
        var values = empty()
        values[0] = 1
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [Int]())
        values[1] = 4
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [Int]())
        values[0] = 3
        // 3 + 4 > 5: both filled cells of cage 0 clash, the empty one does not.
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [0, 1])
    }

    func testFullCageWithWrongSum() {
        var values = empty()
        values[2] = 4
        values[3] = 2
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [2, 3])
        values[3] = 3
        XCTAssertEqual(SumsRules.conflicts(puzzle(), values: values), [Int]())
    }

    func testCageLabelCells() {
        XCTAssertEqual(SumsRules.cageLabelCells(puzzle()), [0, 2, 5, 8, 9, 13])
    }
}

final class SumsSolverTests: XCTestCase {
    private func count(_ size: Int, _ cages: [Int], _ sums: [Int]) -> Int {
        return SumsSolver.countSolutions(size: size, cages: cages, sums: sums, limit: 10)
    }

    func testOneCageCountsLatinSquares() {
        XCTAssertEqual(count(2, [0, 0, 0, 0], [6]), 2)
        XCTAssertEqual(SumsSolver.countSolutions(size: 3, cages: [Int](repeating: 0, count: 9), sums: [18], limit: 100), 12)
        XCTAssertEqual(SumsSolver.countSolutions(size: 4, cages: [Int](repeating: 0, count: 16), sums: [40], limit: 1000), 576)
    }

    func testSingleCellsAreUnique() {
        XCTAssertEqual(count(2, [0, 1, 2, 3], [1, 2, 2, 1]), 1)
        XCTAssertEqual(SumsSolver.firstSolution(size: 2, cages: [0, 1, 2, 3], sums: [1, 2, 2, 1]), [1, 2, 2, 1])
    }

    func testUniqueBySums() {
        // 1 2 3 / 2 3 1 / 3 1 2 with cages {0}=1, {1,2}=5, {3,4}=5, {5,8}=3, {6,7}=4.
        let cages = [0, 1, 1, 2, 2, 3, 4, 4, 3]
        let sums = [1, 5, 5, 3, 4]
        XCTAssertEqual(count(3, cages, sums), 1)
        XCTAssertEqual(SumsSolver.firstSolution(size: 3, cages: cages, sums: sums), [1, 2, 3, 2, 3, 1, 3, 1, 2])
    }

    func testAmbiguous() {
        // Two rows of 3: both 2×2 Latin squares fit.
        XCTAssertEqual(count(2, [0, 0, 1, 1], [3, 3]), 2)
        XCTAssertEqual(SumsSolver.countSolutions(size: 2, cages: [0, 0, 1, 1], sums: [3, 3], limit: 1), 1)
        // Order 3 with only the first cell fixed.
        XCTAssertEqual(count(3, [0, 1, 1, 1, 1, 1, 1, 1, 1], [1, 17]), 4)
    }

    func testImpossible() {
        XCTAssertEqual(count(2, [0, 0, 1, 1], [3, 4]), 0)
        XCTAssertEqual(count(2, [0, 1, 2, 3], [1, 1, 2, 2]), 0)
        XCTAssertEqual(count(2, [0, 1, 2, 3], [5, 2, 2, 1]), 0)
        XCTAssertEqual(count(3, [0, 1, 1, 2, 2, 3, 4, 4, 3], [1, 5, 5, 3, 5]), 0)
    }

    func testMalformed() {
        XCTAssertEqual(count(0, [Int](), [Int]()), 0)
        XCTAssertEqual(count(2, [0, 0, 0], [6]), 0)
        XCTAssertEqual(count(2, [0, 0, 1, 1], [3]), 0)
        XCTAssertEqual(count(2, [0, 0, -1, 1], [3, 3]), 0)
        // Id 2 has no cells.
        XCTAssertEqual(count(2, [0, 0, 1, 1], [3, 3, 3]), 0)
        XCTAssertEqual(SumsSolver.countSolutions(size: 2, cages: [0, 1, 2, 3], sums: [1, 2, 2, 1], limit: 0), 0)
    }
}

final class SumsGeneratorTests: XCTestCase {
    private func check(_ weekday: Int, cages: [Int], sums: [Int]) {
        let seed = PuzzleKind.sums.seed(dateKey: PuzzleCalendar.dateKey(day: PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 23 + weekday)))
        let puzzle = SumsGenerator.generate(weekday: weekday, seed: seed)
        XCTAssertEqual(puzzle.size, SumsGenerator.sizes[weekday], seed)
        XCTAssertEqual(puzzle.cages, cages, seed)
        XCTAssertEqual(puzzle.sums, sums, seed)
    }

    /// Recorded from a Swift run; the same test runs in Kotlin through Skip, so both agree.
    /// Seeds `sums|2026-11-23` (Monday) … `sums|2026-11-29` (Sunday).
    func testFingerprints() {
        check(0, cages: [0, 0, 1, 1, 2, 0, 1, 1, 2, 3, 3, 4, 5, 5, 3, 4],
              sums: [6, 11, 4, 9, 4, 6])
        check(1, cages: [0, 0, 1, 1, 0, 2, 3, 3, 4, 2, 5, 6, 4, 7, 8, 9],
              sums: [9, 3, 3, 7, 4, 3, 4, 4, 2, 1])
        check(2, cages: [0, 1, 2, 2, 2, 1, 1, 1, 3, 3, 4, 4, 5, 5, 3, 6, 7, 8, 9, 9, 10, 10, 11, 11, 9],
              sums: [4, 8, 9, 10, 8, 6, 5, 1, 3, 11, 5, 5])
        check(3, cages: [0, 0, 1, 1, 1, 2, 0, 0, 1, 3, 2, 4, 4, 3, 3, 2, 4, 4, 5, 6, 2, 7, 7, 7, 6],
              sums: [12, 10, 11, 10, 17, 4, 5, 6])
        check(4, cages: [0, 1, 1, 2, 2, 0, 0, 3, 3, 4, 5, 5, 3, 6, 4, 7, 8, 8, 6, 4, 7, 9, 8, 10, 10],
              sums: [7, 9, 3, 9, 8, 6, 9, 6, 8, 2, 8])
        check(5, cages: [0, 0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 1, 5, 5, 6, 4, 7, 7, 8, 8, 6, 6, 9, 10, 8, 11, 11, 12,
                         9, 10, 13, 13, 11, 12, 14, 15],
              sums: [13, 14, 5, 5, 6, 11, 11, 5, 11, 5, 6, 12, 10, 3, 5, 4])
        check(6, cages: [0, 1, 2, 3, 3, 3, 0, 1, 2, 2, 2, 4, 5, 6, 7, 8, 8, 4, 5, 9, 10, 8, 11, 11, 12, 12, 13, 8,
                         11, 14, 15, 15, 13, 13, 14, 14],
              sums: [7, 9, 16, 9, 4, 10, 6, 2, 12, 3, 1, 15, 4, 15, 10, 3])
    }

    func testSizes() {
        XCTAssertEqual(SumsGenerator.sizes, [4, 4, 5, 5, 5, 6, 6])
    }

    func testSameSeedGivesTheSamePuzzle() {
        XCTAssertEqual(SumsGenerator.generate(weekday: 5, seed: "abc"), SumsGenerator.generate(weekday: 5, seed: "abc"))
        XCTAssertNotEqual(SumsGenerator.generate(weekday: 5, seed: "abc"), SumsGenerator.generate(weekday: 5, seed: "abd"))
    }

    /// True when the cells of every cage form one orthogonally connected group.
    private func cagesConnected(_ puzzle: SumsPuzzle) -> Bool {
        let n = puzzle.size
        var id = 0
        while id < puzzle.sums.count {
            var members = [Int]()
            var cell = 0
            while cell < n * n {
                if puzzle.cages[cell] == id { members.append(cell) }
                cell += 1
            }
            if members.isEmpty { return false }
            var reached = [members[0]]
            var index = 0
            while index < reached.count {
                let current = reached[index]
                for other in members {
                    if reached.contains(other) { continue }
                    let sameRow = current / n == other / n
                    let distance = current > other ? current - other : other - current
                    if (sameRow && distance == 1) || distance == n {
                        reached.append(other)
                    }
                }
                index += 1
            }
            if reached.count != members.count { return false }
            id += 1
        }
        return true
    }

    private func assertValid(_ puzzle: SumsPuzzle, _ label: String) {
        let n = puzzle.size
        XCTAssertEqual(puzzle.cages.count, n * n, label)
        XCTAssertEqual(puzzle.solution.count, n * n, label)
        // Ids 0..k-1 in order of each cage's first cell.
        var nextId = 0
        for id in puzzle.cages {
            XCTAssertTrue(id >= 0 && id <= nextId, label)
            if id == nextId { nextId += 1 }
        }
        XCTAssertEqual(nextId, puzzle.sums.count, label)
        // Every cage has 1…4 cells and its sum matches the solution.
        var totals = [Int](repeating: 0, count: puzzle.sums.count)
        var counts = [Int](repeating: 0, count: puzzle.sums.count)
        var cell = 0
        while cell < n * n {
            totals[puzzle.cages[cell]] += puzzle.solution[cell]
            counts[puzzle.cages[cell]] += 1
            cell += 1
        }
        XCTAssertEqual(totals, puzzle.sums, label)
        for size in counts {
            XCTAssertTrue(size >= 1 && size <= 4, label)
        }
        XCTAssertTrue(cagesConnected(puzzle), label)
        XCTAssertTrue(SumsRules.isSolved(puzzle, values: puzzle.solution), label)
        XCTAssertEqual(SumsSolver.countSolutions(size: n, cages: puzzle.cages, sums: puzzle.sums, limit: 2), 1, label)
    }

    func testGeneratedPuzzlesAreValidAndUnique() {
        for weekday in 0..<7 {
            for seed in ["sums|2026-01-05", "sums|2027-03-14", "a", "b"] {
                let puzzle = SumsGenerator.generate(weekday: weekday, seed: seed)
                XCTAssertEqual(puzzle.size, SumsGenerator.sizes[weekday])
                assertValid(puzzle, "\(weekday) \(seed)")
            }
        }
    }

    func testGenerationTime() {
        var weekday = 0
        while weekday < 7 {
            let start = Date()
            var singles = 0
            var cageTotal = 0
            var round = 0
            while round < 5 {
                let puzzle = SumsGenerator.generate(weekday: weekday, seed: "time|\(round)")
                cageTotal += puzzle.sums.count
                var counts = [Int](repeating: 0, count: puzzle.sums.count)
                for id in puzzle.cages {
                    counts[id] += 1
                }
                for size in counts {
                    if size == 1 { singles += 1 }
                }
                round += 1
            }
            let milliseconds = Int(Date().timeIntervalSince(start) * 1000.0) / 5
            print("SUMS TIMING weekday \(weekday) size \(SumsGenerator.sizes[weekday]): \(milliseconds) ms per puzzle, \(cageTotal) cages, \(singles) single cells over 5")
            XCTAssertLessThan(milliseconds, 5000)
            weekday += 1
        }
    }

    func testJSONRoundTripWithExactKeys() throws {
        let puzzle = SumsPuzzle(size: 2, cages: [0, 0, 1, 2], sums: [3, 2, 1], solution: [1, 2, 2, 1])
        let data = try JSONEncoder().encode(puzzle)
        let decoded = try JSONDecoder().decode(SumsPuzzle.self, from: data)
        XCTAssertEqual(decoded, puzzle)

        let json = "{\"size\":2,\"cages\":[0,0,1,2],\"sums\":[3,2,1],\"solution\":[1,2,2,1]}"
        let parsed = try JSONDecoder().decode(SumsPuzzle.self, from: json.data(using: String.Encoding.utf8)!)
        XCTAssertEqual(parsed, puzzle)

        let text = String(data: data, encoding: String.Encoding.utf8) ?? ""
        for key in ["\"size\"", "\"cages\"", "\"sums\"", "\"solution\""] {
            XCTAssertTrue(text.contains(key), key)
        }
    }
}
