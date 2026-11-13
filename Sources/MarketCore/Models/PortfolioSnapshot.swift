import Foundation

public struct PortfolioSnapshot: Codable, Equatable, Sendable {
    public var predictions: PredictionSnapshot?
    public var perps: PerpsSnapshot?
    public var portfolio: Decimal? {
        guard let predictionValue = predictions?.portfolio, let perps else { return nil }
        return predictionValue + perps.portfolio
    }
    public var cash: Decimal? {
        guard let predictionCash = predictions?.cash, let perps else { return nil }
        return predictionCash + perps.cash
    }

    public init(predictions: PredictionSnapshot? = nil, perps: PerpsSnapshot? = nil) {
        self.predictions = predictions; self.perps = perps
    }
}
