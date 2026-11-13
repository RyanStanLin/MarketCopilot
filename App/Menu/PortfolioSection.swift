import SwiftUI
import MarketCore

struct PortfolioSection: View {
    let store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            MenuHeader(store: store)
            MenuSeparator()
            SectionHeading(title: "Portfolio")
            VStack(spacing: DesignTokens.rowGap) {
                SummaryRow(title: "Predictions", amount: store.snapshot.predictions?.portfolio,
                           symbol: "loupe", helpText: store.predictionStatus, hoverID: "portfolioPredictions")
                Button(action: store.toggleDrawer) {
                    SummaryRow(title: "Perps", amount: store.snapshot.perps?.portfolio,
                               symbol: "arrow.forward.circle.dotted", highlighted: store.isPerpsExpanded,
                               foldable: true, expanded: store.isPerpsExpanded,
                               helpText: store.perpsStatus, hoverID: "portfolioPerps")
                }
                .buttonStyle(PressButtonStyle())
                .accessibilityLabel("Perps positions")
                .accessibilityValue(L10n.text(store.isPerpsExpanded ? "Expanded" : "Collapsed"))
                .accessibilityIdentifier("togglePerps")
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal, DesignTokens.inset).padding(.top, 8)
    }
}
