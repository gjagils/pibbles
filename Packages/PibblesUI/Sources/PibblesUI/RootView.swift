import SwiftUI
import PibblesCore

/// The app: four tabs as on the style board. Every screen comes from here; the iOS and
/// Android hosts only show `RootView`.
public struct RootView: View {
    @State var tab = 0

    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            NavigationStack { HomeView() }
                .tabItem { Label(title: { Text(T.s("Home", "Home")) }, icon: { Image("tab-home", bundle: .module).renderingMode(.template) }) }
                .tag(0)
            NavigationStack { MarketView() }
                .tabItem { Label(title: { Text(T.s("Market", "Markt")) }, icon: { Image("tab-markt", bundle: .module).renderingMode(.template) }) }
                .tag(1)
            NavigationStack { RankingView() }
                .tabItem { Label(title: { Text(T.s("Ranking", "Ranglijst")) }, icon: { Image("tab-ranglijst", bundle: .module).renderingMode(.template) }) }
                .tag(2)
            NavigationStack { StatsView() }
                .tabItem { Label(title: { Text(T.s("Stats", "Statistiek")) }, icon: { Image("tab-statistiek", bundle: .module).renderingMode(.template) }) }
                .tag(3)
        }
        .tint(PibblesStyle.purple)
        .task {
            // Results that could not be sent earlier (offline, server down)
            await ScoreUploader.flush()
        }
    }
}

/// One small number tile with its icon: streak, jokers, today.
struct StatTile: View {
    let value: String
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4.0) {
            ZStack {
                Circle().fill(color)
                AssetIcon(name: icon == "flame" ? "icon-streak" : (icon == "cube" ? "icon-joker" : "icon-trophy"), size: 22.0)
            }
            .frame(width: 34.0, height: 34.0)
            Text(value)
                .font(PibblesStyle.title(22.0))
                .foregroundStyle(PibblesStyle.ink)
            Text(label)
                .font(PibblesStyle.text(12.0, .medium))
                .foregroundStyle(PibblesStyle.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12.0)
        .background(PibblesStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18.0))
    }
}

/// A coloured rounded square with the puzzle's icon.
struct KindBadge: View {
    let kind: PuzzleKind
    var size: Double = 44.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28)
                .fill(PibblesStyle.kindColor(kind))
            KindIcon(kind: kind, size: size * 0.78)
        }
        .frame(width: size, height: size)
    }
}

/// A row for one puzzle of one day: badge, name, difficulty, and the result once solved.
struct PuzzleRow: View {
    let kind: PuzzleKind
    let day: Int
    let store: GameStore

    var body: some View {
        HStack(spacing: 12.0) {
            KindBadge(kind: kind)
            VStack(alignment: .leading, spacing: 2.0) {
                Text(KindInfo.name(kind))
                    .font(PibblesStyle.text(17.0, .semibold))
                    .foregroundStyle(PibblesStyle.ink)
                Text(KindInfo.tagline(kind) + " · " + T.difficulty(day))
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
                    .lineLimit(1)
            }
            Spacer()
            if let record = store.book.record(kind: kind, day: day) {
                VStack(alignment: .trailing, spacing: 0.0) {
                    Text(TimeText.clock(milliseconds: record.milliseconds))
                        .font(PibblesStyle.text(15.0, .semibold))
                        .foregroundStyle(PibblesStyle.good)
                    Text(T.hints(record.hints))
                        .font(PibblesStyle.text(11.0))
                        .foregroundStyle(PibblesStyle.muted)
                }
            } else {
                Text(T.s("Play", "Speel"))
                    .font(PibblesStyle.text(14.0, .semibold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 14.0)
                    .padding(.vertical, 7.0)
                    .background(PibblesStyle.purple)
                    .clipShape(Capsule())
            }
        }
        .padding(12.0)
        .background(PibblesStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16.0))
    }
}
