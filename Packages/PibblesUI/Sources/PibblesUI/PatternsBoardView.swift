import SwiftUI
import PibblesCore

/// Pixels: clues on the left and on top; tap to fill, or to mark × in the × mode.
struct PatternsBoardView: View {
    let puzzle: PatternsPuzzle
    let width: Double
    let onSolved: (Int, String) -> Void
    @State var cells: [Int]
    @State var markMode = false
    @State var hints = 0
    @State var reported = false

    init(puzzle: PatternsPuzzle, width: Double, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.onSolved = onSolved
        var empty = [Int]()
        for _ in 0..<(puzzle.size * puzzle.size) { empty.append(0) }
        self._cells = State(initialValue: empty)
    }

    var clueWidth: Double { return width * 0.24 }
    var clueHeight: Double { return Double(maxColumnClues) * 15.0 + 8.0 }
    var maxColumnClues: Int {
        var most = 1
        for clue in puzzle.colClues { most = max(most, clue.count) }
        return most
    }

    var cellSize: Double {
        let n = Double(puzzle.size)
        return (width - clueWidth - (n - 1.0) * 3.0) / n
    }

    var body: some View {
        VStack(spacing: 14.0) {
            VStack(spacing: 3.0) {
                HStack(alignment: .bottom, spacing: 3.0) {
                    Spacer().frame(width: clueWidth, height: clueHeight)
                    ForEach(0..<puzzle.size) { col in
                        VStack(spacing: 0.0) {
                            ForEach(clueText(puzzle.colClues[col]), id: \.self) { item in
                                Text(item)
                                    .font(PibblesStyle.text(13.0, .semibold))
                                    .frame(height: 15.0)
                            }
                        }
                        .foregroundStyle(PatternsRules.colMatches(puzzle, cells: cells, col: col) ? PibblesStyle.muted.opacity(0.5) : PibblesStyle.ink)
                        .frame(width: cellSize, height: clueHeight, alignment: .bottom)
                    }
                }
                ForEach(0..<puzzle.size) { row in
                    HStack(spacing: 3.0) {
                        Text(clueText(puzzle.rowClues[row]).joined(separator: " "))
                            .font(PibblesStyle.text(13.0, .semibold))
                            .foregroundStyle(PatternsRules.rowMatches(puzzle, cells: cells, row: row) ? PibblesStyle.muted.opacity(0.5) : PibblesStyle.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(width: clueWidth - 6.0, height: cellSize, alignment: .trailing)
                            .padding(.trailing, 6.0)
                        ForEach(0..<puzzle.size) { col in
                            square(row * puzzle.size + col)
                        }
                    }
                }
            }
            .frame(width: width)
            HStack(spacing: 10.0) {
                modeButton(title: T.s("Fill", "Kleuren"), active: !markMode) { markMode = false }
                modeButton(title: "× Empty", active: markMode) { markMode = true }
            }
            BoardControls(hints: hints, onHint: { hint() }, onClear: {
                var empty = [Int]()
                for _ in 0..<(puzzle.size * puzzle.size) { empty.append(0) }
                cells = empty
            })
        }
    }

    func clueText(_ clue: [Int]) -> [String] {
        if clue.isEmpty { return ["0"] }
        var result = [String]()
        for value in clue { result.append("\(value)") }
        return result
    }

    func modeButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(PibblesStyle.text(15.0, .semibold))
                .foregroundStyle(active ? Color.white : PibblesStyle.ink)
                .padding(.horizontal, 18.0)
                .padding(.vertical, 9.0)
                .background(active ? PibblesStyle.purple : PibblesStyle.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func square(_ index: Int) -> some View {
        let value = cells[index]
        return ZStack {
            RoundedRectangle(cornerRadius: cellSize * 0.16)
                .fill(value == 1 ? PibblesStyle.purple : PibblesStyle.cell)
                .overlay(RoundedRectangle(cornerRadius: cellSize * 0.16).stroke(value == 1 ? Color.clear : PibblesStyle.line, lineWidth: 1.0))
            if value == 2 {
                Text("×")
                    .font(PibblesStyle.text(cellSize * 0.5))
                    .foregroundStyle(PibblesStyle.muted)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            if reported { return }
            let wanted = markMode ? 2 : 1
            var copy = cells
            copy[index] = value == wanted ? 0 : wanted
            cells = copy
            check()
        }
    }

    func hint() {
        if reported { return }
        guard let index = CellHint.next(values: cells, solution: puzzle.solution, givens: nil, empty: 0) else { return }
        var copy = cells
        copy[index] = puzzle.solution[index] == 1 ? 1 : 2
        cells = copy
        hints += 1
        check()
    }

    func check() {
        if !reported && PatternsRules.isSolved(puzzle, cells: cells) {
            reported = true
            var answer = [Int]()
            for value in cells { answer.append(value == 1 ? 1 : 0) }
            onSolved(hints, Answer.list(answer))
        }
    }
}
