import XCTest
@testable import PibblesCore

final class SolverTests: XCTestCase {
    func testSingleSolutionIsFoundWithItsPositions() {
        // Same call as in the prototype: O4 top left, I2 in row 3.
        let result = Solver.countSolutions(size: 5, shapeKeys: ["O4", "I2"],
                                           rows: [2, 2, 0, 2, 0], cols: [3, 3, 0, 0, 0],
                                           limit: 5, budget: 60000)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.nodes, 2)
        XCTAssertFalse(result.exhausted)
        XCTAssertEqual(result.first, [0, 15])
    }

    func testPositionsFollowTheOrderOfTheGivenShapes() {
        let result = Solver.countSolutions(size: 5, shapeKeys: ["I2", "O4"],
                                           rows: [2, 2, 0, 2, 0], cols: [3, 3, 0, 0, 0],
                                           limit: 5, budget: 60000)
        XCTAssertEqual(result.first, [15, 0])
    }

    func testEqualShapesAreInterchangeable() {
        // Two I2 in rows 0 and 2, same columns: swapping them is not a second solution.
        let result = Solver.countSolutions(size: 4, shapeKeys: ["I2", "I2"],
                                           rows: [2, 0, 2, 0], cols: [2, 2, 0, 0],
                                           limit: 5, budget: 60000)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first, [0, 8])
    }

    func testAmbiguousPuzzleCountsUpToTheLimit() {
        // Two I2 in the top two rows, one square per column: left/right can be swapped.
        let all = Solver.countSolutions(size: 4, shapeKeys: ["I2", "I2"],
                                        rows: [2, 2, 0, 0], cols: [1, 1, 1, 1],
                                        limit: 5, budget: 60000)
        XCTAssertEqual(all.count, 2)
        let limited = Solver.countSolutions(size: 4, shapeKeys: ["I2", "I2"],
                                            rows: [2, 2, 0, 0], cols: [1, 1, 1, 1],
                                            limit: 1, budget: 60000)
        XCTAssertEqual(limited.count, 1)
    }

    func testImpossiblePuzzleHasNoSolution() {
        let result = Solver.countSolutions(size: 4, shapeKeys: ["O4"],
                                           rows: [4, 0, 0, 0], cols: [1, 1, 1, 1],
                                           limit: 2, budget: 60000)
        XCTAssertEqual(result.count, 0)
        XCTAssertNil(result.first)
    }

    func testBudgetStopsTheSearch() {
        let puzzle = PuzzleGenerator.generate(level: Level(size: 7, pieceCount: 8), seed: "d0")
        XCTAssertNotNil(puzzle)
        guard let puzzle else { return }
        let result = Solver.countSolutions(size: puzzle.size, shapeKeys: puzzle.pieces,
                                           rows: puzzle.rows, cols: puzzle.cols, limit: 2, budget: 100)
        XCTAssertTrue(result.exhausted)
    }
}
