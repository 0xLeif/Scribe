// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Tools version 6.0 builds every target in the Swift 6 language mode (complete data-race checking).

import PackageDescription

let package = Package(
    name: "Scribe",
    // The floor is set by `OSAllocatedUnfairLock`, which guards the plugin list
    // without an `@unchecked Sendable` conformance.
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Scribe",
            targets: ["Scribe"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "Scribe",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "ScribeTests",
            dependencies: ["Scribe"]
        )
    ]
)
