import SwiftUI
import PibblesCore

/// The market: four stalls, each with its puzzles.
struct MarketView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                HStack(spacing: 12.0) {
                    PibblesLogo(size: 44.0)
                    VStack(alignment: .leading, spacing: 0.0) {
                        Text(T.s("Puzzle Market", "Puzzelmarkt"))
                            .font(PibblesStyle.title(26.0))
                            .foregroundStyle(PibblesStyle.ink)
                        Text(T.s("Every stall has a new puzzle each day", "Elke kraam heeft elke dag een nieuwe puzzel"))
                            .font(PibblesStyle.text(13.0))
                            .foregroundStyle(PibblesStyle.muted)
                    }
                }
                ForEach(KindInfo.stalls, id: \.self) { stall in
                    VStack(alignment: .leading, spacing: 10.0) {
                        HStack(spacing: 10.0) {
                            RoundedRectangle(cornerRadius: 4.0)
                                .fill(PibblesStyle.stallColor(stall))
                                .frame(width: 8.0, height: 28.0)
                            VStack(alignment: .leading, spacing: 0.0) {
                                Text(stall)
                                    .font(PibblesStyle.title(20.0))
                                    .foregroundStyle(PibblesStyle.ink)
                                Text(KindInfo.stallTagline(stall))
                                    .font(PibblesStyle.text(13.0))
                                    .foregroundStyle(PibblesStyle.muted)
                            }
                        }
                        ForEach(KindInfo.kinds(stall: stall), id: \.self) { kind in
                            NavigationLink(destination: KindWeekView(kind: kind)) {
                                HStack(spacing: 12.0) {
                                    KindBadge(kind: kind, size: 40.0)
                                    VStack(alignment: .leading, spacing: 2.0) {
                                        Text(KindInfo.name(kind))
                                            .font(PibblesStyle.text(17.0, .semibold))
                                            .foregroundStyle(PibblesStyle.ink)
                                        Text(KindInfo.tagline(kind))
                                            .font(PibblesStyle.text(13.0))
                                            .foregroundStyle(PibblesStyle.muted)
                                    }
                                    Spacer()
                                    Text("›")
                                        .font(PibblesStyle.title(24.0))
                                        .foregroundStyle(PibblesStyle.muted)
                                }
                                .padding(12.0)
                                .background(PibblesStyle.background)
                                .clipShape(RoundedRectangle(cornerRadius: 14.0))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .card(14.0)
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 12.0)
        }
        .pibblesScreen()
        .hiddenNavigationBar()
    }
}

/// One puzzle's week: this week's days up to today, and last week's as the archive.
struct KindWeekView: View {
    let kind: PuzzleKind
    @State var store = GameStore.shared
    @State var today = PuzzleCalendar.today()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                HStack(spacing: 12.0) {
                    KindBadge(kind: kind, size: 52.0)
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(KindInfo.name(kind))
                            .font(PibblesStyle.title(26.0))
                            .foregroundStyle(PibblesStyle.ink)
                        Text(T.s("\(kind.stall) stall", "Kraam \(kind.stall)") + " · " + KindInfo.tagline(kind))
                            .font(PibblesStyle.text(13.0))
                            .foregroundStyle(PibblesStyle.muted)
                    }
                }
                VStack(alignment: .leading, spacing: 6.0) {
                    ForEach(KindInfo.rules(kind), id: \.self) { rule in
                        Text("•  " + rule)
                            .font(PibblesStyle.text(14.0))
                            .foregroundStyle(PibblesStyle.ink)
                    }
                }
                .card(14.0)
                weekBlock(title: T.s("This week", "Deze week"), start: PuzzleCalendar.weekStart(day: today))
                weekBlock(title: T.s("Last week", "Vorige week"), start: PuzzleCalendar.weekStart(day: today) - 7)
                Text(T.s("The week gets harder from Monday to Sunday.", "De week wordt moeilijker van maandag naar zondag."))
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 12.0)
        }
        .pibblesScreen()
        .navigationTitle(KindInfo.name(kind))
        .onAppear { today = PuzzleCalendar.today() }
    }

    func weekBlock(title: String, start: Int) -> some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(title)
                .font(PibblesStyle.text(15.0, .semibold))
                .foregroundStyle(PibblesStyle.muted)
            HStack(spacing: 6.0) {
                ForEach(0..<7) { offset in
                    dayTile(day: start + offset)
                }
            }
        }
    }

    @ViewBuilder
    func dayTile(day: Int) -> some View {
        let open = day <= today
        let solved = store.book.record(kind: kind, day: day) != nil
        let tile = VStack(spacing: 2.0) {
            Text(T.weekdayLetter(day))
                .font(PibblesStyle.text(12.0, .semibold))
            Text(solved ? "✓" : (open ? String(PuzzleCalendar.dateKey(day: day).suffix(2)) : "·"))
                .font(PibblesStyle.text(15.0, .bold))
        }
        .foregroundStyle(solved ? Color.white : (open ? PibblesStyle.ink : PibblesStyle.muted))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10.0)
        .background(solved ? PibblesStyle.good : (day == today ? PibblesStyle.sand : PibblesStyle.surface))
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        if open {
            NavigationLink(destination: PlayView(kind: kind, day: day)) { tile }
                .buttonStyle(.plain)
        } else {
            tile
        }
    }
}
