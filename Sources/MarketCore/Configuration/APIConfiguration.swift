import Foundation

public struct APIConfiguration: Codable, Sendable {
    public let data: URL
    public let clob: URL
    public let gamma: URL
    public let perps: URL
    public let predictionMarketSocket: URL
    public let predictionUserSocket: URL
    public let perpsSocket: URL
    public let perpsWebsite: URL
    public let predictionWebsite: URL
    public let polygonRPC: URL
    public let polygonChainID: Int
    public let predictionCollateral: String
    public let collateralDecimals: Int
    public let requestTimeout: TimeInterval

    public static func bundled() throws -> Self {
        guard let url = Bundle.module.url(forResource: "Endpoints", withExtension: "json") else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}
