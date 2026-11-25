import Foundation

/// Generates the daily Sums puzzle. The same weekday and seed give the same puzzle in Swift
/// and in Skip's Kotlin: only `SeededRandom.next()`/`nextInt(_:)`, no `Set` or `Dictionary`
/// order, all loops over arrays in index order.
///
/// Per attempt:
/// 1. A random Latin square (`solution`), filled cell by cell with randomised backtracking.
/// 2. Random connected cages (`randomCages`): cells in random order; each cell not yet in a
///    cage starts one with a target size drawn from the weekday's weights (1…4 cells; easier
///    days more single cells and pairs, harder days more triples and quads) and grows by a
///    random free orthogonal neighbour of the cage until the target is reached or no free
///    neighbour is left. A number appears at most once in a cage, so a neighbour whose
///    number the cage already holds is not free. A cell that wanted company but is boxed in
///    joins the smallest neighbouring cage with fewer than four cells that lacks its number.
/// 3. The sums follow from the solution. When the solver finds a second solution, a cell is
///    picked at random among the cells where the two differ and split off its cage as a
///    single cell (the rest of that cage is split into its connected parts). At most
///    `maxSplits[weekday]` splits; after that the attempt is dropped and the next one starts
///    with the same random stream.
/// The last attempt splits until the puzzle is unique, which always ends: a differing cell
/// is never a single cell, so every split adds a cage, and all single cells are unique.
public enum SumsGenerator {
    /// Grid size per weekday, Monday 0 … Sunday 6.
    public static let sizes: [Int] = [4, 4, 5, 5, 5, 6, 6]
    /// Weights for cages of 1, 2, 3 and 4 cells, per weekday.
    static let cageWeights: [[Int]] = [
        [20, 50, 25, 5],
        [10, 50, 30, 10],
        [20, 45, 30, 5],
        [10, 45, 35, 10],
        [5, 40, 40, 15],
        [12, 45, 33, 10],
        [5, 40, 40, 15],
    ]
    /// Splits allowed per attempt, per weekday: fewer on harder days.
    static let maxSplits: [Int] = [3, 2, 3, 2, 1, 2, 1]
    static let maxAttempts = 40

    public static func generate(weekday: Int, seed: String) -> SumsPuzzle {
        let day = ((weekday % 7) + 7) % 7
        let size = sizes[day]
        let random = SeededRandom(seed: StringHash.fnv1a("sums|\(size)|\(seed)"))
        var attempt = 1
        while attempt < maxAttempts {
            if let built = build(size: size, weights: cageWeights[day], splits: maxSplits[day], random: random) {
                return built
            }
            attempt += 1
        }
        return build(size: size, weights: cageWeights[day], splits: size * size, random: random)
            ?? fallback(size: size)
    }

    /// Never used (the last attempt always ends unique); keeps `generate` total: a cyclic
    /// square with every cell its own cage.
    private static func fallback(size: Int) -> SumsPuzzle {
        var solution = [Int]()
        var cages = [Int]()
        var cell = 0
        while cell < size * size {
            solution.append((cell / size + cell % size) % size + 1)
            cages.append(cell)
            cell += 1
        }
        return SumsPuzzle(size: size, cages: cages, sums: solution, solution: solution)
    }

    /// nil when the puzzle is still ambiguous after `splits` splits.
    private static func build(size: Int, weights: [Int], splits: Int, random: SeededRandom) -> SumsPuzzle? {
        let solution = latinSquare(size: size, random: random)
        var cages = randomCages(size: size, weights: weights, solution: solution, random: random)
        var left = splits
        while true {
            let sums = cageSums(cages, solution)
            let found = SumsSolver.solutions(size: size, cages: cages, sums: sums, limit: 2)
            if found.count == 1 {
                return SumsPuzzle(size: size, cages: cages, sums: sums, solution: solution)
            }
            if found.isEmpty || left <= 0 { return nil }
            let other = found[0] == solution ? found[1] : found[0]
            var differing = [Int]()
            var cell = 0
            while cell < size * size {
                if other[cell] != solution[cell] { differing.append(cell) }
                cell += 1
            }
            let picked = differing[random.nextInt(differing.count)]
            cages = splitOff(cages, cell: picked, size: size)
            left -= 1
        }
    }

    static func cageSums(_ cages: [Int], _ solution: [Int]) -> [Int] {
        var count = 0
        for id in cages {
            if id + 1 > count { count = id + 1 }
        }
        var sums = Array(repeating: 0, count: count)
        var cell = 0
        while cell < cages.count {
            sums[cages[cell]] += solution[cell]
            cell += 1
        }
        return sums
    }

    /// Orthogonal neighbours of a cell, in the order up, left, right, down.
    static func neighbours(_ cell: Int, _ size: Int) -> [Int] {
        var list = [Int]()
        let row = cell / size
        let col = cell % size
        if row > 0 { list.append(cell - size) }
        if col > 0 { list.append(cell - 1) }
        if col + 1 < size { list.append(cell + 1) }
        if row + 1 < size { list.append(cell + size) }
        return list
    }

    /// True when a cell of cage `id` holds `value`.
    static func cageHolds(_ cage: [Int], _ id: Int, _ value: Int, _ solution: [Int]) -> Bool {
        var cell = 0
        while cell < cage.count {
            if cage[cell] == id && solution[cell] == value { return true }
            cell += 1
        }
        return false
    }

