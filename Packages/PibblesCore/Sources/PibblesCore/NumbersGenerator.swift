import Foundation

/// Generates the daily Numbers puzzle. The same weekday and seed give the same puzzle in
/// Swift and in Skip's Kotlin: only `SeededRandom.next()`/`nextInt(_:)`, no `Set` or
/// `Dictionary` order, all loops over arrays in index order.
///
/// Per attempt:
/// 1. A random Latin square (`solution`), filled cell by cell with randomised backtracking.
/// 2. Givens: cells in random order, taken while `givenCount` is not reached and only when
///    the givens alone still allow more than one Latin square. So the givens never decide
///    the puzzle by themselves: the signs are always needed.
/// 3. Every sign between neighbours. If the puzzle is still ambiguous (two Latin squares
///    can share all signs), the attempt is dropped and the next one starts with the same
///    random stream; only the last attempt adds givens in random order until it is unique.
/// 4. Signs are removed in random order whenever the solver proves the puzzle stays unique.
/// 5. Easier days get `extraRelations` of the removed signs back (the first ones removed).
/// The last attempt is accepted when its givens alone are ambiguous; if step 3 had to add
/// givens and they decide the puzzle alone, it is still returned: valid and unique, so
/// `generate` always terminates with a usable puzzle.
public enum NumbersGenerator {
    /// Grid size per weekday, Monday 0 … Sunday 6.
    public static let sizes: [Int] = [4, 4, 5, 5, 5, 6, 6]
    /// Givens placed in step 2, per weekday: fewer later in the week.
    static let givenCounts: [Int] = [4, 2, 4, 3, 2, 3, 1]
    /// Removed signs given back in step 5, per weekday: none on the hardest days.
    static let extraRelations: [Int] = [3, 1, 3, 2, 0, 2, 0]
    static let maxAttempts = 20

    public static func generate(weekday: Int, seed: String) -> NumbersPuzzle {
        let day = ((weekday % 7) + 7) % 7
        let size = sizes[day]
        let random = SeededRandom(seed: StringHash.fnv1a("numbers|\(size)|\(seed)"))
        var attempt = 1
        while attempt < maxAttempts {
            if let built = build(size: size, givenCount: givenCounts[day], extra: extraRelations[day],
                                 random: random, lastAttempt: false) {
                return built
            }
            attempt += 1
        }
        return build(size: size, givenCount: givenCounts[day], extra: extraRelations[day],
                     random: random, lastAttempt: true) ?? fallback(size: size)
    }

    /// Never used (the last attempt always builds a puzzle); keeps `generate` total: a
    /// cyclic square with every cell given but one row, and every sign of that row.
    private static func fallback(size: Int) -> NumbersPuzzle {
        let solution = cyclicSquare(size: size)
        var givens = solution
        var col = 0
        while col < size {
            givens[col] = 0
            col += 1
        }
        var relations = [NumbersRelation]()
        col = 0
        while col + 1 < size {
            relations.append(oriented(col, col + 1, solution))
            col += 1
        }
        return NumbersPuzzle(size: size, givens: givens, relations: relations, solution: solution)
    }

    /// nil when all signs leave the puzzle ambiguous and this is not the last attempt.
    private static func build(size: Int, givenCount: Int, extra: Int, random: SeededRandom,
                              lastAttempt: Bool) -> NumbersPuzzle? {
        let cells = size * size
        let solution = latinSquare(size: size, random: random)

        // 2. Givens that leave the Latin square open on their own.
        var givens = Array(repeating: 0, count: cells)
        var placed = 0
        for cell in shuffled(range(cells), random) {
            if placed >= givenCount { break }
            givens[cell] = solution[cell]
            let open = NumbersSolver.countSolutions(size: size, givens: givens,
                                                    relations: [NumbersRelation](), limit: 2)
            if open > 1 {
                placed += 1
            } else {
                givens[cell] = 0
            }
        }

        // 3. All signs, oriented by the solution, in a random order.
        var relations = [NumbersRelation]()
        var cell = 0
        while cell < cells {
            let row = cell / size
            let col = cell % size
            if col + 1 < size { relations.append(oriented(cell, cell + 1, solution)) }
            if row + 1 < size { relations.append(oriented(cell, cell + size, solution)) }
            cell += 1
        }
        relations = shuffled(relations, random)
        if NumbersSolver.countSolutions(size: size, givens: givens, relations: relations, limit: 2) != 1 {
            if !lastAttempt { return nil }
            for extraCell in shuffled(range(cells), random) {
                if givens[extraCell] != 0 { continue }
                givens[extraCell] = solution[extraCell]
                if NumbersSolver.countSolutions(size: size, givens: givens, relations: relations, limit: 2) == 1 {
                    break
                }
            }
        }

        // 4. Drop signs while the puzzle stays unique.
        var kept = relations
        var removed = [NumbersRelation]()
        for relation in relations {
            var without = [NumbersRelation]()
            for other in kept {
                if other != relation { without.append(other) }
            }
            if NumbersSolver.countSolutions(size: size, givens: givens, relations: without, limit: 2) == 1 {
                kept = without
                removed.append(relation)
            }
        }

        // 5. Give easier days some of the dropped signs back.
        var back = 0
        while back < extra && back < removed.count {
            kept.append(removed[back])
            back += 1
        }

        return NumbersPuzzle(size: size, givens: givens, relations: sortedRelations(kept), solution: solution)
    }

    /// Sorted by the smaller cell of the pair, then the larger one.
    static func sortedRelations(_ list: [NumbersRelation]) -> [NumbersRelation] {
        return list.sorted { a, b in
            let aMin = a.lo < a.hi ? a.lo : a.hi
            let bMin = b.lo < b.hi ? b.lo : b.hi
            if aMin != bMin { return aMin < bMin }
            let aMax = a.lo < a.hi ? a.hi : a.lo
            let bMax = b.lo < b.hi ? b.hi : b.lo
            return aMax < bMax
        }
    }

    private static func oriented(_ a: Int, _ b: Int, _ solution: [Int]) -> NumbersRelation {
        if solution[a] < solution[b] { return NumbersRelation(lo: a, hi: b) }
        return NumbersRelation(lo: b, hi: a)
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
    public static func shuffled<T>(_ list: [T], _ random: SeededRandom) -> [T] {
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

    /// A random Latin square, row by row, values 1…size: cell by cell, each cell trying
    /// the values in a fresh random order and backtracking on a dead end.
    static func latinSquare(size: Int, random: SeededRandom) -> [Int] {
        let filler = LatinFiller(size: size, random: random)
        if filler.fill(0) { return filler.grid }
        // Unreachable (a Latin square always exists); a cyclic square keeps this total.
        return cyclicSquare(size: size)
    }

    private static func cyclicSquare(size: Int) -> [Int] {
        var grid = [Int]()
        var cell = 0
        while cell < size * size {
            grid.append((cell / size + cell % size) % size + 1)
            cell += 1
        }
        return grid
    }
}

private final class LatinFiller {
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
        for value in NumbersGenerator.shuffled(values, random) {
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
