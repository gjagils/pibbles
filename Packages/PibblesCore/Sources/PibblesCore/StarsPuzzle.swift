import Foundation

/// Stars (Star Battle with one star): an n×n grid split into n connected regions. Place
/// exactly one star in every row, every column and every region; no two stars touch, not
/// even diagonally. Exactly one solution.
/// JSON: `{"size":6,"regions":[0,0,1,...],"solution":[5,2,4,1,3,0]}`.
public struct StarsPuzzle: Hashable, Codable, Sendable {
    public let size: Int
    /// Region id 0…size-1 per cell, row by row (index = row × size + col).
    public let regions: [Int]
    /// The column of the star in each row.
    public let solution: [Int]

    public init(size: Int, regions: [Int], solution: [Int]) {
        self.size = size
        self.regions = regions
        self.solution = solution
    }
}

/// The rules the play screen asks. `stars` holds per cell, row by row: 0 empty, 1 marked
/// "no star" by the player, 2 star. Only stars count; marks never matter to the rules.
public enum StarsRules {
    /// Solved when there are exactly `size` stars and none breaks a rule. Checks the rules,
    /// not the stored solution (with a unique puzzle those agree).
    public static func isSolved(_ puzzle: StarsPuzzle, stars: [Int]) -> Bool {
        let n = puzzle.size
        if n <= 0 || stars.count != n * n || puzzle.regions.count != n * n { return false }
        var count = 0
        for value in stars {
            if value == 2 { count += 1 }
        }
        // n stars with no two in a row fill every row; the same holds for columns and
        // regions (when the region ids are 0…n-1).
        if count != n { return false }
        if !StarsSolver.validRegions(size: n, regions: puzzle.regions) { return false }
        return conflicts(puzzle, stars: stars).isEmpty
    }

    /// Indices (ascending) of stars that break a rule: another star in the same row, column
    /// or region, or a star on one of the eight neighbouring cells.
    public static func conflicts(_ puzzle: StarsPuzzle, stars: [Int]) -> [Int] {
        let n = puzzle.size
        if n <= 0 || stars.count != n * n || puzzle.regions.count != n * n { return [Int]() }
        var placed = [Int]()
        var cell = 0
        while cell < n * n {
            if stars[cell] == 2 { placed.append(cell) }
            cell += 1
        }
        var bad = Array(repeating: false, count: n * n)
        var a = 0
        while a < placed.count {
            var b = a + 1
            while b < placed.count {
                if clash(placed[a], placed[b], n, puzzle.regions) {
                    bad[placed[a]] = true
                    bad[placed[b]] = true
                }
                b += 1
            }
            a += 1
        }
        var result = [Int]()
        cell = 0
        while cell < n * n {
            if bad[cell] { result.append(cell) }
            cell += 1
        }
        return result
    }

    /// Indices (ascending) of empty cells (0) that can no longer hold a star because of the
    /// placed stars: same row, column or region as a star, or touching one. The UI may draw
    /// them faded.
    public static func autoMarks(_ puzzle: StarsPuzzle, stars: [Int]) -> [Int] {
        let n = puzzle.size
        if n <= 0 || stars.count != n * n || puzzle.regions.count != n * n { return [Int]() }
        var placed = [Int]()
        var cell = 0
        while cell < n * n {
            if stars[cell] == 2 { placed.append(cell) }
            cell += 1
        }
        var result = [Int]()
        cell = 0
        while cell < n * n {
            if stars[cell] == 0 {
                for star in placed {
                    if clash(cell, star, n, puzzle.regions) {
                        result.append(cell)
                        break
                    }
                }
            }
            cell += 1
        }
        return result
    }

    /// Two different cells that cannot both hold a star.
    static func clash(_ a: Int, _ b: Int, _ n: Int, _ regions: [Int]) -> Bool {
        let rowA = a / n
        let colA = a % n
        let rowB = b / n
        let colB = b % n
        if rowA == rowB || colA == colB { return true }
        if regions[a] == regions[b] { return true }
        let rowGap = rowA > rowB ? rowA - rowB : rowB - rowA
        let colGap = colA > colB ? colA - colB : colB - colA
        return rowGap <= 1 && colGap <= 1
    }
}
