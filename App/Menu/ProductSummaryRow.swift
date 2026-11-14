import MarketCore
import SwiftUI

struct ProductSummaryRow: View {
    let store: AppStore
    let product: MarketProduct
    private var predictions: Bool { product == .predictions }
    private var expanded: Bool { predictions ? store.isPredictionsExpanded : store.isPerpsExpanded }

    var body: some View {
        Button(action: toggle) {
            SummaryRow(title: predictions ? "Predictions" : "Perps",
                amount: predictions ? store.balances.predictionPortfolio : store.balances.perpsPortfolio,
                symbol: predictions ? "loupe" : "arrow.forward.circle.dotted", highlighted: expanded,
                foldable: true, expanded: expanded, helpText: predictions ? store.predictionStatus : store.perpsStatus,
                hoverID: predictions ? "portfolioPredictions" : "portfolioPerps", metric: .portfolio)
        }
        .buttonStyle(PressButtonStyle())
        .accessibilityIdentifier(predictions ? "togglePredictions" : "togglePerps")
        .accessibilityValue(L10n.text(expanded ? "Expanded" : "Collapsed"))
        .padding(.horizontal, DesignTokens.inset)
    }

    private func toggle() { if predictions { store.togglePredictionsDrawer() } else { store.toggleDrawer() } }
}
