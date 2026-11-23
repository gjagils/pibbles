import SwiftUI
import PibblesCore

/// Blocks: the board with the counts, and the tray. Drag a block onto the board (or off
/// it, back to the tray); tapping a block and then a square works too. One drag gesture
/// covers board and tray, so both platforms handle it the same way (Skip has no
/// drag-and-drop between views).
struct BlocksBoardView: View {
    let puzzle: Puzzle
    let width: Double
    /// Room for the whole view (board, tray, buttons): it must fit the screen.
    let height: Double
    /// Keeps the board and the clock, so the puzzle can be continued later.
    let model: PlayModel
    let onSolved: (Int, String) -> Void
    @State var play: BlocksPlay
    @State var reported = false
    // The drag in progress, in the coordinates of the board-and-tray area.
    @State var touchPiece = -1
    @State var touchFromBoard = false
    @State var startX = -1.0
    @State var startY = -1.0
    @State var dragX = 0.0
    @State var dragY = 0.0
    @State var dragging = false

    init(puzzle: Puzzle, width: Double, height: Double, model: PlayModel, onSolved: @escaping (Int, String) -> Void) {
        self.puzzle = puzzle
        self.width = width
        self.height = height
        self.model = model
        self.onSolved = onSolved
        var play = BlocksPlay(puzzle: puzzle)
        let saved = model.saved
        if saved.values.count == puzzle.pieces.count {
            var positions = [Int?]()
            for value in saved.values { positions.append(value >= 0 ? value : nil) }
            play.restore(positions: positions, hints: saved.hints)
        }
        self._play = State(initialValue: play)
    }

    // MARK: Geometry

    let gap = 4.0
    let countsHeight = 28.0
    let countsWidth = 32.0
    let hintHeight = 18.0
    let slotHeight = 72.0

    var n: Int { return puzzle.size }
    var trayRows: Int { return (puzzle.pieces.count + 3) / 4 }
    var trayHeight: Double { return Double(trayRows) * slotHeight }

    var cellSize: Double {
        let count = Double(n)
        let fromWidth = (width - countsWidth - gap - (count - 1.0) * gap) / count
        // counts row + gap, board, 12, hint, 12, tray, 12, buttons 54
        let fixed = countsHeight + gap + 12.0 + hintHeight + 12.0 + trayHeight + 12.0 + 54.0
        let fromHeight = (height - fixed - (count - 1.0) * gap) / count
        return max(18.0, min(fromWidth, fromHeight))
    }

    var stride: Double { return cellSize + gap }
    var boardWidth: Double { return Double(n) * stride - gap + gap + countsWidth }
    var gridX: Double { return (width - boardWidth) / 2.0 }
    var gridY: Double { return countsHeight + gap }
    var boardHeight: Double { return gridY + Double(n) * stride - gap }
    var trayY: Double { return boardHeight + 12.0 + hintHeight + 12.0 }
    var slotWidth: Double { return width / 4.0 }
    /// How far above the finger a dragged block floats, so the finger does not hide it.
    var lift: Double { return cellSize * 1.2 }

    /// The pieces still in the tray, in tray order.
    var trayPieces: [Int] {
        var result = [Int]()
        var index = 0
        while index < puzzle.pieces.count {
            if play.positions[index] == nil { result.append(index) }
            index += 1
        }
        return result
    }

    // MARK: Views

