import Foundation

/// Counts the solutions of a Sums puzzle with constraint propagation and backtracking.
///
/// Each cell keeps its candidates as a bit mask (bit v set = value v still possible; sizes
/// up to 16 fit easily in Kotlin's 32-bit `Int`). Propagation repeats until nothing changes:
/// - a fixed cell removes its value from the other cells in its row and column;
/// - a value with one place left in a row or column goes there (hidden single);
/// - cage bounds: with `min`/`max` the sums of the smallest/largest candidates of the cage's
///   cells, a cell may only keep values v with
///   `sum - (max - largest(cell)) <= v <= sum - (min - smallest(cell))`;
/// - a two-cell cage keeps in each cell only values whose partner `sum - v` is still a
///   candidate of the other cell.
/// Then the search branches on the cell with the fewest candidates, values ascending.
public enum SumsSolver {
    /// The number of solutions, at most `limit`. 0 for malformed input: size outside 1…16,
    /// `cages` not one id per cell, an id outside `sums`, or an id without cells.
    public static func countSolutions(size: Int, cages: [Int], sums: [Int], limit: Int) -> Int {
        guard let search = makeSearch(size: size, cages: cages, sums: sums, limit: limit) else { return 0 }
        search.solve(Array(repeating: search.full, count: size * size))
        return search.count
    }

    /// Up to `limit` solutions (row by row), in search order. Used by the generator.
    static func solutions(size: Int, cages: [Int], sums: [Int], limit: Int) -> [[Int]] {
        guard let search = makeSearch(size: size, cages: cages, sums: sums, limit: limit) else { return [[Int]]() }
        search.solve(Array(repeating: search.full, count: size * size))
        return search.found
    }

    /// The first solution found, or nil when there is none. Used by tests.
    static func firstSolution(size: Int, cages: [Int], sums: [Int]) -> [Int]? {
        let list = solutions(size: size, cages: cages, sums: sums, limit: 1)
        if list.isEmpty { return nil }
        return list[0]
    }

    private static func makeSearch(size: Int, cages: [Int], sums: [Int], limit: Int) -> SumsSearch? {
        if size <= 0 || size > 16 || limit <= 0 || cages.count != size * size || sums.isEmpty { return nil }
        var cageCells = [[Int]]()
        var id = 0
        while id < sums.count {
            cageCells.append([Int]())
            id += 1
        }
        var cell = 0
        while cell < size * size {
            let cage = cages[cell]
            if cage < 0 || cage >= sums.count { return nil }
            cageCells[cage].append(cell)
            cell += 1
        }
        for list in cageCells {
            if list.isEmpty { return nil }
        }
        return SumsSearch(size: size, cageCells: cageCells, sums: sums, limit: limit)
    }
}

/// Bit helpers, with explicit parentheses everywhere: Kotlin's infix `and`/`shl` bind
/// more loosely than Swift's `&`/`<<`.
enum SumsBits {
    static func bit(_ value: Int) -> Int {
        return 1 << value
    }

    static func has(_ mask: Int, _ value: Int) -> Bool {
        return (mask & (1 << value)) != 0
    }

    static func count(_ mask: Int) -> Int {
        var rest = mask
        var total = 0
        while rest != 0 {
            total += (rest & 1)
            rest = (rest >> 1)
        }
        return total
    }

    /// The smallest value in a non-empty mask, 0 for an empty one.
    static func lowest(_ mask: Int, _ size: Int) -> Int {
        var value = 1
        while value <= size {
            if has(mask, value) { return value }
            value += 1
        }
        return 0
    }

    /// The largest value in a non-empty mask, 0 for an empty one.
    static func highest(_ mask: Int, _ size: Int) -> Int {
        var value = size
        while value >= 1 {
            if has(mask, value) { return value }
            value -= 1
        }
        return 0
    }
}

private final class SumsSearch {
    let size: Int
    let limit: Int
    let full: Int
    let cageCells: [[Int]]
    let sums: [Int]
    /// Rows then columns: each a list of cell indices.
    let units: [[Int]]
    /// Per cell the other cells in its row and column.
    let peers: [[Int]]
    var count = 0
    var found = [[Int]]()

