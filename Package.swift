// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "MarketCopilot",
    platforms: [.macOS("27.0")],
    products: [.library(name: "MarketCore", targets: ["MarketCore"])],
    targets: [.target(name: "MarketCore")],
    swiftLanguageModes: [.v6]
)
