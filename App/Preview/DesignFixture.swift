import MarketCore
import Foundation

/// Explicit opt-in visual fixture. Never used as a fallback for live data.
@MainActor
enum DesignFixture {
    static func populate(_ store: AppStore) {
        let position = PerpPosition(id: 2, symbol: "US100", size: 1, entryPrice: 27_951,
                                   leverage: 24, margin: 18.20, positionValue: 437.17,
                                   liquidationPrice: 27_301, unrealizedPnl: 3.70,
                                   returnOnEquity: 0.205, cumulativeFunding: -0.0372)
        var nvda = position
        nvda.id = 3; nvda.symbol = "NVDA"
        store.snapshot = PortfolioSnapshot(
            predictions: PredictionSnapshot(holdingsValue: 5.03, cash: 2.98),
            perps: PerpsSnapshot(portfolio: 17.72, cash: 0.02, positions: [position, nvda]))
        store.accountName = "Ryan Lin"
        store.instruments = [
            2: Instrument(id: 2, symbol: "US100", displaySymbol: "US100", priceDecimals: 0),
            3: Instrument(id: 3, symbol: "NVDA", displaySymbol: "NVDA", priceDecimals: 0)
        ]
        store.quotes = [2: MarketQuote(mark: 28_210), 3: MarketQuote(mark: 28_210)]
        store.predictionStatus = "Design preview — not live account data."
        store.perpsStatus = store.predictionStatus
    }
}
