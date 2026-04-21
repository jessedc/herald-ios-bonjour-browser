// swift-tools-version: 5.9
// herald — macOS command-line companion to the Herald iOS app.
// Kept in its own Package so the root Package.swift (iOS-only SwiftLint
// plugin host) stays untouched. Shared Swift sources are symlinked from
// Herald/Herald/ into Sources/herald/Shared/. The iOS app's Info.plist
// is not bundled as a resource; BonjourTypes.swift locates it at build
// time via `#filePath` so there's a single source of truth.

import PackageDescription

let package = Package(
    name: "herald",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "herald", targets: ["herald"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser",
                 from: "1.3.0"),
    ],
    targets: [
        .executableTarget(
            name: "herald",
            dependencies: [
                .product(name: "ArgumentParser",
                         package: "swift-argument-parser"),
            ],
            path: "Sources/herald"
        ),
    ]
)
