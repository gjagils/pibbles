import SwiftUI
import PibblesCore

/// Home: today's puzzles, the streak and the jokers.
struct HomeView: View {
    @State var store = GameStore.shared
    @State var today = PuzzleCalendar.today()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20.0) {
                HStack(spacing: 12.0) {
                    PibblesLogo(size: 52.0)
                    VStack(alignment: .leading, spacing: 0.0) {
                        Text("Pibbles")
                            .font(PibblesStyle.title(30.0))
                            .foregroundStyle(PibblesStyle.ink)
                        Text(T.s("DAILY PUZZLES", "DAGELIJKSE PUZZELS"))
                            .font(PibblesStyle.text(12.0, .semibold))
                            .tracking(3.0)
                            .foregroundStyle(PibblesStyle.muted)
                    }
                    Spacer()
                }
                let view = store.book.streakView(today: today)
                HStack(spacing: 10.0) {
                    StatTile(value: "\(view.streak)", label: T.s("Streak", "Reeks"), color: PibblesStyle.orange)
                    StatTile(value: "\(view.jokers)", label: T.s("Jokers", "Jokers"), color: PibblesStyle.purple)
                    StatTile(value: "\(solvedToday)/\(PuzzleKind.allCases.count)", label: T.s("Today", "Vandaag"), color: PibblesStyle.teal)
                }
                if view.lost {
                    Text(T.s("Your streak restarted: too few jokers for the days you missed.", "Je reeks begon opnieuw: te weinig jokers voor de gemiste dagen."))
                        .font(PibblesStyle.text(13.0))
                        .foregroundStyle(PibblesStyle.muted)
                } else if view.used > 0 {
                    Text(view.used == 1 ? T.s("Solve a puzzle today and a joker covers the day you missed.", "Los vandaag een puzzel op, dan dekt een joker de gemiste dag.") : T.s("Solve a puzzle today and \(view.used) jokers cover the days you missed.", "Los vandaag een puzzel op, dan dekken \(view.used) jokers de gemiste dagen."))
                        .font(PibblesStyle.text(13.0))
                        .foregroundStyle(PibblesStyle.muted)
                }
                VStack(alignment: .leading, spacing: 4.0) {
                    Text(T.s("Today's puzzles", "Puzzels van vandaag"))
                        .font(PibblesStyle.title(22.0))
                        .foregroundStyle(PibblesStyle.ink)
                    Text(T.weekday(today) + " · " + T.difficulty(today))
                        .font(PibblesStyle.text(14.0))
                        .foregroundStyle(PibblesStyle.muted)
                }
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
            .padding(.vertical, 12.0)
        }
        .pibblesScreen()
        .hiddenNavigationBar()
        .onAppear { today = PuzzleCalendar.today() }
    }

    var solvedToday: Int {
        var count = 0
        for kind in PuzzleKind.allCases {
            if store.book.record(kind: kind, day: today) != nil { count += 1 }
        }
        return count
    }
}
