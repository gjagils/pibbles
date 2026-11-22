import SwiftUI
import PibblesCore

/// Stars: coloured areas; tap once for a dot, twice for a star, a third time to clear.
struct StarsBoardView: View {
    let puzzle: StarsPuzzle
    let width: Double
    let onSolved: (Int, String) -> Void
    @State var stars: [Int]
    @State var hints = 0
    @State var reported = false

    init(puzzle: StarsPuzzle, width: Double, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.onSolved = onSolved
        var empty = [Int]()
        for _ in 0..<(puzzle.size * puzzle.size) { empty.append(0) }
        self._stars = State(initialValue: empty)
    }

    var cellSize: Double {
        return width / Double(puzzle.size)
    }

    func areaColor(_ region: Int) -> Color {
        let palette = [PibblesStyle.purple, PibblesStyle.orange, PibblesStyle.teal, PibblesStyle.rose,
                       PibblesStyle.sky, PibblesStyle.mustard, PibblesStyle.sage, PibblesStyle.plum]
        return palette[region % palette.count].opacity(0.32)
    }

    var body: some View {
        let conflicts = StarsRules.conflicts(puzzle, stars: stars)
        let faded = StarsRules.autoMarks(puzzle, stars: stars)
        let n = puzzle.size
        return VStack(spacing: 16.0) {
            VStack(spacing: 0.0) {
                ForEach(0..<n, id: \.self) { row in
                    HStack(spacing: 0.0) {
                        ForEach(0..<n, id: \.self) { col in
                            square(row * n + col, bad: conflicts.contains(row * n + col), faded: faded.contains(row * n + col))
                        }
                    }
                }
            }
            .frame(width: width)
            .background(PibblesStyle.cell)
            .overlay(Rectangle().stroke(PibblesStyle.ink, lineWidth: 2.5))
            BoardControls(hints: hints, onHint: { hint() }, onClear: {
                var empty = [Int]()
                for _ in 0..<(n * n) { empty.append(0) }
                stars = empty
            })
        }
    }

    func square(_ index: Int, bad: Bool, faded: Bool) -> some View {
        let n = puzzle.size
        let row = index / n
        let col = index % n
        let region = puzzle.regions[index]
        let top = row == 0 || puzzle.regions[index - n] != region
        let bottom = row == n - 1 || puzzle.regions[index + n] != region
        let left = col == 0 || puzzle.regions[index - 1] != region
        let right = col == n - 1 || puzzle.regions[index + 1] != region
        let thick = 2.5
        let thin = 0.5
        let value = stars[index]
        return ZStack {
            Rectangle().fill(PibblesStyle.cell)
            Rectangle().fill(areaColor(region))
            VStack(spacing: 0.0) {
                Rectangle().fill(top ? PibblesStyle.ink : PibblesStyle.line).frame(height: top ? thick : thin)
                Spacer()
                Rectangle().fill(bottom ? PibblesStyle.ink : PibblesStyle.line).frame(height: bottom ? thick : thin)
            }
            HStack(spacing: 0.0) {
                Rectangle().fill(left ? PibblesStyle.ink : PibblesStyle.line).frame(width: left ? thick : thin)
                Spacer()
                Rectangle().fill(right ? PibblesStyle.ink : PibblesStyle.line).frame(width: right ? thick : thin)
            }
            if value == 2 {
                Text("★")
                    .font(Font.system(size: cellSize * 0.6))
                    .foregroundStyle(bad ? PibblesStyle.bad : PibblesStyle.ink)
            } else if value == 1 || faded {
                Circle()
                    .fill(PibblesStyle.muted.opacity(value == 1 ? 0.9 : 0.35))
                    .frame(width: cellSize * 0.14, height: cellSize * 0.14)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            if reported { return }
            var copy = stars
            copy[index] = (value + 1) % 3
            stars = copy
            check()
        }
    }

    /// Places one star from the solution that is not on the board yet.
    func hint() {
        if reported { return }
        let n = puzzle.size
        var row = 0
        while row < n {
            let index = row * n + puzzle.solution[row]
            if stars[index] != 2 {
                var copy = stars
                // Clear wrong stars in this row first.
                var col = 0
                while col < n {
                    if copy[row * n + col] == 2 { copy[row * n + col] = 0 }
                    col += 1
                }
                copy[index] = 2
                stars = copy
                hints += 1
                check()
                return
            }
            row += 1
        }
    }

    func check() {
        if !reported && StarsRules.isSolved(puzzle, stars: stars) {
            reported = true
            var answer = [Int]()
            let n = puzzle.size
            var row = 0
            while row < n {
                var col = 0
                while col < n {
                    if stars[row * n + col] == 2 { answer.append(col) }
                    col += 1
                }
                row += 1
            }
            onSolved(hints, Answer.list(answer))
        }
    }
}
