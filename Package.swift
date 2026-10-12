// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "Persiana",
  platforms: [.macOS("27.0")],
  products: [.executable(name: "Persiana", targets: ["PersianaApp"])],
  targets: [
    .target(name: "PersianaCore"),
    .target(name: "MenuBarVisibility"),
    .executableTarget(name: "PersianaApp", dependencies: ["PersianaCore", "MenuBarVisibility"]),
    .testTarget(name: "PersianaCoreTests", dependencies: ["PersianaCore"]),
  ]
)
