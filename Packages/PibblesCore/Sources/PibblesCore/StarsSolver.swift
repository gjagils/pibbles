import Foundation

/// Counts the solutions of a Stars puzzle by backtracking row by row.
///
/// Row r gets its star in a column that is still free, in a region that is still free and
/// at least two columns away from the star of row r-1 (so they do not touch). Columns and
/// regions used are bit masks (at most 16 bits, well within Kotlin's 32-bit `Int`).
/// Pruning: every region still without a star must keep a free cell (free column) in the
/// rows still to fill; otherwise the branch is dropped.
public enum StarsSolver {
    /// Largest size the bit masks are meant for.
    static let maxSize = 16

    /// The number of solutions, at most `limit`. 0 for malformed input: a size outside
    /// 1…16, the wrong number of cells, or region ids that are not exactly 0…size-1.
    public static func countSolutions(size: Int, regions: [Int], limit: Int) -> Int {
        if limit <= 0 || !validRegions(size: size, regions: regions) { return 0 }
        let search = StarsSearch(size: size, regions: regions, limit: limit)
        search.place(0, 0, 0, -2)
        return search.count
    }

    /// The first solution found (star column per row), or nil when there is none.
    static func firstSolution(size: Int, regions: [Int]) -> [Int]? {
        if !validRegions(size: size, regions: regions) { return nil }
        let search = StarsSearch(size: size, regions: regions, limit: 1)
        search.place(0, 0, 0, -2)
        return search.first
    }

    /// Up to `limit` solutions, in search order (columns ascending row by row); empty for
    /// malformed input. The generator uses it to find a rival of its intended solution.
    static func solutions(size: Int, regions: [Int], limit: Int) -> [[Int]] {
        if limit <= 0 || !validRegions(size: size, regions: regions) { return [[Int]]() }
        let search = StarsSearch(size: size, regions: regions, limit: limit)
        search.place(0, 0, 0, -2)
        return search.found
    }

    /// `size` in 1…16, `size`² cells, every id in 0…size-1 and every id used.
    static func validRegions(size: Int, regions: [Int]) -> Bool {
        if size <= 0 || size > maxSize || regions.count != size * size { return false }
        var used = Array(repeating: false, count: size)
        for id in regions {
            if id < 0 || id >= size { return false }
            used[id] = true
        }
        for seen in used {
            if !seen { return false }
        }
        return true
    }
}

private final class StarsSearch {
    let size: Int
    let regions: [Int]
    let limit: Int
    /// `columnsFrom[r * size + g]`: the columns where region g has a cell in rows r…size-1,
    /// as a bit mask.
    let columnsFrom: [Int]
    var count = 0
    var first: [Int]? = nil
    var found = [[Int]]()
    var path: [Int]

    init(size: Int, regions: [Int], limit: Int) {
        self.size = size
        self.regions = regions
        self.limit = limit
        var masks = Array(repeating: 0, count: (size + 1) * size)
        var row = size - 1
        while row >= 0 {
            var region = 0
            while region < size {
                masks[row * size + region] = masks[(row + 1) * size + region]
                region += 1
            }
            var col = 0
            while col < size {
                let id = regions[row * size + col]
                masks[row * size + id] = masks[row * size + id] | (1 << col)
                col += 1
            }
            row -= 1
        }
        self.columnsFrom = masks
        self.path = Array(repeating: 0, count: size)
    }

    /// Places the star of `row`; `columns` and `used` are the masks of columns and regions
    /// taken so far, `previous` the star column of the row above (-2 for none).
    func place(_ row: Int, _ columns: Int, _ used: Int, _ previous: Int) {
        if count >= limit { return }
        if row == size {
            count += 1
            // An explicit copy: `path` keeps changing while the search goes on.
            var copy = [Int]()
            for col in path {
                copy.append(col)
            }
            if first == nil { first = copy }
            found.append(copy)
            return
        }
        // Every region still open needs a free column in the rows left.
        var region = 0
        while region < size {
            if (used & (1 << region)) == 0 {
                if (columnsFrom[row * size + region] & (~columns)) == 0 { return }
            }
            region += 1
        }
        var col = 0
        while col < size {
            let gap = col > previous ? col - previous : previous - col
            if gap > 1 && (columns & (1 << col)) == 0 {
                let id = regions[row * size + col]
                if (used & (1 << id)) == 0 {
                    path[row] = col
                    place(row + 1, columns | (1 << col), used | (1 << id), col)
                    if count >= limit { return }
                }
            }
            col += 1
        }
    }
}
