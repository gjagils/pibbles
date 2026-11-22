import Foundation

/// The daily puzzle of each kind on a day: generated from the date, so every device
/// (and the server's week pack) has the same one, also offline.
public enum Daily {
    public static func blocks(day: Int) -> Puzzle? {
        let level = WeekSchedule.level(weekday: PuzzleCalendar.weekday(day: day))
        return PuzzleGenerator.generate(level: level, seed: PuzzleKind.blocks.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
    }

    public static func logic(day: Int) -> LogicPuzzle {
        return LogicGenerator.generate(weekday: PuzzleCalendar.weekday(day: day),
                                       seed: PuzzleKind.logic.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
    }

    public static func patterns(day: Int) -> PatternsPuzzle {
        return PatternsGenerator.generate(weekday: PuzzleCalendar.weekday(day: day),
                                          seed: PuzzleKind.patterns.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
    }

    public static func numbers(day: Int) -> NumbersPuzzle {
        return NumbersGenerator.generate(weekday: PuzzleCalendar.weekday(day: day),
                                         seed: PuzzleKind.numbers.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
    }

    /// "Easy", "Medium" or "Hard" for a weekday: Monday–Tuesday, Wednesday–Friday, weekend.
    public static func difficulty(weekday: Int) -> String {
        let index = ((weekday % 7) + 7) % 7
        if index <= 1 { return "Easy" }
        if index <= 4 { return "Medium" }
        return "Hard"
    }

    public static let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    public static let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]
}

/// Hints for the grid puzzles: the first cell (row by row) that is empty or wrong and is
/// not given. The screen then fills in the solution's value there.
public enum CellHint {
    /// `empty` is the value an open cell has (-1 for Logic, 0 for Numbers and Patterns).
    /// For Patterns, a cell marked empty (2) counts as right when the solution is empty.
    public static func next(values: [Int], solution: [Int], givens: [Int]?, empty: Int) -> Int? {
        var index = 0
        while index < solution.count && index < values.count {
            var isGiven = false
            if let givens {
                isGiven = index < givens.count && givens[index] != empty
            }
            if !isGiven {
                let value = values[index]
                let right = value == solution[index] || (value == 2 && solution[index] == 0 && empty == 0 && givens == nil)
                if !right { return index }
            }
            index += 1
        }
        return nil
    }
}
