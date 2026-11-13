import SwiftUI

struct PortfolioMenu: View {
    let store: AppStore
    var staticBackdrop: Color?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        DrawerMenuLayout(store: store, progress: store.isPerpsExpanded ? 1 : 0,
                         expandedHeight: store.expandedDrawerHeight)
        .animation(reduceMotion ? nil : DesignTokens.drawerAnimation, value: store.isPerpsExpanded)
        .animation(reduceMotion ? nil : DesignTokens.drawerAnimation, value: store.expandedDrawerHeight)
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
