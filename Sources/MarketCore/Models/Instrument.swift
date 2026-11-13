import Foundation

public struct Instrument: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var symbol: String
    public var displaySymbol: String
    public var priceDecimals: Int
    public var lightLogo: URL?
    public var darkLogo: URL?

    public init(id: Int, symbol: String, displaySymbol: String, priceDecimals: Int,
                lightLogo: URL? = nil, darkLogo: URL? = nil) {
        self.id = id; self.symbol = symbol; self.displaySymbol = displaySymbol
        self.priceDecimals = priceDecimals; self.lightLogo = lightLogo; self.darkLogo = darkLogo
    }
}
