import XCTest
@testable import PibblesCore

final class ShapeTests: XCTestCase {
    func testCatalogKeepsThePrototypeOrder() {
        let keys = ShapeCatalog.all.map { shape in shape.key }
        XCTAssertEqual(keys, ["I2", "I2v", "I3", "I3v", "L3a", "L3b", "L3c", "L3d", "O4", "I4", "I4v",
                              "L4a", "L4b", "L4c", "L4d", "J4a", "J4b", "J4c", "J4d",
                              "T4a", "T4b", "T4c", "T4d", "S4a", "S4b", "Z4a", "Z4b"])
    }

    func testDimensions() {
        XCTAssertEqual(ShapeCatalog.shape("I4")?.height, 1)
        XCTAssertEqual(ShapeCatalog.shape("I4")?.width, 4)
        XCTAssertEqual(ShapeCatalog.shape("I4v")?.height, 4)
        XCTAssertEqual(ShapeCatalog.shape("I4v")?.width, 1)
        XCTAssertEqual(ShapeCatalog.shape("L4d")?.height, 2)
        XCTAssertEqual(ShapeCatalog.shape("L4d")?.width, 3)
        XCTAssertNil(ShapeCatalog.shape("X9"))
    }

    func testCellsOfAShape() {
        let cells = ShapeCatalog.shape("L3d")?.cells ?? [Cell]()
        XCTAssertEqual(cells, [Cell(row: 0, col: 1), Cell(row: 1, col: 0), Cell(row: 1, col: 1)])
    }

    func testEveryShapeTouchesTheTopAndLeftEdge() {
        for shape in ShapeCatalog.all {
            XCTAssertTrue(shape.cells.contains { cell in cell.row == 0 }, shape.key)
            XCTAssertTrue(shape.cells.contains { cell in cell.col == 0 }, shape.key)
            XCTAssertTrue(shape.cells.count >= 2 && shape.cells.count <= 4, shape.key)
        }
    }
}
