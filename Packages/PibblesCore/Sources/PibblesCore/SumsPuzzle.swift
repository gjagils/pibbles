import Foundation

/// Sums: fill a `size` × `size` grid with 1…size so every row and column holds each number
/// once; the grid is split into connected cages and the numbers in a cage add up to the
/// cage's sum. No givens; exactly one solution.
/// JSON: `{"size":5,"cages":[0,0,1,...],"sums":[11,4,...],"solution":[...]}`.
public struct SumsPuzzle: Hashable, Codable, Sendable {
    public let size: Int
    /// Cage id per cell, row by row: ids 0..k-1, numbered in order of each cage's first cell.
    public let cages: [Int]
    /// `sums[id]`: the sum of cage `id`.
    public let sums: [Int]
    /// Row by row, values 1…size.
    public let solution: [Int]

    public init(size: Int, cages: [Int], sums: [Int], solution: [Int]) {
        self.size = size
        self.cages = cages
        self.sums = sums
        self.solution = solution
    }
}

/// The rules the play screen asks: is the grid solved, which filled cells clash, and where
/// each cage's sum is written.
public enum SumsRules {
    /// Every cell filled with 1…size, each number once per row and column, and every cage
    /// adds up to its sum. Does not look at `puzzle.solution`. `values` row by row, 0 = empty.
    public static func isSolved(_ puzzle: SumsPuzzle, values: [Int]) -> Bool {
        let n = puzzle.size
        if !wellFormed(puzzle) || values.count != n * n { return false }
        for value in values {
            if value < 1 || value > n { return false }
        }
        return conflicts(puzzle, values: values).isEmpty
    }

    /// Indices (ascending) of filled cells that clash: the same number twice in a row or
    /// column; every filled cell of a cage whose filled values add up to more than its sum;
    /// every cell of a full cage with the wrong sum. Empty cells (0) never clash.
    public static func conflicts(_ puzzle: SumsPuzzle, values: [Int]) -> [Int] {
        let n = puzzle.size
        if !wellFormed(puzzle) || values.count != n * n { return [Int]() }
        var bad = Array(repeating: false, count: n * n)
        var line = 0
        while line < n {
            var a = 0
            while a < n {
                var b = a + 1
                while b < n {
                    // Same row: (line, a) and (line, b).
                    let first = line * n + a
                    let second = line * n + b
                    if values[first] != 0 && values[first] == values[second] {
                        bad[first] = true
                        bad[second] = true
                    }
                    // Same column: (a, line) and (b, line).
                    let top = a * n + line
                    let bottom = b * n + line
                    if values[top] != 0 && values[top] == values[bottom] {
                        bad[top] = true
                        bad[bottom] = true
                    }
                    b += 1
                }
                a += 1
            }
            line += 1
        }
        let cageCount = puzzle.sums.count
        var filledTotal = Array(repeating: 0, count: cageCount)
        var empties = Array(repeating: 0, count: cageCount)
        var cell = 0
        while cell < n * n {
            let id = puzzle.cages[cell]
            if values[cell] == 0 {
                empties[id] += 1
            } else {
                filledTotal[id] += values[cell]
            }
            cell += 1
        }
        cell = 0
        while cell < n * n {
            let id = puzzle.cages[cell]
            let over = filledTotal[id] > puzzle.sums[id]
            let wrongFull = empties[id] == 0 && filledTotal[id] != puzzle.sums[id]
            if values[cell] != 0 && (over || wrongFull) { bad[cell] = true }
            cell += 1
        }
        var result = [Int]()
        var index = 0
        while index < n * n {
            if bad[index] { result.append(index) }
            index += 1
        }
        return result
    }

    /// Per cage id the cell where the sum is written: the cage's first cell row by row
    /// (-1 for an id without cells).
    public static func cageLabelCells(_ puzzle: SumsPuzzle) -> [Int] {
        var labels = Array(repeating: -1, count: puzzle.sums.count)
        var cell = 0
        while cell < puzzle.cages.count {
            let id = puzzle.cages[cell]
            if id >= 0 && id < labels.count && labels[id] < 0 { labels[id] = cell }
            cell += 1
        }
        return labels
    }

    /// Positive size, one cage id per cell, every id within `sums`.
    private static func wellFormed(_ puzzle: SumsPuzzle) -> Bool {
        let n = puzzle.size
        if n <= 0 || puzzle.cages.count != n * n { return false }
        for id in puzzle.cages {
            if id < 0 || id >= puzzle.sums.count { return false }
        }
        return true
    }
}
