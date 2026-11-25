import Foundation
import XCTest
@testable import PibblesCore

/// 3 × 3, one colour per row:   0 . 0
///                              1 . 1
///                              2 . 2
private let rowsPuzzle = LinksPuzzle(size: 3, ends: [0, -1, 0, 1, -1, 1, 2, -1, 2],
                                     solution: [[0, 1, 2], [3, 4, 5], [6, 7, 8]])

final class LinksRulesTests: XCTestCase {
    func testSolutionSolvesThePuzzle() {
        XCTAssertTrue(LinksRules.isSolved(rowsPuzzle, paths: rowsPuzzle.solution))
        // A path may start at either dot.
        XCTAssertTrue(LinksRules.isSolved(rowsPuzzle, paths: [[2, 1, 0], [3, 4, 5], [8, 7, 6]]))
        XCTAssertEqual(rowsPuzzle.colourCount, 3)
    }

    func testIncompleteOrWrongPathsDoNotSolve() {
        // A path that stops early.
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 1], [3, 4, 5], [6, 7, 8]]))
        // An empty path.
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 1, 2], [Int](), [6, 7, 8]]))
        // Too few or too many paths.
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 1, 2], [3, 4, 5]]))
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 1, 2], [3, 4, 5], [6, 7, 8], [Int]()]))
        // A jump between cells that are not neighbours.
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 4, 2], [3, 1, 5], [6, 7, 8]]))
        // Overlapping paths.
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 1, 2], [3, 4, 5], [6, 7, 4, 5, 8]]))
        // A path that ends on another colour's dot.
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 1, 4, 3], [5, 2], [6, 7, 8]]))
        // Cells outside the grid.
        XCTAssertFalse(LinksRules.isSolved(rowsPuzzle, paths: [[0, 1, 2], [3, 4, 5], [6, 7, 8, 9]]))
    }

    func testAllCellsMustBeUsed() {
        // 0 . 0 / . . . / 1 . 1: the straight paths leave the middle row empty.
        let puzzle = LinksPuzzle(size: 3, ends: [0, -1, 0, -1, -1, -1, 1, -1, 1], solution: [[Int]]())
        XCTAssertFalse(LinksRules.isSolved(puzzle, paths: [[0, 1, 2], [6, 7, 8]]))
    }

    func testPathThatTouchesItselfDoesNotSolve() {
        // One colour, dots in the top corners: the snake 0 3 6 7 8 5 4 1 2 fills every cell,
        // but 1 lies next to 0 (and 4 next to 1 and 3): not allowed by the convention.
        let puzzle = LinksPuzzle(size: 3, ends: [0, -1, 0, -1, -1, -1, -1, -1, -1], solution: [[Int]]())
        XCTAssertFalse(LinksRules.isSolved(puzzle, paths: [[0, 3, 6, 7, 8, 5, 4, 1, 2]]))
        XCTAssertEqual(LinksSolver.countSolutions(size: 3, ends: puzzle.ends, limit: 10), 0)
    }

    func testExtendStartsOnlyOnOwnDot() {
        let empty = [[Int](), [Int](), [Int]()]
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: empty, colour: 0, to: 2), [[2], [Int](), [Int]()])
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: empty, colour: 0, to: 1), empty)
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: empty, colour: 0, to: 3), empty)
    }

    func testExtendAppendsNeighboursUntilComplete() {
        var paths = [[0], [Int](), [Int]()]
        paths = LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 1)
        XCTAssertEqual(paths[0], [0, 1])
        // Not a neighbour of the last cell.
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 5), paths)
        // Another colour's dot.
        let down = LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 4)
        XCTAssertEqual(down[0], [0, 1, 4])
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: down, colour: 0, to: 3), down)
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: down, colour: 0, to: 5), down)
        // Reaching the other dot completes the path; nothing goes past it.
        paths = LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 2)
        XCTAssertEqual(paths[0], [0, 1, 2])
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: [[0, 1, 4, 7, 8, 5, 2], [Int](), [Int]()], colour: 0, to: 1),
                       [[0, 1], [Int](), [Int]()])
    }

    func testExtendIsBlockedAfterCompletion() {
        // 0 1 2 is complete; 5 is a neighbour of 2 (and colour 1's dot), 4 is a free neighbour
        // of nothing at the end: both refused.
        let paths = [[0, 1, 2], [Int](), [Int]()]
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 5), paths)
        // A puzzle where the cell past the end is free: 0 . 0 / . . . / 1 . 1.
        let open = LinksPuzzle(size: 3, ends: [0, -1, 0, -1, -1, -1, 1, -1, 1], solution: [[Int]]())
        XCTAssertEqual(LinksRules.extend(open, paths: [[0, 1, 2], [Int]()], colour: 0, to: 5), [[0, 1, 2], [Int]()])
        // A path of one dot is not complete.
        XCTAssertEqual(LinksRules.extend(open, paths: [[2], [Int]()], colour: 0, to: 5), [[2, 5], [Int]()])
    }

    func testExtendCutsBackOwnPath() {
        let paths = [[0, 1, 4, 7], [Int](), [Int]()]
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 1), [[0, 1], [Int](), [Int]()])
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 0), [[0], [Int](), [Int]()])
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 7), paths)
    }

    func testExtendCutsTheCrossedPath() {
        let paths = [[0, 1], [3, 4, 5], [6, 7]]
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 4), [[0, 1, 4], [3], [6, 7]])
        // Crossing the path at its second cell from the other side.
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: [[0, 1, 4], [5], [6, 7, 8]], colour: 0, to: 7),
                       [[0, 1, 4, 7], [5], [6]])
    }

    func testExtendIgnoresBadInput() {
        let paths = [[0], [Int](), [Int]()]
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 3, to: 1), paths)
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: -1, to: 1), paths)
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: 9), paths)
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: paths, colour: 0, to: -1), paths)
        // Missing paths are filled in as empty ones.
        XCTAssertEqual(LinksRules.extend(rowsPuzzle, paths: [[Int]](), colour: 1, to: 3), [[Int](), [3], [Int]()])
    }

    func testStartOnDotRestartsThatColour() {
        let paths = [[0, 1], [3, 4, 5], [Int]()]
        let fromOtherDot = LinksRules.start(rowsPuzzle, paths: paths, at: 5)
        XCTAssertEqual(fromOtherDot, StartResult(colour: 1, paths: [[0, 1], [5], [Int]()]))
        let fresh = LinksRules.start(rowsPuzzle, paths: paths, at: 6)
        XCTAssertEqual(fresh?.colour, 2)
        XCTAssertEqual(fresh?.paths, [[0, 1], [3, 4, 5], [6]])
    }

    func testStartOnPathCutsBack() {
        let paths = [[0, 1, 4, 7], [3], [Int]()]
        XCTAssertEqual(LinksRules.start(rowsPuzzle, paths: paths, at: 4), StartResult(colour: 0, paths: [[0, 1, 4], [3], [Int]()]))
        XCTAssertEqual(LinksRules.start(rowsPuzzle, paths: paths, at: 7), StartResult(colour: 0, paths: paths))
    }

    func testStartElsewhereIsNil() {
        let paths = [[0, 1], [3], [Int]()]
        XCTAssertNil(LinksRules.start(rowsPuzzle, paths: paths, at: 4))
        XCTAssertNil(LinksRules.start(rowsPuzzle, paths: paths, at: 9))
        XCTAssertNil(LinksRules.start(rowsPuzzle, paths: paths, at: -1))
    }
}

