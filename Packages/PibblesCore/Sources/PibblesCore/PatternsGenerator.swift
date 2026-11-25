import Foundation

/// Makes the daily Patterns puzzle.
///
/// Choices:
/// - A random grid with a fill density of 0.58: dense enough for long runs and a unique
///   solution, sparse enough to keep it a picture rather than a block.
/// - Half of the puzzles are mirrored left to right, so they look more like a pattern than
///   like noise (one draw of `random.next()` decides, before the cells are drawn).
/// - At most one empty line and at most two completely filled lines (rows and columns
///   together): those are free and make a puzzle dull.
/// - A grid is only accepted when line solving alone fills it in completely. That proves the
///   solution is unique (`PatternsSolver.countSolutions` gives 1) and means a player never
///   has to guess.
/// - After `maxAttempts` grids (never reached in practice) a fully filled grid is returned:
///   valid, unique and deterministic, so `generate` always ends with a puzzle.
public enum PatternsGenerator {
    /// Grid size per weekday, Monday 0 … Sunday 6.
    public static let sizes: [Int] = [5, 5, 6, 6, 6, 6, 6]
    static let density = 0.58
    static let mirrorChance = 0.5
    static let maxEmptyLines = 1
    static let maxFullLines = 2
    static let maxAttempts = 2000

    /// The puzzle of a weekday (Monday 0 … Sunday 6; other values are clamped) and seed
    /// (`PuzzleKind.patterns.seed(dateKey:)`). The same weekday and seed always give the
    /// same puzzle, on iOS and on Android.
    public static func generate(weekday: Int, seed: String) -> PatternsPuzzle {
        let day = weekday < 0 ? 0 : (weekday > 6 ? 6 : weekday)
        let size = sizes[day]
        let random = SeededRandom(seed: StringHash.fnv1a("patterns|\(size)|\(seed)"))
        var attempt = 0
        while attempt < maxAttempts {
            attempt += 1
            let grid = randomGrid(size: size, random: random)
            let puzzle = PatternsRules.puzzle(size: size, solution: grid)
            if !hasFewDullLines(puzzle) { continue }
            if PatternsSolver.isLineSolvable(size: size, rowClues: puzzle.rowClues, colClues: puzzle.colClues) {
                return puzzle
            }
        }
        return PatternsRules.puzzle(size: size, solution: Array(repeating: 1, count: size * size))
    }

    /// Cells drawn row by row, left to right; a mirrored grid draws only the left half
    /// (with the middle column) of each row.
    static func randomGrid(size: Int, random: SeededRandom) -> [Int] {
        let mirrored = random.next() < mirrorChance
        let drawn = mirrored ? (size + 1) / 2 : size
        var grid = Array(repeating: 0, count: size * size)
        var row = 0
        while row < size {
            var col = 0
            while col < drawn {
                let value = random.next() < density ? 1 : 0
                grid[row * size + col] = value
                if mirrored { grid[row * size + size - 1 - col] = value }
                col += 1
            }
            row += 1
        }
        return grid
    }

    /// Not too many empty or completely filled rows and columns.
    static func hasFewDullLines(_ puzzle: PatternsPuzzle) -> Bool {
        var empty = 0
        var full = 0
        for clue in puzzle.rowClues + puzzle.colClues {
            if clue.isEmpty { empty += 1 }
            if clue.count == 1 && clue[0] == puzzle.size { full += 1 }
        }
        return empty <= maxEmptyLines && full <= maxFullLines
    }
}
