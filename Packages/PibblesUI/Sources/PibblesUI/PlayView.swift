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
}

/// Plays one puzzle of one day: clock, board, hints and the result. The first solve of a
/// day is final (ProgressBook); playing it again afterwards does not change the result.
struct PlayView: View {
    let kind: PuzzleKind
    let day: Int
    @State var store = GameStore.shared
    @State var loaded: LoadedPuzzle? = nil
    @State var startedAt = Date()
    @State var now = Date()
    @State var finishedMilliseconds: Int? = nil
    @State var finishedHints = 0
    @State var firstSolve = false
    @State var showRules = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16.0) {
                    header
                    if showRules {
                        rulesCard
                    }
                    if let result = finishedMilliseconds {
                        resultCard(milliseconds: result)
                    }
                    if let loaded {
                        board(loaded, width: min(geometry.size.width - 32.0, 460.0))
                    } else {
                        VStack(spacing: 12.0) {
                            ProgressView()
                            Text(T.s("Setting out today's puzzle…", "De puzzel wordt klaargezet…"))
                                .font(PibblesStyle.text(14.0))
                                .foregroundStyle(PibblesStyle.muted)
                        }
                        .frame(height: 240.0)
                    }
                }
                .padding(.horizontal, 16.0)
                .padding(.vertical, 12.0)
            }
        }
        .pibblesScreen()
        .navigationTitle(KindInfo.name(kind))
        .task {
            await load()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if finishedMilliseconds == nil { now = Date() }
            }
        }
    }

    var header: some View {
        HStack(spacing: 12.0) {
            KindBadge(kind: kind, size: 40.0)
            VStack(alignment: .leading, spacing: 0.0) {
                Text(T.weekday(day) + " · " + T.difficulty(day))
                    .font(PibblesStyle.text(16.0, .semibold))
                    .foregroundStyle(PibblesStyle.ink)
                Text(PuzzleCalendar.dateKey(day: day))
                    .font(PibblesStyle.text(12.0))
                    .foregroundStyle(PibblesStyle.muted)
            }
            Spacer()
            Text(TimeText.clock(milliseconds: finishedMilliseconds ?? elapsed))
                .font(PibblesStyle.text(18.0, .semibold))
                .foregroundStyle(PibblesStyle.ink)
            Button(showRules ? T.s("Hide rules", "Verberg regels") : T.s("Rules", "Regels")) { showRules = !showRules }
                .font(PibblesStyle.text(14.0, .semibold))
                .foregroundStyle(PibblesStyle.purple)
        }
    }

    var rulesCard: some View {
        VStack(alignment: .leading, spacing: 6.0) {
            ForEach(KindInfo.rules(kind), id: \.self) { rule in
                Text("•  " + rule)
                    .font(PibblesStyle.text(14.0))
                    .foregroundStyle(PibblesStyle.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .card(14.0)
    }

    func resultCard(milliseconds: Int) -> some View {
        let record = store.book.record(kind: kind, day: day)
        return VStack(spacing: 6.0) {
            Text(T.s("Solved!", "Opgelost!"))
                .font(PibblesStyle.title(24.0))
                .foregroundStyle(PibblesStyle.good)
            Text(TimeText.clock(milliseconds: milliseconds) + " · " + T.hints(finishedHints))
                .font(PibblesStyle.text(16.0, .semibold))
                .foregroundStyle(PibblesStyle.ink)
            if firstSolve {
                Text(day == store.today ? T.s("Counted for today's ranking and your streak.", "Telt mee voor de ranglijst van vandaag en je reeks.") : T.s("Saved in your archive.", "Bewaard in je archief."))
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
            } else if let record {
                Text(T.s("Your first result stays: ", "Je eerste uitslag blijft staan: ") + TimeText.clock(milliseconds: record.milliseconds) + ".")
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .card(14.0)
    }

    @ViewBuilder
    func board(_ loaded: LoadedPuzzle, width: Double) -> some View {
        if let puzzle = loaded.blocks {
            BlocksBoardView(puzzle: puzzle, width: width, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.logic {
            LogicBoardView(puzzle: puzzle, width: width, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.patterns {
            PatternsBoardView(puzzle: puzzle, width: width, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.numbers {
            NumbersBoardView(puzzle: puzzle, width: width, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.stars {
            StarsBoardView(puzzle: puzzle, width: width, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else if let puzzle = loaded.sums {
            SumsBoardView(puzzle: puzzle, width: width, onSolved: { hints, answer in solved(hints: hints, answer: answer) })
        } else {
            Text(T.s("This puzzle is coming soon.", "Deze puzzel komt binnenkort."))
                .font(PibblesStyle.text(15.0))
                .foregroundStyle(PibblesStyle.muted)
                .frame(height: 200.0)
        }
    }

    var elapsed: Int {
        return Int(now.timeIntervalSince(startedAt) * 1000.0)
    }

    func solved(hints: Int, answer: String) {
        if finishedMilliseconds != nil { return }
        let milliseconds = max(0, Int(Date().timeIntervalSince(startedAt) * 1000.0))
        finishedMilliseconds = milliseconds
        finishedHints = hints
        firstSolve = store.solved(kind: kind, day: day, milliseconds: milliseconds, hints: hints)
        if firstSolve && day == store.today {
            let kindValue = kind
            let dayValue = day
            Task {
                await ScoreUploader.submit(kind: kindValue, day: dayValue, milliseconds: milliseconds, hints: hints, answer: answer)
            }
        }
    }

    /// Generates the puzzle. Generation takes milliseconds (Blocks on Sunday up to about half
    /// a second on an older phone), so it runs here after one frame with the spinner.
    /// `Task.detached` never delivered its result in Skip's Android build (22 November).
    func load() async {
        if loaded != nil { return }
        try? await Task.sleep(nanoseconds: 50_000_000)
        loaded = PlayView.make(kind: kind, day: day)
        startedAt = Date()
        now = startedAt
    }

    static func make(kind: PuzzleKind, day: Int) -> LoadedPuzzle {
        var result = LoadedPuzzle()
        switch kind {
        case PuzzleKind.blocks: result.blocks = Daily.blocks(day: day)
        case PuzzleKind.logic: result.logic = Daily.logic(day: day)
        case PuzzleKind.patterns: result.patterns = Daily.patterns(day: day)
        case PuzzleKind.numbers: result.numbers = Daily.numbers(day: day)
        case PuzzleKind.stars: result.stars = StarsGenerator.generate(weekday: PuzzleCalendar.weekday(day: day), seed: PuzzleKind.stars.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
        case PuzzleKind.sums: result.sums = SumsGenerator.generate(weekday: PuzzleCalendar.weekday(day: day), seed: PuzzleKind.sums.seed(dateKey: PuzzleCalendar.dateKey(day: day)))
        default: break
        }
        return result
    }
}

/// Buttons under a board: hint and start over.
struct BoardControls: View {
    let hints: Int
    let onHint: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12.0) {
            Button(action: onClear) {
                Text(T.s("Start over", "Opnieuw"))
                    .font(PibblesStyle.text(15.0, .semibold))
                    .foregroundStyle(PibblesStyle.ink)
                    .padding(.horizontal, 16.0)
                    .padding(.vertical, 10.0)
                    .background(PibblesStyle.surface)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            Button(action: onHint) {
                Text(hints == 0 ? T.s("Hint", "Hint") : "Hint (\(hints))")
                    .font(PibblesStyle.text(15.0, .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16.0)
                    .padding(.vertical, 10.0)
                    .background(PibblesStyle.orange)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}
