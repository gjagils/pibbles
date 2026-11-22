import XCTest
@testable import PibblesCore

final class PatternsSolverTests: XCTestCase {
    func testLineOverlapFillsTheMiddle() {
        // A run of 4 in 5 cells always covers the middle three.
        XCTAssertEqual(PatternsSolver.solveLine([-1, -1, -1, -1, -1], clue: [4]), [-1, 1, 1, 1, -1])
        // 2 and 2 in 5 cells: only one placement.
        XCTAssertEqual(PatternsSolver.solveLine([-1, -1, -1, -1, -1], clue: [2, 2]), [1, 1, 0, 1, 1])
        // An empty clue empties the line.
        XCTAssertEqual(PatternsSolver.solveLine([-1, -1, -1], clue: [Int]()), [0, 0, 0])
    }

    func testLineUsesKnownCells() {
        // A known empty cell in the middle leaves no room for a run of 3.
        XCTAssertEqual(PatternsSolver.solveLine([-1, -1, 0, -1, -1], clue: [3]), nil)
        XCTAssertEqual(PatternsSolver.solveLine([-1, 0, -1, -1, -1], clue: [3]), [0, 0, 1, 1, 1])
        // A known filled cell pins the run of 1; the rest is empty.
        XCTAssertEqual(PatternsSolver.solveLine([-1, -1, 1, -1], clue: [1]), [0, 0, 1, 0])
    }

    func testLineContradictions() {
        XCTAssertNil(PatternsSolver.solveLine([-1, -1], clue: [3]))
        XCTAssertNil(PatternsSolver.solveLine([-1, -1, -1], clue: [1, 2]))
        XCTAssertNil(PatternsSolver.solveLine([1, -1, -1], clue: [Int]()))
        XCTAssertNil(PatternsSolver.solveLine([-1, -1, -1], clue: [0]))
    }

    func testUniquePuzzle() {
        // X X .
        // . . .
        // X . X
        let count = PatternsSolver.countSolutions(size: 3, rowClues: [[2], [], [1, 1]],
                                                  colClues: [[1, 1], [1], [1]], limit: 2)
        XCTAssertEqual(count, 1)
        XCTAssertTrue(PatternsSolver.isLineSolvable(size: 3, rowClues: [[2], [], [1, 1]],
                                                    colClues: [[1, 1], [1], [1]]))
    }

    func testEmptyGridIsUnique() {
        let empty = [[Int]](repeating: [Int](), count: 4)
        XCTAssertEqual(PatternsSolver.countSolutions(size: 4, rowClues: empty, colClues: empty, limit: 2), 1)
    }

    func testAmbiguousPuzzleCountsUpToTheLimit() {
        // One cell per row and column in 2 × 2: both diagonals fit.
        let ones: [[Int]] = [[1], [1]]
        XCTAssertEqual(PatternsSolver.countSolutions(size: 2, rowClues: ones, colClues: ones, limit: 5), 2)
        XCTAssertEqual(PatternsSolver.countSolutions(size: 2, rowClues: ones, colClues: ones, limit: 1), 1)
        XCTAssertFalse(PatternsSolver.isLineSolvable(size: 2, rowClues: ones, colClues: ones))
        // One cell per row and column in 4 × 4: the 24 permutation matrices.
        let fourOnes: [[Int]] = [[1], [1], [1], [1]]
        XCTAssertEqual(PatternsSolver.countSolutions(size: 4, rowClues: fourOnes, colClues: fourOnes, limit: 100), 24)
    }

    func testUniqueOnlyWithGuessing() {
        // . . . X
        // X . . .
        // X . . .
        // . . . X
        // Line solving only learns that the middle columns are empty; a guess shows that
        // column 0 must hold rows 1 and 2, so there is still exactly one solution.
        let rows: [[Int]] = [[1], [1], [1], [1]]
        let cols: [[Int]] = [[2], [], [], [1, 1]]
        XCTAssertFalse(PatternsSolver.isLineSolvable(size: 4, rowClues: rows, colClues: cols))
        XCTAssertEqual(PatternsSolver.countSolutions(size: 4, rowClues: rows, colClues: cols, limit: 5), 1)
    }

    func testImpossiblePuzzle() {
        // Rows want 3 filled cells, columns only 2.
        XCTAssertEqual(PatternsSolver.countSolutions(size: 2, rowClues: [[2], [1]], colClues: [[1], []], limit: 2), 0)
        // A run longer than the line.
        XCTAssertEqual(PatternsSolver.countSolutions(size: 2, rowClues: [[3], []], colClues: [[1], [1]], limit: 2), 0)
        XCTAssertFalse(PatternsSolver.isLineSolvable(size: 2, rowClues: [[2], [1]], colClues: [[1], []]))
    }

    func testWrongNumberOfCluesHasNoSolution() {
        XCTAssertEqual(PatternsSolver.countSolutions(size: 2, rowClues: [[1]], colClues: [[1], []], limit: 2), 0)
        XCTAssertEqual(PatternsSolver.countSolutions(size: 0, rowClues: [[Int]](), colClues: [[Int]](), limit: 2), 0)
    }
}
