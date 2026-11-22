import XCTest
@testable import PibblesCore

final class PuzzleRulesTests: XCTestCase {
    // Monday "d0": I4v at 0, I4 at 21, I4v at 2, L3d at 8 on a 5x5 board.
    private let puzzle = Puzzle(size: 5, pieces: ["I4v", "I4", "I4v", "L3d"],
                                rows: [2, 3, 4, 2, 4], cols: [4, 1, 5, 2, 3],
                                solution: [0, 21, 2, 8], attempts: 1, nodes: 9)

    func testCellsOfAPlacedPiece() {
        XCTAssertEqual(PuzzleRules.cells(shapeKey: "L3d", position: 8, size: 5), [9, 13, 14])
        XCTAssertEqual(PuzzleRules.cells(shapeKey: "X9", position: 0, size: 5), [Int]())
    }

    func testPieceMustStayOnTheBoard() {
        XCTAssertTrue(PuzzleRules.fits(shapeKey: "I4", position: 21, size: 5))
        XCTAssertFalse(PuzzleRules.fits(shapeKey: "I4", position: 22, size: 5))
        XCTAssertFalse(PuzzleRules.fits(shapeKey: "I4v", position: 10, size: 5))
        XCTAssertFalse(PuzzleRules.fits(shapeKey: "I4", position: -1, size: 5))
        XCTAssertFalse(PuzzleRules.fits(shapeKey: "I4", position: 25, size: 5))
    }

    func testPieceCannotOverlapAnotherPiece() {
        let placed: [Int?] = [0, nil, nil, nil]
        XCTAssertFalse(PuzzleRules.canPlace(puzzle, piece: 2, position: 0, positions: placed))
        XCTAssertTrue(PuzzleRules.canPlace(puzzle, piece: 2, position: 2, positions: placed))
        // Moving a piece does not collide with itself.
        XCTAssertTrue(PuzzleRules.canPlace(puzzle, piece: 0, position: 5, positions: placed))
    }

    func testCountsOfTheBoard() {
        let counts = PuzzleRules.counts(puzzle, positions: [0, nil, nil, 8])
        XCTAssertEqual(counts.rows, [1, 2, 3, 1, 0])
        XCTAssertEqual(counts.cols, [4, 0, 0, 1, 2])
    }

    func testSolvedOnlyWhenAllPiecesLieAndAllNumbersMatch() {
        XCTAssertTrue(PuzzleRules.isSolved(puzzle, positions: [0, 21, 2, 8]))
        XCTAssertFalse(PuzzleRules.isSolved(puzzle, positions: [0, 21, 2, nil]))
        XCTAssertFalse(PuzzleRules.isSolved(puzzle, positions: [0, 21, 3, 8]))
        XCTAssertFalse(PuzzleRules.isSolved(puzzle, positions: [0, 21, 2]))
    }

    func testEqualShapesMayBeSwapped() {
        XCTAssertTrue(PuzzleRules.isSolved(puzzle, positions: [2, 21, 0, 8]))
    }

    func testScoreAddsThirtySecondsPerHint() {
        XCTAssertEqual(Ranking.score(milliseconds: 65000, hints: 0), 65000)
        XCTAssertEqual(Ranking.score(milliseconds: 65000, hints: 2), 125000)
    }
}
