import Foundation

/// Makes the daily Links puzzle. The same weekday and seed give the same puzzle in Swift and
/// in Skip's Kotlin: only `SeededRandom.nextInt(_:)`, no `Set` or `Dictionary` order, all
/// loops over arrays in index order.
///
/// Per attempt:
/// 1. A random cover of the grid by paths. While free cells remain, a path starts at the free
///    cell with the fewest free neighbours (ties drawn at random) and grows at a random end
///    into a free neighbour, never touching itself sideways, until it reaches a drawn length
///    (around `cells / minColours`) or gets stuck. Half of the steps (`hugPercent`) take the
///    neighbour with the fewest free neighbours, the others a random one: hugging the edge
///    and other paths strands fewer cells, the random steps keep the paths lively.
/// 2. Paths shorter than three cells are joined end to end with a neighbouring path when the
///    joined path still does not touch itself; if one cannot be joined the attempt is dropped.
/// 3. The number of paths must lie in the weekday's range (`minColours`...`maxColours`).
/// 4. The path ends become the dots; colours are numbered by their first dot (lowest cell
///    index first) and each solution path runs from that dot to the other one.
/// 5. The puzzle is accepted only when `LinksSolver` proves exactly one solution.
/// After `maxAttempts` attempts (not reached in practice) a fixed puzzle is returned: one
/// straight path per row, which is unique (every path must cross every column once).
public enum LinksGenerator {
    /// Grid size per weekday, Monday 0 … Sunday 6.
    public static let sizes: [Int] = [5, 5, 6, 6, 6, 7, 7]
    /// The range of colours per weekday: fewer colours (longer paths) later in the week.
    static let minColours: [Int] = [5, 4, 6, 5, 4, 6, 5]
    static let maxColours: [Int] = [6, 5, 7, 6, 5, 7, 6]
    static let maxAttempts = 3000
    static let hugPercent = 50

    public static func generate(weekday: Int, seed: String) -> LinksPuzzle {
        let day = weekday < 0 ? 0 : (weekday > 6 ? 6 : weekday)
        let size = sizes[day]
        let random = SeededRandom(seed: StringHash.fnv1a("links|\(size)|\(seed)"))
        let cells = size * size
        // Drawn path lengths vary around the length for the fewest colours: joining short
        // leftovers and paths that get stuck early bring the count up into the range.
        let average = cells / minColours[day]
        var attempt = 0
        while attempt < maxAttempts {
            attempt += 1
            guard let paths = cover(size: size, average: average, random: random) else { continue }
            if paths.count < minColours[day] || paths.count > maxColours[day] { continue }
            let puzzle = puzzleFrom(size: size, paths: paths)
            if LinksSolver.countSolutions(size: size, ends: puzzle.ends, limit: 2) == 1 {
                return puzzle
            }
        }
        return fallback(size: size)
    }

    /// One straight path per row.
    static func fallback(size: Int) -> LinksPuzzle {
        var paths = [[Int]]()
        var row = 0
        while row < size {
            var path = [Int]()
            var col = 0
            while col < size {
                path.append(row * size + col)
                col += 1
            }
            paths.append(path)
            row += 1
        }
        return puzzleFrom(size: size, paths: paths)
    }

    /// Dots at the path ends; colours ordered by their first dot, paths from that dot.
    static func puzzleFrom(size: Int, paths: [[Int]]) -> LinksPuzzle {
        var oriented = [[Int]]()
        for path in paths {
            if path[0] <= path[path.count - 1] {
                oriented.append(path)
            } else {
                oriented.append(reversed(path))
            }
        }
        // Selection sort on the first cell: plain, stable and the same in Kotlin.
        var sorted = [[Int]]()
        var taken = Array(repeating: false, count: oriented.count)
        while sorted.count < oriented.count {
            var best = -1
            var index = 0
            while index < oriented.count {
                if !taken[index] && (best < 0 || oriented[index][0] < oriented[best][0]) { best = index }
                index += 1
            }
            taken[best] = true
            sorted.append(oriented[best])
        }
        var ends = Array(repeating: -1, count: size * size)
        var colour = 0
        while colour < sorted.count {
            ends[sorted[colour][0]] = colour
            ends[sorted[colour][sorted[colour].count - 1]] = colour
            colour += 1
        }
        return LinksPuzzle(size: size, ends: ends, solution: sorted)
    }

