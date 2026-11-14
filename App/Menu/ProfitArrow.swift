import MarketCore
import SwiftUI

struct ProfitArrow: View {
    let profit: Decimal?
    private var profitable: Bool { (profit ?? 0) >= 0 }
    var body: some View {
        Image(systemName: profitable ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
            .font(.system(size: 14)).foregroundStyle(DesignTokens.secondary)
            .frame(width: 14, height: 20)
            .contentTransition(.symbolEffect(.replace))
            .accessibilityLabel(L10n.text(profitable ? "Profitable position" : "Losing position"))
            .animation(DesignTokens.numberAnimation, value: profitable)
    }
}
