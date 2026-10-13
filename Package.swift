// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Persiana",
  platforms: [.macOS("27.0")],
  products: [.executable(name: "Persiana", targets: ["PersianaApp"])],
  dependencies: [.package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")],
  targets: [
    .target(name: "PersianaCore"),
    .target(name: "MenuBarVisibility"),
    .executableTarget(
      name: "PersianaApp",
      dependencies: [
        "PersianaCore", "MenuBarVisibility", .product(name: "Sparkle", package: "Sparkle"),
      ],
      linkerSettings: [
        .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
      ]),
    .testTarget(name: "PersianaCoreTests", dependencies: ["PersianaCore"]),
    .testTarget(name: "PersianaAppTests", dependencies: ["PersianaApp"]),
  ]
)
