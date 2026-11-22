import Foundation

/// Generates the daily Logic puzzle.
///
/// 1. A random full valid grid (`LogicSolver.randomFullGrid`: propagation plus
///    backtracking with a random value first at each branch).
/// 2. All cells in a random order (Fisher-Yates with `SeededRandom`); each cell is
///    emptied when the solver still proves exactly one solution, else it stays a given.
///
/// Easier days: on Monday the last `size` cells of that order (6) and on Tuesday the last
/// `size / 2` (3) are never tried, so they stay as extra givens on top of a minimal set.
/// From Wednesday on the givens are minimal: no given can be removed without losing
/// uniqueness.
///
/// The same weekday and seed always give the same puzzle, in Swift and in Kotlin. Callers
/// pass `PuzzleKind.logic.seed(dateKey:)` as seed.
public enum LogicGenerator {
    /// Grid size per weekday, Monday … Sunday.
    public static let sizes: [Int] = [6, 6, 8, 8, 8, 10, 10]
    static let fullGridBudget = 200000

    public static func generate(weekday: Int, seed: String) -> LogicPuzzle {
        let day = ((weekday % 7) + 7) % 7
        let size = sizes[day]
        var keep = 0
        if day == 0 { keep = size }
        if day == 1 { keep = size / 2 }
        return build(size: size, seed: seed, keep: keep)
    }

    /// The same puzzle as `generate` for this size and seed, without extra givens.
    static func minimalGivens(size: Int, seed: String) -> LogicPuzzle {
        return build(size: size, seed: seed, keep: 0)
    }

    static func build(size: Int, seed: String, keep: Int) -> LogicPuzzle {
        let random = SeededRandom(seed: StringHash.fnv1a("logic|\(size)|\(seed)"))
        let count = size * size
        var solution = fallbackGrid(size: size)
        if let grid = LogicSolver.randomFullGrid(size: size, random: random, budget: fullGridBudget) {
            solution = grid
        }

        var order = [Int]()
        for index in 0..<count { order.append(index) }
        var last = count - 1
        while last > 0 {
            let other = random.nextInt(last + 1)
            let swap = order[last]
            order[last] = order[other]
            order[other] = swap
            last -= 1
        }

        var givens = solution
        let tries = max(0, count - keep)
        for step in 0..<tries {
            let index = order[step]
            givens[index] = -1
            if LogicSolver.countSolutions(size: size, givens: givens, limit: 2) != 1 {
                givens[index] = solution[index]
            }
        }
        return LogicPuzzle(size: size, givens: givens, solution: solution)
    }

    /// A valid grid (a checkerboard) for the unseen case that the random search runs out.
    static func fallbackGrid(size: Int) -> [Int] {
        var grid = [Int]()
        for row in 0..<size {
            for col in 0..<size {
                grid.append((row + col) % 2)
            }
        }
        return grid
    }
}
