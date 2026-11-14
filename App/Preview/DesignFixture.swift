#if DEBUG
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
        var third = position
        third.id = 4
        store.snapshot = PortfolioSnapshot(
            predictions: PredictionSnapshot(holdingsValue: 5.03, cash: 2.98, positions: (0..<2).map { index in
                PredictionPosition(tokenID: "design-\(index)", conditionID: "design", title: "Will Jon Ossoff win the 2028 Democratic presidential nomination?",
                    outcome: "Yes", outcomeIndex: 0, shares: 523_508.1, averagePrice: 0.04, currentPrice: 0.261,
                    currentValue: 136_373.86, unrealizedPnl: 115_356.58, returnOnEquity: 5.4887,
                    status: "OPEN", isArchived: false, isRedeemable: false)
            }),
            perps: PerpsSnapshot(portfolio: 17.72, cash: 0.02, positions: [position, nvda, third]))
        store.maximumMenuHeight = 1100
        store.predictionHealth = DataHealth(updatedAt: .now, channel: .webSocket)
        store.perpsHealth = DataHealth(updatedAt: .now.addingTimeInterval(-3), channel: .polling)
        store.accountName = "Ryan Lin"
        store.instruments = [
            2: Instrument(id: 2, symbol: "US100", displaySymbol: "US100", priceDecimals: 0),
            3: Instrument(id: 3, symbol: "NVDA", displaySymbol: "NVDA", priceDecimals: 0),
            4: Instrument(id: 4, symbol: "US100", displaySymbol: "US100", priceDecimals: 0)
        ]
        store.quotes = [2: MarketQuote(mark: 28_210), 3: MarketQuote(mark: 28_210), 4: MarketQuote(mark: 28_210)]
        store.predictionStatus = "Design preview — not live account data."
        store.perpsStatus = store.predictionStatus
    }
}
#endif
