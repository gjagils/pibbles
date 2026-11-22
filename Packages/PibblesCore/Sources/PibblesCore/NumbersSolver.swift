import Foundation

/// Counts the solutions of a Numbers puzzle with constraint propagation and backtracking.
///
/// Each cell keeps its candidates as a bit mask (bit v set = value v still possible; with
/// at most 6 or so values that fits easily in Kotlin's 32-bit `Int`). Propagation repeats
/// until nothing changes:
/// - a fixed cell removes its value from the other cells in its row and column;
/// - a value with one place left in a row or column goes there (hidden single);
/// - a sign `lo < hi` keeps in `lo` only values below the largest candidate of `hi`, and
///   in `hi` only values above the smallest candidate of `lo`.
/// Then the search branches on the cell with the fewest candidates, values ascending.
public enum NumbersSolver {
    /// The number of solutions, at most `limit`. 0 for malformed input (wrong lengths,
    /// givens outside 1…size, relations outside the grid).
    public static func countSolutions(size: Int, givens: [Int], relations: [NumbersRelation], limit: Int) -> Int {
        if size <= 0 || limit <= 0 || givens.count != size * size { return 0 }
        for relation in relations {
            if relation.lo < 0 || relation.lo >= size * size || relation.hi < 0 || relation.hi >= size * size {
                return 0
            }
            if relation.lo == relation.hi { return 0 }
        }
        let search = NumbersSearch(size: size, relations: relations, limit: limit)
        var candidates = Array(repeating: search.full, count: size * size)
        var i = 0
        while i < size * size {
            let given = givens[i]
            if given != 0 {
                if given < 1 || given > size { return 0 }
                candidates[i] = NumbersBits.bit(given)
            }
            i += 1
        }
        search.solve(candidates)
        return search.count
    }

    /// The first solution found (row by row), or nil when there is none. Used by tests.
    static func firstSolution(size: Int, givens: [Int], relations: [NumbersRelation]) -> [Int]? {
        if size <= 0 || givens.count != size * size { return nil }
        let search = NumbersSearch(size: size, relations: relations, limit: 1)
        var candidates = Array(repeating: search.full, count: size * size)
        var i = 0
        while i < size * size {
            if givens[i] != 0 { candidates[i] = NumbersBits.bit(givens[i]) }
            i += 1
        }
        search.solve(candidates)
        return search.first
    }
}

/// Bit helpers, with explicit parentheses everywhere: Kotlin's infix `and`/`shl` bind
/// more loosely than Swift's `&`/`<<`.
enum NumbersBits {
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
            total += rest & 1
            rest = rest >> 1
        }
        return total
    }

    /// The smallest value in a non-empty mask.
    static func lowest(_ mask: Int, _ size: Int) -> Int {
        var value = 1
        while value <= size {
            if has(mask, value) { return value }
            value += 1
        }
        return 0
    }

    /// The largest value in a non-empty mask.
    static func highest(_ mask: Int, _ size: Int) -> Int {
        var value = size
        while value >= 1 {
            if has(mask, value) { return value }
            value -= 1
        }
        return 0
    }

    /// The single value of a mask with exactly one bit, else 0.
    static func single(_ mask: Int, _ size: Int) -> Int {
        if count(mask) != 1 { return 0 }
        return lowest(mask, size)
    }
}

private final class NumbersSearch {
    let size: Int
    let limit: Int
    let full: Int
    let relations: [NumbersRelation]
    /// Rows then columns: each a list of cell indices.
    let units: [[Int]]
    /// Per cell the other cells in its row and column.
    let peers: [[Int]]
    /// `below[v]`: the values 1…v-1; `above[v]`: the values v+1…size.
    let below: [Int]
    let above: [Int]
    var count = 0
    var first: [Int]? = nil

    init(size: Int, relations: [NumbersRelation], limit: Int) {
        self.size = size
        self.limit = limit
        self.relations = relations
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
        var belowList = [Int]()
        var aboveList = [Int]()
        let allMask = (1 << (size + 1)) - 2
        var v = 0
        while v <= size + 1 {
            // Values 1…v-1: bits 1…v-1.
            let low = v <= 1 ? 0 : ((1 << v) - 2)
            belowList.append(low & allMask)
            // Values v+1…size.
            let upTo = v >= size ? allMask : ((1 << (v + 1)) - 2)
            aboveList.append(allMask & (~upTo))
            v += 1
        }
        self.below = belowList
        self.above = aboveList
    }

    func solve(_ start: [Int]) {
        if count >= limit { return }
        guard let candidates = propagate(start) else { return }
        var best = -1
        var bestCount = size + 1
        var i = 0
        while i < size * size {
            let c = NumbersBits.count(candidates[i])
            if c > 1 && c < bestCount {
                best = i
                bestCount = c
            }
            i += 1
        }
        if best < 0 {
            count += 1
            if first == nil {
                var solution = [Int]()
                for mask in candidates {
                    solution.append(NumbersBits.lowest(mask, size))
                }
                first = solution
            }
            return
        }
        var value = 1
        while value <= size {
            if NumbersBits.has(candidates[best], value) {
                var next = candidates
                next[best] = NumbersBits.bit(value)
                solve(next)
                if count >= limit { return }
            }
            value += 1
        }
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
                if NumbersBits.count(mask) == 1 {
                    for peer in peers[cell] {
                        if (cand[peer] & mask) != 0 {
                            let reduced = cand[peer] & (~mask)
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
                        if NumbersBits.has(cand[index], value) {
                            places += 1
                            place = index
                        }
                    }
                    if places == 0 { return nil }
                    if places == 1 && cand[place] != NumbersBits.bit(value) {
                        cand[place] = NumbersBits.bit(value)
                        changed = true
                    }
                    value += 1
                }
            }
            // Signs: lo below the largest of hi, hi above the smallest of lo.
            for relation in relations {
                let loMask = cand[relation.lo]
                let hiMask = cand[relation.hi]
                if loMask == 0 || hiMask == 0 { return nil }
                let maxHi = NumbersBits.highest(hiMask, size)
                let minLo = NumbersBits.lowest(loMask, size)
                let newLo = loMask & below[maxHi]
                let newHi = hiMask & above[minLo]
                if newLo == 0 || newHi == 0 { return nil }
                if newLo != loMask {
                    cand[relation.lo] = newLo
                    changed = true
                }
                if newHi != hiMask {
                    cand[relation.hi] = newHi
                    changed = true
                }
            }
        }
        return cand
    }
}
