import Foundation

/// The difficulty of a puzzle: the board is `size` × `size` and holds `pieceCount` blocks.
public struct Level: Hashable, Sendable {
    public let size: Int
    public let pieceCount: Int

    public init(size: Int, pieceCount: Int) {
        self.size = size
        self.pieceCount = pieceCount
    }
}

/// One puzzle a day, easy on Monday and hardest on Sunday.
public enum WeekSchedule {
    public static let levels: [Level] = [
        Level(size: 5, pieceCount: 4), Level(size: 5, pieceCount: 5), Level(size: 6, pieceCount: 5),
        Level(size: 6, pieceCount: 6), Level(size: 6, pieceCount: 7), Level(size: 6, pieceCount: 7),
        Level(size: 6, pieceCount: 8),
    ]

    /// `weekday`: Monday is 0, Sunday is 6. Other values wrap around the week.
    public static func level(weekday: Int) -> Level {
        let index = ((weekday % 7) + 7) % 7
        return levels[index]
    }
}
