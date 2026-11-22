import SwiftUI
import PibblesCore

/// Number buttons under Signs and Sums.
struct NumberPad: View {
    let size: Int
    let onNumber: (Int) -> Void

    var body: some View {
        HStack(spacing: 8.0) {
            ForEach(1..<(size + 1)) { value in
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
    let onSolved: (Int, String) -> Void
    @State var values: [Int]
    @State var selected = -1
    @State var hints = 0
    @State var reported = false

    init(puzzle: NumbersPuzzle, width: Double, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.onSolved = onSolved
        self._values = State(initialValue: puzzle.givens)
    }

    let gap = 22.0

    var cellSize: Double {
        let n = Double(puzzle.size)
        return (width - (n - 1.0) * gap) / n
    }

    /// The sign between two neighbouring squares, as the player reads it left to right
    /// or top to bottom: "<", ">", "∧", "∨" or "".
    func sign(_ first: Int, _ second: Int, vertical: Bool) -> String {
        for relation in puzzle.relations {
            if relation.lo == first && relation.hi == second { return vertical ? "∧" : "<" }
            if relation.lo == second && relation.hi == first { return vertical ? "∨" : ">" }
        }
        return ""
    }

    var body: some View {
        let conflicts = NumbersRules.conflicts(puzzle, values: values)
        let n = puzzle.size
        return VStack(spacing: 16.0) {
            VStack(spacing: 0.0) {
                ForEach(0..<n) { row in
                    HStack(spacing: 0.0) {
                        ForEach(0..<n) { col in
                            square(row * n + col, bad: conflicts.contains(row * n + col))
                            if col < n - 1 {
                                Text(sign(row * n + col, row * n + col + 1, vertical: false))
                                    .font(PibblesStyle.title(17.0))
                                    .foregroundStyle(PibblesStyle.orange)
                                    .frame(width: gap)
                            }
                        }
                    }
                    if row < n - 1 {
                        HStack(spacing: 0.0) {
                            ForEach(0..<n) { col in
                                Text(sign(row * n + col, row * n + col + n, vertical: true))
                                    .font(PibblesStyle.title(17.0))
                                    .foregroundStyle(PibblesStyle.orange)
                                    .frame(width: cellSize, height: gap)
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

    func check() {
        if !reported && NumbersRules.isSolved(puzzle, values: values) {
            reported = true
            selected = -1
            onSolved(hints, Answer.list(values))
        }
    }
}
