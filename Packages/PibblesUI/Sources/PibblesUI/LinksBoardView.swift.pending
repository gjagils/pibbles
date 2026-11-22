import SwiftUI
import PibblesCore

/// Links: drag from a dot to draw its line; drag back over a line to shorten it.
struct LinksBoardView: View {
    let puzzle: LinksPuzzle
    let width: Double
    let onSolved: (Int, String) -> Void
    @State var paths: [[Int]]
    @State var colour = -1
    @State var hints = 0
    @State var reported = false

    init(puzzle: LinksPuzzle, width: Double, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.onSolved = onSolved
        var empty = [[Int]]()
        for _ in puzzle.solution { empty.append([Int]()) }
        self._paths = State(initialValue: empty)
    }

    var cellSize: Double {
        return width / Double(puzzle.size)
    }

    /// The colour whose line runs through a square, or -1.
    func owner(_ index: Int) -> Int {
        var colourIndex = 0
        while colourIndex < paths.count {
            if paths[colourIndex].contains(index) { return colourIndex }
            colourIndex += 1
        }
        return -1
    }

    var body: some View {
        let n = puzzle.size
        return VStack(spacing: 16.0) {
            VStack(spacing: 0.0) {
                ForEach(0..<n, id: \.self) { row in
                    HStack(spacing: 0.0) {
                        ForEach(0..<n, id: \.self) { col in
                            square(row * n + col)
                        }
                    }
                }
            }
            .frame(width: width, height: width)
            .background(PibblesStyle.cell)
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            .gesture(
                DragGesture(minimumDistance: 0.0)
                    .onChanged { value in moved(x: value.location.x, y: value.location.y) }
                    .onEnded { _ in
                        colour = -1
                        check()
                    }
            )
            Text(T.s("Drag from a dot. Drag back over a line to shorten it.", "Sleep vanaf een stip. Sleep terug over een lijn om hem in te korten."))
                .font(PibblesStyle.text(13.0))
                .foregroundStyle(PibblesStyle.muted)
            BoardControls(hints: hints, onHint: { hint() }, onClear: {
                var empty = [[Int]]()
                for _ in puzzle.solution { empty.append([Int]()) }
                paths = empty
            })
        }
    }

    func square(_ index: Int) -> some View {
        let n = puzzle.size
        let mine = owner(index)
        let dot = puzzle.ends[index]
        // Line pieces towards the neighbours on the same path.
        var up = false
        var down = false
        var left = false
        var right = false
        if mine >= 0 {
            let path = paths[mine]
            var position = 0
            while position < path.count {
                if path[position] == index {
                    if position > 0 {
                        let other = path[position - 1]
                        if other == index - n { up = true }
                        if other == index + n { down = true }
                        if other == index - 1 { left = true }
                        if other == index + 1 { right = true }
                    }
                    if position + 1 < path.count {
                        let other = path[position + 1]
                        if other == index - n { up = true }
                        if other == index + n { down = true }
                        if other == index - 1 { left = true }
                        if other == index + 1 { right = true }
                    }
                }
                position += 1
            }
        }
        let lineColor = mine >= 0 ? PibblesStyle.pieceColor(mine) : Color.clear
        let thickness = cellSize * 0.3
        return ZStack {
            Rectangle()
                .fill(mine >= 0 ? PibblesStyle.pieceColor(mine).opacity(0.18) : PibblesStyle.cell)
            Rectangle().stroke(PibblesStyle.line, lineWidth: 0.5)
            VStack(spacing: 0.0) {
                Rectangle().fill(up ? lineColor : Color.clear).frame(width: thickness, height: cellSize / 2.0)
                Rectangle().fill(down ? lineColor : Color.clear).frame(width: thickness, height: cellSize / 2.0)
            }
            HStack(spacing: 0.0) {
                Rectangle().fill(left ? lineColor : Color.clear).frame(width: cellSize / 2.0, height: thickness)
                Rectangle().fill(right ? lineColor : Color.clear).frame(width: cellSize / 2.0, height: thickness)
            }
            if mine >= 0 && dot < 0 {
                Circle().fill(lineColor).frame(width: thickness, height: thickness)
            }
            if dot >= 0 {
                Circle()
                    .fill(PibblesStyle.pieceColor(dot))
                    .frame(width: cellSize * 0.62, height: cellSize * 0.62)
            }
        }
        .frame(width: cellSize, height: cellSize)
    }

    func moved(x: Double, y: Double) {
        if reported { return }
        let n = puzzle.size
        let col = Int(x / cellSize)
        let row = Int(y / cellSize)
        if x < 0.0 || y < 0.0 || col >= n || row >= n { return }
        let cell = row * n + col
        if colour < 0 {
            guard let start = LinksRules.start(puzzle, paths: paths, at: cell) else { return }
            colour = start.colour
            paths = start.paths
            return
        }
        let next = LinksRules.extend(puzzle, paths: paths, colour: colour, to: cell)
        if next != paths { paths = next }
    }

    /// Draws one line from the solution that is not finished yet.
    func hint() {
        if reported { return }
        var colourIndex = 0
        while colourIndex < puzzle.solution.count {
            let wanted = puzzle.solution[colourIndex]
            let have = paths[colourIndex]
            var reversed = [Int]()
            for cell in wanted { reversed.insert(cell, at: 0) }
            if have != wanted && have != reversed {
                var copy = paths
                // Lines that cross the solution line go back.
                var other = 0
                while other < copy.count {
                    if other != colourIndex {
                        for cell in wanted {
                            if copy[other].contains(cell) { copy[other] = [Int]() }
                        }
                    }
                    other += 1
                }
                copy[colourIndex] = wanted
                paths = copy
                hints += 1
                check()
                return
            }
            colourIndex += 1
        }
    }

    func check() {
        if !reported && LinksRules.isSolved(puzzle, paths: paths) {
            reported = true
            onSolved(hints, Answer.nested(paths))
        }
    }
}
