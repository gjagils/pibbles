import Foundation

/// One square of a shape or of the board.
public struct Cell: Hashable, Sendable {
    public let row: Int
    public let col: Int

    public init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

/// A block with a fixed orientation: blocks cannot be rotated, so every orientation
/// is its own shape (`I2` and `I2v`).
public struct PieceShape: Hashable, Sendable {
    public let key: String
    /// The squares, relative to the top left corner of the bounding box.
    public let cells: [Cell]
    public let height: Int
    public let width: Int

    public init(key: String, cells: [Cell]) {
        self.key = key
        self.cells = cells
        var height = 0
        var width = 0
        for cell in cells {
            if cell.row + 1 > height { height = cell.row + 1 }
            if cell.col + 1 > width { width = cell.col + 1 }
        }
        self.height = height
        self.width = width
    }
}

/// All shapes, in the order of the prototype. The generator draws by index, so the
/// order is part of what makes a seed give the same puzzle everywhere.
public enum ShapeCatalog {
    public static let all: [PieceShape] = [
        make("I2", [0, 0, 0, 1]), make("I2v", [0, 0, 1, 0]),
        make("I3", [0, 0, 0, 1, 0, 2]), make("I3v", [0, 0, 1, 0, 2, 0]),
        make("L3a", [0, 0, 1, 0, 1, 1]), make("L3b", [0, 0, 0, 1, 1, 0]),
        make("L3c", [0, 0, 0, 1, 1, 1]), make("L3d", [0, 1, 1, 0, 1, 1]),
        make("O4", [0, 0, 0, 1, 1, 0, 1, 1]),
        make("I4", [0, 0, 0, 1, 0, 2, 0, 3]), make("I4v", [0, 0, 1, 0, 2, 0, 3, 0]),
        make("L4a", [0, 0, 1, 0, 2, 0, 2, 1]), make("L4b", [0, 0, 0, 1, 0, 2, 1, 0]),
        make("L4c", [0, 0, 0, 1, 1, 1, 2, 1]), make("L4d", [0, 2, 1, 0, 1, 1, 1, 2]),
        make("J4a", [0, 1, 1, 1, 2, 0, 2, 1]), make("J4b", [0, 0, 1, 0, 1, 1, 1, 2]),
        make("J4c", [0, 0, 0, 1, 1, 0, 2, 0]), make("J4d", [0, 0, 0, 1, 0, 2, 1, 2]),
        make("T4a", [0, 0, 0, 1, 0, 2, 1, 1]), make("T4b", [0, 1, 1, 0, 1, 1, 2, 1]),
        make("T4c", [0, 1, 1, 0, 1, 1, 1, 2]), make("T4d", [0, 0, 1, 0, 1, 1, 2, 0]),
        make("S4a", [0, 1, 0, 2, 1, 0, 1, 1]), make("S4b", [0, 0, 1, 0, 1, 1, 2, 1]),
        make("Z4a", [0, 0, 0, 1, 1, 1, 1, 2]), make("Z4b", [0, 1, 1, 0, 1, 1, 2, 0]),
    ]

    public static func shape(_ key: String) -> PieceShape? {
        for shape in all {
            if shape.key == key { return shape }
        }
        return nil
    }

    /// `pairs` holds row, col, row, col, …
    private static func make(_ key: String, _ pairs: [Int]) -> PieceShape {
        var cells = [Cell]()
        var index = 0
        while index + 1 < pairs.count {
            cells.append(Cell(row: pairs[index], col: pairs[index + 1]))
            index += 2
        }
        return PieceShape(key: key, cells: cells)
    }
}
