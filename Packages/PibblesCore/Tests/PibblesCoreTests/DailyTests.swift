import XCTest
@testable import PibblesCore

final class DailyTests: XCTestCase {
    func testBlocksOfADayMatchesThePrototypeSeed() {
        // 22 November 2026 is a Sunday; the prototype's puzzle for that date.
        let day = PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 22)
        let puzzle = Daily.blocks(day: day)
        XCTAssertEqual(puzzle?.pieces, ["L4b", "I3v", "L3d", "I3", "I3", "I3v", "L3b", "L4d"])
    }

    func testOtherKindsFollowTheWeekday() {
        let monday = PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 23)
        XCTAssertEqual(Daily.logic(day: monday).size, 6)
        XCTAssertEqual(Daily.patterns(day: monday).size, 5)
        XCTAssertEqual(Daily.numbers(day: monday).size, 4)
        XCTAssertEqual(Daily.logic(day: monday + 6).size, 8)
    }

    func testDifficultyNames() {
        XCTAssertEqual(Daily.difficulty(weekday: 0), "Easy")
        XCTAssertEqual(Daily.difficulty(weekday: 3), "Medium")
        XCTAssertEqual(Daily.difficulty(weekday: 6), "Hard")
    }

    func testHintFindsTheFirstOpenOrWrongCell() {
        XCTAssertEqual(CellHint.next(values: [1, -1, 0], solution: [1, 0, 0], givens: [1, -1, -1], empty: -1), 1)
        XCTAssertEqual(CellHint.next(values: [1, 1, 0], solution: [1, 0, 0], givens: [1, -1, -1], empty: -1), 1)
        XCTAssertNil(CellHint.next(values: [1, 0, 0], solution: [1, 0, 0], givens: [1, -1, -1], empty: -1))
        // Patterns: a cell marked empty is right where the solution is empty.
        XCTAssertEqual(CellHint.next(values: [2, 0], solution: [0, 1], givens: nil, empty: 0), 1)
    }
}
