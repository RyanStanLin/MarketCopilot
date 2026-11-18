import AppKit
import MarketCore

struct StatusTokenValue: Identifiable, Equatable {
    let id: UUID
    let metric: MenuBarMetric
    let value: String
    let caption: String
    let number: Decimal?
    let liveMetric: LiveMetricKind
    let help: String
    var isIcon: Bool { metric == .appIcon }

    var width: CGFloat {
        if isIcon { return DesignTokens.statusIconSize }
        let amount = (value as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 13)]).width
        let label = (caption as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 10)]).width
        return ceil(max(amount, min(DesignTokens.statusCaptionMaximumWidth, label)))
    }
}
