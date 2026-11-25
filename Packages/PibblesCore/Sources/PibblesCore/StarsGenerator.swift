import Foundation

/// The result of one generation, with the number of attempts it took (for tests and
/// timing).
struct StarsGeneration {
    let puzzle: StarsPuzzle
    let attempts: Int
}

/// Generates the daily Stars puzzle. The same weekday and seed give the same puzzle in
/// Swift and in Skip's Kotlin: only `SeededRandom.next()`/`nextInt(_:)`, no `Set` or
/// `Dictionary` order, all loops over arrays in index order.
///
/// Per attempt:
/// 1. A star placement (`solution`): a random permutation with no neighbouring columns in
///    consecutive rows, built row by row with randomised backtracking. Size 5 has only 14
///    placements; that is plenty, because the regions do the work.
/// 2. Regions grown from the stars: the star of row r starts region r. Each step picks a
///    region at random among those that can still grow (so small regions grow as often as
///    big ones and none stays a single cell by bad luck), then one of its (empty cell,
///    touching side) pairs at random. Counting a cell once per touching side favours cells
///    in a region's bend, so regions come out rounder than with a plain frontier.
/// 3. Repair, at most `maxRepairs` times: the solver looks for two solutions. If it finds
///    a rival of the intended one, a star cell of the rival that is not an intended star
///    moves to a neighbouring region (chosen at random among the moves that keep its own
///    region connected). The rival then has two stars in that region and none in the old
///    one, so it is gone; the intended solution is untouched. New rivals may appear, hence
///    the loop.
/// 4. Accepted when the solver proves exactly one solution and, for the first
///    `strictAttempts` attempts, the shapes are good: no region of a single cell and no
///    region that is a straight line of four or more cells.
/// After `maxAttempts` a fixed puzzle per size is returned (`fallback`); not needed for any
/// tested seed, but it keeps `generate` total.
public enum StarsGenerator {
    /// Grid size per weekday, Monday 0 … Sunday 6.
    public static let sizes: [Int] = [5, 5, 6, 6, 6, 7, 7]
    static let maxRepairs = 40
    /// Measured over 400 seeds per size: on average 1 (size 5) to 10 (size 8) attempts, at
    /// worst 51 for size 8. The limits leave a wide margin.
    static let strictAttempts = 200
    static let maxAttempts = 300

    public static func generate(weekday: Int, seed: String) -> StarsPuzzle {
        return generation(weekday: weekday, seed: seed).puzzle
    }

    static func generation(weekday: Int, seed: String) -> StarsGeneration {
        let day = ((weekday % 7) + 7) % 7
        let size = sizes[day]
        let random = SeededRandom(seed: StringHash.fnv1a("stars|\(size)|\(seed)"))
        var attempt = 0
        while attempt < maxAttempts {
            let strict = attempt < strictAttempts
            let solution = placement(size: size, random: random)
            let regions = growRegions(size: size, solution: solution, random: random)
            if repair(size: size, regions: regions, solution: solution, strict: strict, random: random) {
                if !strict || goodShapes(size: size, regions: regions) {
                    return StarsGeneration(puzzle: StarsPuzzle(size: size, regions: regions.ids, solution: solution),
                                           attempts: attempt + 1)
                }
            }
            attempt += 1
        }
        return StarsGeneration(puzzle: fallback(size: size), attempts: maxAttempts)
    }

    /// Step 3. Changes `regions` (a reference type, so no `inout`) until the solver finds
    /// one solution; false when it gives up.
    private static func repair(size: Int, regions: StarsRegions, solution: [Int], strict: Bool,
                               random: SeededRandom) -> Bool {
        var round = 0
        while round <= maxRepairs {
            let found = StarsSolver.solutions(size: size, regions: regions.ids, limit: 2)
            if found.count == 1 { return true }
            if found.count == 0 || round == maxRepairs { return false }
            let rival = found[0] == solution ? found[1] : found[0]
            var moveCells = [Int]()
            var moveRegions = [Int]()
            var row = 0
            while row < size {
                if rival[row] != solution[row] {
                    let cell = row * size + rival[row]
                    let own = regions.ids[cell]
                    if regions.staysConnected(without: cell, minimum: strict ? 2 : 1) {
                        for other in neighbours(cell, size) {
                            let target = regions.ids[other]
                            if target != own {
                                moveCells.append(cell)
                                moveRegions.append(target)
                            }
                        }
                    }
                }
                row += 1
            }
            if moveCells.isEmpty { return false }
            let pick = random.nextInt(moveCells.count)
            regions.ids[moveCells[pick]] = moveRegions[pick]
            round += 1
        }
        return false
    }

