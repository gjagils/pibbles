import SwiftUI
import PibblesCore

/// Sums: a Latin square in outlined blocks; each block adds up to its small number.
struct SumsBoardView: View {
    let puzzle: SumsPuzzle
    let width: Double
    /// Room for the whole board view (board, extras and buttons): it must fit the screen.
    let height: Double
    let onSolved: (Int, String) -> Void
    @State var values: [Int]
    @State var selected = -1
    @State var hints = 0
    @State var reported = false

    init(puzzle: SumsPuzzle, width: Double, height: Double, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.height = height
        self.onSolved = onSolved
        var empty = [Int]()
        for _ in 0..<(puzzle.size * puzzle.size) { empty.append(0) }
        self._values = State(initialValue: empty)
    }

    var cellSize: Double {
        let n = Double(puzzle.size)
        return max(20.0, min(width / n, (height - 134.0) / n))
    }

    var body: some View {
        let conflicts = SumsRules.conflicts(puzzle, values: values)
        let labels = SumsRules.cageLabelCells(puzzle)
        let n = puzzle.size
        return VStack(spacing: 16.0) {
            VStack(spacing: 0.0) {
                ForEach(0..<n, id: \.self) { row in
                    HStack(spacing: 0.0) {
                        ForEach(0..<n, id: \.self) { col in
                            square(row * n + col, bad: conflicts.contains(row * n + col), labels: labels)
                        }
                    }
                }
            }
            .frame(width: cellSize * Double(n))
            .background(PibblesStyle.cell)
            .overlay(Rectangle().stroke(PibblesStyle.ink, lineWidth: 2.5))
            NumberPad(size: n) { value in enter(value) }
            BoardControls(hints: hints, onHint: { hint() }, onClear: {
                var empty = [Int]()
                for _ in 0..<(n * n) { empty.append(0) }
                values = empty
                selected = -1
            })
        }
    }

    /// One square with thick edges where its block ends.
    func square(_ index: Int, bad: Bool, labels: [Int]) -> some View {
        let n = puzzle.size
        let row = index / n
        let col = index % n
        let cage = puzzle.cages[index]
        let top = row == 0 || puzzle.cages[index - n] != cage
        let bottom = row == n - 1 || puzzle.cages[index + n] != cage
        let left = col == 0 || puzzle.cages[index - 1] != cage
        let right = col == n - 1 || puzzle.cages[index + 1] != cage
        let thick = 2.5
        let thin = 1.2
        let value = values[index]
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(selected == index ? PibblesStyle.sand : PibblesStyle.cell)
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
            if cage < labels.count && labels[cage] == index {
                Text("\(puzzle.sums[cage])")
                    .font(PibblesStyle.text(max(10.0, cellSize * 0.2), .semibold))
                    .foregroundStyle(PibblesStyle.muted)
                    .padding(.leading, 5.0)
                    .padding(.top, 3.0)
            }
            if value > 0 {
                Text("\(value)")
                    .font(PibblesStyle.title(cellSize * 0.45))
                    .foregroundStyle(bad ? PibblesStyle.bad : PibblesStyle.purple)
                    .frame(width: cellSize, height: cellSize)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .onTapGesture {
            if reported { return }
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
        guard let index = CellHint.next(values: values, solution: puzzle.solution, givens: nil, empty: 0) else { return }
        var copy = values
        copy[index] = puzzle.solution[index]
        values = copy
        hints += 1
        check()
    }

    func check() {
        if !reported && SumsRules.isSolved(puzzle, values: values) {
            reported = true
            selected = -1
            onSolved(hints, Answer.list(values))
        }
    }
}
