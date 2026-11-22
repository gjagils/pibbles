import XCTest
@testable import PibblesCore

final class ProgressBookTests: XCTestCase {
    func testFirstSolveOfADayIsFinal() {
        var book = ProgressBook()
        XCTAssertTrue(book.add(kind: PuzzleKind.blocks, day: 10, milliseconds: 60000, hints: 1, today: 10))
        XCTAssertFalse(book.add(kind: PuzzleKind.blocks, day: 10, milliseconds: 30000, hints: 0, today: 10))
        XCTAssertEqual(book.record(kind: PuzzleKind.blocks, day: 10)?.score, 90000)
    }

    func testAnyPuzzleOfTheDayCountsOnceForTheStreak() {
        var book = ProgressBook()
        book.add(kind: PuzzleKind.blocks, day: 10, milliseconds: 1000, hints: 0, today: 10)
        book.add(kind: PuzzleKind.logic, day: 10, milliseconds: 1000, hints: 0, today: 10)
        book.add(kind: PuzzleKind.logic, day: 11, milliseconds: 1000, hints: 0, today: 11)
        XCTAssertEqual(book.streak.streak, 2)
        XCTAssertEqual(book.streakView(today: 12).streak, 2)
    }

    func testOlderDaysDoNotMoveTheStreak() {
        var book = ProgressBook()
        book.add(kind: PuzzleKind.blocks, day: 8, milliseconds: 1000, hints: 0, today: 10)
        XCTAssertEqual(book.streak.streak, 0)
        XCTAssertNotNil(book.record(kind: PuzzleKind.blocks, day: 8))
    }

    func testStatsPerKind() {
        var book = ProgressBook()
        book.add(kind: PuzzleKind.blocks, day: 1, milliseconds: 40000, hints: 1, today: 1)
        book.add(kind: PuzzleKind.blocks, day: 2, milliseconds: 80000, hints: 0, today: 2)
        let stats = book.stats(kind: PuzzleKind.blocks)
        XCTAssertEqual(stats.solved, 2)
        XCTAssertEqual(stats.bestScore, 70000)
        XCTAssertEqual(stats.averageMilliseconds, 60000)
        XCTAssertEqual(book.stats(kind: PuzzleKind.numbers).solved, 0)
        XCTAssertNil(book.stats(kind: PuzzleKind.numbers).bestScore)
    }

    func testJsonRoundTrip() {
        var book = ProgressBook()
        book.add(kind: PuzzleKind.patterns, day: 5, milliseconds: 12345, hints: 2, today: 5)
        let copy = ProgressBook.decode(book.encoded())
        XCTAssertEqual(copy, book)
        XCTAssertEqual(ProgressBook.decode("nonsense"), ProgressBook())
    }

    func testClockText() {
        XCTAssertEqual(TimeText.clock(milliseconds: 65000), "1:05")
        XCTAssertEqual(TimeText.clock(milliseconds: 750000), "12:30")
        XCTAssertEqual(TimeText.clock(milliseconds: -5), "0:00")
    }
}
