import Foundation

/// The play state of a Blocks puzzle: which piece lies where, and which piece the player
/// holds. The screen only draws this and passes taps on; the rules live here.
public struct BlocksPlay: Hashable, Sendable {
    public let puzzle: Puzzle
    /// Per piece the position of its top left corner, nil while it is in the tray.
    public private(set) var positions: [Int?]
    /// The piece in the player's hand, nil when none.
    public private(set) var selected: Int?
    public private(set) var hints: Int = 0

    public init(puzzle: Puzzle) {
        self.puzzle = puzzle
        var empty = [Int?]()
        for _ in puzzle.pieces { empty.append(nil) }
        self.positions = empty
        self.selected = puzzle.pieces.isEmpty ? nil : 0
    }

    /// Puts back a saved game: positions per piece (nil in the tray) and the hints used.
    /// Ignored when it does not fit this puzzle (wrong length, a piece off the board or
    /// on another piece).
    public mutating func restore(positions saved: [Int?], hints savedHints: Int) {
        if saved.count != puzzle.pieces.count { return }
        var check = BlocksPlay(puzzle: puzzle)
        var index = 0
        while index < saved.count {
            if let position = saved[index] {
                if !PuzzleRules.canPlace(puzzle, piece: index, position: position, positions: check.positions) { return }
                check.positions[index] = position
            }
            index += 1
        }
        // `self.`: in Kotlin the argument labels become parameter names that hide these
        self.positions = check.positions
        self.hints = max(0, savedHints)
        selected = nil
        var next = 0
        while next < self.positions.count {
            if self.positions[next] == nil {
                selected = next
                break
            }
            next += 1
        }
    }

    public var isSolved: Bool {
        return PuzzleRules.isSolved(puzzle, positions: positions)
    }

    public var counts: BoardCounts {
        return PuzzleRules.counts(puzzle, positions: positions)
    }

    /// The piece covering a board square, if any.
    public func piece(at square: Int) -> Int? {
        var index = 0
        while index < positions.count {
            if let position = positions[index] {
                if PuzzleRules.cells(shapeKey: puzzle.pieces[index], position: position, size: puzzle.size).contains(square) {
                    return index
                }
            }
            index += 1
        }
        return nil
    }

    /// Take a piece from the tray (or pick up a placed one).
    public mutating func select(_ piece: Int) {
        if piece < 0 || piece >= puzzle.pieces.count || isSolved { return }
        selected = piece
    }

    /// A tap on a board square. On a placed piece with nothing in hand: pick it up. With a
    /// piece in hand: put its top left corner on the square, moved in so it fits; pieces in
    /// the way go back to the tray. Returns true when something changed.
    @discardableResult
    public mutating func tap(square: Int) -> Bool {
        if isSolved || square < 0 || square >= puzzle.size * puzzle.size { return false }
        guard let piece = selected else {
            if let hit = self.piece(at: square) {
                positions[hit] = nil
                selected = hit
                return true
            }
            return false
        }
        guard let shape = ShapeCatalog.shape(puzzle.pieces[piece]) else { return false }
        let size = puzzle.size
        let row = min(square / size, size - shape.height)
        let col = min(square % size, size - shape.width)
        let position = row * size + col
        place(piece, at: position)
        return true
    }

    /// Back to the tray.
    public mutating func remove(_ piece: Int) {
        if piece < 0 || piece >= positions.count || isSolved { return }
        positions[piece] = nil
        selected = piece
    }

    public mutating func clear() {
        var index = 0
        while index < positions.count {
            positions[index] = nil
            index += 1
        }
        selected = puzzle.pieces.isEmpty ? nil : 0
    }

    /// Puts one piece where the solution has it (a piece of the same shape counts too).
    /// Returns false when there is nothing to show.
    @discardableResult
    public mutating func hint() -> Bool {
        if isSolved { return false }
        var index = 0
        while index < puzzle.pieces.count {
            if !isCorrect(index) {
                let key = puzzle.pieces[index]
                // A solution spot of this shape that no correct piece holds yet.
                var spot = 0
                while spot < puzzle.pieces.count {
                    if puzzle.pieces[spot] == key && !spotTaken(puzzle.solution[spot], key: key) {
                        place(index, at: puzzle.solution[spot])
                        hints += 1
                        return true
                    }
                    spot += 1
                }
            }
            index += 1
        }
        return false
    }

    /// The piece lies on a spot where the solution has a piece of its shape.
    public func isCorrect(_ piece: Int) -> Bool {
        guard let position = positions[piece] else { return false }
        let key = puzzle.pieces[piece]
        var spot = 0
        while spot < puzzle.pieces.count {
            if puzzle.pieces[spot] == key && puzzle.solution[spot] == position { return true }
            spot += 1
        }
        return false
    }

    private func spotTaken(_ position: Int, key: String) -> Bool {
        var index = 0
        while index < positions.count {
            if puzzle.pieces[index] == key && positions[index] == position { return true }
            index += 1
        }
        return false
    }

    private mutating func place(_ piece: Int, at position: Int) {
        let wanted = PuzzleRules.cells(shapeKey: puzzle.pieces[piece], position: position, size: puzzle.size)
        var other = 0
        while other < positions.count {
            if other != piece, let placed = positions[other] {
                let cells = PuzzleRules.cells(shapeKey: puzzle.pieces[other], position: placed, size: puzzle.size)
                var overlaps = false
                for square in cells {
                    if wanted.contains(square) { overlaps = true }
                }
                if overlaps { positions[other] = nil }
            }
            other += 1
        }
        positions[piece] = position
        // Hand the next piece from the tray to the player.
        selected = nil
        var next = 0
        while next < positions.count {
            if positions[next] == nil {
                selected = next
                break
            }
            next += 1
        }
    }
}
