import SwiftUI

struct CashSection: View {
    let store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            if !store.isPerpsExpanded { MenuSeparator() }
            SectionHeading(title: "Cash")
            VStack(spacing: DesignTokens.rowGap) {
                SummaryRow(title: "Predictions", amount: store.snapshot.predictions?.cash,
                           symbol: "loupe", helpText: store.predictionStatus)
                SummaryRow(title: "Perps", amount: store.snapshot.perps?.cash,
                           symbol: "arrow.forward.circle.dotted",
                           helpText: "Available order margin\n" + store.perpsStatus)
            }.padding(.vertical, 6)
            MenuSeparator()
            Button(action: store.openSettings) {
                Text("Settings").font(DesignTokens.action).foregroundStyle(DesignTokens.primary)
                    .frame(maxWidth: .infinity, alignment: .leading).frame(height: 22)
            }
            .buttonStyle(PressButtonStyle())
            .accessibilityIdentifier("openSettings")
        }
        .padding(.horizontal, DesignTokens.inset).padding(.bottom, 8)
    }
}