/// Counts solutions by trying every colour in every cell, row by row, checking each cell's
/// number of same-coloured neighbours as soon as they are all known, and at the end that
/// every colour is one connected piece. Slow, but obviously right: the check for the solver.
private final class LinksBruteForce {
    let size: Int
    let cells: Int
    let ends: [Int]
    let colours: Int
    var colouring: [Int]
    var count = 0

    init(size: Int, ends: [Int]) {
        self.size = size
        self.cells = size * size
        self.ends = ends
        var largest = -1
        for value in ends {
            if value > largest { largest = value }
        }
        self.colours = largest + 1
        self.colouring = ends
    }

    func run() -> Int {
        place(0)
        return count
    }

    private func place(_ cell: Int) {
        if cell == cells {
            var all = 0
            var ok = true
            while all < cells && ok {
                ok = degreeFits(all)
                all += 1
            }
            if ok && connected() { count += 1 }
            return
        }
        var colour = ends[cell] >= 0 ? ends[cell] : 0
        let last = ends[cell] >= 0 ? ends[cell] : colours - 1
        while colour <= last {
            colouring[cell] = colour
            if cell < size || degreeFits(cell - size) { place(cell + 1) }
            colour += 1
        }
        colouring[cell] = ends[cell]
    }

    /// A dot has one neighbour of its colour, any other cell two.
    private func degreeFits(_ cell: Int) -> Bool {
        var same = 0
        for next in LinksGenerator.neighbourCells(size, cell) {
            if colouring[next] == colouring[cell] { same += 1 }
        }
        return same == (ends[cell] >= 0 ? 1 : 2)
    }

