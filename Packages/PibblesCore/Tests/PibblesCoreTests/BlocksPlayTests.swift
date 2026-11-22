import XCTest
@testable import PibblesCore

final class BlocksPlayTests: XCTestCase {
    // Monday "d0": I4v at 0, I4 at 21, I4v at 2, L3d at 8 on a 5x5 board.
    private let puzzle = Puzzle(size: 5, pieces: ["I4v", "I4", "I4v", "L3d"],
                                rows: [2, 3, 4, 2, 4], cols: [4, 1, 5, 2, 3],
                                solution: [0, 21, 2, 8], attempts: 1, nodes: 9)

    func testStartsWithTheFirstPieceInHand() {
        let play = BlocksPlay(puzzle: puzzle)
        XCTAssertEqual(play.selected, 0)
        XCTAssertEqual(play.positions, [nil, nil, nil, nil])
        XCTAssertFalse(play.isSolved)
    }

    func testTapPlacesAndHandsTheNextPiece() {
        var play = BlocksPlay(puzzle: puzzle)
        play.tap(square: 0)
        XCTAssertEqual(play.positions[0], 0)
        XCTAssertEqual(play.selected, 1)
    }

    func testPieceIsMovedInToFit() {
        var play = BlocksPlay(puzzle: puzzle)
        play.select(1) // I4, four wide
        play.tap(square: 24)
        XCTAssertEqual(play.positions[1], 21)
    }

    func testPlacingOnAPieceSendsItBack() {
        var play = BlocksPlay(puzzle: puzzle)
        play.tap(square: 0) // I4v at 0, column 0 rows 0-3
        play.select(1)
        play.tap(square: 15) // I4 at 15 covers square 15, which the I4v holds
        XCTAssertEqual(play.positions[1], 15)
        XCTAssertNil(play.positions[0])
    }

    func testTapOnAPlacedPieceWithEmptyHandPicksItUp() {
        var play = BlocksPlay(puzzle: puzzle)
        play.tap(square: 0)
        play.tap(square: 21)
        play.tap(square: 2)
        play.tap(square: 13) // L3d at 13: not the solution, but all pieces lie
        XCTAssertNil(play.selected)
        XCTAssertFalse(play.isSolved)
        play.tap(square: 14)
        XCTAssertEqual(play.selected, 3)
        XCTAssertNil(play.positions[3])
    }

    func testSolving() {
        var play = BlocksPlay(puzzle: puzzle)
        play.tap(square: 0)
        play.tap(square: 21)
        play.tap(square: 2)
        play.tap(square: 8)
        XCTAssertTrue(play.isSolved)
        XCTAssertFalse(play.tap(square: 0))
    }

    func testHintPlacesAPieceOnASolutionSpot() {
        var play = BlocksPlay(puzzle: puzzle)
        XCTAssertTrue(play.hint())
        XCTAssertEqual(play.hints, 1)
        XCTAssertEqual(play.positions[0], 0)
        XCTAssertTrue(play.isCorrect(0))
    }

    func testHintsSolveThePuzzle() {
        var play = BlocksPlay(puzzle: puzzle)
        play.select(2)
        play.tap(square: 0) // second I4v on the first I4v's spot: also correct
        var guardCount = 0
        while !play.isSolved && guardCount < 10 {
            play.hint()
            guardCount += 1
        }
        XCTAssertTrue(play.isSolved)
        XCTAssertEqual(play.hints, 3)
        XCTAssertFalse(play.hint())
    }

    func testClear() {
        var play = BlocksPlay(puzzle: puzzle)
        play.tap(square: 0)
        play.clear()
        XCTAssertEqual(play.positions, [nil, nil, nil, nil])
        XCTAssertEqual(play.selected, 0)
    }
}
