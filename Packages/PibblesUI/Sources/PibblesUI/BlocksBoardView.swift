import SwiftUI
import PibblesCore

/// Blocks: the board with the counts, and the tray. Tap a block, then a square.
struct BlocksBoardView: View {
    let puzzle: Puzzle
    let width: Double
    let onSolved: (Int, String) -> Void
    @State var play: BlocksPlay
    @State var reported = false

    init(puzzle: Puzzle, width: Double, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.onSolved = onSolved
        self._play = State(initialValue: BlocksPlay(puzzle: puzzle))
    }

    var cellSize: Double {
        let n = Double(puzzle.size)
        return (width - 36.0 - (n - 1.0) * 4.0) / n
    }

    var body: some View {
        VStack(spacing: 16.0) {
            board
            tray
            BoardControls(hints: play.hints, onHint: {
                play.hint()
                check()
            }, onClear: {
                play.clear()
            })
        }
    }

    var board: some View {
        let counts = play.counts
        return VStack(spacing: 4.0) {
            HStack(spacing: 4.0) {
                ForEach(0..<puzzle.size) { col in
                    countLabel(target: puzzle.cols[col], current: counts.cols[col])
                        .frame(width: cellSize, height: 28.0)
                }
                Spacer().frame(width: 32.0, height: 28.0)
            }
            ForEach(0..<puzzle.size) { row in
                HStack(spacing: 4.0) {
                    ForEach(0..<puzzle.size) { col in
                        square(row * puzzle.size + col)
                    }
                    countLabel(target: puzzle.rows[row], current: counts.rows[row])
                        .frame(width: 32.0, height: cellSize)
                }
            }
        }
        .frame(width: width)
    }

    func countLabel(target: Int, current: Int) -> some View {
        Text("\(target)")
            .font(PibblesStyle.title(20.0))
            .foregroundStyle(current == target ? PibblesStyle.good : (current > target ? PibblesStyle.bad : PibblesStyle.ink))
    }

    func square(_ index: Int) -> some View {
        let piece = play.piece(at: index)
        let fill = piece == nil ? PibblesStyle.cell : PibblesStyle.pieceColor(piece ?? 0)
        return RoundedRectangle(cornerRadius: cellSize * 0.18)
            .fill(fill)
            .overlay(
                RoundedRectangle(cornerRadius: cellSize * 0.18)
                    .stroke(piece == nil ? PibblesStyle.line : Color.clear, lineWidth: 1.0)
            )
            .frame(width: cellSize, height: cellSize)
            .onTapGesture {
                play.tap(square: index)
                check()
            }
    }

    var tray: some View {
        VStack(spacing: 8.0) {
            Text(play.isSolved ? T.s("All blocks fit.", "Alle blokken passen.") : (play.selected == nil ? T.s("Tap a block on the board to pick it up.", "Tik op een blok op het veld om het op te pakken.") : T.s("Tap a square for the top left corner of the chosen block.", "Tik op het vak voor de linkerbovenhoek van het gekozen blok.")))
                .font(PibblesStyle.text(13.0))
                .foregroundStyle(PibblesStyle.muted)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12.0) {
                    ForEach(0..<puzzle.pieces.count) { index in
                        if play.positions[index] == nil {
                            pieceView(index)
                        }
                    }
                }
                .padding(.horizontal, 4.0)
                .padding(.vertical, 4.0)
            }
            .frame(height: 96.0)
        }
    }

    func pieceView(_ index: Int) -> some View {
        let shape = ShapeCatalog.shape(puzzle.pieces[index])
        let height = shape?.height ?? 1
        let widthCells = shape?.width ?? 1
        let cells = shape?.cells ?? [Cell]()
        let unit = 16.0
        let isSelected = play.selected == index
        return VStack(spacing: 2.0) {
            ForEach(0..<height) { row in
                HStack(spacing: 2.0) {
                    ForEach(0..<widthCells) { col in
                        RoundedRectangle(cornerRadius: 3.0)
                            .fill(cells.contains(Cell(row: row, col: col)) ? PibblesStyle.pieceColor(index) : Color.clear)
                            .frame(width: unit, height: unit)
                    }
                }
            }
        }
        .padding(10.0)
        .background(isSelected ? PibblesStyle.sand : PibblesStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .overlay(RoundedRectangle(cornerRadius: 12.0).stroke(isSelected ? PibblesStyle.purple : PibblesStyle.line, lineWidth: isSelected ? 2.5 : 1.0))
        .onTapGesture {
            play.select(index)
        }
    }

    func check() {
        if play.isSolved && !reported {
            reported = true
            var answer = [Int]()
            for position in play.positions { answer.append(position ?? -1) }
            onSolved(play.hints, Answer.list(answer))
        }
    }
}