    var body: some View {
        VStack(spacing: 12.0) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 12.0) {
                    board
                    Text(hintText)
                        .font(PibblesStyle.text(13.0))
                        .foregroundStyle(PibblesStyle.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(height: hintHeight)
                    tray
                }
                .frame(width: width)
                if dragging && touchPiece >= 0 {
                    floatingPiece(touchPiece)
                }
            }
            .frame(width: width, height: trayY + trayHeight, alignment: .topLeading)
            .gesture(
                DragGesture(minimumDistance: 0.0)
                    .onChanged { value in changed(x: value.location.x, y: value.location.y) }
                    .onEnded { value in ended(x: value.location.x, y: value.location.y) }
            )
            BoardControls(hints: play.hints, onHint: {
                play.hint()
                check()
            }, onClear: {
                play.clear()
                persist()
            })
        }
    }

    var hintText: String {
        if play.isSolved { return T.s("All blocks fit.", "Alle blokken passen.") }
        return T.s("Drag a block onto the board, or tap a block and then a square.",
                   "Sleep een blok naar het veld, of tik een blok en dan een vak.")
    }

    var board: some View {
        let counts = play.counts
        return VStack(spacing: gap) {
            HStack(spacing: gap) {
                ForEach(0..<n, id: \.self) { col in
                    countLabel(target: puzzle.cols[col], current: counts.cols[col])
                        .frame(width: cellSize, height: countsHeight)
                }
                Spacer().frame(width: countsWidth, height: countsHeight)
            }
            ForEach(0..<n, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<n, id: \.self) { col in
                        square(row * n + col)
                    }
                    countLabel(target: puzzle.rows[row], current: counts.rows[row])
                        .frame(width: countsWidth, height: cellSize)
                }
            }
        }
        .frame(width: boardWidth, height: boardHeight)
    }

    func countLabel(target: Int, current: Int) -> some View {
        Text("\(target)")
            .font(PibblesStyle.title(min(20.0, cellSize * 0.5)))
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
    }

    var tray: some View {
        let pieces = trayPieces
        return VStack(spacing: 0.0) {
            ForEach(0..<trayRows, id: \.self) { row in
                HStack(spacing: 0.0) {
                    ForEach(0..<4, id: \.self) { col in
                        let slot = row * 4 + col
                        ZStack {
                            if slot < pieces.count {
                                trayPiece(pieces[slot])
                            }
                        }
                        .frame(width: slotWidth, height: slotHeight)
                    }
                }
            }
        }
        .frame(width: width, height: trayHeight)
    }

    func shapeView(_ index: Int, unit: Double, spacing: Double, opacity: Double) -> some View {
        let shape = ShapeCatalog.shape(puzzle.pieces[index])
        let rows = shape?.height ?? 1
        let cols = shape?.width ?? 1
        let cells = shape?.cells ?? [Cell]()
        return VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<cols, id: \.self) { col in
                        RoundedRectangle(cornerRadius: unit * 0.2)
                            .fill(cells.contains(Cell(row: row, col: col)) ? PibblesStyle.pieceColor(index).opacity(opacity) : Color.clear)
                            .frame(width: unit, height: unit)
                    }
                }
            }
        }
    }

    func trayPiece(_ index: Int) -> some View {
        let isSelected = play.selected == index
        let isLifted = dragging && touchPiece == index
        return shapeView(index, unit: 13.0, spacing: 2.0, opacity: isLifted ? 0.25 : 1.0)
            .padding(8.0)
            .background(isSelected ? PibblesStyle.sand : PibblesStyle.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            .overlay(RoundedRectangle(cornerRadius: 12.0).stroke(isSelected ? PibblesStyle.purple : PibblesStyle.line, lineWidth: isSelected ? 2.5 : 1.0))
    }

    /// The block under the finger, at board size, floating a little above it.
    func floatingPiece(_ index: Int) -> some View {
        let shape = ShapeCatalog.shape(puzzle.pieces[index])
        let pieceWidth = Double(shape?.width ?? 1) * stride - gap
        let pieceHeight = Double(shape?.height ?? 1) * stride - gap
        return shapeView(index, unit: cellSize, spacing: gap, opacity: 0.85)
            .offset(x: dragX - pieceWidth / 2.0, y: dragY - lift - pieceHeight / 2.0)
    }

    // MARK: Touch

    /// The board square at a point, or -1.
    func squareAt(x: Double, y: Double) -> Int {
        let col = Int(floor((x - gridX) / stride))
        let row = Int(floor((y - gridY) / stride))
        if x < gridX || y < gridY || col >= n || row >= n { return -1 }
        return row * n + col
    }

    /// The tray piece at a point, or -1.
    func trayPieceAt(x: Double, y: Double) -> Int {
        if y < trayY || y >= trayY + trayHeight || x < 0.0 || x >= width { return -1 }
        let slot = Int(floor((y - trayY) / slotHeight)) * 4 + Int(floor(x / slotWidth))
        let pieces = trayPieces
        return slot < pieces.count ? pieces[slot] : -1
    }

    func changed(x: Double, y: Double) {
        if reported { return }
        if startX < 0.0 {
            startX = x
            startY = y
            touchPiece = -1
            touchFromBoard = false
            let square = squareAt(x: x, y: y)
            if square >= 0 {
                if let piece = play.piece(at: square) {
                    touchPiece = piece
                    touchFromBoard = true
                }
            } else {
                touchPiece = trayPieceAt(x: x, y: y)
            }
        }
        let moved = abs(x - startX) + abs(y - startY)
        if !dragging && touchPiece >= 0 && moved > 8.0 {
            dragging = true
            if touchFromBoard {
                play.remove(touchPiece)
            }
        }
        if dragging {
            dragX = x
            dragY = y
        }
    }

    func ended(x: Double, y: Double) {
        if reported {
            reset()
            return
        }
        if dragging && touchPiece >= 0 {
            drop(touchPiece, x: x, y: y)
        } else {
            // A tap: on a square places or picks up, on a tray block selects it.
            let square = squareAt(x: x, y: y)
            if square >= 0 {
                play.tap(square: square)
            } else {
                let piece = trayPieceAt(x: x, y: y)
                if piece >= 0 { play.select(piece) }
            }
        }
        reset()
        check()
    }

    /// Puts the dragged block where it floats: its top left square is the one nearest to
    /// the block's top left corner. Dropped off the board, it goes back to the tray.
    func drop(_ piece: Int, x: Double, y: Double) {
        guard let shape = ShapeCatalog.shape(puzzle.pieces[piece]) else { return }
        let pieceWidth = Double(shape.width) * stride - gap
        let pieceHeight = Double(shape.height) * stride - gap
        let left = x - pieceWidth / 2.0
        let top = y - lift - pieceHeight / 2.0
        let col = Int(floor((left - gridX) / stride + 0.5))
        let row = Int(floor((top - gridY) / stride + 0.5))
        // Mostly off the board: back to the tray.
        if col < -1 || row < -1 || col > n - shape.width + 1 || row > n - shape.height + 1 { return }
        let clampedRow = min(max(row, 0), n - shape.height)
        let clampedCol = min(max(col, 0), n - shape.width)
        play.select(piece)
        play.tap(square: clampedRow * n + clampedCol)
    }

    func reset() {
        startX = -1.0
        startY = -1.0
        touchPiece = -1
        touchFromBoard = false
        dragging = false
    }

    func persist() {
        var values = [Int]()
        for position in play.positions { values.append(position ?? -1) }
        model.save(hints: play.hints, values: values, lists: [[Int]]())
    }

    func check() {
        persist()
        if play.isSolved && !reported {
            reported = true
            var answer = [Int]()
            for position in play.positions { answer.append(position ?? -1) }
            onSolved(play.hints, Answer.list(answer))
        }
    }
}
