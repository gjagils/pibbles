import Foundation

/// A Links puzzle (Numberlink): connect the two dots of every colour with a path of
/// orthogonally adjacent cells; paths do not cross or share cells and together fill the
/// whole grid. Square grid, cells row by row (index = row × size + col).
/// JSON: `{"size":5,"ends":[0,-1,...],"solution":[[0,1,2],[3,8,...],...]}`.
///
/// Convention ("no shortcuts"): a path never touches itself sideways. Two cells of the same
/// colour that are neighbours are always consecutive on its path, so a path makes no 2×2
/// block and no U-turn against itself. The cells of a colour then fix its path, the solver
/// counts distinct colourings (`LinksSolver`), and `LinksRules.isSolved` accepts exactly
/// those colourings.
public struct LinksPuzzle: Hashable, Codable, Sendable {
    public let size: Int
    /// Per cell the colour of its dot, -1 for no dot; every colour 0..<k exactly twice.
    public let ends: [Int]
    /// Per colour the cells of its path, from one dot to the other (both included).
    public let solution: [[Int]]

    public init(size: Int, ends: [Int], solution: [[Int]]) {
        self.size = size
        self.ends = ends
        self.solution = solution
    }

    /// The number of colours (the largest colour in `ends` plus one).
    public var colourCount: Int {
        var largest = -1
        for value in ends {
            if value > largest { largest = value }
        }
        return largest + 1
    }
}

/// The result of putting a finger down (`LinksRules.start`): the colour being drawn now
/// and the paths after the restart or cut.
public struct StartResult: Hashable, Sendable {
    public let colour: Int
    public let paths: [[Int]]

    public init(colour: Int, paths: [[Int]]) {
        self.colour = colour
        self.paths = paths
    }
}

/// The rules while playing. The play screen asks here; it has no rules of its own.
/// `paths[c]` is the player's path for colour c, cells in drawing order, starting at either
/// dot of that colour; an empty path is `[Int]()`.
public enum LinksRules {
    /// Solved when every path runs from one dot of its colour to the other through adjacent
    /// cells, never touches itself sideways (see `LinksPuzzle`), paths do not overlap, and
    /// all cells are used.
    public static func isSolved(_ puzzle: LinksPuzzle, paths: [[Int]]) -> Bool {
        let size = puzzle.size
        let cells = size * size
        let k = puzzle.colourCount
        if size <= 0 || puzzle.ends.count != cells || paths.count != k { return false }
        var owner = Array(repeating: -1, count: cells)
        var used = 0
        var colour = 0
        while colour < k {
            let path = paths[colour]
            if path.count < 2 { return false }
            var index = 0
            while index < path.count {
                let cell = path[index]
                if cell < 0 || cell >= cells || owner[cell] >= 0 { return false }
                owner[cell] = colour
                used += 1
                if index > 0 && !adjacent(size, path[index - 1], cell) { return false }
                index += 1
            }
            let first = path[0]
            let last = path[path.count - 1]
            if puzzle.ends[first] != colour || puzzle.ends[last] != colour { return false }
            colour += 1
        }
        if used != cells { return false }
        // No sideways touching: neighbours of one colour are consecutive on its path.
        var position = Array(repeating: 0, count: cells)
        colour = 0
        while colour < k {
            var index = 0
            while index < paths[colour].count {
                position[paths[colour][index]] = index
                index += 1
            }
            colour += 1
        }
        var cell = 0
        while cell < cells {
            let col = cell % size
            if col + 1 < size && owner[cell + 1] == owner[cell] && distance(position[cell], position[cell + 1]) != 1 {
                return false
            }
            if cell + size < cells && owner[cell + size] == owner[cell]
                && distance(position[cell], position[cell + size]) != 1 {
                return false
            }
            cell += 1
        }
        return true
    }

    /// The drawing rule while the finger moves with `colour`. On a cell already on that path
    /// the path is cut back to it. Otherwise the cell is appended when it is adjacent to the
    /// path's last cell, the path is not complete yet, and the cell is not another colour's
    /// dot; another colour's path crossed there is cut back to just before the cell. An
    /// empty path starts when the cell is a dot of the colour. Anything else: unchanged.
    public static func extend(_ puzzle: LinksPuzzle, paths: [[Int]], colour: Int, to cell: Int) -> [[Int]] {
        let size = puzzle.size
        let cells = size * size
        var result = normalised(puzzle, paths)
        if colour < 0 || colour >= result.count || cell < 0 || cell >= cells || puzzle.ends.count != cells {
            return result
        }
        let path = result[colour]
        if path.isEmpty {
            if puzzle.ends[cell] == colour { result[colour] = [cell] }
            return result
        }
        let at = indexOf(cell, path)
        if at >= 0 {
            result[colour] = prefix(path, at + 1)
            return result
        }
        let last = path[path.count - 1]
        if !adjacent(size, last, cell) { return result }
        if path.count > 1 && puzzle.ends[last] == colour { return result }
        let dot = puzzle.ends[cell]
        if dot >= 0 && dot != colour { return result }
        var other = 0
        while other < result.count {
            if other != colour {
                let crossed = indexOf(cell, result[other])
                if crossed >= 0 { result[other] = prefix(result[other], crossed) }
            }
            other += 1
        }
        var grown = path
        grown.append(cell)
        result[colour] = grown
        return result
    }

    /// Finger down. On a dot: that colour's path restarts from this dot. On a cell of a path:
    /// that path is cut back to this cell (and drawing continues from it). Otherwise nil.
    public static func start(_ puzzle: LinksPuzzle, paths: [[Int]], at cell: Int) -> StartResult? {
        let cells = puzzle.size * puzzle.size
        if cell < 0 || cell >= cells || puzzle.ends.count != cells { return nil }
        var result = normalised(puzzle, paths)
        let dot = puzzle.ends[cell]
        if dot >= 0 && dot < result.count {
            result[dot] = [cell]
            return StartResult(colour: dot, paths: result)
        }
        var colour = 0
        while colour < result.count {
            let at = indexOf(cell, result[colour])
            if at >= 0 {
                result[colour] = prefix(result[colour], at + 1)
                return StartResult(colour: colour, paths: result)
            }
            colour += 1
        }
        return nil
    }

    /// Exactly one path per colour: missing paths are empty, extra ones dropped.
    static func normalised(_ puzzle: LinksPuzzle, _ paths: [[Int]]) -> [[Int]] {
        let k = puzzle.colourCount
        var result = [[Int]]()
        var colour = 0
        while colour < k {
            result.append(colour < paths.count ? paths[colour] : [Int]())
            colour += 1
        }
        return result
    }

    static func adjacent(_ size: Int, _ a: Int, _ b: Int) -> Bool {
        if a < 0 || b < 0 || a >= size * size || b >= size * size { return false }
        let rowA = a / size
        let rowB = b / size
        if rowA == rowB { return distance(a, b) == 1 }
        return a % size == b % size && distance(rowA, rowB) == 1
    }

    private static func distance(_ a: Int, _ b: Int) -> Int {
        return a > b ? a - b : b - a
    }

    private static func indexOf(_ cell: Int, _ path: [Int]) -> Int {
        var index = 0
        while index < path.count {
            if path[index] == cell { return index }
            index += 1
        }
        return -1
    }

    private static func prefix(_ path: [Int], _ count: Int) -> [Int] {
        var result = [Int]()
        var index = 0
        while index < count && index < path.count {
            result.append(path[index])
            index += 1
        }
        return result
    }
}
