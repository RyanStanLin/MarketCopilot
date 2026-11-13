import SwiftUI
import MarketCore

struct CashSection: View {
    let store: AppStore
    let separatorHeight: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            MenuSeparator()
                .frame(height: separatorHeight, alignment: .top)
                .clipped()
            SectionHeading(title: "Cash")
            VStack(spacing: DesignTokens.rowGap) {
                SummaryRow(title: "Predictions", amount: store.snapshot.predictions?.cash,
                           symbol: "loupe", helpText: store.predictionStatus, hoverID: "cashPredictions")
                SummaryRow(title: "Perps", amount: store.snapshot.perps?.cash,
                           symbol: "arrow.forward.circle.dotted",
                           helpText: L10n.text("Available order margin") + "\n" + L10n.text(store.perpsStatus), hoverID: "cashPerps")
            }.padding(.vertical, 6)
            MenuSeparator()
            Button(action: store.openSettings) {
                Text("Settings").font(DesignTokens.action).foregroundStyle(DesignTokens.primary)
                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: 22)
            }
            .buttonStyle(PressButtonStyle())
            .menuHover(.action, id: "settings")
            .accessibilityIdentifier("openSettings")
        }
        .padding(.horizontal, DesignTokens.inset).padding(.bottom, 8)
    }
}
