import SwiftUI
import PibblesCore

/// The loaded puzzle of one day, whatever its kind.
struct LoadedPuzzle {
    var blocks: Puzzle? = nil
    var logic: LogicPuzzle? = nil
    var patterns: PatternsPuzzle? = nil
    var numbers: NumbersPuzzle? = nil
    var sums: SumsPuzzle? = nil
    var stars: StarsPuzzle? = nil
    var links: LinksPuzzle? = nil
}

/// Loads the puzzle off the main thread and runs the clock. A class, so the work does
/// not depend on SwiftUI restarting a `.task` (on Android a `.task` that loaded the
/// puzzle never delivered it, 22 November).
@Observable
final class PlayModel {
    let kind: PuzzleKind
    let day: Int
    var loaded: LoadedPuzzle? = nil
    var startedAt = Date()
    var now = Date()
    var finished = false
    var started = false

    init(kind: PuzzleKind, day: Int) {
        self.kind = kind
        self.day = day
    }

    /// Called when the screen appears; SwiftUI creates many PlayView values (one per
    /// link), so nothing may start in `init`.
    func start() {
        if started { return }
        started = true
        let model = self
        Task {
            await model.load()
        }
        Task {
            await model.tick()
        }
    }

    func load() async {
        let kindValue = kind
        let dayValue = day
        #if SKIP
        let result = kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Default) {
            PlayView.make(kind: kindValue, day: dayValue)
        }
        #else
        let result = await Task.detached {
            return PlayView.make(kind: kindValue, day: dayValue)
        }.value
        #endif
        loaded = result
        startedAt = Date()
        now = startedAt
    }

    func tick() async {
        while !finished {
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !finished { now = Date() }
        }
    }
}

/// Plays one puzzle of one day: clock, board, hints and the result. The first solve of a
/// day is final (ProgressBook); playing it again afterwards does not change the result.
struct PlayView: View {
    /// The puzzle this screen was opened for. The model keeps it fixed: SwiftUI may hand
    /// this view a new `kind` when the link that opened it changes (the home card moves on
    /// to the next puzzle after a solve), so everything below reads `model.kind`.
    let kind: PuzzleKind
    let day: Int
    @State var store = GameStore.shared
    @State var model: PlayModel
    @State var finishedMilliseconds: Int? = nil
    @State var finishedHints = 0
    @State var firstSolve = false
    @State var showRules = false

    init(kind: PuzzleKind, day: Int) {
        self.kind = kind
        self.day = day
        self._model = State(initialValue: PlayModel(kind: kind, day: day))
        // A puzzle you never solved opens with its rules shown.
        self._showRules = State(initialValue: GameStore.shared.book.stats(kind: kind).solved == 0)
    }

