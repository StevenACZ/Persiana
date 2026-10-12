// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Persiana",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .target(name: "MenuBarVisibility"),
        .executableTarget(name: "Persiana", dependencies: ["MenuBarVisibility"])
    ]
)
