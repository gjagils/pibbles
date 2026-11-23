import SwiftUI
import PibblesCore

/// Home ("Today"): logo and landscape, streak, jokers and today's tally, and the market:
/// a card per stall with today's puzzles in it. The puzzle to go on with stands out.
struct HomeView: View {
    @State var store = GameStore.shared
    @State var today = PuzzleCalendar.today()
    /// The puzzle to go on with (highlighted); set when home appears, not on every change,
    /// so the highlight does not jump while a puzzle is open.
    @State var cardKind = PuzzleKind.blocks

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18.0) {
                ZStack(alignment: .bottom) {
                    Landscape(height: 150.0)
                    HStack(spacing: 12.0) {
                        PibblesLogo(size: 56.0)
                        VStack(alignment: .leading, spacing: 0.0) {
                            Text("Pibbles")
                                .font(PibblesStyle.title(34.0))
                                .foregroundStyle(PibblesStyle.ink)
                            Text(T.s("DAILY PUZZLES", "DAGELIJKSE PUZZELS"))
                                .font(PibblesStyle.text(11.0, .semibold))
                                .tracking(3.0)
                                .foregroundStyle(PibblesStyle.muted)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 8.0)
                }
                let view = store.book.streakView(today: today)
                HStack(spacing: 10.0) {
                    StatTile(value: "\(view.streak)", label: T.s("Streak", "Reeks"), color: PibblesStyle.orange, icon: "flame")
                    StatTile(value: "\(view.jokers)", label: T.s("Jokers", "Jokers"), color: PibblesStyle.purple, icon: "cube")
                    StatTile(value: "\(solvedToday)/\(PuzzleCase.count)", label: T.s("Today", "Vandaag"), color: PibblesStyle.mustard, icon: "trophy")
                }
                if view.lost {
                    note(T.s("Your streak restarted: too few jokers for the days you missed.", "Je reeks begon opnieuw: te weinig jokers voor de gemiste dagen."))
                } else if view.used > 0 {
                    note(view.used == 1 ? T.s("Solve a puzzle today and a joker covers the day you missed.", "Los vandaag een puzzel op, dan dekt een joker de gemiste dag.") : T.s("Solve a puzzle today and \(view.used) jokers cover the days you missed.", "Los vandaag een puzzel op, dan dekken \(view.used) jokers de gemiste dagen."))
                }
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(T.s("Puzzle Market", "Puzzelmarkt"))
                        .font(PibblesStyle.title(20.0))
                        .foregroundStyle(PibblesStyle.ink)
                    Text(solvedToday == PuzzleCase.count ? T.s("All done today!", "Alles gedaan vandaag!") : T.weekday(today) + " · " + T.difficulty(today))
                        .font(PibblesStyle.text(13.0))
                        .foregroundStyle(PibblesStyle.muted)
                }
                ForEach(KindInfo.stalls, id: \.self) { stall in
                    StallTodayCard(stall: stall, day: today, store: store, started: started, next: solvedToday == PuzzleCase.count ? nil : cardKind)
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.bottom, 16.0)
        }
        .pibblesScreen()
        .hiddenNavigationBar()
        .onAppear {
            today = PuzzleCalendar.today()
            cardKind = nextKind
        }
    }

    /// Today's puzzles with a saved, unfinished game. Reading `savedGames` makes this
    /// update when a puzzle screen saves on its way out (after home has appeared).
    var started: [PuzzleKind] {
        let _ = store.savedGames
        var begun = [PuzzleKind]()
        for kind in PuzzleKind.allCases {
            let game = SavedGame.load(kind: kind, day: today)
            if game.elapsedMilliseconds > 0 || !game.values.isEmpty { begun.append(kind) }
        }
        return begun
    }

    /// The puzzle to go on with: a begun one that is not solved, else the first unsolved one.
    var nextKind: PuzzleKind {
        let begun = started
        for kind in PuzzleKind.allCases {
            if begun.contains(kind) && store.book.record(kind: kind, day: today) == nil { return kind }
        }
        for kind in PuzzleKind.allCases {
            if store.book.record(kind: kind, day: today) == nil { return kind }
        }
        return PuzzleKind.blocks
    }

    func note(_ text: String) -> some View {
        Text(text)
            .font(PibblesStyle.text(13.0))
            .foregroundStyle(PibblesStyle.muted)
    }

    var solvedToday: Int {
        var count = 0
        for kind in PuzzleKind.allCases {
            if store.book.record(kind: kind, day: today) != nil { count += 1 }
        }
        return count
    }
}

