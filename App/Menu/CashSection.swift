import SwiftUI

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
                           helpText: "Available order margin\n" + store.perpsStatus, hoverID: "cashPerps")
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
