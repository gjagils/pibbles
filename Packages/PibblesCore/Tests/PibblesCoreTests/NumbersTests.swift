import Foundation
import XCTest
@testable import PibblesCore

final class NumbersRulesTests: XCTestCase {
    /// 3×3 for brevity:
    /// 1 2 3
    /// 2 3 1
    /// 3 1 2
    private let solution = [1, 2, 3, 2, 3, 1, 3, 1, 2]

    private func puzzle(givens: [Int], relations: [NumbersRelation]) -> NumbersPuzzle {
        return NumbersPuzzle(size: 3, givens: givens, relations: relations, solution: solution)
    }

    func testSolvedGrid() {
        let p = puzzle(givens: [1, 0, 0, 0, 0, 0, 0, 0, 0], relations: [NumbersRelation(lo: 0, hi: 1)])
        XCTAssertTrue(NumbersRules.isSolved(p, values: solution))
        XCTAssertEqual(NumbersRules.conflicts(p, values: solution), [Int]())
    }

    func testEmptyCellIsNotSolved() {
        let p = puzzle(givens: [Int](repeating: 0, count: 9), relations: [NumbersRelation]())
        var values = solution
        values[4] = 0
        XCTAssertFalse(NumbersRules.isSolved(p, values: values))
        XCTAssertEqual(NumbersRules.conflicts(p, values: values), [Int]())
    }

    func testGivenMustBeKept() {
        // Another valid Latin square that changes the given in cell 0.
        let other = [2, 3, 1, 3, 1, 2, 1, 2, 3]
        let p = puzzle(givens: [1, 0, 0, 0, 0, 0, 0, 0, 0], relations: [NumbersRelation]())
        XCTAssertFalse(NumbersRules.isSolved(p, values: other))
        XCTAssertFalse(NumbersRules.isSolved(p, values: [1, 2, 3]))
    }

    func testBrokenSignIsNotSolved() {
        let p = puzzle(givens: [Int](repeating: 0, count: 9), relations: [NumbersRelation(lo: 1, hi: 0)])
        XCTAssertFalse(NumbersRules.isSolved(p, values: solution))
        XCTAssertEqual(NumbersRules.conflicts(p, values: solution), [0, 1])
    }

    func testConflictsInRowsAndColumns() {
        let p = puzzle(givens: [Int](repeating: 0, count: 9), relations: [NumbersRelation]())
        // Row 0 has two 1s (cells 0 and 2); column 1 has two 3s (cells 4 and 7).
        let values = [1, 0, 1, 0, 3, 0, 0, 3, 0]
        XCTAssertEqual(NumbersRules.conflicts(p, values: values), [0, 2, 4, 7])
    }

    func testSignOnlyClashesWhenBothFilled() {
        let p = puzzle(givens: [Int](repeating: 0, count: 9), relations: [NumbersRelation(lo: 3, hi: 0)])
        XCTAssertEqual(NumbersRules.conflicts(p, values: [2, 0, 0, 0, 0, 0, 0, 0, 0]), [Int]())
        XCTAssertEqual(NumbersRules.conflicts(p, values: [2, 0, 0, 2, 0, 0, 0, 0, 0]), [0, 3])
        XCTAssertEqual(NumbersRules.conflicts(p, values: [2, 0, 0, 3, 0, 0, 0, 0, 0]), [0, 3])
        XCTAssertEqual(NumbersRules.conflicts(p, values: [3, 0, 0, 2, 0, 0, 0, 0, 0]), [Int]())
    }
}

final class NumbersSolverTests: XCTestCase {
    private func count(_ size: Int, _ givens: [Int], _ relations: [NumbersRelation]) -> Int {
        return NumbersSolver.countSolutions(size: size, givens: givens, relations: relations, limit: 10)
    }

    func testEmptyGridsHaveManySolutions() {
        // 2 Latin squares of order 2, 12 of order 3.
        XCTAssertEqual(count(2, [0, 0, 0, 0], [NumbersRelation]()), 2)
        XCTAssertEqual(NumbersSolver.countSolutions(size: 3, givens: [Int](repeating: 0, count: 9),
                                                    relations: [NumbersRelation](), limit: 100), 12)
        XCTAssertEqual(NumbersSolver.countSolutions(size: 4, givens: [Int](repeating: 0, count: 16),
                                                    relations: [NumbersRelation](), limit: 1000), 576)
    }

