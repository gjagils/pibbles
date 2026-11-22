import XCTest
@testable import PibblesCore

final class WeekScheduleTests: XCTestCase {
    func testWeekRunsFromEasyMondayToHardSunday() {
        let sizes = WeekSchedule.levels.map { level in level.size }
        let pieces = WeekSchedule.levels.map { level in level.pieceCount }
        XCTAssertEqual(sizes, [5, 5, 6, 6, 6, 7, 7])
        XCTAssertEqual(pieces, [4, 5, 5, 6, 7, 7, 8])
    }

    func testLevelOfAWeekday() {
        XCTAssertEqual(WeekSchedule.level(weekday: 0), Level(size: 5, pieceCount: 4))
        XCTAssertEqual(WeekSchedule.level(weekday: 6), Level(size: 7, pieceCount: 8))
    }

    func testWeekdayOutsideTheWeekWraps() {
        XCTAssertEqual(WeekSchedule.level(weekday: 7), WeekSchedule.level(weekday: 0))
        XCTAssertEqual(WeekSchedule.level(weekday: -1), WeekSchedule.level(weekday: 6))
    }
}