    var body: some View {
        GeometryReader { geometry in
            // No ScrollView: the whole puzzle fits one screen, and a scroll view would steal
            // the drags of Blocks and Links. The board takes the room left under the header.
            let width = min(geometry.size.width - 32.0, 460.0)
            let boardHeight = geometry.size.height - 24.0 - 56.0 - 12.0
            VStack(spacing: 12.0) {
                header
                if let loaded = model.loaded {
                    ZStack(alignment: .bottom) {
                        board(loaded, width: width, height: boardHeight)
                        if let result = finishedMilliseconds {
                            resultCard(milliseconds: result)
                        }
                    }
                } else {
                    Spacer()
                    ProgressView()
                    Text(T.s("Setting out today's puzzle…", "De puzzel wordt klaargezet…"))
                        .font(PibblesStyle.text(14.0))
                        .foregroundStyle(PibblesStyle.muted)
                }
                Spacer(minLength: 0.0)
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 12.0)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .pibblesScreen()
        .navigationTitle(KindInfo.name(model.kind))
        .onAppear { model.start() }
        .sheet(isPresented: $showRules) {
            rulesSheet
        }
    }

    var header: some View {
        HStack(spacing: 12.0) {
            KindBadge(kind: model.kind, size: 40.0)
            VStack(alignment: .leading, spacing: 0.0) {
                Text(T.weekday(model.day) + " · " + T.difficulty(model.day))
                    .font(PibblesStyle.text(16.0, .semibold))
                    .foregroundStyle(PibblesStyle.ink)
                Text(PuzzleCalendar.dateKey(day: model.day))
                    .font(PibblesStyle.text(12.0))
                    .foregroundStyle(PibblesStyle.muted)
            }
            Spacer()
            ClockLabel(model: model, finishedMilliseconds: finishedMilliseconds)
            Button(T.s("Rules", "Regels")) { showRules = true }
                .font(PibblesStyle.text(14.0, .semibold))
                .foregroundStyle(PibblesStyle.purple)
        }
    }

    /// The rules in a sheet, so they never push the board off the screen.
    var rulesSheet: some View {
        VStack(alignment: .leading, spacing: 16.0) {
            HStack(spacing: 12.0) {
                KindBadge(kind: model.kind, size: 44.0)
                Text(KindInfo.name(model.kind))
                    .font(PibblesStyle.title(24.0))
                    .foregroundStyle(PibblesStyle.ink)
                Spacer()
            }
            ForEach(KindInfo.rules(model.kind), id: \.self) { rule in
                Text("•  " + rule)
                    .font(PibblesStyle.text(16.0))
                    .foregroundStyle(PibblesStyle.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            Button(action: { showRules = false }) {
                Text(T.s("Play", "Spelen"))
                    .font(PibblesStyle.text(17.0, .semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14.0)
                    .background(PibblesStyle.purple)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24.0)
        .background(PibblesStyle.background.ignoresSafeArea())
    }

    func resultCard(milliseconds: Int) -> some View {
        let record = store.book.record(kind: model.kind, day: model.day)
        return VStack(spacing: 6.0) {
            Text(T.s("Solved!", "Opgelost!"))
                .font(PibblesStyle.title(24.0))
                .foregroundStyle(PibblesStyle.good)
            Text(TimeText.clock(milliseconds: milliseconds) + " · " + T.hints(finishedHints))
                .font(PibblesStyle.text(16.0, .semibold))
                .foregroundStyle(PibblesStyle.ink)
            if firstSolve {
                Text(model.day == store.today ? T.s("Counted for today's ranking and your streak.", "Telt mee voor de ranglijst van vandaag en je reeks.") : T.s("Saved in your archive.", "Bewaard in je archief."))
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
            } else if let record {
                Text(T.s("Your first result stays: ", "Je eerste uitslag blijft staan: ") + TimeText.clock(milliseconds: record.milliseconds) + ".")
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(14.0)
        .background(PibblesStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18.0))
        .shadow(color: Color.black.opacity(0.15), radius: 8.0)
    }

    @ViewBuilder
    func board(_ loaded: LoadedPuzzle, width: Double, height: Double) -> some View {
        if let puzzle = loaded.blocks {
            BlocksBoardView(puzzle: puzzle, width: width, height: height, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.logic {
            LogicBoardView(puzzle: puzzle, width: width, height: height, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.patterns {
            PatternsBoardView(puzzle: puzzle, width: width, height: height, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.numbers {
            NumbersBoardView(puzzle: puzzle, width: width, height: height, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.links {
            LinksBoardView(puzzle: puzzle, width: width, height: height, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.stars {
            StarsBoardView(puzzle: puzzle, width: width, height: height, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.sums {
            SumsBoardView(puzzle: puzzle, width: width, height: height, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else {
            Text(T.s("This puzzle is coming soon.", "Deze puzzel komt binnenkort."))
                .font(PibblesStyle.text(15.0))
                .foregroundStyle(PibblesStyle.muted)
                .frame(height: 200.0)
        }
    }


    func solved(hints: Int, answer: String) {
        if finishedMilliseconds != nil { return }
        let milliseconds = max(0, Int(Date().timeIntervalSince(model.startedAt) * 1000.0))
        model.finished = true
        finishedMilliseconds = milliseconds
        finishedHints = hints
        firstSolve = store.solved(kind: model.kind, day: model.day, milliseconds: milliseconds, hints: hints)
        if firstSolve && model.day == store.today {
            let kindValue = model.kind
            let dayValue = model.day
            Task {
                await ScoreUploader.submit(kind: kindValue, day: dayValue, milliseconds: milliseconds, hints: hints, answer: answer)
            }
        }
    }

    static func make(kind: PuzzleKind, day: Int) -> LoadedPuzzle {
        var result = LoadedPuzzle()
        switch kind {
        case PuzzleKind.blocks: result.blocks = Daily.blocks(day: day)
        case PuzzleKind.logic: result.logic = Daily.logic(day: day)
        case PuzzleKind.patterns: result.patterns = Daily.patterns(day: day)
        case PuzzleKind.numbers: result.numbers = Daily.numbers(day: day)
        case PuzzleKind.stars: result.stars = StarsGenerator.generate(weekday: PuzzleCalendar.weekday(day: day), seed: PuzzleKind.stars.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
        case PuzzleKind.links: result.links = LinksGenerator.generate(weekday: PuzzleCalendar.weekday(day: day), seed: PuzzleKind.links.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
        case PuzzleKind.sums: result.sums = SumsGenerator.generate(weekday: PuzzleCalendar.weekday(day: day), seed: PuzzleKind.sums.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
        }
        return result
    }
}

/// The running clock. Its own view, so only this label redraws twice a second and the
/// board does not (redrawing the board while the clock ticked swallowed taps, 22 November).
struct ClockLabel: View {
    let model: PlayModel
    let finishedMilliseconds: Int?

    var body: some View {
        let running = Int(model.now.timeIntervalSince(model.startedAt) * 1000.0)
        return Text(TimeText.clock(milliseconds: finishedMilliseconds ?? running))
            .font(PibblesStyle.text(18.0, .semibold))
            .foregroundStyle(PibblesStyle.ink)
    }
}

/// Buttons under a board, as on the style board: start over, and a hint with its count.
struct BoardControls: View {
    let hints: Int
    let onHint: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 18.0) {
            Button(action: onClear) {
                RestartIcon()
                    .stroke(PibblesStyle.ink, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 22.0, height: 22.0)
                    .frame(width: 54.0, height: 54.0)
                    .background(PibblesStyle.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            Button(action: onHint) {
                HStack(spacing: 8.0) {
                    BulbIcon()
                        .stroke(PibblesStyle.mustard, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                        .frame(width: 20.0, height: 22.0)
                    Text(hints == 0 ? T.s("Hint", "Hint") : "\(hints)")
                        .font(PibblesStyle.text(16.0, .semibold))
                        .foregroundStyle(PibblesStyle.ink)
                }
                .padding(.horizontal, 20.0)
                .frame(height: 54.0)
                .background(PibblesStyle.surface)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}
