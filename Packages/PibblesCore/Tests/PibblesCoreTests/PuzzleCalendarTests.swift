import Foundation
import XCTest
@testable import PibblesCore

final class PuzzleCalendarTests: XCTestCase {
    func testDayZeroIsMondayFifthOfJanuary() {
        XCTAssertEqual(PuzzleCalendar.dayNumber(year: 2026, month: 1, day: 5), 0)
        XCTAssertEqual(PuzzleCalendar.dateKey(day: 0), "2026-01-05")
        XCTAssertEqual(PuzzleCalendar.weekday(day: 0), 0)
    }

    func testDateKeysRoundTrip() {
        var day = -800
        while day < 3000 {
            let key = PuzzleCalendar.dateKey(day: day)
            XCTAssertEqual(PuzzleCalendar.dayNumber(dateKey: key), day, key)
            day += 37
        }
    }

    func testKnownWeekdays() {
        // 22 November 2026 is a Sunday, 23 November a Monday, 29 February 2028 a Tuesday.
        XCTAssertEqual(PuzzleCalendar.weekday(day: PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 22)), 6)
        XCTAssertEqual(PuzzleCalendar.weekday(day: PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 23)), 0)
        XCTAssertEqual(PuzzleCalendar.weekday(day: PuzzleCalendar.dayNumber(year: 2028, month: 2, day: 29)), 1)
        XCTAssertEqual(PuzzleCalendar.dateKey(day: PuzzleCalendar.dayNumber(year: 2028, month: 2, day: 29)), "2028-02-29")
    }

    func testWeekStartIsMonday() {
        let sunday = PuzzleCalendar.dayNumber(year: 2026, month: 11, day: 22)
        XCTAssertEqual(PuzzleCalendar.dateKey(day: PuzzleCalendar.weekStart(day: sunday)), "2026-11-16")
        XCTAssertEqual(PuzzleCalendar.weekday(day: -1), 6)
    }

    func testBadDateKeys() {
        XCTAssertNil(PuzzleCalendar.dayNumber(dateKey: "2026-13-01"))
        XCTAssertNil(PuzzleCalendar.dayNumber(dateKey: "morgen"))
    }

    func testTodayUsesTheDeviceClock() {
        let date = Date(timeIntervalSince1970: 1_795_000_000)
        let expected = (1_795_000_000 + TimeZone.current.secondsFromGMT(for: date)) / 86400 - 20458
        XCTAssertEqual(PuzzleCalendar.today(now: date), expected)
    }

    func testSeedsPerKind() {
        XCTAssertEqual(PuzzleKind.blocks.seed(dateKey: "2026-11-23"), "2026-11-23")
        XCTAssertEqual(PuzzleKind.logic.seed(dateKey: "2026-11-23"), "logic|2026-11-23")
        XCTAssertEqual(PuzzleKind.allCases.count, 7)
        XCTAssertEqual(PuzzleKind.links.seed(dateKey: "2026-11-23"), "links|2026-11-23")
        XCTAssertEqual(PuzzleKind.stars.stall, "Logic")
    }
}
