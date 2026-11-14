import SwiftUI
import MarketCore

struct PortfolioSection: View {
    let store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            MenuHeader(store: store)
            MenuSeparator()
            SectionHeading(title: "Portfolio")
        }
        .padding(.horizontal, DesignTokens.inset).padding(.top, 8)
    }
}