    func testOneSignMakesOrderTwoUnique() {
        XCTAssertEqual(count(2, [0, 0, 0, 0], [NumbersRelation(lo: 0, hi: 1)]), 1)
        XCTAssertEqual(NumbersSolver.firstSolution(size: 2, givens: [0, 0, 0, 0],
                                                   relations: [NumbersRelation(lo: 0, hi: 1)]), [1, 2, 2, 1])
    }

    func testUniqueBySignsOnly() {
        // 1 2 3 / 2 3 1 / 3 1 2 with signs along the first row and column and one inside.
        let relations = [NumbersRelation(lo: 0, hi: 1), NumbersRelation(lo: 1, hi: 2),
                         NumbersRelation(lo: 0, hi: 3), NumbersRelation(lo: 3, hi: 6),
                         NumbersRelation(lo: 5, hi: 4)]
        XCTAssertEqual(count(3, [Int](repeating: 0, count: 9), relations), 1)
        XCTAssertEqual(NumbersSolver.firstSolution(size: 3, givens: [Int](repeating: 0, count: 9), relations: relations),
                       [1, 2, 3, 2, 3, 1, 3, 1, 2])
    }

    func testAmbiguous() {
        // Only the first row is fixed: two ways to finish an order-3 square.
        XCTAssertEqual(count(3, [1, 2, 3, 0, 0, 0, 0, 0, 0], [NumbersRelation]()), 2)
        XCTAssertEqual(NumbersSolver.countSolutions(size: 3, givens: [1, 2, 3, 0, 0, 0, 0, 0, 0],
                                                    relations: [NumbersRelation](), limit: 1), 1)
    }

    func testImpossible() {
        // Two equal givens in a row.
        XCTAssertEqual(count(3, [1, 1, 0, 0, 0, 0, 0, 0, 0], [NumbersRelation]()), 0)
        // A cycle of signs.
        XCTAssertEqual(count(2, [0, 0, 0, 0], [NumbersRelation(lo: 0, hi: 1), NumbersRelation(lo: 1, hi: 0)]), 0)
        // The largest value below a neighbour.
        XCTAssertEqual(count(3, [3, 0, 0, 0, 0, 0, 0, 0, 0], [NumbersRelation(lo: 0, hi: 1)]), 0)
        // Malformed input.
        XCTAssertEqual(count(3, [4, 0, 0, 0, 0, 0, 0, 0, 0], [NumbersRelation]()), 0)
        XCTAssertEqual(count(3, [0, 0, 0], [NumbersRelation]()), 0)
        XCTAssertEqual(count(2, [0, 0, 0, 0], [NumbersRelation(lo: 0, hi: 9)]), 0)
    }
}

