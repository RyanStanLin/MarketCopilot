import MarketCore
import SwiftUI

struct StatusLabel: View {
    let store: AppStore
    let availableHeight: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        .scaleEffect(store.isMenuOpen && !reduceMotion ? 0.97 : 1)
        .animation(reduceMotion ? nil : DesignTokens.pressAnimation, value: store.isMenuOpen)
        .animation(DesignTokens.numberAnimation, value: store.statusPortfolio)
        .animation(DesignTokens.numberAnimation, value: store.statusCash)
        .help(store.statusDescription)
        .environment(\.locale, store.locale)
        .accessibilityElement(children: .combine)
        .transaction { if reduceMotion { $0.disablesAnimations = true } }
    }
}
