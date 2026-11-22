import Foundation

/// Counts the solutions of a Logic puzzle: propagation (no three equal, half per line)
/// plus backtracking on the first empty cell.
public enum LogicSolver {
    /// How many solutions `givens` (-1 empty, 0, 1) has, counting no further than `limit`.
    /// 0 for a malformed grid (odd size, wrong length).
    public static func countSolutions(size: Int, givens: [Int], limit: Int) -> Int {
        if size < 2 || size % 2 != 0 || givens.count != size * size || limit < 1 { return 0 }
        for value in givens {
            if value < -1 || value > 1 { return 0 }
        }
        return search(givens, size: size, limit: limit)
    }

    static func search(_ grid: [Int], size: Int, limit: Int) -> Int {
        guard let filled = propagate(grid, size: size) else { return 0 }
        var empty = -1
        var index = 0
        while index < filled.count && empty < 0 {
            if filled[index] == -1 { empty = index }
            index += 1
        }
        if empty < 0 { return 1 }
        var found = 0
        for value in 0..<2 {
            var next = filled
            next[empty] = value
            found += search(next, size: size, limit: limit - found)
            if found >= limit { return found }
        }
        return found
    }

    /// A random full valid grid: the same search, with a random value first at every
    /// branch. Nil when the node budget runs out (never seen for sizes up to 10).
    static func randomFullGrid(size: Int, random: SeededRandom, budget: Int) -> [Int]? {
        let counter = NodeCounter()
        return randomSearch(Array(repeating: -1, count: size * size), size: size, random: random,
                            counter: counter, budget: budget)
    }

    static func randomSearch(_ grid: [Int], size: Int, random: SeededRandom, counter: NodeCounter,
                             budget: Int) -> [Int]? {
        counter.nodes += 1
        if counter.nodes > budget { return nil }
        guard let filled = propagate(grid, size: size) else { return nil }
        var empty = -1
        var index = 0
        while index < filled.count && empty < 0 {
            if filled[index] == -1 { empty = index }
            index += 1
        }
        if empty < 0 { return filled }
        let first = random.nextInt(2)
        for step in 0..<2 {
            var next = filled
            next[empty] = step == 0 ? first : 1 - first
            if let result = randomSearch(next, size: size, random: random, counter: counter, budget: budget) {
                return result
            }
            if counter.nodes > budget { return nil }
        }
        return nil
    }

    /// Index of `position` in row (or column) `line`.
    static func cellIndex(size: Int, isRow: Bool, line: Int, position: Int) -> Int {
        return isRow ? line * size + position : position * size + line
    }

    /// Fills every forced cell. Nil on a contradiction. When the result has no empty
    /// cell it is a valid solution: the last pass checked every line.
    static func propagate(_ start: [Int], size: Int) -> [Int]? {
        var grid = start
        let half = size / 2
        var changed = true
        while changed {
            changed = false
            var line = 0
            while line < size * 2 {
                let isRow = line < size
                let fixed = isRow ? line : line - size
                // Pairs and gaps: x x _ , _ x x and x _ x force the other value.
                var position = 0
                while position + 2 < size {
                    let a = cellIndex(size: size, isRow: isRow, line: fixed, position: position)
                    let b = cellIndex(size: size, isRow: isRow, line: fixed, position: position + 1)
                    let c = cellIndex(size: size, isRow: isRow, line: fixed, position: position + 2)
                    let va = grid[a]
                    let vb = grid[b]
                    let vc = grid[c]
                    if va != -1 && va == vb && vb == vc { return nil }
                    if va != -1 && va == vb && vc == -1 {
                        grid[c] = 1 - va
                        changed = true
                    } else if vb != -1 && vb == vc && va == -1 {
                        grid[a] = 1 - vb
                        changed = true
                    } else if va != -1 && va == vc && vb == -1 {
                        grid[b] = 1 - va
                        changed = true
                    }
                    position += 1
                }
                // Counts: more than half is a contradiction; a full half fills the rest.
                var zeros = 0
                var ones = 0
                for spot in 0..<size {
                    let value = grid[cellIndex(size: size, isRow: isRow, line: fixed, position: spot)]
                    if value == 0 { zeros += 1 }
                    if value == 1 { ones += 1 }
                }
                if zeros > half || ones > half { return nil }
                if zeros + ones < size && (zeros == half || ones == half) {
                    let fill = zeros == half ? 1 : 0
                    for spot in 0..<size {
                        let index = cellIndex(size: size, isRow: isRow, line: fixed, position: spot)
                        if grid[index] == -1 { grid[index] = fill }
                    }
                    changed = true
                }
                line += 1
            }
        }
        return grid
    }
}

final class NodeCounter {
    var nodes = 0
}