    /// Orthogonal neighbours in a fixed order: up, left, right, down.
    static func neighbours(_ cell: Int, _ size: Int) -> [Int] {
        let r = cell / size
        let c = cell % size
        var list = [Int]()
        if r > 0 { list.append(cell - size) }
        if c > 0 { list.append(cell - 1) }
        if c + 1 < size { list.append(cell + 1) }
        if r + 1 < size { list.append(cell + size) }
        return list
    }

    /// A random placement: per row a fresh random column order, backtracking on a dead end.
    static func placement(size: Int, random: SeededRandom) -> [Int] {
        let placer = StarsPlacer(size: size, random: random)
        if placer.fill(0) { return placer.columns }
        // Unreachable for sizes 4 and up (a placement always exists).
        var columns = [Int]()
        var row = 0
        while row < size {
            columns.append(row)
            row += 1
        }
        return columns
    }

    /// Step 2: grows `size` connected regions from the stars (region r holds the star of
    /// row r).
    static func growRegions(size: Int, solution: [Int], random: SeededRandom) -> StarsRegions {
        let cells = size * size
        var ids = Array(repeating: -1, count: cells)
        var row = 0
        while row < size {
            ids[row * size + solution[row]] = row
            row += 1
        }
        var remaining = cells - size
        while remaining > 0 {
            // Per region the (empty cell, touching side) pairs, in cell order.
            var pairCells = [Int]()
            var pairRegions = [Int]()
            var cell = 0
            while cell < cells {
                if ids[cell] < 0 {
                    for other in neighbours(cell, size) {
                        if ids[other] >= 0 {
                            pairCells.append(cell)
                            pairRegions.append(ids[other])
                        }
                    }
                }
                cell += 1
            }
            var growing = [Int]()
            var region = 0
            while region < size {
                if pairRegions.contains(region) { growing.append(region) }
                region += 1
            }
            // Never empty: the grid is connected and at least one cell is taken.
            let chosen = growing[random.nextInt(growing.count)]
            var options = [Int]()
            var index = 0
            while index < pairCells.count {
                if pairRegions[index] == chosen { options.append(pairCells[index]) }
                index += 1
            }
            ids[options[random.nextInt(options.count)]] = chosen
            remaining -= 1
        }
        return StarsRegions(size: size, ids: ids)
    }

    /// No region of one cell and no region that is a straight line of four or more cells.
    static func goodShapes(size: Int, regions: StarsRegions) -> Bool {
        var region = 0
        while region < size {
            var count = 0
            var minRow = size
            var maxRow = -1
            var minCol = size
            var maxCol = -1
            var cell = 0
            while cell < size * size {
                if regions.ids[cell] == region {
                    count += 1
                    let r = cell / size
                    let c = cell % size
                    if r < minRow { minRow = r }
                    if r > maxRow { maxRow = r }
                    if c < minCol { minCol = c }
                    if c > maxCol { maxCol = c }
                }
                cell += 1
            }
            if count < 2 { return false }
            if count >= 4 && (minRow == maxRow || minCol == maxCol) { return false }
            region += 1
        }
        return true
    }

