// swift-tools-version: 6.1
import PackageDescription

// Writes the week pack for the server: the 7 × 7 daily puzzles of one week, made by the
// same PibblesCore code as the apps. Usage: swift run --package-path Tools/PackBuilder
// PackBuilder 2026-11-30 > week.json  (the date must be a Monday; default: next Monday).
let package = Package(
    name: "PackBuilder",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../Packages/PibblesCore"),
    ],
    targets: [
        .executableTarget(name: "PackBuilder", dependencies: [
            .product(name: "PibblesCore", package: "PibblesCore"),
        ]),
    ],
    swiftLanguageModes: [.v5]
)