final class NumbersGeneratorTests: XCTestCase {
    private func check(_ weekday: Int, givens: [Int], relations: [Int]) {
        let seed = PuzzleKind.numbers.seed(dateKey: PuzzleCalendar.dateKey(day: PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 23 + weekday)))
        let puzzle = NumbersGenerator.generate(weekday: weekday, seed: seed)
        XCTAssertEqual(puzzle.size, NumbersGenerator.sizes[weekday], seed)
        XCTAssertEqual(puzzle.givens, givens, seed)
        var flat = [Int]()
        for relation in puzzle.relations {
            flat.append(relation.lo)
            flat.append(relation.hi)
        }
        XCTAssertEqual(flat, relations, seed)
    }

    /// Recorded from a Swift run; the same test runs in Kotlin through Skip, so both agree.
    /// Seeds `numbers|2026-11-23` (Monday) … `numbers|2026-11-29` (Sunday). Relations are
    /// flattened as lo, hi, lo, hi, …
    func testFingerprints() {
        check(0, givens: [0, 0, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 2],
              relations: [1, 2, 6, 2, 12, 8, 15, 14])
        check(1, givens: [0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0],
              relations: [4, 8, 6, 10, 8, 9, 13, 9])
        check(2, givens: [0, 4, 0, 2, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
              relations: [10, 5, 11, 10, 11, 12, 12, 13, 12, 17, 18, 13, 16, 17, 19, 18, 21, 20])
        check(3, givens: [0, 3, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0],
              relations: [1, 0, 6, 7, 7, 12, 15, 10, 13, 14, 20, 15, 23, 18, 19, 24, 20, 21, 24, 23])
        check(4, givens: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0],
              relations: [0, 1, 2, 1, 1, 6, 14, 9, 15, 20, 20, 21, 23, 24])
        check(5, givens: [0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
              relations: [1, 0, 3, 9, 5, 11, 7, 6, 8, 7, 7, 13, 11, 17, 19, 13, 19, 18, 21, 27, 28, 27, 27, 33,
                          30, 31, 34, 35])
        check(6, givens: [0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
              relations: [7, 1, 3, 9, 4, 5, 10, 9, 12, 13, 18, 12, 23, 17, 18, 24, 19, 25, 20, 26, 22, 28, 32, 26,
                          28, 29, 33, 34])
    }

    func testSizes() {
        XCTAssertEqual(NumbersGenerator.sizes, [4, 4, 5, 5, 5, 6, 6])
    }

    func testSameSeedGivesTheSamePuzzle() {
        XCTAssertEqual(NumbersGenerator.generate(weekday: 5, seed: "abc"), NumbersGenerator.generate(weekday: 5, seed: "abc"))
        XCTAssertNotEqual(NumbersGenerator.generate(weekday: 5, seed: "abc"), NumbersGenerator.generate(weekday: 5, seed: "abd"))
    }

    private func assertValid(_ puzzle: NumbersPuzzle, _ label: String) {
        let n = puzzle.size
        XCTAssertEqual(puzzle.givens.count, n * n, label)
        XCTAssertEqual(puzzle.solution.count, n * n, label)
        // The solution is a Latin square that keeps the givens and obeys the signs.
        XCTAssertTrue(NumbersRules.isSolved(puzzle, values: puzzle.solution), label)
        for relation in puzzle.relations {
            let rowLo = relation.lo / n
            let rowHi = relation.hi / n
            let distance = relation.lo > relation.hi ? relation.lo - relation.hi : relation.hi - relation.lo
            let neighbours = (rowLo == rowHi && distance == 1) || distance == n
            XCTAssertTrue(neighbours, label)
        }
        XCTAssertEqual(NumbersGenerator.sortedRelations(puzzle.relations), puzzle.relations, label)
        XCTAssertEqual(NumbersSolver.countSolutions(size: n, givens: puzzle.givens, relations: puzzle.relations, limit: 2), 1, label)
        // The signs are needed: the givens alone leave more than one Latin square.
        XCTAssertEqual(NumbersSolver.countSolutions(size: n, givens: puzzle.givens, relations: [NumbersRelation](), limit: 2), 2, label)
        XCTAssertFalse(puzzle.relations.isEmpty, label)
    }

    func testGeneratedPuzzlesAreValidAndUnique() {
        for weekday in 0..<7 {
            for seed in ["numbers|2026-01-05", "numbers|2027-03-14", "a", "b"] {
                let puzzle = NumbersGenerator.generate(weekday: weekday, seed: seed)
                XCTAssertEqual(puzzle.size, NumbersGenerator.sizes[weekday])
                assertValid(puzzle, "\(weekday) \(seed)")
            }
        }
    }

    func testGenerationTime() {
        var weekday = 0
        while weekday < 7 {
            let start = Date()
            var round = 0
            while round < 5 {
                _ = NumbersGenerator.generate(weekday: weekday, seed: "time|\(round)")
                round += 1
            }
            let milliseconds = Int(Date().timeIntervalSince(start) * 1000.0) / 5
            print("NUMBERS TIMING weekday \(weekday) size \(NumbersGenerator.sizes[weekday]): \(milliseconds) ms per puzzle")
            XCTAssertLessThan(milliseconds, 5000)
            weekday += 1
        }
    }

    func testJSONRoundTripWithExactKeys() throws {
        let puzzle = NumbersPuzzle(size: 2, givens: [0, 2, 0, 0], relations: [NumbersRelation(lo: 0, hi: 1)],
                                   solution: [1, 2, 2, 1])
        let data = try JSONEncoder().encode(puzzle)
        let decoded = try JSONDecoder().decode(NumbersPuzzle.self, from: data)
        XCTAssertEqual(decoded, puzzle)

        let json = "{\"size\":2,\"givens\":[0,2,0,0],\"relations\":[{\"lo\":0,\"hi\":1}],\"solution\":[1,2,2,1]}"
        let parsed = try JSONDecoder().decode(NumbersPuzzle.self, from: json.data(using: String.Encoding.utf8)!)
        XCTAssertEqual(parsed, puzzle)

        let text = String(data: data, encoding: String.Encoding.utf8) ?? ""
        for key in ["\"size\"", "\"givens\"", "\"relations\"", "\"solution\"", "\"lo\"", "\"hi\""] {
            XCTAssertTrue(text.contains(key), key)
        }
    }
}
