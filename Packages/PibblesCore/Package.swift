// swift-tools-version: 6.1
// This is a Skip (https://skip.dev) package.
import PackageDescription

// The pure rules of Pibbles (shapes, week schedule, generator, solver, streak):
// no SwiftUI. Skip transpiles it to Kotlin for Android.
let package = Package(
    name: "PibblesCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PibblesCore", targets: ["PibblesCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/skiptools/skip.git", from: "1.9.11"),
        .package(url: "https://github.com/skiptools/skip-foundation.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "PibblesCore", dependencies: [
            .product(name: "SkipFoundation", package: "skip-foundation"),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "PibblesCoreTests", dependencies: [
            "PibblesCore",
            .product(name: "SkipTest", package: "skip"),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
