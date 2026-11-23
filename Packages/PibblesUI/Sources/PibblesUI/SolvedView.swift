import SwiftUI
import PibblesCore

/// After a solve: a brush ring draws itself with your place inside, then today's ranking
/// for this puzzle slides in with your own row marked. Offline, the ring holds your time
/// and the ranking follows when it comes. Archive days have no ranking.
struct SolvedView: View {
    let kind: PuzzleKind
    let day: Int
    let milliseconds: Int
    let hints: Int
    /// False when this puzzle was solved before today: the first result stays.
    let firstSolve: Bool
    let onClose: () -> Void
    @State var store = GameStore.shared
    @State var drawn = false
    @State var rowsShown = false
    @State var ranking: RankingResponse? = nil
    @State var failed = false

    var isToday: Bool { return day == store.today }

    var body: some View {
        VStack(spacing: 10.0) {
            HStack {
                Spacer()
                Button(action: { onClose() }) {
                    Text(T.s("View board", "Bekijk bord"))
                        .font(PibblesStyle.text(13.0, .semibold))
                        .foregroundStyle(PibblesStyle.muted)
                }
                .buttonStyle(.plain)
            }
            Text(T.s("Solved!", "Opgelost!"))
                .font(PibblesStyle.title(24.0))
                .foregroundStyle(PibblesStyle.ink)
            ring
            stats
            list
            Spacer(minLength: 0.0)
            buttons
        }
        .padding(16.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PibblesStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22.0))
        .shadow(color: Color.black.opacity(0.12), radius: 10.0)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.9)) { drawn = true }
        }
        .task { await load() }
    }

    // MARK: Ring

    var ring: some View {
        ZStack {
            // The brush ring from the logo, painted on: a circle that grows clockwise from
            // the lower left (where the stroke starts) reveals the real brush texture.
            Image("brushring", bundle: .module)
                .resizable()
                .frame(width: 156.0, height: 156.0)
                .mask(
                    Circle()
                        .trim(from: 0.0, to: drawn ? 1.0 : 0.0)
                        .stroke(Color.black, style: StrokeStyle(lineWidth: 30.0, lineCap: .round))
                        .rotationEffect(Angle.degrees(135.0))
                        .frame(width: 136.0, height: 136.0)
                )
            VStack(spacing: 0.0) {
                ringContent
            }
            .scaleEffect(drawn ? 1.0 : 0.6)
            .opacity(drawn ? 1.0 : 0.0)
            .animation(Animation.spring(response: 0.45, dampingFraction: 0.55).delay(0.75), value: drawn)
            petals
        }
        .frame(width: 160.0, height: 160.0)
    }

    @ViewBuilder
    var ringContent: some View {
        if let me = ranking?.me, isToday {
            Text(T.s("place", "plaats"))
                .font(PibblesStyle.text(12.0))
                .foregroundStyle(PibblesStyle.muted)
            Text("\(me.rank)")
                .font(PibblesStyle.title(44.0))
                .foregroundStyle(PibblesStyle.purple)
            Text(T.s("of \(ranking?.total ?? me.rank)", "van \(ranking?.total ?? me.rank)"))
                .font(PibblesStyle.text(12.0))
                .foregroundStyle(PibblesStyle.muted)
        } else {
            Text(TimeText.clock(milliseconds: milliseconds))
                .font(PibblesStyle.title(34.0))
                .foregroundStyle(PibblesStyle.purple)
            Text(isToday ? (failed ? T.s("time", "tijd") : T.s("ranking follows", "ranglijst volgt")) : T.s("archive", "archief"))
                .font(PibblesStyle.text(12.0))
                .foregroundStyle(PibblesStyle.muted)
        }
    }

    /// A few blossom petals that drift down once the ring is drawn.
    var petals: some View {
        ZStack {
            petal(x: -58.0, y: -50.0, dx: -14.0, delay: 0.95)
            petal(x: 54.0, y: -58.0, dx: 12.0, delay: 1.05)
            petal(x: 64.0, y: 12.0, dx: 16.0, delay: 1.15)
            petal(x: -64.0, y: 24.0, dx: -10.0, delay: 1.1)
        }
    }

    func petal(x: Double, y: Double, dx: Double, delay: Double) -> some View {
        RoundedRectangle(cornerRadius: 3.0)
            .fill(PibblesStyle.rose)
            .frame(width: 8.0, height: 8.0)
            .rotationEffect(Angle.degrees(drawn ? 200.0 : 45.0))
            .offset(x: x + (drawn ? dx : 0.0), y: y + (drawn ? 60.0 : 0.0))
            .opacity(drawn ? 0.0 : 1.0)
            .animation(Animation.easeOut(duration: 1.4).delay(delay), value: drawn)
    }

    // MARK: Stats and ranking

    var stats: some View {
        let streak = store.book.streakView(today: store.today).streak
        return HStack(spacing: 24.0) {
            stat(TimeText.clock(milliseconds: milliseconds), T.s("time", "tijd"), PibblesStyle.ink)
            stat("\(hints)", T.s("hints", "hints"), PibblesStyle.ink)
            stat("\(streak)", T.s("streak", "reeks"), PibblesStyle.orange)
        }
    }

    func stat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 0.0) {
            Text(value)
                .font(PibblesStyle.title(16.0))
                .foregroundStyle(color)
            Text(label)
                .font(PibblesStyle.text(11.0))
                .foregroundStyle(PibblesStyle.muted)
        }
    }

    /// The rows to show: the top four, or the top three and your own row below them.
    var rows: [RankEntry] {
        guard let ranking else { return [RankEntry]() }
        var result = [RankEntry]()
        if let me = ranking.me, me.rank > 4 {
            for entry in ranking.top {
                if entry.rank <= 3 { result.append(entry) }
            }
            result.append(me)
        } else {
            for entry in ranking.top {
                if entry.rank <= 4 { result.append(entry) }
            }
        }
        return result
    }

    @ViewBuilder
    var list: some View {
        if !firstSolve && isToday {
            note(T.s("Your first result counts for the ranking.", "Je eerste uitslag telt voor de ranglijst."))
        }
        if !isToday {
            note(T.s("Saved in your archive. Only today's puzzles have a ranking.", "Bewaard in je archief. Alleen de puzzels van vandaag hebben een ranglijst."))
        } else if ranking != nil {
            let entries = rows
            VStack(spacing: 5.0) {
                ForEach(0..<entries.count, id: \.self) { index in
                    if index == 3 && entries[index].rank > 4 {
                        Text("···")
                            .font(PibblesStyle.text(13.0))
                            .foregroundStyle(PibblesStyle.muted)
                    }
                    row(entries[index])
                        .opacity(rowsShown ? 1.0 : 0.0)
                        .offset(y: rowsShown ? 0.0 : 10.0)
                        .animation(Animation.easeOut(duration: 0.35).delay(0.08 * Double(index)), value: rowsShown)
                }
            }
        } else if failed {
            note(T.s("The ranking is not reachable right now.", "De ranglijst is nu niet bereikbaar."))
        }
    }

    func row(_ entry: RankEntry) -> some View {
        let isMine = ranking?.me?.rank == entry.rank && ranking?.me?.score == entry.score
        return HStack(spacing: 10.0) {
            Text("\(entry.rank)")
                .font(PibblesStyle.title(15.0))
                .foregroundStyle(isMine ? PibblesStyle.purple : PibblesStyle.orange)
                .frame(width: 24.0, alignment: .leading)
            Text(isMine ? entry.name + T.s(" (you)", " (jij)") : entry.name)
                .font(PibblesStyle.text(14.0, isMine ? .semibold : .regular))
                .foregroundStyle(PibblesStyle.ink)
                .lineLimit(1)
            Spacer()
            Text(TimeText.clock(milliseconds: entry.score))
                .font(PibblesStyle.text(14.0, .semibold))
                .foregroundStyle(PibblesStyle.ink)
        }
        .padding(.horizontal, 12.0)
        .padding(.vertical, 8.0)
        .background(isMine ? PibblesStyle.purple.opacity(0.18) : PibblesStyle.background)
        .clipShape(RoundedRectangle(cornerRadius: 10.0))
        .overlay(RoundedRectangle(cornerRadius: 10.0).stroke(isMine ? PibblesStyle.purple : Color.clear, lineWidth: 1.5))
    }

    func note(_ text: String) -> some View {
        Text(text)
            .font(PibblesStyle.text(13.0))
            .foregroundStyle(PibblesStyle.muted)
            .multilineTextAlignment(.center)
    }

    // MARK: Buttons

    /// The next puzzle of today that is not solved yet, other than this one.
    var nextKind: PuzzleKind? {
        for item in PuzzleKind.allCases {
            if item != kind && store.book.record(kind: item, day: store.today) == nil { return item }
        }
        return nil
    }

    var buttons: some View {
        HStack(spacing: 10.0) {
            if isToday {
                Button(action: {
                    store.rankingKind = kind
                    store.tab = 2
                }) {
                    Text(T.s("Full ranking", "Hele ranglijst"))
                        .font(PibblesStyle.text(14.0, .semibold))
                        .foregroundStyle(PibblesStyle.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11.0)
                        .overlay(Capsule().stroke(PibblesStyle.purple.opacity(0.5), lineWidth: 1.0))
                }
                .buttonStyle(.plain)
            }
            if let next = nextKind {
                NavigationLink(destination: PlayView(kind: next, day: store.today)) {
                    Text(T.s("Next: ", "Volgende: ") + KindInfo.name(next))
                        .font(PibblesStyle.text(14.0, .semibold))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11.0)
                        .background(PibblesStyle.purple)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Loading

    /// Today's ranking. A first solve may still be on its way to the server, so when the
    /// answer does not hold this phone's result yet, ask again a few times.
    func load() async {
        if !isToday { return }
        var attempt = 0
        while attempt < 4 {
            if attempt > 0 {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
            if let answer = await ScoreUploader.ranking(kind: kind, day: day) {
                ranking = answer
                failed = false
                withAnimation { rowsShown = true }
                if answer.me != nil { return }
            } else {
                failed = true
            }
            attempt += 1
        }
    }
}
