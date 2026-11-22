import Foundation

/// A Logic puzzle (binary puzzle): fill every cell of a `size` × `size` grid with 0 or 1
/// so that every row and column holds as many 0s as 1s and no three equal values sit next
/// to each other, horizontally or vertically. Cells row by row (index = row × size + col).
public struct LogicPuzzle: Hashable, Codable, Sendable {
    public let size: Int
    /// -1 for an empty cell, 0 or 1 for a given.
    public let givens: [Int]
    /// The one solution, 0 or 1 per cell.
    public let solution: [Int]

    public init(size: Int, givens: [Int], solution: [Int]) {
        self.size = size
        self.givens = givens
        self.solution = solution
    }
}

/// The rules as the play screen needs them.
public enum LogicRules {
    /// True when every cell is filled, the givens are kept and no rule is broken.
    /// `values` uses -1 for empty, 0 and 1.
    public static func isSolved(_ puzzle: LogicPuzzle, values: [Int]) -> Bool {
        let size = puzzle.size
        if size < 2 || values.count != size * size || puzzle.givens.count != values.count { return false }
        for index in 0..<values.count {
            let value = values[index]
            if value != 0 && value != 1 { return false }
            let given = puzzle.givens[index]
            if given != -1 && given != value { return false }
        }
        // Full and never more than half of one value in a line: every line is balanced.
        return conflicts(puzzle, values: values).isEmpty
    }

    /// Indices (ascending) of cells that are part of a visible rule break: three equal
    /// values in a row or column, or a row or column holding more than half of one value
    /// (the cells with that value). Empty cells are never part of a conflict.
    public static func conflicts(_ puzzle: LogicPuzzle, values: [Int]) -> [Int] {
        let size = puzzle.size
        let count = size * size
        if size < 2 || values.count != count { return [Int]() }
        let half = size / 2
        var marked = Array(repeating: false, count: count)
        var line = 0
        while line < size * 2 {
            let isRow = line < size
            let fixed = isRow ? line : line - size
            var zeros = 0
            var ones = 0
            for position in 0..<size {
                let value = values[LogicSolver.cellIndex(size: size, isRow: isRow, line: fixed, position: position)]
                if value == 0 { zeros += 1 }
                if value == 1 { ones += 1 }
            }
            for position in 0..<size {
                let index = LogicSolver.cellIndex(size: size, isRow: isRow, line: fixed, position: position)
                let value = values[index]
                if (value == 0 && zeros > half) || (value == 1 && ones > half) { marked[index] = true }
            }
            var position = 0
            while position + 2 < size {
                let a = LogicSolver.cellIndex(size: size, isRow: isRow, line: fixed, position: position)
                let b = LogicSolver.cellIndex(size: size, isRow: isRow, line: fixed, position: position + 1)
                let c = LogicSolver.cellIndex(size: size, isRow: isRow, line: fixed, position: position + 2)
                if values[a] != -1 && values[a] == values[b] && values[b] == values[c] {
                    marked[a] = true
                    marked[b] = true
                    marked[c] = true
                }
                position += 1
            }
            line += 1
        }
        var result = [Int]()
        for index in 0..<count {
            if marked[index] { result.append(index) }
        }
        return result
    }
}
