import XCTest
@testable import PibblesCore

final class StreakTests: XCTestCase {
    private func solve(_ days: [Int], from start: StreakState = StreakState()) -> StreakState {
        var state = start
        for day in days { state = StreakRules.afterSolve(state, day: day) }
        return state
    }

    func testFirstSolveStartsTheStreak() {
        let state = solve([100])
        XCTAssertEqual(state, StreakState(streak: 1, jokers: 0, lastDay: 100, best: 1))
    }

    func testFiveDaysInARowEarnAJoker() {
        // Same run as prototype/t.js.
        let state = solve([1, 2, 3, 4, 5])
        XCTAssertEqual(state, StreakState(streak: 5, jokers: 1, lastDay: 5, best: 5))
    }

    func testSolvingTheSameDayTwiceChangesNothing() {
        let state = solve([1, 2])
        XCTAssertEqual(StreakRules.afterSolve(state, day: 2), state)
    }

    func testAMissedDayCostsAJoker() {
        let state = solve([1, 2, 3, 4, 5])
        let view = StreakRules.now(state, day: 7)
        XCTAssertEqual(view, StreakView(streak: 5, jokers: 0, used: 1, lost: false))
        XCTAssertEqual(StreakRules.afterSolve(state, day: 7),
                       StreakState(streak: 6, jokers: 0, lastDay: 7, best: 6))
    }

    func testWithoutEnoughJokersTheStreakRestarts() {
        let state = solve([1, 2, 3, 4, 5, 7])
        let view = StreakRules.now(state, day: 10)
        XCTAssertEqual(view, StreakView(streak: 0, jokers: 0, used: 0, lost: true))
        XCTAssertEqual(StreakRules.afterSolve(state, day: 10),
                       StreakState(streak: 1, jokers: 0, lastDay: 10, best: 6))
    }

    func testJokersStayWhenTheStreakRestarts() {
        // One joker, two days missed: the streak restarts, the joker is kept.
        let state = solve([1, 2, 3, 4, 5])
        XCTAssertEqual(StreakRules.now(state, day: 8), StreakView(streak: 0, jokers: 1, used: 0, lost: true))
        XCTAssertEqual(StreakRules.afterSolve(state, day: 8),
                       StreakState(streak: 1, jokers: 1, lastDay: 8, best: 5))
    }

    func testAtMostThreeJokers() {
        var days = [Int]()
        for day in 1...25 { days.append(day) }
        let state = solve(days)
        XCTAssertEqual(state.streak, 25)
        XCTAssertEqual(state.jokers, 3)
        XCTAssertEqual(state.best, 25)
    }

    func testTodayAndYesterdayKeepTheStreak() {
        let state = solve([1, 2, 3])
        XCTAssertEqual(StreakRules.now(state, day: 3), StreakView(streak: 3, jokers: 0, used: 0, lost: false))
        XCTAssertEqual(StreakRules.now(state, day: 4), StreakView(streak: 3, jokers: 0, used: 0, lost: false))
    }

    func testNothingSolvedYet() {
        XCTAssertEqual(StreakRules.now(StreakState(), day: 50), StreakView(streak: 0, jokers: 0, used: 0, lost: false))
    }
}
