// swift-tools-version: 6.1
import PackageDescription

// The screens both apps share. Skip transpiles them to Compose for Android;
// iOS links them as plain SwiftUI. Rules live in PibblesCore, never here.
let package = Package(
    name: "PibblesUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PibblesUI", targets: ["PibblesUI"])],
    dependencies: [
        .package(path: "../PibblesCore"),
        .package(url: "https://github.com/skiptools/skip.git", from: "1.9.11"),
        .package(url: "https://github.com/skiptools/skip-ui.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "PibblesUI", dependencies: [
            .product(name: "PibblesCore", package: "PibblesCore"),
            .product(name: "SkipUI", package: "skip-ui"),
        ], resources: [.process("Resources")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ],
    // Swift 5 mode, as the Skip templates: Swift 6's strict concurrency adds nothing
    // the Kotlin side would keep.
    swiftLanguageModes: [.v5]
)
