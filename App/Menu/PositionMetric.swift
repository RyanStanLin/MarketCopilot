import SwiftUI

struct PositionMetric: View {
    let value: String
    let label: String
    var alignment: HorizontalAlignment = .leading
    var helpText = ""

    var body: some View {
        VStack(alignment: alignment, spacing: 0) {
            Text(value).font(DesignTokens.metric).lineLimit(1).minimumScaleFactor(0.65)
                .frame(height: 20).contentTransition(.numericText())
            Text(label).font(DesignTokens.caption).frame(height: 15)
        }
        .foregroundStyle(DesignTokens.secondary)
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
        .help(helpText.isEmpty ? value : helpText)
        .accessibilityElement(children: .combine)
        .animation(DesignTokens.numberAnimation, value: value)
    }
}
