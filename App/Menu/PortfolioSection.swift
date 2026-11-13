import SwiftUI

struct PortfolioSection: View {
    let store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            MenuHeader(store: store)
            MenuSeparator()
            SectionHeading(title: "Portfolio")
            VStack(spacing: DesignTokens.rowGap) {
                SummaryRow(title: "Predictions", amount: store.snapshot.predictions?.portfolio,
                           symbol: "loupe", helpText: store.predictionStatus)
                Button(action: store.toggleDrawer) {
                    SummaryRow(title: "Perps", amount: store.snapshot.perps?.portfolio,
                               symbol: "arrow.forward.circle.dotted", highlighted: true,
                               foldable: true, helpText: store.perpsStatus)
                }
                .buttonStyle(PressButtonStyle())
                .accessibilityLabel("Perps positions")
                .accessibilityValue(store.isPerpsExpanded ? "Expanded" : "Collapsed")
                .accessibilityIdentifier("togglePerps")
            }
            .padding(.vertical, 6)
        }
        .padding(.horizontal, DesignTokens.inset).padding(.top, 8)
    }
}
