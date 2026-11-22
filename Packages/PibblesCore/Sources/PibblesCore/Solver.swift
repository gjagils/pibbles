import Foundation

public struct SolveResult: Sendable {
    /// Number of solutions found, at most the limit that was asked for.
    public let count: Int
    /// Number of placements tried: a measure of the work, not of the difficulty.
    public let nodes: Int
    /// The search stopped on its budget, so `count` proves nothing.
    public let exhausted: Bool
    /// The first solution: per given shape the position (row × size + col) of the
    /// top left corner of its bounding box.
    public let first: [Int]?
}

public enum Solver {
    /// Counts the solutions of a puzzle, up to `limit`. Equal shapes are interchangeable:
    /// swapping two of them is not a second solution.
    public static func countSolutions(size: Int, shapeKeys: [String], rows: [Int], cols: [Int],
                                      limit: Int, budget: Int) -> SolveResult {
        let search = SolverSearch(size: size, shapeKeys: shapeKeys, rows: rows, cols: cols,
                                  limit: limit, budget: budget)
        search.run(0)
        return SolveResult(count: search.count, nodes: search.nodes,
                           exhausted: search.nodes > budget, first: search.first)
    }
}

/// A shape with its place in the list the caller gave.
private struct OrderedShape {
    let shape: PieceShape
    let index: Int
}

private final class SolverSearch {
    let size: Int
    let limit: Int
    let budget: Int
    let order: [OrderedShape]
    var grid: [Bool]
    var rowsLeft: [Int]
    var colsLeft: [Int]
    var positions: [Int]
    var count = 0
    var nodes = 0
    var first: [Int]? = nil

    init(size: Int, shapeKeys: [String], rows: [Int], cols: [Int], limit: Int, budget: Int) {
        self.size = size
        self.limit = limit
        self.budget = budget
        var list = [OrderedShape]()
        var index = 0
        for key in shapeKeys {
            // An unknown key has no squares and never fits a puzzle with numbers.
            let shape = ShapeCatalog.shape(key) ?? PieceShape(key: key, cells: [Cell]())
            list.append(OrderedShape(shape: shape, index: index))
            index += 1
        }
        // Largest shapes first, equal shapes next to each other; the index keeps the
        // order stable (JavaScript's sort is stable, Swift's need not be).
        self.order = list.sorted { a, b in
            if a.shape.cells.count != b.shape.cells.count { return a.shape.cells.count > b.shape.cells.count }
            if a.shape.key != b.shape.key { return a.shape.key < b.shape.key }
            return a.index < b.index
        }
        self.grid = Array(repeating: false, count: size * size)
        self.rowsLeft = rows
        self.colsLeft = cols
        self.positions = Array(repeating: 0, count: shapeKeys.count)
    }

    private var stopped: Bool {
        return count >= limit || nodes > budget
    }

    func run(_ depth: Int) {
        if stopped { return }
        if depth == order.count {
            for value in rowsLeft { if value != 0 { return } }
            for value in colsLeft { if value != 0 { return } }
            count += 1
            if first == nil {
                var solution = Array(repeating: 0, count: order.count)
                var j = 0
                while j < order.count {
                    solution[order[j].index] = positions[j]
                    j += 1
                }
                first = solution
            }
            return
        }
        let shape = order[depth].shape
        // The second of two equal shapes only goes after the first.
        var position = 0
        if depth > 0 && order[depth - 1].shape.key == shape.key {
            position = positions[depth - 1] + 1
        }
        while position < size * size {
            let row = position / size
            let col = position % size
            if row + shape.height <= size && col + shape.width <= size && isFree(shape, row, col) {
                for cell in shape.cells {
                    rowsLeft[row + cell.row] -= 1
                    colsLeft[col + cell.col] -= 1
                }
                var fits = true
                var i = 0
                while i < size {
                    if rowsLeft[i] < 0 || colsLeft[i] < 0 {
                        fits = false
                        break
                    }
                    i += 1
                }
                if fits {
                    nodes += 1
                    mark(shape, row, col, true)
                    positions[depth] = position
                    run(depth + 1)
                    mark(shape, row, col, false)
                }
                for cell in shape.cells {
                    rowsLeft[row + cell.row] += 1
                    colsLeft[col + cell.col] += 1
                }
                if stopped { return }
            }
            position += 1
        }
    }

    private func isFree(_ shape: PieceShape, _ row: Int, _ col: Int) -> Bool {
        for cell in shape.cells {
            if grid[(row + cell.row) * size + col + cell.col] { return false }
        }
        return true
    }

    private func mark(_ shape: PieceShape, _ row: Int, _ col: Int, _ filled: Bool) {
        for cell in shape.cells {
            grid[(row + cell.row) * size + col + cell.col] = filled
        }
    }
}
