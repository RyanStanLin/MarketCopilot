import MarketCore
import SwiftUI

struct DataHealthRow: View {
    let title: LocalizedStringKey
    let health: DataHealth
    let now: Date
    let staleAfter: TimeInterval
    var detail = ""
    private var status: String {
        guard let date = health.updatedAt else { return L10n.text(health.issue == nil ? "Not connected" : "Unavailable") }
        let age = max(0, Int(now.timeIntervalSince(date)))
        let time = age < 2 ? L10n.text("health.now") : (age < 60 ? L10n.format("%llds ago", age) : L10n.format("%lldm ago", age / 60))
        let state = health.issue != nil ? L10n.text("Unavailable") + " · "
            : (now.timeIntervalSince(date) > staleAfter ? L10n.text("Stale") + " · " : "")
        return state + L10n.format("%@ (Via %@)", time, L10n.text(health.channel.rawValue))
    }
    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.system(size: 11, weight: .medium)).frame(maxWidth: .infinity, alignment: .leading)
            Text(status).font(.system(size: 11, weight: .light)).lineLimit(1).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .trailing).contentTransition(.numericText())
                .animation(DesignTokens.numberAnimation, value: status)
        }
        .foregroundStyle(DesignTokens.secondary).frame(height: 22)
        .help(health.issue ?? (detail.isEmpty ? status : L10n.text(detail)))
        .menuHover(.action, id: String(describing: title))
    }
}
