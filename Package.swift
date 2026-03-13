// swift-tools-version: 5.9
// This Package.swift exists solely to provide SwiftLint as a local command plugin.
// The app itself is built via the Xcode project, not SPM.

import PackageDescription

let package = Package(
    name: "Herald",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.58.0"),
    ],
    targets: [
        .target(
            name: "HeraldLintTarget",
            path: "Herald/Herald",
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins"),
            ]
        ),
    ]
)
