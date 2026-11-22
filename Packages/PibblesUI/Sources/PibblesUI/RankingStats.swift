import SwiftUI
import PibblesCore

/// Sends a first solve of today to the ranking server, and reads today's ranking.
/// The server (server/) may not be live yet: failures are quiet and the app keeps working.
enum ScoreUploader {
    /// The live server; a debug build in the iOS Simulator talks to `npx wrangler dev` on this Mac.
    static var base: String {
        #if DEBUG && os(iOS) && !SKIP && targetEnvironment(simulator)
        return "http://localhost:8787/api"
        #else
        return "https://pibbles.app/api"
        #endif
    }

    static func submit(kind: PuzzleKind, day: Int, milliseconds: Int, hints: Int, answer: String) async {
        let store = GameStore.shared
        let name = store.playerName.isEmpty ? T.s("Player", "Speler") : store.playerName
        let body = "{\"date\":\"\(PuzzleCalendar.dateKey(day: day))\",\"kind\":\"\(kind.rawValue)\",\"deviceId\":\"\(store.deviceId)\",\"name\":\(quoted(name)),\"ms\":\(milliseconds),\"hints\":\(hints),\"solution\":\(answer)}"
        if await !send(body) {
            var pending = loadPending()
            pending.append(body)
            savePending(pending)
        }
    }

    /// Sends results that could not be sent before (offline, server down). The server only
    /// takes today and yesterday and refuses the rest; refused ones are dropped.
    static func flush() async {
        let pending = loadPending()
        if pending.isEmpty { return }
        var keep = [String]()
        for body in pending {
            if await !send(body) { keep.append(body) }
        }
        savePending(keep)
    }

    /// One result per line (a JSON body has no line breaks); `stringArray` is not in Skip.
    static func loadPending() -> [String] {
        let text = UserDefaults.standard.string(forKey: "pendingScores") ?? ""
        var result = [String]()
        for line in text.split(separator: "\n") {
            if !line.isEmpty { result.append(String(line)) }
        }
        return result
    }

    static func savePending(_ bodies: [String]) {
        UserDefaults.standard.set(bodies.joined(separator: "\n"), forKey: "pendingScores")
    }

    /// True when the server answered (also when it refused the result): only a missing
    /// answer or a server error means "try again later".
    static func send(_ body: String) async -> Bool {
        guard let url = URL(string: base + "/scores") else { return true }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: String.Encoding.utf8)
        request.timeoutInterval = 10.0
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return http.statusCode < 500
            }
            return true
        } catch {
            return false
        }
    }

    static func quoted(_ text: String) -> String {
        var result = "\""
        for character in text {
            if character == "\"" || character == "\\" {
                result += "\\"
            }
            result += String(character)
        }
        return result + "\""
    }
}

struct RankEntry: Codable, Hashable, Identifiable {
    let rank: Int
    let name: String
    let ms: Int
    let hints: Int
    let score: Int
    var id: Int { return rank }
}

struct RankingResponse: Codable {
    let top: [RankEntry]
    let me: RankEntry?
}

