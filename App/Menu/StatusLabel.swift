import MarketCore
import SwiftUI

struct StatusLabel: View {
    let store: AppStore
    let availableHeight: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var scale: CGFloat { min(1, availableHeight / DesignTokens.statusHeight) }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(store.statusTokens) { token in
                if token.isIcon {
                    Image("MenuBarMark").renderingMode(.template).resizable().scaledToFit()
                        .frame(width: DesignTokens.statusIconSize, height: DesignTokens.statusIconSize)
                        .accessibilityLabel("MarketCopilot")
                } else {
                    StatusColumn(value: token.value, title: token.caption, number: token.number, metric: token.liveMetric)
                        .frame(width: token.width, alignment: .leading)
                        .help(token.help)
                }
            }
        }
        .foregroundStyle(.primary)
        .fixedSize().scaleEffect(scale)
        .frame(height: availableHeight)
        .opacity(store.isMenuOpen ? 0.78 : 1)
        .scaleEffect(store.isMenuOpen && !reduceMotion ? 0.97 : 1)
        .animation(reduceMotion ? nil : DesignTokens.pressAnimation, value: store.isMenuOpen)
        .animation(DesignTokens.numberAnimation, value: store.statusPortfolio)
        .animation(DesignTokens.numberAnimation, value: store.statusCash)
        .help(store.menuBarStatusDescription)
        .environment(\.locale, store.locale)
        .environment(\.liveColorSettings, store.refreshSettings.liveColor)
        .accessibilityElement(children: .combine)
        .transaction { if reduceMotion { $0.disablesAnimations = true } }
    }
}
