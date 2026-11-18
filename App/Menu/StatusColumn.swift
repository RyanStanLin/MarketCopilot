import SwiftUI
import MarketCore

struct StatusColumn: View {
    let value: String
    let title: String
    let number: Decimal?
    let metric: LiveMetricKind

    var body: some View {
        VStack(alignment: .leading, spacing: -3) {
            Text(value).font(DesignTokens.statusAmount).lineLimit(1).frame(height: 16).contentTransition(.numericText())
                .liveColor(number, metric: metric, baseline: .primary)
            Text(title).font(DesignTokens.statusCaption).lineLimit(1).frame(height: 13)
                .liveColor(number, metric: metric, baseline: .primary)
        }
        .animation(DesignTokens.numberAnimation, value: number)
    }
}
