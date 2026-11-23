import SwiftUI
import PibblesCore

/// Stars: coloured areas; tap once for a dot, twice for a star, a third time to clear.
struct StarsBoardView: View {
    let puzzle: StarsPuzzle
    let width: Double
    /// Room for the whole board view (board, extras and buttons): it must fit the screen.
    let height: Double
    let onSolved: (Int, String) -> Void
    @State var stars: [Int]
    @State var hints = 0
    @State var reported = false
    // Touch: one gesture for the board. A tap marks, a double tap places a star, a drag
    // marks every square it passes (or clears marks when it starts on a mark).
    @State var startCell = -1
    @State var dragged = false
    @State var eraseMarks = false
    @State var lastDragCell = -1
    @State var lastTapCell = -1
    @State var lastTapTime = 0.0
    @State var valueBeforeTap = 0

    init(puzzle: StarsPuzzle, width: Double, height: Double, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.height = height
        self.onSolved = onSolved
        var empty = [Int]()
        for _ in 0..<(puzzle.size * puzzle.size) { empty.append(0) }
        self._stars = State(initialValue: empty)
    }

    var cellSize: Double {
        let n = Double(puzzle.size)
        return max(20.0, min(width / n, (height - 70.0) / n))
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
            .frame(width: cellSize * Double(n))
            .background(PibblesStyle.cell)
            .overlay(Rectangle().stroke(PibblesStyle.ink, lineWidth: 2.5))
            .gesture(
                DragGesture(minimumDistance: 0.0)
                    .onChanged { value in touchMoved(x: value.location.x, y: value.location.y) }
                    .onEnded { value in touchEnded(x: value.location.x, y: value.location.y) }
            )
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
        let thin = 1.2
        let value = stars[index]
        return ZStack {
            Rectangle().fill(PibblesStyle.cell)
            Rectangle().fill(areaColor(region))
            VStack(spacing: 0.0) {
                Rectangle().fill(top ? PibblesStyle.ink : PibblesStyle.muted.opacity(0.45)).frame(height: top ? thick : thin)
                Spacer()
                Rectangle().fill(bottom ? PibblesStyle.ink : PibblesStyle.muted.opacity(0.45)).frame(height: bottom ? thick : thin)
            }
            HStack(spacing: 0.0) {
                Rectangle().fill(left ? PibblesStyle.ink : PibblesStyle.muted.opacity(0.45)).frame(width: left ? thick : thin)
                Spacer()
                Rectangle().fill(right ? PibblesStyle.ink : PibblesStyle.muted.opacity(0.45)).frame(width: right ? thick : thin)
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
    }

    func cellAt(x: Double, y: Double) -> Int {
        let n = puzzle.size
        if x < 0.0 || y < 0.0 { return -1 }
        let col = Int(floor(x / cellSize))
        let row = Int(floor(y / cellSize))
        if col >= n || row >= n { return -1 }
        return row * n + col
    }

    func touchMoved(x: Double, y: Double) {
        if reported { return }
        let cell = cellAt(x: x, y: y)
        if startCell < 0 {
            startCell = cell
            dragged = false
            eraseMarks = cell >= 0 && stars[cell] == 1
            return
        }
        if cell < 0 || (cell == startCell && !dragged) { return }
        if !dragged {
            dragged = true
            mark(startCell)
            lastDragCell = startCell
        }
        // A fast finger can jump over squares: walk from the last square to this one.
        let n = puzzle.size
        var row = lastDragCell / n
        var col = lastDragCell % n
        let targetRow = cell / n
        let targetCol = cell % n
        while row != targetRow || col != targetCol {
            if abs(targetCol - col) >= abs(targetRow - row) {
                col += targetCol > col ? 1 : -1
            } else {
                row += targetRow > row ? 1 : -1
            }
            mark(row * n + col)
        }
        lastDragCell = cell
    }

    /// While dragging: empty squares get a mark, or marks are cleared in erase mode. Stars stay.
    func mark(_ cell: Int) {
        if cell < 0 || stars[cell] == 2 { return }
        let wanted = eraseMarks ? 0 : 1
        if stars[cell] == wanted { return }
        var copy = stars
        copy[cell] = wanted
        stars = copy
    }

    func touchEnded(x: Double, y: Double) {
        defer {
            startCell = -1
            dragged = false
        }
        if reported || dragged { return }
        let cell = cellAt(x: x, y: y)
        if cell < 0 || cell != startCell { return }
        let now = Date().timeIntervalSince1970
        var copy = stars
        if cell == lastTapCell && now - lastTapTime < 0.35 {
            // Double tap: a star, or away with the star it already was.
            copy[cell] = valueBeforeTap == 2 ? 0 : 2
            lastTapCell = -1
        } else {
            // Single tap: mark or unmark; a star goes away.
            valueBeforeTap = copy[cell]
            copy[cell] = copy[cell] == 0 ? 1 : 0
            lastTapCell = cell
            lastTapTime = now
        }
        stars = copy
        check()
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
