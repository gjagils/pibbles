import Foundation

/// What is stored about the streak. `lastDay` is the day number (days since a fixed
/// date) of the last solved daily puzzle.
public struct StreakState: Hashable, Sendable {
    public let streak: Int
    public let jokers: Int
    public let lastDay: Int?
    public let best: Int

    public init(streak: Int = 0, jokers: Int = 0, lastDay: Int? = nil, best: Int = 0) {
        self.streak = streak
        self.jokers = jokers
        self.lastDay = lastDay
        self.best = best
    }
}

/// The streak as it stands on a given day, before that day is solved.
public struct StreakView: Hashable, Sendable {
    public let streak: Int
    public let jokers: Int
    /// Jokers that the missed days since the last solve will cost.
    public let used: Int
    /// A running streak was lost because there were too few jokers.
    public let lost: Bool

    public init(streak: Int, jokers: Int, used: Int, lost: Bool) {
        self.streak = streak
        self.jokers = jokers
        self.used = used
        self.lost = lost
    }
}

/// Every solved day counts, also with hints. A missed day costs a joker; with too few
/// jokers the streak restarts and the jokers stay.
public enum StreakRules {
    /// Proposed values, not yet confirmed by the owner (HANDOFF.md).
    public static let jokerEvery = 5
    public static let jokerMax = 3

    public static func afterSolve(_ state: StreakState, day: Int) -> StreakState {
        var streak = state.streak
        var jokers = state.jokers
        if let lastDay = state.lastDay {
            if lastDay == day { return state }
            let gap = day - lastDay - 1
            if gap > 0 {
                if gap <= jokers {
                    jokers -= gap
                } else {
                    streak = 0
                }
            }
        } else {
            streak = 0
        }
        streak += 1
        if streak % jokerEvery == 0 && jokers < jokerMax { jokers += 1 }
        return StreakState(streak: streak, jokers: jokers, lastDay: day, best: max(state.best, streak))
    }

    public static func now(_ state: StreakState, day: Int) -> StreakView {
        guard let lastDay = state.lastDay else {
            return StreakView(streak: 0, jokers: state.jokers, used: 0, lost: false)
        }
        let gap = max(0, day - lastDay - 1)
        if gap == 0 {
            return StreakView(streak: state.streak, jokers: state.jokers, used: 0, lost: false)
        }
        if gap <= state.jokers {
            return StreakView(streak: state.streak, jokers: state.jokers - gap, used: gap, lost: false)
        }
        return StreakView(streak: 0, jokers: state.jokers, used: 0, lost: state.streak > 0)
    }
}
