import Foundation

/// The puzzle kinds. The market groups them in four stalls (`stall`).
public enum PuzzleKind: String, CaseIterable, Codable, Sendable {
    case blocks
    case logic
    case patterns
    case numbers
    case stars
    case links
    case sums

    /// The stall of the style board this kind belongs to.
    public var stall: String {
        switch self {
        case PuzzleKind.blocks: return "Blocks"
        case PuzzleKind.logic, PuzzleKind.stars: return "Logic"
        case PuzzleKind.patterns, PuzzleKind.links: return "Patterns"
        case PuzzleKind.numbers, PuzzleKind.sums: return "Numbers"
        }
    }

    /// The seed of the daily puzzle of this kind on a date (`yyyy-MM-dd`). Blocks keeps the
    /// bare date, as in the prototype.
    public func seed(dateKey: String) -> String {
        if self == PuzzleKind.blocks { return dateKey }
        return rawValue + "|" + dateKey
    }
}

/// Day numbers without `Calendar`, so iOS, Android and the server count the same way.
/// Day 0 is Monday 5 January 2026; weekday = day mod 7 with Monday 0.
public enum PuzzleCalendar {
    /// Days from 1970-01-01 to 2026-01-05.
    static let epochOffset = 20458

    /// Days since 1970-01-01 of a civil date (Howard Hinnant's algorithm).
    static func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yearOfEra = y - era * 400
        let shiftedMonth = month > 2 ? month - 3 : month + 9
        let dayOfYear = (153 * shiftedMonth + 2) / 5 + day - 1
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear
        return era * 146097 + dayOfEra - 719468
    }

    public static func dayNumber(year: Int, month: Int, day: Int) -> Int {
        return daysFromCivil(year: year, month: month, day: day) - epochOffset
    }

    /// `yyyy-MM-dd`; nil when it is not a date.
    public static func dayNumber(dateKey: String) -> Int? {
        let parts = dateKey.split(separator: "-")
        if parts.count != 3 { return nil }
        guard let year = Int(String(parts[0])), let month = Int(String(parts[1])), let day = Int(String(parts[2])) else {
            return nil
        }
        if month < 1 || month > 12 || day < 1 || day > 31 { return nil }
        return dayNumber(year: year, month: month, day: day)
    }

    public static func dateKey(day: Int) -> String {
        // Inverse of daysFromCivil.
        let z = day + epochOffset + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let dayOfEra = z - era * 146097
        let yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146096) / 365
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)
        let shiftedMonth = (5 * dayOfYear + 2) / 153
        let dayOfMonth = dayOfYear - (153 * shiftedMonth + 2) / 5 + 1
        let month = shiftedMonth < 10 ? shiftedMonth + 3 : shiftedMonth - 9
        let year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0)
        return "\(year)-\(pad(month))-\(pad(dayOfMonth))"
    }

    /// Monday 0 … Sunday 6.
    public static func weekday(day: Int) -> Int {
        return ((day % 7) + 7) % 7
    }

    /// The Monday of the week of `day`.
    public static func weekStart(day: Int) -> Int {
        return day - weekday(day: day)
    }

    /// Today's day number on this device, in its own time zone.
    public static func today(now: Date = Date()) -> Int {
        let seconds = Int(now.timeIntervalSince1970) + TimeZone.current.secondsFromGMT(for: now)
        let days = seconds >= 0 ? seconds / 86400 : (seconds - 86399) / 86400
        return days - epochOffset
    }

    private static func pad(_ value: Int) -> String {
        return value < 10 ? "0\(value)" : "\(value)"
    }
}
