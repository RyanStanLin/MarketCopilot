import MarketCore
import SwiftUI

struct DrawerMenuLayout: View, Animatable {
    let store: AppStore
    nonisolated var progress: CGFloat
    nonisolated var expandedHeight: CGFloat

    // Clamp spring overshoot before it can reveal content outside the drawer.
    nonisolated var animatableData: AnimatableValues<CGFloat, CGFloat> {
        get { AnimatableValues(progress, expandedHeight) }
        set {
            progress = min(1, max(0, newValue.value.0))
            expandedHeight = max(0, newValue.value.1)
        }
    }

    var body: some View {
        let presentation = DrawerPresentation(progress: progress, expandedHeight: expandedHeight,
            collapsedHeight: DesignTokens.collapsedHeight, separatorHeight: DesignTokens.separatorHeight)
        VStack(spacing: 0) {
            PortfolioSection(store: store)
                .modifier(MenuLayoutProbe(store: store, component: "header"))
                .zIndex(1)
            PositionsDrawer(store: store, height: expandedHeight)
                .modifier(MenuLayoutProbe(store: store, component: "drawerContent"))
                .frame(height: presentation.drawerHeight, alignment: .top)
                .clipped()
                .modifier(MenuLayoutProbe(store: store, component: "drawerViewport"))
                .allowsHitTesting(store.isPerpsExpanded)
                .accessibilityHidden(!store.isPerpsExpanded)
            CashSection(store: store, separatorHeight: presentation.separatorHeight)
                .modifier(MenuLayoutProbe(store: store, component: "cash"))
                .zIndex(1)
        }
        .frame(width: DesignTokens.menuWidth, height: presentation.menuHeight, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            store.renderedMenuHeightChanged(height)
        }
        // The interpolated presentation already supplies every layout frame.
        // Child frame modifiers must not start a second implicit animation.
        .transaction { $0.animation = nil }
    }
}
