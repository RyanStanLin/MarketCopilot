import MarketCore
import SwiftUI

struct DrawerMenuLayout: View, Animatable {
    let store: AppStore
    nonisolated var predictionProgress: CGFloat
    nonisolated var progress: CGFloat
    nonisolated var expandedHeight: CGFloat
    nonisolated var predictionHeight: CGFloat

    // Clamp spring overshoot before it can reveal content outside the drawer.
    nonisolated var animatableData: AnimatableValues<CGFloat, CGFloat, CGFloat, CGFloat> {
        get { AnimatableValues(predictionProgress, progress, expandedHeight, predictionHeight) }
        set {
            predictionProgress = min(1, max(0, newValue.value.0))
            progress = min(1, max(0, newValue.value.1))
            expandedHeight = max(0, newValue.value.2)
            predictionHeight = max(0, newValue.value.3)
        }
    }

    var body: some View {
        let separator = DesignTokens.separatorHeight * (1 - max(progress, predictionProgress))
        let height = DesignTokens.collapsedHeight - DesignTokens.separatorHeight + separator
            + expandedHeight * progress + predictionHeight * predictionProgress + 2 * predictionProgress
        VStack(spacing: 0) {
            PortfolioSection(store: store)
                .modifier(MenuLayoutProbe(store: store, component: "header"))
                .zIndex(1)
            ProductSummaryRow(store: store, product: .predictions).padding(.vertical, 6).zIndex(1)
            PositionsDrawer(store: store, product: .predictions, height: predictionHeight)
                .frame(height: predictionHeight * predictionProgress, alignment: .top).clipped()
                .allowsHitTesting(store.isPredictionsExpanded).accessibilityHidden(!store.isPredictionsExpanded)
            ProductSummaryRow(store: store, product: .perps)
                .padding(.top, 4 + 2 * predictionProgress).padding(.bottom, 6).zIndex(1)
            PositionsDrawer(store: store, product: .perps, height: expandedHeight)
                .modifier(MenuLayoutProbe(store: store, component: "drawerContent"))
                .frame(height: expandedHeight * progress, alignment: .top)
                .clipped()
                .modifier(MenuLayoutProbe(store: store, component: "drawerViewport"))
                .allowsHitTesting(store.isPerpsExpanded)
                .accessibilityHidden(!store.isPerpsExpanded)
            CashSection(store: store, separatorHeight: separator)
                .modifier(MenuLayoutProbe(store: store, component: "cash"))
                .zIndex(1)
        }
        .frame(width: DesignTokens.menuWidth, height: height, alignment: .top)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            store.renderedMenuHeightChanged(height)
        }
        // The interpolated presentation already supplies every layout frame.
        // Child frame modifiers must not start a second implicit animation.
        .transaction { $0.animation = nil }
    }
}
