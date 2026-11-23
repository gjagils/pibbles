import Foundation
import Observation
import PibblesCore

/// What the app keeps on the device: results, streak, the anonymous device id and the
/// name shown in the ranking. Rules (what counts, the streak) are in PibblesCore.
@Observable
public final class GameStore {
    public static let shared = GameStore()

    public var book: ProgressBook
    /// Goes up whenever an unfinished game is saved or cleared, so Today can show "Continue".
    public var savedGames = 0
    public var playerName: String {
        didSet { UserDefaults.standard.set(playerName, forKey: "playerName") }
    }
    public let deviceId: String

    init() {
        let defaults = UserDefaults.standard
        book = ProgressBook.decode(defaults.string(forKey: "progress") ?? "")
        playerName = defaults.string(forKey: "playerName") ?? ""
        if let id = defaults.string(forKey: "deviceId") {
            deviceId = id
        } else {
            let id = UUID().uuidString
            defaults.set(id, forKey: "deviceId")
            deviceId = id
        }
    }

    public var today: Int {
        return PuzzleCalendar.today()
    }

    /// Stores a solve; true when it is the first of that day and kind.
    @discardableResult
    public func solved(kind: PuzzleKind, day: Int, milliseconds: Int, hints: Int) -> Bool {
        var copy = book
        let added = copy.add(kind: kind, day: day, milliseconds: milliseconds, hints: hints, today: today)
        if added {
            book = copy
            UserDefaults.standard.set(book.encoded(), forKey: "progress")
        }
        return added
    }
}
