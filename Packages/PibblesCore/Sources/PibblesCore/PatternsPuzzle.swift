import Foundation

/// A Patterns puzzle (picture logic): colour cells so that every row and column shows the
/// run lengths in its clue, in order. Square grid, cells row by row (index = row × size + col).
/// JSON: `{"size":5,"rowClues":[[2,1],[5],[],...],"colClues":[...],"solution":[0,1,...]}`.
public struct PatternsPuzzle: Hashable, Codable, Sendable {
    public let size: Int
    /// Per row the lengths of the filled runs, left to right; `[]` for an empty row.
    public let rowClues: [[Int]]
    /// Per column the lengths of the filled runs, top to bottom; `[]` for an empty column.
    public let colClues: [[Int]]
    /// 1 = filled, 0 = empty; `size * size` cells, row by row.
    public let solution: [Int]

    public init(size: Int, rowClues: [[Int]], colClues: [[Int]], solution: [Int]) {
        self.size = size
        self.rowClues = rowClues
        self.colClues = colClues
        self.solution = solution
    }
}

/// The rules while playing. The play screen asks here; it has no rules of its own.
/// Player cells: 0 empty, 1 filled, 2 marked as empty by the player (counts as empty).
public enum PatternsRules {
    /// The lengths of the runs of 1s in a line, in order. Any other value counts as empty.
    public static func clues(of line: [Int]) -> [Int] {
        var result = [Int]()
        var run = 0
        for value in line {
            if value == 1 {
                run += 1
            } else if run > 0 {
                result.append(run)
                run = 0
            }
        }
        if run > 0 { result.append(run) }
        return result
    }

    /// Every row and every column matches its clue. With a unique puzzle that means the
    /// cells equal the solution (apart from 2 versus 0).
    public static func isSolved(_ puzzle: PatternsPuzzle, cells: [Int]) -> Bool {
        if cells.count != puzzle.size * puzzle.size { return false }
        var index = 0
        while index < puzzle.size {
            if !rowMatches(puzzle, cells: cells, row: index) { return false }
            if !colMatches(puzzle, cells: cells, col: index) { return false }
            index += 1
        }
        return true
    }

    /// The row shows exactly its clue (for greying out a finished clue).
    public static func rowMatches(_ puzzle: PatternsPuzzle, cells: [Int], row: Int) -> Bool {
        let size = puzzle.size
        if row < 0 || row >= size || row >= puzzle.rowClues.count || cells.count != size * size { return false }
        var line = [Int]()
        var col = 0
        while col < size {
            line.append(cells[row * size + col])
            col += 1
        }
        return clues(of: line) == puzzle.rowClues[row]
    }

    /// The column shows exactly its clue (for greying out a finished clue).
    public static func colMatches(_ puzzle: PatternsPuzzle, cells: [Int], col: Int) -> Bool {
        let size = puzzle.size
        if col < 0 || col >= size || col >= puzzle.colClues.count || cells.count != size * size { return false }
        var line = [Int]()
        var row = 0
        while row < size {
            line.append(cells[row * size + col])
            row += 1
        }
        return clues(of: line) == puzzle.colClues[col]
    }

    /// The puzzle whose clues are those of a filled grid (1 filled, anything else empty).
    static func puzzle(size: Int, solution: [Int]) -> PatternsPuzzle {
        var rowClues = [[Int]]()
        var colClues = [[Int]]()
        var index = 0
        while index < size {
            var rowLine = [Int]()
            var colLine = [Int]()
            var other = 0
            while other < size {
                rowLine.append(solution[index * size + other])
                colLine.append(solution[other * size + index])
                other += 1
            }
            rowClues.append(clues(of: rowLine))
            colClues.append(clues(of: colLine))
            index += 1
        }
        return PatternsPuzzle(size: size, rowClues: rowClues, colClues: colClues, solution: solution)
    }
}