/// Today's ranking per puzzle: time plus 30 seconds per hint, lowest wins.
struct RankingView: View {
    @State var store = GameStore.shared
    @State var kind = PuzzleKind.blocks
    @State var entries: [RankEntry]? = nil
    @State var mine: RankEntry? = nil
    @State var failed = false
    @State var nameDraft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                Text(T.s("Today's ranking", "Ranglijst van vandaag"))
                    .font(PibblesStyle.title(26.0))
                    .foregroundStyle(PibblesStyle.ink)
                Text(T.s("Time plus 30 seconds per hint. Your first solve counts.", "Tijd plus 30 seconden per hint. Je eerste oplossing telt."))
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8.0) {
                        ForEach(PuzzleKind.allCases, id: \.self) { item in
                            Button(action: {
                                kind = item
                                Task { await refresh() }
                            }) {
                                Text(KindInfo.name(item))
                                    .font(PibblesStyle.text(14.0, .semibold))
                                    .foregroundStyle(item == kind ? Color.white : PibblesStyle.ink)
                                    .padding(.horizontal, 14.0)
                                    .padding(.vertical, 8.0)
                                    .background(item == kind ? PibblesStyle.purple : PibblesStyle.surface)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                ownResult
                if let entries {
                    if entries.isEmpty {
                        Text(T.s("No results yet today. Be the first!", "Nog geen uitslagen vandaag. Wees de eerste!"))
                            .font(PibblesStyle.text(14.0))
                            .foregroundStyle(PibblesStyle.muted)
                    }
                    ForEach(entries) { entry in
                        let isMine = mine?.rank == entry.rank && mine?.score == entry.score
                        HStack {
                            Text("\(entry.rank)")
                                .font(PibblesStyle.title(17.0))
                                .foregroundStyle(PibblesStyle.orange)
                                .frame(width: 32.0, alignment: .leading)
                            Text(isMine ? entry.name + T.s(" (you)", " (jij)") : entry.name)
                                .font(PibblesStyle.text(15.0, .semibold))
                                .foregroundStyle(PibblesStyle.ink)
                            Spacer()
                            Text(TimeText.clock(milliseconds: entry.score))
                                .font(PibblesStyle.text(15.0, .semibold))
                                .foregroundStyle(PibblesStyle.ink)
                        }
                        .padding(12.0)
                        .background(isMine ? PibblesStyle.purple.opacity(0.25) : PibblesStyle.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12.0))
                    }
                    if let mine, mine.rank > entries.count {
                        Text(T.s("You are number \(mine.rank).", "Jij staat op plaats \(mine.rank)."))
                            .font(PibblesStyle.text(14.0, .semibold))
                            .foregroundStyle(PibblesStyle.purple)
                    }
                } else if failed {
                    Text(T.s("The ranking is not reachable right now. Your results are saved on this phone.", "De ranglijst is nu niet bereikbaar. Je uitslagen staan veilig op deze telefoon."))
                        .font(PibblesStyle.text(14.0))
                        .foregroundStyle(PibblesStyle.muted)
                } else {
                    ProgressView()
                }
                nameCard
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 12.0)
        }
        .pibblesScreen()
        .hiddenNavigationBar()
        .task {
            nameDraft = store.playerName
            await refresh()
        }
    }

    @ViewBuilder
    var ownResult: some View {
        if let record = store.book.record(kind: kind, day: store.today) {
            Text(T.s("You: ", "Jij: ") + TimeText.clock(milliseconds: record.score) + " (" + TimeText.clock(milliseconds: record.milliseconds) + ", " + T.hints(record.hints) + ")")
                .font(PibblesStyle.text(15.0, .semibold))
                .foregroundStyle(PibblesStyle.good)
        } else {
            Text(T.s("You have not solved today's ", "Je hebt vandaag nog geen ") + KindInfo.name(kind) + T.s(" yet.", " opgelost."))
                .font(PibblesStyle.text(14.0))
                .foregroundStyle(PibblesStyle.muted)
        }
    }

    var nameCard: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            Text(T.s("Your name in the ranking", "Je naam in de ranglijst"))
                .font(PibblesStyle.text(15.0, .semibold))
                .foregroundStyle(PibblesStyle.ink)
            TextField(T.s("Player", "Speler"), text: $nameDraft)
                .font(PibblesStyle.text(16.0))
                .padding(10.0)
                .background(PibblesStyle.background)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .onSubmit { saveName() }
            Button(T.s("Save name", "Bewaar naam")) { saveName() }
                .font(PibblesStyle.text(15.0, .semibold))
                .foregroundStyle(PibblesStyle.purple)
        }
        .card(14.0)
    }

    func saveName() {
        var trimmed = nameDraft.trimmingCharacters(in: .whitespaces)
        if trimmed.count > 20 { trimmed = String(trimmed.prefix(20)) }
        store.playerName = trimmed
        nameDraft = trimmed
    }

    func refresh() async {
        entries = nil
        mine = nil
        failed = false
        await ScoreUploader.flush()
        let path = ScoreUploader.base + "/scores/" + PuzzleCalendar.dateKey(day: store.today) + "/" + kind.rawValue + "?deviceId=" + store.deviceId
        guard let url = URL(string: path) else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                failed = true
                return
            }
            let decoded = try JSONDecoder().decode(RankingResponse.self, from: data)
            entries = decoded.top
            mine = decoded.me
        } catch {
            failed = true
        }
    }
}

/// Stats: streak, jokers and per puzzle how often solved and the best score.
struct StatsView: View {
    @State var store = GameStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16.0) {
                Text(T.s("Stats", "Statistiek"))
                    .font(PibblesStyle.title(26.0))
                    .foregroundStyle(PibblesStyle.ink)
                let view = store.book.streakView(today: store.today)
                HStack(spacing: 10.0) {
                    StatTile(value: "\(view.streak)", label: T.s("Streak", "Reeks"), color: PibblesStyle.orange, icon: "flame")
                    StatTile(value: "\(store.book.streak.best)", label: T.s("Best streak", "Langste reeks"), color: PibblesStyle.teal, icon: "trophy")
                    StatTile(value: "\(view.jokers)", label: T.s("Jokers", "Jokers"), color: PibblesStyle.purple, icon: "cube")
                }
                Text(T.s("Every 5 days in a row earn a joker (at most 3). A missed day costs a joker; without one the streak starts again and the jokers stay.", "Elke 5 dagen op rij leveren een joker op (hooguit 3). Een gemiste dag kost een joker; zonder joker begint de reeks opnieuw en blijven de jokers."))
                    .font(PibblesStyle.text(13.0))
                    .foregroundStyle(PibblesStyle.muted)
                ForEach(PuzzleKind.allCases, id: \.self) { kind in
                    let stats = store.book.stats(kind: kind)
                    HStack(spacing: 12.0) {
                        KindBadge(kind: kind, size: 36.0)
                        VStack(alignment: .leading, spacing: 2.0) {
                            Text(KindInfo.name(kind))
                                .font(PibblesStyle.text(16.0, .semibold))
                                .foregroundStyle(PibblesStyle.ink)
                            Text(T.s("\(stats.solved) solved", "\(stats.solved) opgelost"))
                                .font(PibblesStyle.text(13.0))
                                .foregroundStyle(PibblesStyle.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2.0) {
                            Text(stats.bestScore == nil ? "–" : TimeText.clock(milliseconds: stats.bestScore ?? 0))
                                .font(PibblesStyle.text(16.0, .semibold))
                                .foregroundStyle(PibblesStyle.ink)
                            Text(T.s("best", "beste"))
                                .font(PibblesStyle.text(11.0))
                                .foregroundStyle(PibblesStyle.muted)
                        }
                    }
                    .padding(12.0)
                    .background(PibblesStyle.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14.0))
                }
            }
            .padding(.horizontal, 16.0)
            .padding(.vertical, 12.0)
        }
        .pibblesScreen()
        .hiddenNavigationBar()
    }
}
