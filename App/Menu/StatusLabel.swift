import MarketCore
import SwiftUI

struct StatusLabel: View {
    let store: AppStore
    let availableHeight: CGFloat
    private var scale: CGFloat { min(1, availableHeight / DesignTokens.statusHeight) }

    var body: some View {
        HStack(spacing: 8) {
            StatusColumn(value: MarketFormat.currency(store.statusPortfolio), title: "Portfolio")
            StatusColumn(value: MarketFormat.currency(store.statusCash), title: "Cash")
        }
        .foregroundStyle(.primary)
        .fixedSize().scaleEffect(scale)
        .frame(height: availableHeight)
        .opacity(store.isMenuOpen ? 0.78 : 1)
        .animation(DesignTokens.numberAnimation, value: store.statusPortfolio)
        .animation(DesignTokens.numberAnimation, value: store.statusCash)
        .help(store.statusDescription)
        .accessibilityElement(children: .combine)
    }
}