    /// Every colour is one piece (so no separate loops).
    private func connected() -> Bool {
        var colour = 0
        while colour < colours {
            var start = -1
            var total = 0
            var cell = 0
            while cell < cells {
                if colouring[cell] == colour {
                    total += 1
                    if start < 0 { start = cell }
                }
                cell += 1
            }
            var seen = Array(repeating: false, count: cells)
            var stack = [start]
            seen[start] = true
            var reached = 1
            while !stack.isEmpty {
                let current = stack.removeLast()
                for next in LinksGenerator.neighbourCells(size, current) {
                    if !seen[next] && colouring[next] == colour {
                        seen[next] = true
                        reached += 1
                        stack.append(next)
                    }
                }
            }
            if reached != total { return false }
            colour += 1
        }
        return true
    }
}

final class LinksSolverTests: XCTestCase {
    private func count(_ size: Int, _ ends: [Int]) -> Int {
        return LinksSolver.countSolutions(size: size, ends: ends, limit: 10)
    }

    func testUnique() {
        XCTAssertEqual(count(3, rowsPuzzle.ends), 1)
        // Neighbouring dots are joined directly: 0 . . / 2 2 . / 1 1 0 has only 0 1 2 5 8.
        XCTAssertEqual(count(3, [0, -1, -1, 2, 2, -1, 1, 1, 0]), 1)
        // A generated-looking 5 × 5.
        XCTAssertEqual(count(5, [0, 1, 2, -1, 2, -1, -1, 3, -1, 3, -1, -1, 4, 5, -1, -1, -1, -1, 4, -1, 0, -1, -1, 1, 5]), 1)
    }

    func testAmbiguous() {
        // 0 . . .     Either 0 runs along the top, down the right and back along the bottom
        // . 1 2 .     to its dot in the middle while 1 takes 4 8 to the corner, or 1 takes
        // . 0 2 .     that long way round and 0 goes down 4 8.
        // 1 . . .
        let ends = [0, -1, -1, -1, -1, 1, 2, -1, -1, 0, 2, -1, 1, -1, -1, -1]
        XCTAssertEqual(count(4, ends), 2)
        XCTAssertEqual(LinksSolver.countSolutions(size: 4, ends: ends, limit: 1), 1)
        XCTAssertEqual(LinksBruteForce(size: 4, ends: ends).run(), 2)
    }

    func testImpossible() {
        // Crossing pairs: 0 . 1 / . . . / 1 . 0.
        XCTAssertEqual(count(3, [0, -1, 1, -1, -1, -1, 1, -1, 0]), 0)
        // The middle row cannot be filled: 0 . 0 / . . . / 1 . 1.
        XCTAssertEqual(count(3, [0, -1, 0, -1, -1, -1, 1, -1, 1]), 0)
        // One colour cannot fill a 2 × 2 without touching itself.
        XCTAssertEqual(count(2, [0, -1, 0, -1]), 0)
    }

    func testMalformed() {
        XCTAssertEqual(count(3, [0, -1, 0]), 0)
        XCTAssertEqual(count(0, [Int]()), 0)
        // A colour once, three times, or a gap in the colours.
        XCTAssertEqual(count(3, [0, -1, 0, 1, -1, -1, 2, -1, 2]), 0)
        XCTAssertEqual(count(3, [0, 0, 0, 1, -1, 1, 2, -1, 2]), 0)
        XCTAssertEqual(count(3, [0, -1, 0, 2, -1, 2, 3, -1, 3]), 0)
        // A value below -1, no dots at all, a limit of 0.
        XCTAssertEqual(count(3, [0, -1, 0, 1, -2, 1, 2, -1, 2]), 0)
        XCTAssertEqual(count(2, [-1, -1, -1, -1]), 0)
        XCTAssertEqual(LinksSolver.countSolutions(size: 3, ends: rowsPuzzle.ends, limit: 0), 0)
    }