    init(size: Int, cageCells: [[Int]], sums: [Int], limit: Int) {
        self.size = size
        self.limit = limit
        self.cageCells = cageCells
        self.sums = sums
        self.full = (1 << (size + 1)) - 2
        var unitList = [[Int]]()
        var row = 0
        while row < size {
            var unit = [Int]()
            var col = 0
            while col < size {
                unit.append(row * size + col)
                col += 1
            }
            unitList.append(unit)
            row += 1
        }
        var column = 0
        while column < size {
            var unit = [Int]()
            var r = 0
            while r < size {
                unit.append(r * size + column)
                r += 1
            }
            unitList.append(unit)
            column += 1
        }
        self.units = unitList
        var peerList = [[Int]]()
        var cell = 0
        while cell < size * size {
            var list = [Int]()
            let cellRow = cell / size
            let cellCol = cell % size
            var k = 0
            while k < size {
                if k != cellCol { list.append(cellRow * size + k) }
                if k != cellRow { list.append(k * size + cellCol) }
                k += 1
            }
            peerList.append(list)
            cell += 1
        }
        self.peers = peerList
    }

    func solve(_ start: [Int]) {
        if count >= limit { return }
        guard let candidates = propagate(start) else { return }
        var best = -1
        var bestCount = size + 1
        var i = 0
        while i < size * size {
            let c = SumsBits.count(candidates[i])
            if c > 1 && c < bestCount {
                best = i
                bestCount = c
            }
            i += 1
        }
        if best < 0 {
            count += 1
            var solution = [Int]()
            for mask in candidates {
                solution.append(SumsBits.lowest(mask, size))
            }
            found.append(solution)
            return
        }
        var value = 1
        while value <= size {
            if SumsBits.has(candidates[best], value) {
                var next = candidates
                next[best] = SumsBits.bit(value)
                solve(next)
                if count >= limit { return }
            }
            value += 1
        }
    }

    /// The values low…high (clipped to 1…size) as a mask.
    private func rangeMask(_ low: Int, _ high: Int) -> Int {
        var mask = 0
        var value = low < 1 ? 1 : low
        while value <= size && value <= high {
            mask = (mask | (1 << value))
            value += 1
        }
        return mask
    }

    /// Applies the rules until nothing changes; nil when a cell runs out of candidates.
    private func propagate(_ start: [Int]) -> [Int]? {
        var cand = start
        var changed = true
        while changed {
            changed = false
            // Fixed cells clear their value from their peers.
            var cell = 0
            while cell < size * size {
                let mask = cand[cell]
                if mask == 0 { return nil }
                if SumsBits.count(mask) == 1 {
                    for peer in peers[cell] {
                        if (cand[peer] & mask) != 0 {
                            let reduced = (cand[peer] & (~mask))
                            if reduced == 0 { return nil }
                            cand[peer] = reduced
                            changed = true
                        }
                    }
                }
                cell += 1
            }
            // Hidden singles: a value with one place left in a row or column.
            for unit in units {
                var value = 1
                while value <= size {
                    var places = 0
                    var place = -1
                    for index in unit {
                        if SumsBits.has(cand[index], value) {
                            places += 1
                            place = index
                        }
                    }
                    if places == 0 { return nil }
                    if places == 1 && cand[place] != SumsBits.bit(value) {
                        cand[place] = SumsBits.bit(value)
                        changed = true
                    }
                    value += 1
                }
            }
            // Cage sums. The totals are computed once per cage per round; when a cell
            // shrinks they only get looser, so the bounds stay sound.
            var cage = 0
            while cage < cageCells.count {
                let cells = cageCells[cage]
                let target = sums[cage]
                var minTotal = 0
                var maxTotal = 0
                for c in cells {
                    let mask = cand[c]
                    if mask == 0 { return nil }
                    minTotal += SumsBits.lowest(mask, size)
                    maxTotal += SumsBits.highest(mask, size)
                }
                if target < minTotal || target > maxTotal { return nil }
                for c in cells {
                    let mask = cand[c]
                    let low = target - (maxTotal - SumsBits.highest(mask, size))
                    let high = target - (minTotal - SumsBits.lowest(mask, size))
                    var reduced = (mask & rangeMask(low, high))
                    if cells.count == 2 {
                        let partner = c == cells[0] ? cells[1] : cells[0]
                        var paired = 0
                        var value = 1
                        while value <= size {
                            let other = target - value
                            if SumsBits.has(reduced, value) && other >= 1 && other <= size
                                && SumsBits.has(cand[partner], other) {
                                paired = (paired | (1 << value))
                            }
                            value += 1
                        }
                        reduced = paired
                    }
                    if reduced == 0 { return nil }
                    if reduced != mask {
                        cand[c] = reduced
                        changed = true
                    }
                }
                cage += 1
            }
        }
        return cand
    }
}
