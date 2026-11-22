import Foundation

/// Counts the solutions of a Links puzzle: distinct colourings of all cells in which every
/// colour's cells form a path between its two dots that never touches itself sideways (the
/// convention of `LinksPuzzle`).
///
/// Search: every colour grows one path from its first dot (lower cell index) towards the
/// other dot. At each step the colour whose head has the fewest legal moves is extended
/// (a colour with one move is forced, a colour with none ends the branch), trying each move
/// in neighbour order. A move goes to a free cell that touches no cell of its own colour
/// other than the head and the target dot; touching the target dot completes the path, so
/// the cells of a solution fix every choice and each solution is counted once. After every
/// move the branch is dropped when
/// - a free cell has fewer than two neighbours that are free or an open end (the head or
///   the target dot of an unfinished colour): it could not lie in the middle of a path;
/// - an unfinished colour's head and target no longer border a common region of free cells;
/// - a region of free cells borders no unfinished colour at both of its ends.
public enum LinksSolver {
    /// The number of solutions, at most `limit`. 0 for malformed input: wrong length, a
    /// colour below -1, a colour that does not appear exactly twice, or no dots at all.
    public static func countSolutions(size: Int, ends: [Int], limit: Int) -> Int {
        if size <= 0 || limit <= 0 || ends.count != size * size { return 0 }
        guard let search = LinksSearch(size: size, ends: ends, limit: limit) else { return 0 }
        search.run()
        return search.count
    }
}

/// The search state, changed in place and undone on the way back.
final class LinksSearch {
    let size: Int
    let cells: Int
    let colours: Int
    let limit: Int
    var count = 0
    /// Four neighbours per cell (up, left, right, down), -1 outside the grid.
    var neighbours: [Int]
    /// Colour per cell, -1 when free.
    var owner: [Int]
    var head: [Int]
    var target: [Int]
    var done: [Bool]
    var pending: Int
    var free: Int
    /// Scratch for the region check.
    var region: [Int]
    var stack: [Int]
    var regionUsed: [Bool]
    /// Scratch for the moves at each depth, `cells` slots per depth.
    var moves: [Int]

    init?(size: Int, ends: [Int], limit: Int) {
        let cells = size * size
        var largest = -1
        for value in ends {
            if value < -1 { return nil }
            if value > largest { largest = value }
        }
        if largest < 0 { return nil }
        let colours = largest + 1
        var first = Array(repeating: -1, count: colours)
        var second = Array(repeating: -1, count: colours)
        var cell = 0
        while cell < cells {
            let colour = ends[cell]
            if colour >= 0 {
                if first[colour] < 0 {
                    first[colour] = cell
                } else if second[colour] < 0 {
                    second[colour] = cell
                } else {
                    return nil
                }
            }
            cell += 1
        }
        var colour = 0
        while colour < colours {
            if second[colour] < 0 { return nil }
            colour += 1
        }
        self.size = size
        self.cells = cells
        self.colours = colours
        self.limit = limit
        var neighbours = Array(repeating: -1, count: cells * 4)
        cell = 0
        while cell < cells {
            let row = cell / size
            let col = cell % size
            if row > 0 { neighbours[cell * 4] = cell - size }
            if col > 0 { neighbours[cell * 4 + 1] = cell - 1 }
            if col + 1 < size { neighbours[cell * 4 + 2] = cell + 1 }
            if row + 1 < size { neighbours[cell * 4 + 3] = cell + size }
            cell += 1
        }
        self.neighbours = neighbours
        self.owner = ends
        self.head = first
        self.target = second
        self.done = Array(repeating: false, count: colours)
        self.pending = colours
        self.free = cells - 2 * colours
        self.region = Array(repeating: -1, count: cells)
        self.stack = Array(repeating: 0, count: cells)
        self.regionUsed = Array(repeating: false, count: cells)
        self.moves = Array(repeating: 0, count: cells * (cells + 1))
    }

    func run() {
        // Dots that are neighbours must be joined directly (no sideways touching).
        var colour = 0
        while colour < colours {
            if touches(head[colour], target[colour]) {
                done[colour] = true
                pending -= 1
            }
            colour += 1
        }
        if !consistent() { return }
        solve(depth: 0)
    }

