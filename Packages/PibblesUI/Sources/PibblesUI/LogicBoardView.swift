import SwiftUI
import PibblesCore

/// Duo: tap a square to cycle empty → teal → purple → empty.
struct LogicBoardView: View {
    let puzzle: LogicPuzzle
    let width: Double
    /// Room for the whole board view (board, extras and buttons): it must fit the screen.
    let height: Double
    /// Keeps the board and the clock, so the puzzle can be continued later.
    let model: PlayModel
    let onSolved: (Int, String) -> Void
    @State var values: [Int]
    @State var hints = 0
    @State var reported = false

    init(puzzle: LogicPuzzle, width: Double, height: Double, model: PlayModel, onSolved: @escaping (Int, String) -> Void) {
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

    var cellSize: Double {
        let n = Double(puzzle.size)
        let fromWidth = (width - (n - 1.0) * 4.0) / n
        let fromHeight = (height - 70.0 - (n - 1.0) * 4.0) / n
        return max(16.0, min(fromWidth, fromHeight))
    }

    var body: some View {
        let conflicts = LogicRules.conflicts(puzzle, values: values)
        return VStack(spacing: 16.0) {
            VStack(spacing: 4.0) {
                ForEach(0..<puzzle.size, id: \.self) { row in
                    HStack(spacing: 4.0) {
                        ForEach(0..<puzzle.size, id: \.self) { col in
                            square(row * puzzle.size + col, bad: conflicts.contains(row * puzzle.size + col))
                        }
                    }
                }
            }
            .frame(width: width)
            BoardControls(hints: hints, onHint: { hint() }, onClear: {
                values = puzzle.givens
                persist()
            })
        }
    }

    func square(_ index: Int, bad: Bool) -> some View {
        let value = values[index]
        let given = puzzle.givens[index] >= 0
        return ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.2)
                .fill(PibblesStyle.cell)
                .overlay(RoundedRectangle(cornerRadius: cellSize * 0.2).stroke(PibblesStyle.line, lineWidth: 1.0))
            if value >= 0 {
                Circle()
                    .fill(value == 0 ? PibblesStyle.teal : PibblesStyle.purple)
                    .frame(width: cellSize * 0.66, height: cellSize * 0.66)
                    .overlay(Circle().stroke(bad ? PibblesStyle.bad : (given ? PibblesStyle.ink.opacity(0.35) : Color.clear), lineWidth: bad ? 3.0 : 2.0))
            }
            if given {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: cellSize * 0.12, height: cellSize * 0.12)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            if given || reported { return }
            var copy = values
            copy[index] = value < 0 ? 0 : (value == 0 ? 1 : -1)
            values = copy
            check()
        }
    }

    func hint() {
        if reported { return }
        guard let index = CellHint.next(values: values, solution: puzzle.solution, givens: puzzle.givens, empty: -1) else { return }
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
        if !reported && LogicRules.isSolved(puzzle, values: values) {
            reported = true
            onSolved(hints, Answer.list(values))
        }
    }
}
