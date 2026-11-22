import Foundation

/// One solved daily puzzle. The first solve of a day and kind is final (HANDOFF.md).
public struct PlayRecord: Hashable, Codable, Sendable {
    public let kind: String
    public let day: Int
    public let milliseconds: Int
    public let hints: Int

    public init(kind: String, day: Int, milliseconds: Int, hints: Int) {
        self.kind = kind
        self.day = day
        self.milliseconds = milliseconds
        self.hints = hints
    }

    public var score: Int {
        return Ranking.score(milliseconds: milliseconds, hints: hints)
    }
}

/// Per kind: how often solved and the best score.
public struct KindStats: Hashable, Sendable {
    public let kind: PuzzleKind
    public let solved: Int
    public let bestScore: Int?
    public let averageMilliseconds: Int?
}

/// Everything the app keeps about play: results and the streak. Stored as JSON.
public struct ProgressBook: Hashable, Codable, Sendable {
    public private(set) var records: [PlayRecord]
    public private(set) var streak: StreakState

    public init() {
        self.records = [PlayRecord]()
        self.streak = StreakState()
    }

    enum CodingKeys: String, CodingKey {
        case records, streakCount, jokers, lastDay, best
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        records = try container.decode([PlayRecord].self, forKey: CodingKeys.records)
        let count = try container.decode(Int.self, forKey: CodingKeys.streakCount)
        let jokers = try container.decode(Int.self, forKey: CodingKeys.jokers)
        let lastDay = try container.decodeIfPresent(Int.self, forKey: CodingKeys.lastDay)
        let best = try container.decode(Int.self, forKey: CodingKeys.best)
        streak = StreakState(streak: count, jokers: jokers, lastDay: lastDay, best: best)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(records, forKey: CodingKeys.records)
        try container.encode(streak.streak, forKey: CodingKeys.streakCount)
        try container.encode(streak.jokers, forKey: CodingKeys.jokers)
        try container.encodeIfPresent(streak.lastDay, forKey: CodingKeys.lastDay)
        try container.encode(streak.best, forKey: CodingKeys.best)
    }

    public func record(kind: PuzzleKind, day: Int) -> PlayRecord? {
        for item in records {
            if item.kind == kind.rawValue && item.day == day { return item }
        }
        return nil
    }

    /// Stores a solve. Only the first solve of a day and kind counts; only solving today's
    /// puzzle on its own day moves the streak (a day counts when any of its puzzles is solved).
    /// Returns false when the result was already fixed.
    @discardableResult
    public mutating func add(kind: PuzzleKind, day: Int, milliseconds: Int, hints: Int, today: Int) -> Bool {
        if record(kind: kind, day: day) != nil { return false }
        records.append(PlayRecord(kind: kind.rawValue, day: day, milliseconds: milliseconds, hints: hints))
        if day == today {
            streak = StreakRules.afterSolve(streak, day: day)
        }
        return true
    }

    public func streakView(today: Int) -> StreakView {
        return StreakRules.now(streak, day: today)
    }

    public func stats(kind: PuzzleKind) -> KindStats {
        var solved = 0
        var best: Int? = nil
        var total = 0
        for item in records {
            if item.kind != kind.rawValue { continue }
            solved += 1
            total += item.milliseconds
            if let current = best {
                if item.score < current { best = item.score }
            } else {
                best = item.score
            }
        }
        return KindStats(kind: kind, solved: solved, bestScore: best, averageMilliseconds: solved > 0 ? total / solved : nil)
    }

    public static func decode(_ json: String) -> ProgressBook {
        guard let data = json.data(using: String.Encoding.utf8) else { return ProgressBook() }
        do {
            return try JSONDecoder().decode(ProgressBook.self, from: data)
        } catch {
            return ProgressBook()
        }
    }

    public func encoded() -> String {
        do {
            let data = try JSONEncoder().encode(self)
            return String(data: data, encoding: String.Encoding.utf8) ?? ""
        } catch {
            return ""
        }
    }
}

/// "1:05" or "12:30".
public enum TimeText {
    public static func clock(milliseconds: Int) -> String {
        let seconds = max(0, milliseconds / 1000)
        let rest = seconds % 60
        return "\(seconds / 60):" + (rest < 10 ? "0\(rest)" : "\(rest)")
    }
}
