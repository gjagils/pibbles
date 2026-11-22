import Foundation
import PibblesCore

/// Texts in the phone's language: Dutch when the phone is set to Dutch, English otherwise.
/// Pairs stay next to each other at the call site, so a missing translation shows up in review.
public enum T {
    public static let dutch: Bool = Locale.current.identifier.lowercased().hasPrefix("nl")

    public static func s(_ english: String, _ nederlands: String) -> String {
        return dutch ? nederlands : english
    }

    public static func weekday(_ day: Int) -> String {
        let english = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let nederlands = ["maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag", "zondag"]
        let index = PuzzleCalendar.weekday(day: day)
        return dutch ? nederlands[index].capitalized : english[index]
    }

    public static func weekdayLetter(_ day: Int) -> String {
        let english = ["M", "T", "W", "T", "F", "S", "S"]
        let nederlands = ["M", "D", "W", "D", "V", "Z", "Z"]
        let index = PuzzleCalendar.weekday(day: day)
        return dutch ? nederlands[index] : english[index]
    }

    public static func difficulty(_ day: Int) -> String {
        let name = Daily.difficulty(weekday: PuzzleCalendar.weekday(day: day))
        if !dutch { return name }
        if name == "Easy" { return "Makkelijk" }
        if name == "Medium" { return "Gemiddeld" }
        return "Moeilijk"
    }

    public static func hints(_ count: Int) -> String {
        if count == 0 { return s("no hints", "zonder hints") }
        if count == 1 { return "1 hint" }
        return "\(count) hints"
    }
}
