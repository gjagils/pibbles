import Foundation

// 32-bit arithmetic written with Int64 and a mask, so Swift and the Kotlin that Skip
// generates give the same numbers as JavaScript (`prototype/logic.js`). Swift's `Int`
// becomes a 32-bit `Int` in Kotlin, and Swift traps on overflow where Kotlin wraps.
enum Bits32 {
    static let mask: Int64 = 0xFFFFFFFF
    static let low16: Int64 = 0xFFFF

    /// JavaScript's `Math.imul`, as an unsigned 32-bit value.
    static func multiply(_ a: Int64, _ b: Int64) -> Int64 {
        let low = b & low16
        let high = (b >> 16) & low16
        return ((a * low) + (((a * high) & low16) << 16)) & mask
    }
}

/// FNV-1a over the bytes of a string (`hashStr` in the prototype). The prototype hashes
/// UTF-16 code units, which is the same for ASCII: keep seeds ASCII (dates, numbers).
/// Not `text.utf16`: in Skip's Kotlin that gives bytes with a byte order mark.
public enum StringHash {
    public static func fnv1a(_ text: String) -> Int64 {
        var hash: Int64 = 2166136261
        let prime: Int64 = 16777619
        let byteMask: Int64 = 0xFF
        for unit in text.utf8 {
            hash = Bits32.multiply(hash ^ (Int64(unit) & byteMask), prime)
        }
        return hash
    }
}

/// Mulberry32: a small seeded generator, the same one as in the prototype, so a seed
/// gives the same puzzle on iOS, on Android and on the server.
public final class SeededRandom {
    private var state: Int64

    public init(seed: Int64) {
        self.state = seed & Bits32.mask
    }

    /// The next value in 0..<1.
    public func next() -> Double {
        let step: Int64 = 0x6D2B79F5
        state = (state + step) & Bits32.mask
        // Typed constants: in Kotlin `1 or state` mixes Int and Long and does not compile.
        let one: Int64 = 1
        let sixtyOne: Int64 = 61
        var t = Bits32.multiply(state ^ (state >> 15), one | state)
        t = ((t + Bits32.multiply(t ^ (t >> 7), sixtyOne | t)) & Bits32.mask) ^ t
        return Double(t ^ (t >> 14)) / 4294967296.0
    }

    /// A whole number in 0..<bound.
    public func nextInt(_ bound: Int) -> Int {
        return Int(next() * Double(bound))
    }
}