enum PuzzleCase {
    static let count = PuzzleKind.allCases.count
}

/// A stall as on the market, with today's puzzles in it. The header leads to the stall
/// (its week and rules); each row plays today's puzzle.
struct StallTodayCard: View {
    let stall: String
    let day: Int
    let store: GameStore
    let started: [PuzzleKind]
    /// The puzzle to go on with, or nil when today is done.
    let next: PuzzleKind?

    var holdsNext: Bool {
        if let next = next { return KindInfo.kinds(stall: stall).contains(next) }
        return false
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image("hill-" + stall.lowercased(), bundle: .module)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150.0, height: 60.0)
            VStack(spacing: 0.0) {
                NavigationLink(destination: StallView(stall: stall)) {
                    HStack(spacing: 14.0) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16.0)
                                .fill(PibblesStyle.stallColor(stall))
                            StallIcon(stall: stall, size: 40.0)
                        }
                        .frame(width: 58.0, height: 58.0)
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(stall)
                                .font(PibblesStyle.title(20.0))
                                .foregroundStyle(PibblesStyle.ink)
                            Text(KindInfo.stallTagline(stall))
                                .font(PibblesStyle.text(13.0))
                                .foregroundStyle(PibblesStyle.muted)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(T.s("Week", "Week") + " ›")
                            .font(PibblesStyle.text(13.0, .semibold))
                            .foregroundStyle(PibblesStyle.muted)
                    }
                }
                .buttonStyle(.plain)
                ForEach(KindInfo.kinds(stall: stall), id: \.self) { kind in
                    Rectangle()
                        .fill(PibblesStyle.line)
                        .frame(height: 1.0)
                        .padding(.vertical, 10.0)
                    NavigationLink(destination: PlayView(kind: kind, day: day)) {
                        row(kind)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14.0)
        }
        .background(PibblesStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20.0))
        .overlay(RoundedRectangle(cornerRadius: 20.0).stroke(holdsNext ? PibblesStyle.purple : Color.clear, lineWidth: 2.0))
    }

    func row(_ kind: PuzzleKind) -> some View {
        HStack(spacing: 12.0) {
            KindBadge(kind: kind, size: 40.0, color: PibblesStyle.stallColor(stall))
            VStack(alignment: .leading, spacing: 2.0) {
                Text(KindInfo.name(kind))
                    .font(PibblesStyle.text(16.0, .semibold))
                    .foregroundStyle(PibblesStyle.ink)
                Text(KindInfo.tagline(kind))
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
                    .lineLimit(1)
            }
            Spacer()
            status(kind)
        }
    }

    @ViewBuilder
    func status(_ kind: PuzzleKind) -> some View {
        if let record = store.book.record(kind: kind, day: day) {
            Text("✓ " + TimeText.clock(milliseconds: record.milliseconds))
                .font(PibblesStyle.text(14.0, .semibold))
                .foregroundStyle(PibblesStyle.good)
                .padding(.horizontal, 12.0)
                .padding(.vertical, 7.0)
                .background(PibblesStyle.good.opacity(0.14))
                .clipShape(Capsule())
        } else {
            let label = started.contains(kind) ? T.s("Continue", "Verder") : T.s("Play", "Speel")
            if kind == next {
                Text(label)
                    .font(PibblesStyle.text(14.0, .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14.0)
                    .padding(.vertical, 7.0)
                    .background(PibblesStyle.purple)
                    .clipShape(Capsule())
            } else {
                Text(label)
                    .font(PibblesStyle.text(14.0, .semibold))
                    .foregroundStyle(PibblesStyle.purple)
                    .padding(.horizontal, 14.0)
                    .padding(.vertical, 7.0)
                    .overlay(Capsule().stroke(PibblesStyle.purple.opacity(0.5), lineWidth: 1.0))
            }
        }
    }
}
