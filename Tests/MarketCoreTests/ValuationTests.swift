import Foundation
import Testing
@testable import MarketCore

@Suite("Portfolio valuation")
struct ValuationTests {
    @Test func totalsIncludePredictionCashWithoutDoubleCountingPerpsCash() {
        let snapshot = PortfolioSnapshot(
            predictions: PredictionSnapshot(holdingsValue: Decimal(string: "5.03")!, cash: Decimal(string: "2.98")!),
            perps: PerpsSnapshot(portfolio: Decimal(string: "17.72")!, cash: Decimal(string: "0.02")!, positions: []))
        #expect(snapshot.predictions?.portfolio == Decimal(string: "8.01"))
        #expect(snapshot.portfolio == Decimal(string: "25.73"))
        #expect(snapshot.cash == Decimal(string: "3.00"))
    }

    @Test func missingProductDoesNotBecomeZeroInTotals() {
        let onlyPrediction = PortfolioSnapshot(predictions: PredictionSnapshot(holdingsValue: 10, cash: 5))
        #expect(onlyPrediction.portfolio == nil)
        #expect(onlyPrediction.cash == nil)
        let missingCash = PortfolioSnapshot(
            predictions: PredictionSnapshot(holdingsValue: 10, cash: nil),
            perps: PerpsSnapshot(portfolio: 2, cash: 1, positions: []))
        #expect(missingCash.portfolio == nil)
        #expect(missingCash.cash == nil)
    }

    @Test func confirmedEmptyAccountsAreValidZeroBalances() {
        let snapshot = PortfolioSnapshot(
            predictions: PredictionSnapshot(holdingsValue: 0, cash: 0),
            perps: PerpsSnapshot(portfolio: 0, cash: 0, positions: []))
        #expect(snapshot.portfolio == 0)
        #expect(snapshot.cash == 0)
    }

    @Test func formattingPreservesSignedMoneyAndFundingPrecision() {
        #expect(MarketFormat.currency(Decimal(string: "3.70"), signed: true) == "+$3.70")
        #expect(MarketFormat.currency(Decimal(string: "-0.0372"), fractionDigits: 4) == "-$0.0372")
        #expect(MarketFormat.currency(nil) == "—")
        #expect(MarketFormat.currency(28_210, fractionDigits: 0) == "$28,210")
        #expect(MarketFormat.percent(Decimal(string: "0.205")!) == "+20.50%")
        #expect(MarketFormat.percent(Decimal(string: "-0.0027")!) == "-0.27%")
    }
}
