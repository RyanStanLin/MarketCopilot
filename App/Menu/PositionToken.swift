import MarketCore
import SwiftUI

struct PositionToken: View {
    let label: String
    let detail: String
    let positive: Bool
    let number: Decimal?
    let metric: LiveMetricKind

    var body: some View {
        HStack(spacing: 0) {
            Text(L10n.text(label)).font(.system(size: 12).width(.condensed))
                .foregroundStyle(positive ? Color.green : Color.red)
                .frame(height: 15).padding(.leading, 6).padding(.trailing, 4).padding(.vertical, 2)
                .background(.fill.tertiary)
            Text(detail).font(.system(size: 12, design: .rounded))
                .frame(height: 15).contentTransition(.numericText())
                .liveColor(number, metric: metric)
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(.fill.secondary)
        }
        .clipShape(.rect(cornerRadius: 6))
        .fixedSize()
        .animation(DesignTokens.numberAnimation, value: number)
    }
}
