import XCTest
@testable import PibblesCore

/// Reference values come from `prototype/logic.js` (hashStr, mulberry32).
final class SeededRandomTests: XCTestCase {
    func testHashMatchesThePrototype() {
        XCTAssertEqual(StringHash.fnv1a(""), Int64(2166136261))
        XCTAssertEqual(StringHash.fnv1a("a"), Int64(3826002220))
        XCTAssertEqual(StringHash.fnv1a("5x4|d0"), Int64(3758008540))
        XCTAssertEqual(StringHash.fnv1a("7x8|2026-11-22"), Int64(3954132092))
    }

    func testSequenceMatchesThePrototype() {
        let random = SeededRandom(seed: StringHash.fnv1a("5x4|d0"))
        let expected = [0.3853315399028361, 0.2614238699898124, 0.0218608605209738,
                        0.365480515640229, 0.9806499294936657]
        for value in expected {
            XCTAssertEqual(random.next(), value, accuracy: 1e-15)
        }
    }

    func testSeedZeroMatchesThePrototype() {
        let random = SeededRandom(seed: Int64(0))
        XCTAssertEqual(random.next(), 0.26642920868471265, accuracy: 1e-15)
        XCTAssertEqual(random.next(), 0.0003297457005828619, accuracy: 1e-15)
        XCTAssertEqual(random.next(), 0.2232720274478197, accuracy: 1e-15)
    }

    func testValuesStayBelowOne() {
        let random = SeededRandom(seed: Int64(12345))
        for _ in 0..<1000 {
            let value = random.next()
            XCTAssertTrue(value >= 0.0 && value < 1.0)
        }
    }
}
