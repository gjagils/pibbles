import SwiftUI
import PibblesCore

/// Number buttons under Signs and Sums.
struct NumberPad: View {
    let size: Int
    let onNumber: (Int) -> Void

    var body: some View {
        HStack(spacing: 8.0) {
            ForEach(1..<(size + 1), id: \.self) { value in
                padButton("\(value)") { onNumber(value) }
            }
            padButton("⌫") { onNumber(0) }
        }
    }

    func padButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(PibblesStyle.title(20.0))
                .foregroundStyle(PibblesStyle.ink)
                .frame(width: 44.0, height: 48.0)
                .background(PibblesStyle.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12.0))
        }
        .buttonStyle(.plain)
    }
}

/// Signs: a Latin square with < and > between some squares. Tap a square, then a number.
struct NumbersBoardView: View {
    let puzzle: NumbersPuzzle
    let width: Double
    /// Room for the whole board view (board, extras and buttons): it must fit the screen.
    let height: Double
    /// Keeps the board and the clock, so the puzzle can be continued later.
    let model: PlayModel
    let onSolved: (Int, String) -> Void
    @State var values: [Int]
    @State var selected = -1
    @State var hints = 0
    @State var reported = false

    init(puzzle: NumbersPuzzle, width: Double, height: Double, model: PlayModel, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.height = height
        self.model = model
        self.onSolved = onSolved
        let saved = model.saved
        if saved.values.count == puzzle.givens.count {
            self._values = State(initialValue: saved.values)
            self._hints = State(initialValue: saved.hints)
        } else {
            self._values = State(initialValue: puzzle.givens)
        }
    }

    let gap = 26.0

    var cellSize: Double {
        let n = Double(puzzle.size)
        let fromWidth = (width - (n - 1.0) * gap) / n
        let fromHeight = (height - 134.0 - (n - 1.0) * gap) / n
        return max(20.0, min(fromWidth, fromHeight))
    }

    /// Where the sign between two neighbouring squares points: always at the smaller one.
    /// -1 no sign, else a `SignChevron` direction.
    func sign(_ first: Int, _ second: Int, vertical: Bool) -> Int {
        for relation in puzzle.relations {
            if relation.lo == first && relation.hi == second { return vertical ? SignChevron.up : SignChevron.left }
            if relation.lo == second && relation.hi == first { return vertical ? SignChevron.down : SignChevron.right }
        }
        return -1
    }

    @ViewBuilder
    func signView(_ direction: Int, width: Double) -> some View {
        if direction >= 0 {
            SignChevron(direction: direction)
                .stroke(PibblesStyle.orange, style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                .frame(width: 15.0, height: 15.0)
                .frame(width: width, height: gap)
        } else {
            Color.clear.frame(width: width, height: gap)
        }
    }

    var body: some View {
        let conflicts = NumbersRules.conflicts(puzzle, values: values)
        let n = puzzle.size
        return VStack(spacing: 16.0) {
            VStack(spacing: 0.0) {
                ForEach(0..<n, id: \.self) { row in
                    HStack(spacing: 0.0) {
                        ForEach(0..<n, id: \.self) { col in
                            square(row * n + col, bad: conflicts.contains(row * n + col))
                            if col < n - 1 {
                                signView(sign(row * n + col, row * n + col + 1, vertical: false), width: gap)
                            }
                        }
                    }
                    if row < n - 1 {
                        HStack(spacing: 0.0) {
                            ForEach(0..<n, id: \.self) { col in
                                signView(sign(row * n + col, row * n + col + n, vertical: true), width: cellSize)
                                if col < n - 1 {
                                    Spacer().frame(width: gap, height: gap)
                                }
                            }
                        }
                    }
                }
            }
            .frame(width: width)
            NumberPad(size: n) { value in enter(value) }
            BoardControls(hints: hints, onHint: { hint() }, onClear: {
                values = puzzle.givens
                selected = -1
                persist()
            })
        }
    }

    func square(_ index: Int, bad: Bool) -> some View {
        let given = puzzle.givens[index] > 0
        let value = values[index]
        return ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.2)
                .fill(given ? PibblesStyle.sand : PibblesStyle.cell)
                .overlay(RoundedRectangle(cornerRadius: cellSize * 0.2)
                    .stroke(selected == index ? PibblesStyle.purple : PibblesStyle.line, lineWidth: selected == index ? 3.0 : 1.0))
            if value > 0 {
                Text("\(value)")
                    .font(PibblesStyle.title(cellSize * 0.48))
                    .foregroundStyle(bad ? PibblesStyle.bad : (given ? PibblesStyle.ink : PibblesStyle.purple))
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            if given || reported { return }
            selected = index
        }
    }

    func enter(_ value: Int) {
        if selected < 0 || reported { return }
        var copy = values
        copy[selected] = value
        values = copy
        check()
    }

    func hint() {
        if reported { return }
        guard let index = CellHint.next(values: values, solution: puzzle.solution, givens: puzzle.givens, empty: 0) else { return }
        var copy = values
        copy[index] = puzzle.solution[index]
        values = copy
        hints += 1
        check()
    }

    func persist() {
        model.save(hints: hints, values: values, lists: [[Int]]())
    }

    func check() {
        persist()
        if !reported && NumbersRules.isSolved(puzzle, values: values) {
            reported = true
            selected = -1
            onSolved(hints, Answer.list(values))
        }
    }
}

/// A bold arrowhead between two Signs squares; the point is at the smaller number.
struct SignChevron: Shape {
    static let left = 0
    static let right = 1
    static let up = 2
    static let down = 3
    let direction: Int

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        if direction == SignChevron.left {
            path.move(to: CGPoint(x: w * 0.75, y: 0.0))
            path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.5))
            path.addLine(to: CGPoint(x: w * 0.75, y: h))
        } else if direction == SignChevron.right {
            path.move(to: CGPoint(x: w * 0.25, y: 0.0))
            path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.5))
            path.addLine(to: CGPoint(x: w * 0.25, y: h))
        } else if direction == SignChevron.up {
            path.move(to: CGPoint(x: 0.0, y: h * 0.75))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.2))
            path.addLine(to: CGPoint(x: w, y: h * 0.75))
        } else {
            path.move(to: CGPoint(x: 0.0, y: h * 0.25))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.8))
            path.addLine(to: CGPoint(x: w, y: h * 0.25))
        }
        return path
    }
}
