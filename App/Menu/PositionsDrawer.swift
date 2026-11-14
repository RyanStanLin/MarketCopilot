import SwiftUI
import MarketCore

struct PositionsDrawer: View {
    let store: AppStore
    let product: MarketProduct
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            SectionHeading(title: product == .predictions ? "Markets" : "Positions")
            PositionsContent(store: store, product: product, viewportHeight: max(0, height - 42))
        }
        .padding(.horizontal, DesignTokens.inset).padding(.vertical, 8)
        .frame(height: max(0, height - 2), alignment: .top)
        .background(.fill.quaternary)
        .padding(.vertical, 1)
        .background(DesignTokens.drawerBorder)
        .accessibilityIdentifier(product == .predictions ? "predictionDrawer" : "positionsDrawer")
    }
}