    /// Steps 1 and 2: a cover of the grid by paths of at least three cells, or nil.
    static func cover(size: Int, average: Int, random: SeededRandom) -> [[Int]]? {
        let cells = size * size
        var owner = Array(repeating: -1, count: cells)
        var paths = [[Int]]()
        var free = cells
        while free > 0 {
            let start = startCell(size: size, owner: owner, random: random)
            let id = paths.count
            var path = [start]
            owner[start] = id
            free -= 1
            let spread = average / 2
            let length = average - spread + random.nextInt(2 * spread + 1)
            while path.count < length {
                // Moves at the last end first, then at the first end.
                var options = [Int]()
                var atEnd = [Bool]()
                let last = path[path.count - 1]
                for next in neighbourCells(size, last) {
                    if owner[next] < 0 && touchesOnly(size, owner, next, id, last) {
                        options.append(next)
                        atEnd.append(true)
                    }
                }
                if path.count > 1 {
                    for next in neighbourCells(size, path[0]) {
                        if owner[next] < 0 && touchesOnly(size, owner, next, id, path[0]) {
                            options.append(next)
                            atEnd.append(false)
                        }
                    }
                }
                if options.isEmpty { break }
                var pick = random.nextInt(options.count)
                if random.nextInt(100) < hugPercent {
                    // The option with the fewest free neighbours (first on ties): hugging the
                    // edge and other paths leaves fewer cells stranded.
                    var fewest = 5
                    var index = 0
                    while index < options.count {
                        let n = freeNeighbours(size, owner, options[index])
                        if n < fewest {
                            fewest = n
                            pick = index
                        }
                        index += 1
                    }
                }
                let cell = options[pick]
                owner[cell] = id
                free -= 1
                if atEnd[pick] {
                    path.append(cell)
                } else {
                    path = [cell] + path
                }
            }
            paths.append(path)
        }
        return joinShort(size: size, paths: paths)
    }

    /// The free cell with the fewest free neighbours; ties drawn at random.
    private static func startCell(size: Int, owner: [Int], random: SeededRandom) -> Int {
        var candidates = [Int]()
        var fewest = 5
        var cell = 0
        while cell < size * size {
            if owner[cell] < 0 {
                var n = 0
                for next in neighbourCells(size, cell) {
                    if owner[next] < 0 { n += 1 }
                }
                if n < fewest {
                    fewest = n
                    candidates = [cell]
                } else if n == fewest {
                    candidates.append(cell)
                }
            }
            cell += 1
        }
        return candidates[random.nextInt(candidates.count)]
    }

    private static func freeNeighbours(_ size: Int, _ owner: [Int], _ cell: Int) -> Int {
        var n = 0
        for next in neighbourCells(size, cell) {
            if owner[next] < 0 { n += 1 }
        }
        return n
    }

    /// `cell` has no neighbour owned by `id` other than `from`.
    private static func touchesOnly(_ size: Int, _ owner: [Int], _ cell: Int, _ id: Int, _ from: Int) -> Bool {
        for next in neighbourCells(size, cell) {
            if next != from && owner[next] == id { return false }
        }
        return true
    }

    /// Step 2: joins every path shorter than three cells to a neighbouring path end.
    private static func joinShort(size: Int, paths start: [[Int]]) -> [[Int]]? {
        var paths = start
        var index = 0
        while index < paths.count {
            if paths[index].count >= 3 {
                index += 1
                continue
            }
            guard let joined = joinOne(size: size, paths: paths, index: index) else { return nil }
            paths = joined
            index = 0
        }
        return paths
    }

    /// Joins path `index` with the first neighbouring path end that keeps the joined path
    /// free of sideways touching (ends of `index` first-last, neighbours in order); nil if none.
    private static func joinOne(size: Int, paths: [[Int]], index: Int) -> [[Int]]? {
        let short = paths[index]
        var side = 0
        while side < 2 {
            // `mine` ends at the cell that gets joined.
            let mine = side == 0 ? reversed(short) : short
            let end = mine[mine.count - 1]
            for next in neighbourCells(size, end) {
                var other = 0
                while other < paths.count {
                    if other != index {
                        let path = paths[other]
                        var theirs = [Int]()
                        if path[0] == next {
                            theirs = path
                        } else if path[path.count - 1] == next {
                            theirs = reversed(path)
                        }
                        if !theirs.isEmpty {
                            let merged = mine + theirs
                            if isInduced(size, merged) {
                                var result = [[Int]]()
                                var k = 0
                                while k < paths.count {
                                    if k != index && k != other { result.append(paths[k]) }
                                    k += 1
                                }
                                result.append(merged)
                                return result
                            }
                        }
                    }
                    other += 1
                }
            }
            side += 1
        }
        return nil
    }

    /// No two cells of the path are neighbours unless they are consecutive.
    static func isInduced(_ size: Int, _ path: [Int]) -> Bool {
        var i = 0
        while i < path.count {
            var j = i + 2
            while j < path.count {
                if LinksRules.adjacent(size, path[i], path[j]) { return false }
                j += 1
            }
            i += 1
        }
        return true
    }

    /// Up, left, right, down.
    static func neighbourCells(_ size: Int, _ cell: Int) -> [Int] {
        var result = [Int]()
        let row = cell / size
        let col = cell % size
        if row > 0 { result.append(cell - size) }
        if col > 0 { result.append(cell - 1) }
        if col + 1 < size { result.append(cell + 1) }
        if row + 1 < size { result.append(cell + size) }
        return result
    }

    private static func reversed(_ path: [Int]) -> [Int] {
        var result = [Int]()
        var index = path.count - 1
        while index >= 0 {
            result.append(path[index])
            index -= 1
        }
        return result
    }
}