    /// The solver agrees with brute force on random small layouts: random dots (mostly
    /// impossible), and dots from random path covers with one dot moved.
    func testAgreesWithBruteForce() {
        let random = SeededRandom(seed: 2026)
        var round = 0
        var solvable = 0
        while round < 60 {
            let size = 3 + round % 2
            var ends = [Int]()
            if round % 3 == 0 {
                let colours = 2 + random.nextInt(2)
                ends = Array(repeating: -1, count: size * size)
                var placed = 0
                while placed < 2 * colours {
                    let cell = random.nextInt(size * size)
                    if ends[cell] < 0 {
                        ends[cell] = placed / 2
                        placed += 1
                    }
                }
            } else if let paths = LinksGenerator.cover(size: size, average: 3 + random.nextInt(3), random: random) {
                ends = LinksGenerator.puzzleFrom(size: size, paths: paths).ends
                if round % 3 == 2 {
                    let to = random.nextInt(size * size)
                    if ends[to] < 0 {
                        var from = 0
                        while ends[from] != 0 { from += 1 }
                        ends[from] = -1
                        ends[to] = 0
                    }
                }
            } else {
                round += 1
                continue
            }
            let expected = LinksBruteForce(size: size, ends: ends).run()
            XCTAssertEqual(LinksSolver.countSolutions(size: size, ends: ends, limit: 100), expected, "\(ends)")
            if expected > 0 { solvable += 1 }
            round += 1
        }
        XCTAssertTrue(solvable > 10)
    }
}

