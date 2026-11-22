import Foundation

/// A puzzle: the player drags the `pieces` onto a `size` × `size` board until every
/// row and column holds the number of filled squares given in `rows` and `cols`.
public struct Puzzle: Hashable, Codable, Sendable {
    public let size: Int
    /// Shape keys (`ShapeCatalog`), in the order the player gets them.
    public let pieces: [String]
    public let rows: [Int]
    public let cols: [Int]
    /// Per piece the position (row × size + col) of the top left corner of its bounding box.
    public let solution: [Int]
    /// How many boards the generator tried, and how much work the solver did. Not in JSON.
    public var attempts: Int = 0
    public var nodes: Int = 0

    enum CodingKeys: String, CodingKey {
        case size, pieces, rows, cols, solution
    }

    public init(size: Int, pieces: [String], rows: [Int], cols: [Int], solution: [Int],
                attempts: Int, nodes: Int) {
        self.size = size
        self.pieces = pieces
        self.rows = rows
        self.cols = cols
        self.solution = solution
        self.attempts = attempts
        self.nodes = nodes
    }
}

public enum PuzzleGenerator {
    static let maxAttempts = 20000
    static let placementTries = 40
    static let solverBudget = 60000

    /// Lays down random pieces, derives the numbers and accepts the board only when the
    /// solver proves there is exactly one solution. The same level and seed always give
    /// the same puzzle, also in `prototype/logic.js`.
    public static func generate(level: Level, seed: String) -> Puzzle? {
        let size = level.size
        let random = SeededRandom(seed: StringHash.fnv1a("\(size)x\(level.pieceCount)|\(seed)"))
        let shapes = ShapeCatalog.all
        var attempt = 0
        while attempt < maxAttempts {
            attempt += 1
            var grid = Array(repeating: false, count: size * size)
            var keys = [String]()
            var positions = [Int]()
            var failed = false
            while keys.count < level.pieceCount && !failed {
                var placed = false
                var tries = 0
                while tries < placementTries && !placed {
                    tries += 1
                    let shape = shapes[random.nextInt(shapes.count)]
                    // Fewer two-square pieces: they make a puzzle loose.
                    if shape.cells.count < 3 && random.next() < 0.6 { continue }
                    let row = random.nextInt(size - shape.height + 1)
                    let col = random.nextInt(size - shape.width + 1)
                    var free = true
                    for cell in shape.cells {
                        if grid[(row + cell.row) * size + col + cell.col] { free = false }
                    }
                    if !free { continue }
                    for cell in shape.cells {
                        grid[(row + cell.row) * size + col + cell.col] = true
                    }
                    keys.append(shape.key)
                    positions.append(row * size + col)
                    placed = true
                }
                if !placed { failed = true }
            }
            if failed { continue }

            // At most twice the same shape.
            var perShape = [String: Int]()
            var tooMany = false
            for key in keys {
                let count = (perShape[key] ?? 0) + 1
                perShape[key] = count
                if count > 2 { tooMany = true }
            }
            if tooMany { continue }

            var rows = Array(repeating: 0, count: size)
            var cols = Array(repeating: 0, count: size)
            var empty = 0
            for row in 0..<size {
                for col in 0..<size {
                    if grid[row * size + col] {
                        rows[row] += 1
                        cols[col] += 1
                    }
                }
            }
            for value in rows { if value == 0 { empty += 1 } }
            for value in cols { if value == 0 { empty += 1 } }
            // No empty row or column; with four pieces one is allowed.
            let allowedEmpty = level.pieceCount < 5 ? 1 : 0
            if empty > allowedEmpty { continue }

            let result = Solver.countSolutions(size: size, shapeKeys: keys, rows: rows, cols: cols,
                                               limit: 2, budget: solverBudget)
            if result.count == 1 && !result.exhausted {
                return Puzzle(size: size, pieces: keys, rows: rows, cols: cols, solution: positions,
                              attempts: attempt, nodes: result.nodes)
            }
        }
        return nil
    }
}
