import Foundation

/// The player's answer as JSON for the ranking server: a flat list of numbers.
enum Answer {
    static func list(_ values: [Int]) -> String {
        var text = "["
        var index = 0
        while index < values.count {
            if index > 0 { text += "," }
            text += "\(values[index])"
            index += 1
        }
        return text + "]"
    }

    static func nested(_ lists: [[Int]]) -> String {
        var text = "["
        var index = 0
        while index < lists.count {
            if index > 0 { text += "," }
            text += list(lists[index])
            index += 1
        }
        return text + "]"
    }
}