/// The same seed must give the same puzzle in Swift and in Skip's Kotlin; these values were
/// recorded from a Swift run and this test also runs in Kotlin. Changing the generator (cover,
/// joining, colour ranges, order of random draws) changes every puzzle: record anew.
final class LinksGeneratorTests: XCTestCase {
    private func check(_ weekday: Int, ends: [Int]) {
        let dateKey = PuzzleCalendar.dateKey(day: PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 23 + weekday))
        let seed = PuzzleKind.links.seed(dateKey: dateKey)
        let puzzle = LinksGenerator.generate(weekday: weekday, seed: seed)
        XCTAssertEqual(puzzle.size, LinksGenerator.sizes[weekday], seed)
        XCTAssertEqual(puzzle.ends, ends, seed)
        assertValid(puzzle, weekday: weekday, label: seed)
    }

    func testFingerprintMonday() {
        check(0, ends: [0, 1, 2, -1, 2, -1, -1, 3, -1, 3, -1, -1, 4, 5, -1, -1, -1, -1, 4, -1, 0, -1, -1, 1,
                        5])
    }

    func testFingerprintTuesday() {
        check(1, ends: [-1, 0, -1, -1, -1, -1, 1, -1, 2, 1, -1, -1, 0, -1, 2, -1, -1, -1, -1, -1, 3, 4, -1, 4,
                        3])
    }

    func testFingerprintWednesday() {
        check(2, ends: [-1, -1, -1, -1, -1, 0, -1, 1, -1, -1, -1, -1, -1, 0, 2, -1, 3, -1, 4, -1, -1, 3, 5, -1,
                        -1, 2, 5, -1, -1, 1, -1, -1, -1, -1, -1, 4])
    }

    func testFingerprintThursday() {
        check(3, ends: [-1, 0, -1, -1, -1, -1, -1, 1, -1, 2, -1, -1, -1, -1, -1, 3, -1, -1, -1, -1, 1, 2, -1, -1,
                        -1, 0, 4, -1, -1, 3, 5, -1, -1, 5, -1, 4])
    }

    func testFingerprintFriday() {
        check(4, ends: [-1, 0, 1, -1, -1, 2, -1, -1, -1, 3, -1, -1, -1, 3, -1, -1, -1, -1, -1, -1, 1, 4, -1, -1,
                        4, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, 2])
    }

    func testFingerprintSaturday() {
        check(5, ends: [-1, -1, -1, 0, -1, 1, -1, -1, 2, -1, -1, -1, 0, -1, 3, -1, -1, -1, 4, -1, -1, 5, -1, -1,
                        -1, -1, -1, -1, 6, -1, -1, 6, -1, -1, -1, -1, 5, 2, -1, 3, 4, -1, -1, -1, -1, -1, 1, -1,
                        -1])
    }

    func testFingerprintSunday() {
        check(6, ends: [0, -1, -1, -1, 0, -1, 1, 2, -1, -1, 1, -1, -1, 2, -1, 3, -1, -1, -1, -1, -1, -1, -1, -1,
                        -1, -1, -1, -1, -1, -1, 4, -1, -1, -1, -1, -1, -1, -1, -1, 5, -1, -1, -1, -1, -1, 3, 4, -1,
                        5])
    }

    func testSizesRunFromMondayToSunday() {
        XCTAssertEqual(LinksGenerator.sizes, [5, 5, 6, 6, 6, 7, 7])
    }

    func testSameSeedGivesTheSamePuzzle() {
        XCTAssertEqual(LinksGenerator.generate(weekday: 3, seed: "abc"), LinksGenerator.generate(weekday: 3, seed: "abc"))
        XCTAssertNotEqual(LinksGenerator.generate(weekday: 3, seed: "abc"), LinksGenerator.generate(weekday: 3, seed: "abd"))
    }

    func testWeekdayOutsideTheWeekIsClamped() {
        XCTAssertEqual(LinksGenerator.generate(weekday: -2, seed: "x").size, 5)
        XCTAssertEqual(LinksGenerator.generate(weekday: 11, seed: "x").size, 7)
    }

    func testFallbackIsUnique() {
        for size in [5, 6, 7, 8] {
            let puzzle = LinksGenerator.fallback(size: size)
            XCTAssertTrue(LinksRules.isSolved(puzzle, paths: puzzle.solution))
            XCTAssertEqual(LinksSolver.countSolutions(size: size, ends: puzzle.ends, limit: 2), 1)
        }
    }

    private func assertValid(_ puzzle: LinksPuzzle, weekday: Int, label: String) {
        let size = puzzle.size
        XCTAssertEqual(puzzle.ends.count, size * size, label)
        let colours = puzzle.colourCount
        XCTAssertTrue(colours >= LinksGenerator.minColours[weekday] && colours <= LinksGenerator.maxColours[weekday], label)
        XCTAssertEqual(puzzle.solution.count, colours, label)
        var dots = Array(repeating: 0, count: colours)
        for value in puzzle.ends {
            XCTAssertTrue(value >= -1 && value < colours, label)
            if value >= 0 { dots[value] += 1 }
        }
        for n in dots {
            XCTAssertEqual(n, 2, label)
        }
        var colour = 0
        while colour < colours {
            let path = puzzle.solution[colour]
            XCTAssertTrue(path.count >= 3, label)
            // From the first dot (lower cell index) to the other.
            XCTAssertTrue(path[0] < path[path.count - 1], label)
            XCTAssertTrue(LinksGenerator.isInduced(size, path), label)
            colour += 1
        }
        // Colours are numbered by their first dot.
        colour = 1
        while colour < colours {
            XCTAssertTrue(puzzle.solution[colour - 1][0] < puzzle.solution[colour][0], label)
            colour += 1
        }
        XCTAssertTrue(LinksRules.isSolved(puzzle, paths: puzzle.solution), label)
        XCTAssertEqual(LinksSolver.countSolutions(size: size, ends: puzzle.ends, limit: 2), 1, label)
        XCTAssertNotEqual(puzzle, LinksGenerator.fallback(size: size), label)
    }

    func testGeneratedPuzzlesAreValidAndUnique() {
        for weekday in 0..<7 {
            for seed in ["links|2026-01-05", "links|2027-03-14", "a"] {
                let puzzle = LinksGenerator.generate(weekday: weekday, seed: seed)
                XCTAssertEqual(puzzle.size, LinksGenerator.sizes[weekday])
                assertValid(puzzle, weekday: weekday, label: "\(weekday) \(seed)")
            }
        }
    }

    func testGenerationTime() {
        var weekday = 0
        while weekday < 7 {
            let start = Date()
            var round = 0
            while round < 5 {
                _ = LinksGenerator.generate(weekday: weekday, seed: "time|\(round)")
                round += 1
            }
            let milliseconds = Int(Date().timeIntervalSince(start) * 1000.0) / 5
            print("LINKS TIMING weekday \(weekday) size \(LinksGenerator.sizes[weekday]): \(milliseconds) ms per puzzle")
            XCTAssertLessThan(milliseconds, 5000)
            weekday += 1
        }
    }

    func testJSONRoundTripWithExactKeys() throws {
        let data = try JSONEncoder().encode(rowsPuzzle)
        let decoded = try JSONDecoder().decode(LinksPuzzle.self, from: data)
        XCTAssertEqual(decoded, rowsPuzzle)

        let json = "{\"size\":3,\"ends\":[0,-1,0,1,-1,1,2,-1,2],\"solution\":[[0,1,2],[3,4,5],[6,7,8]]}"
        let parsed = try JSONDecoder().decode(LinksPuzzle.self, from: json.data(using: String.Encoding.utf8)!)
        XCTAssertEqual(parsed, rowsPuzzle)

        let text = String(data: data, encoding: String.Encoding.utf8) ?? ""
        for key in ["\"size\"", "\"ends\"", "\"solution\""] {
            XCTAssertTrue(text.contains(key), key)
        }
        XCTAssertFalse(text.contains("colourCount"))
    }
}