    private func touches(_ a: Int, _ b: Int) -> Bool {
        var d = 0
        while d < 4 {
            if neighbours[a * 4 + d] == b { return true }
            d += 1
        }
        return false
    }

    /// The legal moves of a colour, written at `moves[base...]`; returns how many.
    private func collectMoves(_ colour: Int, base: Int) -> Int {
        let from = head[colour]
        var n = 0
        var d = 0
        while d < 4 {
            let next = neighbours[from * 4 + d]
            if next >= 0 && owner[next] < 0 && allowed(next, colour: colour, from: from) {
                moves[base + n] = next
                n += 1
            }
            d += 1
        }
        return n
    }

    /// `cell` touches no cell of `colour` except the head and the target dot.
    private func allowed(_ cell: Int, colour: Int, from: Int) -> Bool {
        var d = 0
        while d < 4 {
            let other = neighbours[cell * 4 + d]
            if other >= 0 && other != from && owner[other] == colour && other != target[colour] { return false }
            d += 1
        }
        return true
    }

    private func solve(depth: Int) {
        if count >= limit { return }
        if pending == 0 {
            if free == 0 { count += 1 }
            return
        }
        // The unfinished colour with the fewest moves.
        let base = depth * cells
        var best = -1
        var bestCount = 5
        var colour = 0
        while colour < colours {
            if !done[colour] {
                let n = collectMoves(colour, base: base)
                if n == 0 { return }
                if n < bestCount {
                    best = colour
                    bestCount = n
                }
            }
            colour += 1
        }
        let n = collectMoves(best, base: base)
        let from = head[best]
        var index = 0
        while index < n {
            let cell = moves[base + index]
            owner[cell] = best
            head[best] = cell
            free -= 1
            let finished = touches(cell, target[best])
            if finished {
                done[best] = true
                pending -= 1
            }
            if consistent() { solve(depth: depth + 1) }
            if finished {
                done[best] = false
                pending += 1
            }
            free += 1
            head[best] = from
            owner[cell] = -1
            if count >= limit { return }
            index += 1
        }
    }

    /// An open end of an unfinished colour: its head or its target dot.
    private func isOpenEnd(_ cell: Int) -> Bool {
        let colour = owner[cell]
        if colour < 0 || done[colour] { return false }
        return head[colour] == cell || target[colour] == cell
    }

    /// The dead-end and region checks of the type comment.
    private func consistent() -> Bool {
        var cell = 0
        while cell < cells {
            if owner[cell] < 0 {
                var open = 0
                var d = 0
                while d < 4 {
                    let other = neighbours[cell * 4 + d]
                    if other >= 0 && (owner[other] < 0 || isOpenEnd(other)) { open += 1 }
                    d += 1
                }
                if open < 2 { return false }
            }
            region[cell] = -1
            cell += 1
        }
        // Label the regions of free cells.
        var regions = 0
        cell = 0
        while cell < cells {
            if owner[cell] < 0 && region[cell] < 0 {
                region[cell] = regions
                regionUsed[regions] = false
                var top = 0
                stack[top] = cell
                top += 1
                while top > 0 {
                    top -= 1
                    let current = stack[top]
                    var d = 0
                    while d < 4 {
                        let other = neighbours[current * 4 + d]
                        if other >= 0 && owner[other] < 0 && region[other] < 0 {
                            region[other] = regions
                            stack[top] = other
                            top += 1
                        }
                        d += 1
                    }
                }
                regions += 1
            }
            cell += 1
        }
        // Every unfinished colour needs a region bordering both its ends; such regions are used.
        var colour = 0
        while colour < colours {
            if !done[colour] {
                var shared = false
                var d = 0
                while d < 4 {
                    let a = neighbours[head[colour] * 4 + d]
                    if a >= 0 && owner[a] < 0 && bordersRegion(target[colour], region[a]) {
                        regionUsed[region[a]] = true
                        shared = true
                    }
                    d += 1
                }
                if !shared { return false }
            }
            colour += 1
        }
        var index = 0
        while index < regions {
            if !regionUsed[index] { return false }
            index += 1
        }
        return true
    }

    private func bordersRegion(_ cell: Int, _ label: Int) -> Bool {
        var d = 0
        while d < 4 {
            let other = neighbours[cell * 4 + d]
            if other >= 0 && owner[other] < 0 && region[other] == label { return true }
            d += 1
        }
        return false
    }
}
