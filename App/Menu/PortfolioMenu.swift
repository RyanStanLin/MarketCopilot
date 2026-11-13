import SwiftUI

struct PortfolioMenu: View {
    let store: AppStore
    var staticBackdrop: Color?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            PortfolioSection(store: store)
            if store.isPerpsExpanded {
                PositionsDrawer(store: store)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
            }
            CashSection(store: store)
        }
        .frame(width: DesignTokens.menuWidth, height: store.menuHeight, alignment: .top)
        .background {
            if let staticBackdrop { staticBackdrop } else { GlassSurface() }
        }
        .clipShape(.rect(cornerRadius: DesignTokens.cornerRadius))
        .opacity(store.isMenuOpen ? 1 : 0)
        .scaleEffect(store.isMenuOpen || reduceMotion ? 1 : 0.975, anchor: .top)
        .environment(\.menuIsVisible, store.isMenuOpen)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("portfolioMenu")
        .transaction { if reduceMotion { $0.disablesAnimations = true } }
    }
}
