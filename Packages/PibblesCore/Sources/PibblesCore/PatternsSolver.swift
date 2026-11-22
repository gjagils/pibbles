import Foundation

/// Solves Patterns puzzles. Grid cells: -1 unknown, 0 empty, 1 filled.
///
/// Line solving: for one row or column, all placements of its runs that agree with the
/// known cells are considered at once (dynamic programming, no enumeration); a cell that is
/// filled in all of them, or empty in all of them, becomes known. Rows and columns are
/// repeated until nothing changes. When cells are still unknown, the solver guesses the
/// first unknown cell (filled first, then empty) and recurses.
public enum PatternsSolver {
    /// The number of solutions, counting at most up to `limit`. Clues with a run length of 0
    /// or less, or with the wrong number of lines, have no solution.
    public static func countSolutions(size: Int, rowClues: [[Int]], colClues: [[Int]], limit: Int) -> Int {
        if size <= 0 || limit <= 0 || rowClues.count != size || colClues.count != size { return 0 }
        let search = PatternsSearch(size: size, rowClues: rowClues, colClues: colClues, limit: limit)
        search.solve(Array(repeating: -1, count: size * size))
        return search.count
    }

    /// Line solving alone, without guessing: true when it fills in the whole grid. That
    /// proves the solution is unique, and that a player can find it step by step.
    static func isLineSolvable(size: Int, rowClues: [[Int]], colClues: [[Int]]) -> Bool {
        if size <= 0 || rowClues.count != size || colClues.count != size { return false }
        guard let grid = propagate(size: size, rowClues: rowClues, colClues: colClues,
                                   grid: Array(repeating: -1, count: size * size)) else {
            return false
        }
        for value in grid {
            if value < 0 { return false }
        }
        return true
    }

    /// Repeats line solving over all rows and columns until nothing changes. Nil when a
    /// line has no placement left (contradiction).
    static func propagate(size: Int, rowClues: [[Int]], colClues: [[Int]], grid start: [Int]) -> [Int]? {
        var grid = start
        var rowDirty = Array(repeating: true, count: size)
        var colDirty = Array(repeating: true, count: size)
        var changed = true
        while changed {
            changed = false
            var row = 0
            while row < size {
                if rowDirty[row] {
                    rowDirty[row] = false
                    var line = [Int]()
                    var col = 0
                    while col < size {
                        line.append(grid[row * size + col])
                        col += 1
                    }
                    guard let solved = solveLine(line, clue: rowClues[row]) else { return nil }
                    col = 0
                    while col < size {
                        if solved[col] != line[col] {
                            grid[row * size + col] = solved[col]
                            colDirty[col] = true
                            changed = true
                        }
                        col += 1
                    }
                }
                row += 1
            }
            var col = 0
            while col < size {
                if colDirty[col] {
                    colDirty[col] = false
                    var line = [Int]()
                    var r = 0
                    while r < size {
                        line.append(grid[r * size + col])
                        r += 1
                    }
                    guard let solved = solveLine(line, clue: colClues[col]) else { return nil }
                    r = 0
                    while r < size {
                        if solved[r] != line[r] {
                            grid[r * size + col] = solved[r]
                            rowDirty[r] = true
                            changed = true
                        }
                        r += 1
                    }
                }
                col += 1
            }
        }
        return grid
    }

    /// One line: the cells that are equal in every placement of the runs consistent with
    /// the known cells become known. Nil when no placement fits.
    ///
    /// `solvable[i][j]`: cells `i..<n` can hold runs `j..<k`, given that cell `i` may start
    /// a run (the cell before it, if any, is empty). Then a forward pass over the reachable
    /// states marks which cells can be filled and which can be empty.
    static func solveLine(_ line: [Int], clue: [Int]) -> [Int]? {
        let n = line.count
        let k = clue.count
        for length in clue {
            if length <= 0 { return nil }
        }
        var emptyBefore = Array(repeating: 0, count: n + 1)
        var i = 0
        while i < n {
            emptyBefore[i + 1] = emptyBefore[i] + (line[i] == 0 ? 1 : 0)
            i += 1
        }
        let width = k + 1
        var solvable = Array(repeating: false, count: (n + 2) * width)
        solvable[n * width + k] = true
        solvable[(n + 1) * width + k] = true
        i = n - 1
        while i >= 0 {
            var j = k
            while j >= 0 {
                var ok = false
                if line[i] != 1 && solvable[(i + 1) * width + j] { ok = true }
                if !ok && j < k && runFits(line, emptyBefore, i, clue[j])
                    && solvable[(i + clue[j] + 1) * width + j + 1] {
                    ok = true
                }
                solvable[i * width + j] = ok
                j -= 1
            }
            i -= 1
        }
        if !solvable[0] { return nil }

        var reach = Array(repeating: false, count: (n + 2) * width)
        reach[0] = true
        var canEmpty = Array(repeating: false, count: n)
        var canFill = Array(repeating: false, count: n)
        i = 0
        while i < n {
            var j = 0
            while j <= k {
                if reach[i * width + j] {
                    if line[i] != 1 && solvable[(i + 1) * width + j] {
                        canEmpty[i] = true
                        reach[(i + 1) * width + j] = true
                    }
                    if j < k {
                        let length = clue[j]
                        if runFits(line, emptyBefore, i, length) && solvable[(i + length + 1) * width + j + 1] {
                            var c = i
                            while c < i + length {
                                canFill[c] = true
                                c += 1
                            }
                            if i + length < n { canEmpty[i + length] = true }
                            reach[(i + length + 1) * width + j + 1] = true
                        }
                    }
                }
                j += 1
            }
            i += 1
        }

        var result = line
        i = 0
        while i < n {
            if canFill[i] && !canEmpty[i] {
                result[i] = 1
            } else if canEmpty[i] && !canFill[i] {
                result[i] = 0
            } else if !canEmpty[i] && !canFill[i] {
                return nil
            }
            i += 1
        }
        return result
    }

    /// A run of `length` can start at `start`: it fits, covers no known empty cell, and the
    /// cell right after it is not known to be filled.
    private static func runFits(_ line: [Int], _ emptyBefore: [Int], _ start: Int, _ length: Int) -> Bool {
        let end = start + length
        if end > line.count { return false }
        if emptyBefore[end] - emptyBefore[start] != 0 { return false }
        if end < line.count && line[end] == 1 { return false }
        return true
    }
}

/// Line solving plus guessing, counting solutions up to a limit.
private final class PatternsSearch {
    let size: Int
    let rowClues: [[Int]]
    let colClues: [[Int]]
    let limit: Int
    var count = 0

    init(size: Int, rowClues: [[Int]], colClues: [[Int]], limit: Int) {
        self.size = size
        self.rowClues = rowClues
        self.colClues = colClues
        self.limit = limit
    }

    func solve(_ start: [Int]) {
        if count >= limit { return }
        guard let grid = PatternsSolver.propagate(size: size, rowClues: rowClues, colClues: colClues,
                                                  grid: start) else {
            return
        }
        var unknown = -1
        var index = 0
        while index < grid.count && unknown < 0 {
            if grid[index] < 0 { unknown = index }
            index += 1
        }
        if unknown < 0 {
            count += 1
            return
        }
        var filled = grid
        filled[unknown] = 1
        solve(filled)
        if count >= limit { return }
        var empty = grid
        empty[unknown] = 0
        solve(empty)
    }
}
