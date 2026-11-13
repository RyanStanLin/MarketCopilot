import Foundation

/// Offsets are a presentation layer. Raw snapshots, positions and cached API data are unchanged.
public struct BalancePresentation: Equatable, Sendable {
    public let predictionCash: Decimal?
    public let predictionPortfolio: Decimal?
    public let perpsCash: Decimal?
    public let perpsPortfolio: Decimal?
    public var cash: Decimal? { Self.sum([predictionCash, perpsCash]) }
    public var portfolio: Decimal? { Self.sum([predictionPortfolio, perpsPortfolio]) }

    public init(snapshot: PortfolioSnapshot, predictionCashOffset: Decimal, perpsCashOffset: Decimal) {
        predictionCash = Self.adjust(snapshot.predictions?.cash, by: predictionCashOffset)
        predictionPortfolio = Self.adjust(snapshot.predictions?.portfolio, by: predictionCashOffset)
        perpsCash = Self.adjust(snapshot.perps?.cash, by: perpsCashOffset)
        perpsPortfolio = Self.adjust(snapshot.perps?.portfolio, by: perpsCashOffset)
    }

    private static func adjust(_ amount: Decimal?, by offset: Decimal) -> Decimal? {
        if let amount { return amount + offset }
        return offset == 0 ? nil : offset
    }

    private static func sum(_ values: [Decimal?]) -> Decimal? {
        let available = values.compactMap { $0 }
        return available.isEmpty ? nil : available.reduce(0, +)
    }
}
