import MarketCore
import SwiftUI

struct SummaryRow: View {
    let title: LocalizedStringKey
    let amount: Decimal?
    let symbol: String
    var highlighted = false
    var foldable = false
    var expanded = false
    var helpText = ""
    var hoverID = ""

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: DesignTokens.iconGap) {
                HeadIcon(symbol: symbol, highlighted: highlighted)
                VStack(alignment: .leading, spacing: 0) {
                    Text(MarketFormat.currency(amount)).font(DesignTokens.amount)
                        .foregroundStyle(DesignTokens.primary)
                        .frame(height: 20).contentTransition(.numericText())
                    Text(title).font(DesignTokens.caption).foregroundStyle(DesignTokens.secondary).frame(height: 15)
                }
            }
            Spacer(minLength: 4)
            if foldable {
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .animation(DesignTokens.drawerAnimation, value: expanded)
                    .frame(width: 12, height: 22).foregroundStyle(DesignTokens.primary)
            }
        }
        .frame(height: DesignTokens.metricHeight)
        .contentShape(Rectangle())
        .help(L10n.text(helpText))
        .animation(DesignTokens.numberAnimation, value: amount)
        .accessibilityElement(children: .combine)
        .menuHover(.summary, id: hoverID)
    }
}
