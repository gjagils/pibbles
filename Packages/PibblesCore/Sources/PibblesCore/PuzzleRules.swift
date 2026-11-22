import Foundation

/// Filled squares per row and per column.
public struct BoardCounts: Hashable, Sendable {
    public let rows: [Int]
    public let cols: [Int]

    public init(rows: [Int], cols: [Int]) {
        self.rows = rows
        self.cols = cols
    }
}

/// The rules of the board while playing. The play screen asks here; it has no rules of its own.
/// A position is row × size + col of the top left corner of a piece's bounding box;
/// `positions` holds one entry per piece, `nil` while the piece is not on the board.
public enum PuzzleRules {
    /// The piece lies completely on the board.
    public static func fits(shapeKey: String, position: Int, size: Int) -> Bool {
        guard let shape = ShapeCatalog.shape(shapeKey) else { return false }
        if position < 0 || position >= size * size { return false }
        return position / size + shape.height <= size && position % size + shape.width <= size
    }

    /// The board squares a piece covers; empty when it does not fit.
    public static func cells(shapeKey: String, position: Int, size: Int) -> [Int] {
        var result = [Int]()
        guard let shape = ShapeCatalog.shape(shapeKey) else { return result }
        if !fits(shapeKey: shapeKey, position: position, size: size) { return result }
        let row = position / size
        let col = position % size
        for cell in shape.cells {
            result.append((row + cell.row) * size + col + cell.col)
        }
        return result
    }

    /// Piece number `piece` may go to `position`: on the board and not on another piece.
    /// Its own current place does not count, so a piece can be moved.
    public static func canPlace(_ puzzle: Puzzle, piece: Int, position: Int, positions: [Int?]) -> Bool {
        if piece < 0 || piece >= puzzle.pieces.count { return false }
        let wanted = cells(shapeKey: puzzle.pieces[piece], position: position, size: puzzle.size)
        if wanted.isEmpty { return false }
        var other = 0
        while other < puzzle.pieces.count && other < positions.count {
            if other != piece, let placed = positions[other] {
                for square in cells(shapeKey: puzzle.pieces[other], position: placed, size: puzzle.size) {
                    if wanted.contains(square) { return false }
                }
            }
            other += 1
        }
        return true
    }

    public static func counts(_ puzzle: Puzzle, positions: [Int?]) -> BoardCounts {
        var rows = Array(repeating: 0, count: puzzle.size)
        var cols = Array(repeating: 0, count: puzzle.size)
        var piece = 0
        while piece < puzzle.pieces.count && piece < positions.count {
            if let placed = positions[piece] {
                for square in cells(shapeKey: puzzle.pieces[piece], position: placed, size: puzzle.size) {
                    rows[square / puzzle.size] += 1
                    cols[square % puzzle.size] += 1
                }
            }
            piece += 1
        }
        return BoardCounts(rows: rows, cols: cols)
    }

    /// All pieces lie on the board without overlap and every number matches.
    public static func isSolved(_ puzzle: Puzzle, positions: [Int?]) -> Bool {
        if positions.count != puzzle.pieces.count { return false }
        var filled = Array(repeating: false, count: puzzle.size * puzzle.size)
        var piece = 0
        while piece < puzzle.pieces.count {
            guard let placed = positions[piece] else { return false }
            let squares = cells(shapeKey: puzzle.pieces[piece], position: placed, size: puzzle.size)
            if squares.isEmpty { return false }
            for square in squares {
                if filled[square] { return false }
                filled[square] = true
            }
            piece += 1
        }
        let result = counts(puzzle, positions: positions)
        return result.rows == puzzle.rows && result.cols == puzzle.cols
    }
}

/// Today's ranking: time plus a penalty per hint, lowest wins.
public enum Ranking {
    /// Proposed value, not yet confirmed by the owner (HANDOFF.md).
    public static let hintPenaltyMilliseconds = 30000

    public static func score(milliseconds: Int, hints: Int) -> Int {
        return milliseconds + hints * hintPenaltyMilliseconds
    }
}
