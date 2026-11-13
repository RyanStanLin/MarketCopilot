// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "MarketCopilot",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "MarketCore", targets: ["MarketCore"]),
        .executable(name: "market-probe", targets: ["MarketProbe"])
    ],
    targets: [
        .target(name: "MarketCore", resources: [.process("Resources")]),
        .executableTarget(name: "MarketProbe", dependencies: ["MarketCore"], path: "Tools/MarketProbe"),
        .testTarget(name: "MarketCoreTests", dependencies: ["MarketCore"])
    ],
    swiftLanguageModes: [.v6]
)
