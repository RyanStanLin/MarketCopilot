import Foundation

public struct PortfolioSnapshot: Codable, Equatable, Sendable {
    public var predictions: PredictionSnapshot?
    public var perps: PerpsSnapshot?
    public var portfolio: Decimal? {
        sumAvailable([predictions?.portfolio, perps?.portfolio])
    }
    public var cash: Decimal? {
        sumAvailable([predictions?.cash, perps?.cash])
    }
    public var hasPartialTotals: Bool { predictions == nil || perps == nil || predictions?.cash == nil }

    public init(predictions: PredictionSnapshot? = nil, perps: PerpsSnapshot? = nil) {
        self.predictions = predictions; self.perps = perps
    }

    private func sumAvailable(_ amounts: [Decimal?]) -> Decimal? {
        let available = amounts.compactMap { $0 }
        return available.isEmpty ? nil : available.reduce(0, +)
    }
}
