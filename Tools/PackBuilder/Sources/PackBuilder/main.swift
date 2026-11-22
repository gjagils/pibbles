import Foundation
import PibblesCore

struct DayPack: Encodable {
    let date: String
    let blocks: Puzzle
    let logic: LogicPuzzle
    let patterns: PatternsPuzzle
    let numbers: NumbersPuzzle
    let stars: StarsPuzzle
    let links: LinksPuzzle
    let sums: SumsPuzzle
}

struct WeekPack: Encodable {
    let weekStart: String
    let days: [DayPack]
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

let arguments = CommandLine.arguments
var start: Int
if arguments.count > 1 {
    guard let day = PuzzleCalendar.dayNumber(dateKey: arguments[1]) else { fail("Not a date: \(arguments[1])") }
    if PuzzleCalendar.weekday(day: day) != 0 { fail("\(arguments[1]) is not a Monday") }
    start = day
} else {
    start = PuzzleCalendar.weekStart(day: PuzzleCalendar.today()) + 7
}

var days = [DayPack]()
for offset in 0..<7 {
    let day = start + offset
    let weekday = PuzzleCalendar.weekday(day: day)
    let key = PuzzleCalendar.dateKey(day: day)
    guard let blocks = Daily.blocks(day: day) else { fail("No Blocks puzzle for \(key)") }
    days.append(DayPack(
        date: key,
        blocks: blocks,
        logic: Daily.logic(day: day),
        patterns: Daily.patterns(day: day),
        numbers: Daily.numbers(day: day),
        stars: StarsGenerator.generate(weekday: weekday, seed: PuzzleKind.stars.seed(dateKey: key)),
        links: LinksGenerator.generate(weekday: weekday, seed: PuzzleKind.links.seed(dateKey: key)),
        sums: SumsGenerator.generate(weekday: weekday, seed: PuzzleKind.sums.seed(dateKey: key))))
    FileHandle.standardError.write("\(key) done\n".data(using: .utf8)!)
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
let data = try encoder.encode(WeekPack(weekStart: PuzzleCalendar.dateKey(day: start), days: days))
FileHandle.standardOutput.write(data)
