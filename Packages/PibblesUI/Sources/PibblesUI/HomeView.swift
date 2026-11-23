import SwiftUI
import PibblesCore

/// Home, as on the style board: logo, landscape, today's puzzles with a play button,
/// streak, jokers and today's tally, the market's stalls, and the list of today's puzzles.
struct HomeView: View {
    @State var store = GameStore.shared
    @State var today = PuzzleCalendar.today()
    /// The puzzle behind the big card; set when home appears, not on every change, so an
    /// open puzzle screen is not handed another puzzle when this one gets solved.
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
                todayCard
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
                HStack {
                    Text(T.s("Puzzle Market", "Puzzelmarkt"))
                        .font(PibblesStyle.title(20.0))
                        .foregroundStyle(PibblesStyle.ink)
                    Spacer()
                }
                HStack(spacing: 10.0) {
                    ForEach(KindInfo.stalls, id: \.self) { stall in
                        NavigationLink(destination: StallView(stall: stall)) {
                            VStack(spacing: 8.0) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12.0).fill(PibblesStyle.stallColor(stall))
                                    StallIcon(stall: stall, size: 34.0)
                                }
                                .frame(width: 46.0, height: 46.0)
                                Text(stall)
                                    .font(PibblesStyle.text(13.0, .semibold))
                                    .foregroundStyle(PibblesStyle.ink)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14.0)
                            .background(PibblesStyle.stallColor(stall).opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(T.s("Today's puzzles", "Puzzels van vandaag"))
                    .font(PibblesStyle.title(20.0))
                    .foregroundStyle(PibblesStyle.ink)
                VStack(spacing: 10.0) {
                    ForEach(PuzzleKind.allCases, id: \.self) { kind in
                        NavigationLink(destination: PlayView(kind: kind, day: today)) {
                            PuzzleRow(kind: kind, day: today, store: store)
                        }
                        .buttonStyle(.plain)
                    }
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

    /// The first puzzle of today that is not solved yet, or the first of all.
    var nextKind: PuzzleKind {
        for kind in PuzzleKind.allCases {
            if store.book.record(kind: kind, day: today) == nil { return kind }
        }
        return PuzzleKind.blocks
    }

    var todayCard: some View {
        NavigationLink(destination: PlayView(kind: cardKind, day: today)) {
            HStack(spacing: 14.0) {
                AssetIcon(name: "icon-calendar", size: 36.0, color: PibblesStyle.ink)
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(solvedToday == PuzzleCase.count ? T.s("All done today!", "Alles gedaan vandaag!") : T.s("Today's puzzle", "Puzzel van vandaag") + ": " + KindInfo.name(cardKind))
                        .font(PibblesStyle.text(18.0, .bold))
                        .foregroundStyle(PibblesStyle.ink)
                    Text(T.weekday(today) + " · " + T.difficulty(today))
                        .font(PibblesStyle.text(14.0))
                        .foregroundStyle(PibblesStyle.muted)
                }
                Spacer()
                ZStack {
                    Circle().fill(PibblesStyle.purple)
                    PlayIcon().fill(Color.white).frame(width: 16.0, height: 18.0).offset(x: 2.0)
                }
                .frame(width: 50.0, height: 50.0)
            }
            .padding(16.0)
            .background(PibblesStyle.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20.0))
        }
        .buttonStyle(.plain)
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
