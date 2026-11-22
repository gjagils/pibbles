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
        if !SolverSearch.usable(size: size, rows: rows, cols: cols) || shapeKeys.count > 10 {
            return SolveResult(count: 0, nodes: 0, exhausted: false, first: nil)
        }
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

/// Every place one shape fits on the board, in position order. Per placement: the squares
/// as a bit mask (boards are at most 8×8), and how much it takes from each row and column,
/// packed one byte per row (see `SolverSearch`). Built once, stored in `let` arrays.
private final class Placements {
    let positions: [Int]
    let masks: [Int64]
    let rowTakes: [Int64]
    let colTakes: [Int64]

    init(shape: PieceShape, size: Int) {
        var positions = [Int]()
        var masks = [Int64]()
        var rowTakes = [Int64]()
        var colTakes = [Int64]()
        let one: Int64 = 1
        var position = 0
        while position < size * size {
            let row = position / size
            let col = position % size
            if row + shape.height <= size && col + shape.width <= size {
                var mask: Int64 = 0
                var rowTake: Int64 = 0
                var colTake: Int64 = 0
                for cell in shape.cells {
                    let square = (row + cell.row) * size + col + cell.col
                    mask = mask | (one << square)
                    rowTake = rowTake + (one << (8 * (row + cell.row)))
                    colTake = colTake + (one << (8 * (col + cell.col)))
                }
                positions.append(position)
                masks.append(mask)
                rowTakes.append(rowTake)
                colTakes.append(colTake)
            }
            position += 1
        }
        self.positions = positions
        self.masks = masks
        self.rowTakes = rowTakes
        self.colTakes = colTakes
    }
}

/// The search keeps its whole state in 64-bit numbers, never in arrays it writes to:
/// Skip's Kotlin copies an array held by a class on every write, which made the search
/// a hundred times slower on Android (22 November).
/// - `occupied`: one bit per square.
/// - `rowsLeft`/`colsLeft`: per row (column) one byte holding 8 + the count still to fill.
///   A placement takes at most 4 from a byte, so bytes stay within 4…16; a byte below 8
///   means the count went negative. Rows beyond the board stay at 8.
/// - `chosen`: per depth 6 bits with the position chosen there.
private final class SolverSearch {
    static let eights: Int64 = 0x0808080808080808

    let size: Int
    let limit: Int
    let budget: Int
    let order: [OrderedShape]
    let placements: [Placements]
    let sameAsPrevious: [Bool]
    var occupied: Int64 = 0
    var rowsLeft: Int64 = 0
    var colsLeft: Int64 = 0
    var chosen: Int64 = 0
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
        let sorted = list.sorted { a, b in
            if a.shape.cells.count != b.shape.cells.count { return a.shape.cells.count > b.shape.cells.count }
            if a.shape.key != b.shape.key { return a.shape.key < b.shape.key }
            return a.index < b.index
        }
        self.order = sorted
        var built = [Placements]()
        var same = [Bool]()
        var depth = 0
        while depth < sorted.count {
            built.append(Placements(shape: sorted[depth].shape, size: size))
            same.append(depth > 0 && sorted[depth - 1].shape.key == sorted[depth].shape.key)
            depth += 1
        }
        self.placements = built
        self.sameAsPrevious = same
        rowsLeft = SolverSearch.pack(rows)
        colsLeft = SolverSearch.pack(cols)
    }

    /// Counts as bytes of 8 + count; missing rows count 0.
    static func pack(_ counts: [Int]) -> Int64 {
        var packed: Int64 = 0
        var index = 0
        while index < 8 {
            let value = index < counts.count ? counts[index] : 0
            let byte = Int64(8 + value)
            packed = packed | (byte << (8 * index))
            index += 1
        }
        return packed
    }

    /// The input fits the packed representation (else the search reports no solution).
    static func usable(size: Int, rows: [Int], cols: [Int]) -> Bool {
        if size < 1 || size > 8 || rows.count != size || cols.count != size { return false }
        for value in rows { if value < 0 || value > 8 { return false } }
        for value in cols { if value < 0 || value > 8 { return false } }
        return true
    }

    private var stopped: Bool {
        return count >= limit || nodes > budget
    }

    /// True when no byte dropped below 8.
    private static func allAtLeastEight(_ packed: Int64) -> Bool {
        let spread = packed | (packed >> 1)
        return (spread & eights) == eights
    }

    private func positionAt(_ depth: Int) -> Int {
        let mask: Int64 = 63
        return Int((chosen >> (6 * depth)) & mask)
    }

    func run(_ depth: Int) {
        if stopped { return }
        if depth == order.count {
            if rowsLeft != SolverSearch.eights || colsLeft != SolverSearch.eights { return }
            count += 1
            if first == nil {
                var solution = Array(repeating: 0, count: order.count)
                var j = 0
                while j < order.count {
                    solution[order[j].index] = positionAt(j)
                    j += 1
                }
                first = solution
            }
            return
        }
        let options = placements[depth]
        // The second of two equal shapes only goes after the first.
        var start = 0
        if sameAsPrevious[depth] {
            start = positionAt(depth - 1) + 1
        }
        let total = options.positions.count
        let empty: Int64 = 0
        let sixBits: Int64 = 63
        var option = 0
        while option < total {
            let position = options.positions[option]
            if position >= start {
                let mask = options.masks[option]
                if (occupied & mask) == empty {
                    let rowTake = options.rowTakes[option]
                    let colTake = options.colTakes[option]
                    rowsLeft = rowsLeft - rowTake
                    colsLeft = colsLeft - colTake
                    if SolverSearch.allAtLeastEight(rowsLeft) && SolverSearch.allAtLeastEight(colsLeft) {
                        nodes += 1
                        occupied = occupied | mask
                        let shift = 6 * depth
                        chosen = (chosen & ~(sixBits << shift)) | (Int64(position) << shift)
                        run(depth + 1)
                        occupied = occupied & ~mask
                    }
                    rowsLeft = rowsLeft + rowTake
                    colsLeft = colsLeft + colTake
                    if stopped { return }
                }
            }
            option += 1
        }
    }
}
