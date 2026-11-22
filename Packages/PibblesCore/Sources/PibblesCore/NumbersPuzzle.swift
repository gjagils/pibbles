import Foundation

/// A sign between two orthogonal neighbours: value(cell `lo`) < value(cell `hi`).
/// Cells are numbered row by row: index = row × size + col.
public struct NumbersRelation: Hashable, Codable, Sendable {
    public let lo: Int
    public let hi: Int

    public init(lo: Int, hi: Int) {
        self.lo = lo
        self.hi = hi
    }
}

/// Numbers: fill a `size` × `size` grid with 1…size so every row and column holds each
/// number once, keep the `givens` and obey every sign in `relations`. Exactly one solution.
/// JSON: `{"size":4,"givens":[0,2,0,...],"relations":[{"lo":3,"hi":4}],"solution":[...]}`.
public struct NumbersPuzzle: Hashable, Codable, Sendable {
    public let size: Int
    /// Row by row; 0 = empty.
    public let givens: [Int]
    /// Sorted by the smaller cell index of the pair, then by the larger one.
    public let relations: [NumbersRelation]
    /// Row by row, values 1…size.
    public let solution: [Int]

    public init(size: Int, givens: [Int], relations: [NumbersRelation], solution: [Int]) {
        self.size = size
        self.givens = givens
        self.relations = relations
        self.solution = solution
    }
}

/// The rules the play screen asks: is the grid solved, and which filled cells clash.
public enum NumbersRules {
    /// Every cell filled with 1…size, givens kept, each number once per row and column,
    /// and every sign obeyed. `values` row by row, 0 = empty.
    public static func isSolved(_ puzzle: NumbersPuzzle, values: [Int]) -> Bool {
        let n = puzzle.size
        if n <= 0 || values.count != n * n || puzzle.givens.count != n * n { return false }
        var i = 0
        while i < n * n {
            let value = values[i]
            if value < 1 || value > n { return false }
            if puzzle.givens[i] != 0 && puzzle.givens[i] != value { return false }
            i += 1
        }
        return conflicts(puzzle, values: values).isEmpty
    }

    /// Indices (ascending) of filled cells that clash: the same number twice in a row or
    /// column, or a broken sign between two filled cells. Empty cells (0) never clash.
    public static func conflicts(_ puzzle: NumbersPuzzle, values: [Int]) -> [Int] {
        let n = puzzle.size
        if n <= 0 || values.count != n * n { return [Int]() }
        var bad = Array(repeating: false, count: n * n)
        var row = 0
        while row < n {
            var a = 0
            while a < n {
                var b = a + 1
                while b < n {
                    // Same row: (row, a) and (row, b).
                    let first = row * n + a
                    let second = row * n + b
                    if values[first] != 0 && values[first] == values[second] {
                        bad[first] = true
                        bad[second] = true
                    }
                    // Same column: (a, row) and (b, row).
                    let top = a * n + row
                    let bottom = b * n + row
                    if values[top] != 0 && values[top] == values[bottom] {
                        bad[top] = true
                        bad[bottom] = true
                    }
                    b += 1
                }
                a += 1
            }
            row += 1
        }
        for relation in puzzle.relations {
            if relation.lo < 0 || relation.lo >= n * n || relation.hi < 0 || relation.hi >= n * n { continue }
            let low = values[relation.lo]
            let high = values[relation.hi]
            if low != 0 && high != 0 && low >= high {
                bad[relation.lo] = true
                bad[relation.hi] = true
            }
        }
        var result = [Int]()
        var index = 0
        while index < n * n {
            if bad[index] { result.append(index) }
            index += 1
        }
        return result
    }
}