    /// Fixed puzzles, one per size, each proven unique by a test; used only when
    /// `maxAttempts` runs out. Generated with seed `fallback`. Sizes outside the table
    /// (never asked for) get the 8×8 one.
    static func fallback(size: Int) -> StarsPuzzle {
        if size == 5 {
            return StarsPuzzle(size: 5, regions: [1, 1, 1, 0, 3, 1, 1, 2, 0, 3, 1, 4, 2, 2, 3, 4, 4, 4, 3, 3,
                                                  4, 4, 4, 4, 3],
                               solution: [3, 0, 2, 4, 1])
        }
        if size == 6 {
            return StarsPuzzle(size: 6, regions: [5, 5, 3, 1, 0, 0, 2, 5, 3, 1, 0, 4, 2, 5, 3, 3, 4, 4, 2, 5,
                                                  3, 3, 4, 4, 5, 5, 5, 3, 4, 4, 5, 5, 5, 4, 4, 4],
                               solution: [5, 3, 0, 2, 4, 1])
        }
        if size == 7 {
            return StarsPuzzle(size: 7, regions: [1, 1, 1, 1, 0, 0, 0, 2, 1, 1, 2, 2, 2, 0, 2, 2, 2, 2, 2, 2,
                                                  0, 2, 2, 2, 2, 2, 3, 3, 4, 4, 4, 2, 3, 3, 3, 5, 5, 4, 4, 4,
                                                  4, 3, 5, 5, 6, 6, 4, 3, 3],
                               solution: [5, 1, 4, 6, 2, 0, 3])
        }
        return StarsPuzzle(size: 8, regions: [4, 4, 4, 0, 0, 0, 1, 1, 4, 4, 2, 2, 0, 0, 0, 1, 4, 4, 2, 2,
                                              2, 0, 3, 1, 4, 4, 2, 2, 2, 0, 3, 1, 4, 4, 4, 2, 2, 5, 5, 5,
                                              4, 4, 2, 2, 2, 5, 5, 5, 6, 4, 6, 6, 7, 7, 5, 5, 6, 6, 6, 6,
                                              7, 7, 5, 5],
                           solution: [3, 7, 2, 6, 1, 5, 0, 4])
    }
}

/// Region ids per cell, as a class so the repair step can change them without `inout`.
final class StarsRegions {
    let size: Int
    var ids: [Int]

    init(size: Int, ids: [Int]) {
        self.size = size
        self.ids = ids
    }

    /// Whether the region of `cell` stays one connected piece of at least `minimum` cells
    /// when `cell` leaves it.
    func staysConnected(without cell: Int, minimum: Int) -> Bool {
        let region = ids[cell]
        var start = -1
        var total = 0
        var index = 0
        while index < size * size {
            if index != cell && ids[index] == region {
                total += 1
                if start < 0 { start = index }
            }
            index += 1
        }
        if total < minimum || start < 0 { return false }
        var seen = Array(repeating: false, count: size * size)
        seen[cell] = true
        seen[start] = true
        var stack = [start]
        var reached = 0
        while !stack.isEmpty {
            let current = stack.removeLast()
            reached += 1
            for other in StarsGenerator.neighbours(current, size) {
                if !seen[other] && ids[other] == region {
                    seen[other] = true
                    stack.append(other)
                }
            }
        }
        return reached == total
    }
}

private final class StarsPlacer {
    let size: Int
    let random: SeededRandom
    var columns: [Int]
    var taken: [Bool]

    init(size: Int, random: SeededRandom) {
        self.size = size
        self.random = random
        self.columns = Array(repeating: 0, count: size)
        self.taken = Array(repeating: false, count: size)
    }

    func fill(_ row: Int) -> Bool {
        if row == size { return true }
        var order = [Int]()
        var col = 0
        while col < size {
            order.append(col)
            col += 1
        }
        for candidate in NumbersGenerator.shuffled(order, random) {
            if taken[candidate] { continue }
            if row > 0 {
                let gap = candidate > columns[row - 1] ? candidate - columns[row - 1] : columns[row - 1] - candidate
                if gap <= 1 { continue }
            }
            taken[candidate] = true
            columns[row] = candidate
            if fill(row + 1) { return true }
            taken[candidate] = false
        }
        return false
    }
}
