import Foundation
import PibblesCore

/// An unfinished puzzle: time played so far, hints used and the board (numbers per square,
/// or for Links one list per line). Kept per puzzle and day, so leaving a puzzle pauses it.
struct SavedGame {
    var elapsedMilliseconds = 0
    var hints = 0
    var values = [Int]()
    var lists = [[Int]]()

    static func key(kind: PuzzleKind, day: Int) -> String {
        return "game-" + kind.rawValue + "-\(day)"
    }

    static func load(kind: PuzzleKind, day: Int) -> SavedGame {
        var game = SavedGame()
        guard let text = UserDefaults.standard.string(forKey: key(kind: kind, day: day)) else { return game }
        let parts = text.split(separator: ";", omittingEmptySubsequences: false)
        if parts.count != 4 { return game }
        game.elapsedMilliseconds = Int(String(parts[0])) ?? 0
        game.hints = Int(String(parts[1])) ?? 0
        game.values = numbers(String(parts[2]))
        var lists = [[Int]]()
        for line in parts[3].split(separator: "|", omittingEmptySubsequences: false) {
            lists.append(numbers(String(line)))
        }
        game.lists = String(parts[3]).isEmpty ? [[Int]]() : lists
        return game
    }

    func save(kind: PuzzleKind, day: Int) {
        var lines = [String]()
        for list in lists { lines.append(SavedGame.text(list)) }
        let text = "\(elapsedMilliseconds);\(hints);" + SavedGame.text(values) + ";" + lines.joined(separator: "|")
        UserDefaults.standard.set(text, forKey: SavedGame.key(kind: kind, day: day))
    }

    static func clear(kind: PuzzleKind, day: Int) {
        UserDefaults.standard.removeObject(forKey: key(kind: kind, day: day))
    }

    static func numbers(_ text: String) -> [Int] {
        var result = [Int]()
        for item in text.split(separator: ",") {
            if let value = Int(String(item)) { result.append(value) }
        }
        return result
    }

    static func text(_ values: [Int]) -> String {
        var items = [String]()
        for value in values { items.append("\(value)") }
        return items.joined(separator: ",")
    }
}
