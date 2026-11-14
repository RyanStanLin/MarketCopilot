import MarketCore
import SwiftUI

struct PositionProfit: View {
    let profit: Decimal?
    let percentage: Decimal?

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(MarketFormat.currency(profit, signed: true))
                .font(DesignTokens.amount).frame(height: 20).contentTransition(.numericText())
                .liveColor(profit, metric: .profit, baseline: DesignTokens.primary)
            Text(percentage.map(MarketFormat.percent) ?? "—")
                .font(DesignTokens.caption).frame(height: 15).contentTransition(.numericText())
                .liveColor(percentage, metric: .returnOnEquity, baseline: DesignTokens.primary)
        }
        .fixedSize()
        .animation(DesignTokens.numberAnimation, value: profit)
        .animation(DesignTokens.numberAnimation, value: percentage)
    }
}