    /// Step 2: random connected cages with distinct numbers, ids renumbered in order of each
    /// cage's first cell.
    static func randomCages(size: Int, weights: [Int], solution: [Int], random: SeededRandom) -> [Int] {
        let cells = size * size
        var cage = Array(repeating: -1, count: cells)
        var cageSize = [Int]()
        var total = 0
        for weight in weights {
            total += weight
        }
        for start in shuffled(range(cells), random) {
            if cage[start] >= 0 { continue }
            // Target size 1…4 from the weights.
            var draw = random.nextInt(total)
            var target = 1
            var w = 0
            while w < weights.count {
                if draw < weights[w] {
                    target = w + 1
                    break
                }
                draw -= weights[w]
                w += 1
            }
            let id = cageSize.count
            cage[start] = id
            cageSize.append(1)
            var members = [start]
            while members.count < target {
                var frontier = [Int]()
                var cell = 0
                while cell < cells {
                    if cage[cell] < 0 && !cageHolds(cage, id, solution[cell], solution) {
                        for neighbour in neighbours(cell, size) {
                            if cage[neighbour] == id {
                                frontier.append(cell)
                                break
                            }
                        }
                    }
                    cell += 1
                }
                if frontier.isEmpty { break }
                let pick = frontier[random.nextInt(frontier.count)]
                cage[pick] = id
                cageSize[id] += 1
                members.append(pick)
            }
            if members.count == 1 && target > 1 {
                // Boxed in: join the smallest neighbouring cage with room.
                var best = -1
                for neighbour in neighbours(start, size) {
                    let other = cage[neighbour]
                    if other < 0 || other == id || cageSize[other] >= 4 { continue }
                    if cageHolds(cage, other, solution[start], solution) { continue }
                    if best < 0 || cageSize[other] < cageSize[best] { best = other }
                }
                if best >= 0 {
                    cage[start] = best
                    cageSize[best] += 1
                    cageSize[id] = 0
                }
            }
        }
        return normalized(cage)
    }

    /// Takes `cell` out of its cage as a single cell; the rest of that cage is split into
    /// its connected parts.
    static func splitOff(_ cages: [Int], cell: Int, size: Int) -> [Int] {
        var result = cages
        let old = cages[cell]
        var nextId = 0
        for id in cages {
            if id + 1 > nextId { nextId = id + 1 }
        }
        result[cell] = nextId
        nextId += 1
        // Flood the remaining cells of the old cage: the first part keeps its id.
        var assigned = Array(repeating: false, count: size * size)
        var first = true
        var seed = 0
        while seed < size * size {
            if result[seed] == old && !assigned[seed] {
                let id = first ? old : nextId
                if !first { nextId += 1 }
                first = false
                var queue = [seed]
                assigned[seed] = true
                var index = 0
                while index < queue.count {
                    let current = queue[index]
                    result[current] = id
                    for neighbour in neighbours(current, size) {
                        if cages[neighbour] == old && neighbour != cell && !assigned[neighbour] {
                            assigned[neighbour] = true
                            queue.append(neighbour)
                        }
                    }
                    index += 1
                }
            }
            seed += 1
        }
        return normalized(result)
    }

    /// Renumbers cage ids 0..k-1 in order of each cage's first cell (unused ids vanish).
    static func normalized(_ cages: [Int]) -> [Int] {
        var maxId = -1
        for id in cages {
            if id > maxId { maxId = id }
        }
        var mapping = Array(repeating: -1, count: maxId + 1)
        var next = 0
        var result = [Int]()
        for id in cages {
            if mapping[id] < 0 {
                mapping[id] = next
                next += 1
            }
            result.append(mapping[id])
        }
        return result
    }

    private static func range(_ count: Int) -> [Int] {
        var list = [Int]()
        var i = 0
        while i < count {
            list.append(i)
            i += 1
        }
        return list
    }

    /// Fisher-Yates from the back, with `nextInt`.
    static func shuffled(_ list: [Int], _ random: SeededRandom) -> [Int] {
        var result = list
        var i = result.count - 1
        while i > 0 {
            let j = random.nextInt(i + 1)
            let keep = result[i]
            result[i] = result[j]
            result[j] = keep
            i -= 1
        }
        return result
    }

    /// A random Latin square, row by row, values 1…size: cell by cell, each cell trying the
    /// values in a fresh random order and backtracking on a dead end.
    static func latinSquare(size: Int, random: SeededRandom) -> [Int] {
        let filler = SumsLatinFiller(size: size, random: random)
        if filler.fill(0) { return filler.grid }
        // Unreachable (a Latin square always exists); a cyclic square keeps this total.
        var grid = [Int]()
        var cell = 0
        while cell < size * size {
            grid.append((cell / size + cell % size) % size + 1)
            cell += 1
        }
        return grid
    }
}

private final class SumsLatinFiller {
    let size: Int
    let random: SeededRandom
    var grid: [Int]

    init(size: Int, random: SeededRandom) {
        self.size = size
        self.random = random
        self.grid = Array(repeating: 0, count: size * size)
    }

    func fill(_ cell: Int) -> Bool {
        if cell == size * size { return true }
        let row = cell / size
        let col = cell % size
        var values = [Int]()
        var v = 1
        while v <= size {
            values.append(v)
            v += 1
        }
        for value in SumsGenerator.shuffled(values, random) {
            if fits(value, row, col) {
                grid[cell] = value
                if fill(cell + 1) { return true }
                grid[cell] = 0
            }
        }
        return false
    }

    private func fits(_ value: Int, _ row: Int, _ col: Int) -> Bool {
        var k = 0
        while k < col {
            if grid[row * size + k] == value { return false }
            k += 1
        }
        k = 0
        while k < row {
            if grid[k * size + col] == value { return false }
            k += 1
        }
        return true
    }
}
