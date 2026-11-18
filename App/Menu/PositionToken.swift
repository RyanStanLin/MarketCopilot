import AppKit
import MarketCore
import SwiftUI

struct PositionToken: View {
    let label: String
    let detail: String
    let positive: Bool
    let number: Decimal?
    let metric: LiveMetricKind
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityContrast) private var contrast

    var body: some View {
        HStack(spacing: 0) {
            Text(L10n.text(label)).font(.system(size: 12).width(.condensed))
                .foregroundStyle(labelColor)
                .frame(height: 15).padding(.leading, 6).padding(.trailing, 4).padding(.vertical, 2)
                .background(.fill.tertiary)
            Text(detail).font(.system(size: 12, design: .rounded))
                .frame(height: 15).contentTransition(.numericText())
                .liveColor(number, metric: metric)
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(.fill.secondary)
        }
        .clipShape(.rect(cornerRadius: 6))
        .fixedSize()
        .animation(DesignTokens.numberAnimation, value: number)
    }

    private var labelColor: Color {
        let name: NSAppearance.Name
        if colorScheme == .dark {
            name = contrast == .increased ? .accessibilityHighContrastDarkAqua : .darkAqua
        } else {
            name = contrast == .increased ? .accessibilityHighContrastAqua : .aqua
        }
        var result = positive ? NSColor.systemGreen : NSColor.systemRed
        NSAppearance(named: name)?.performAsCurrentDrawingAppearance {
            let base = result.usingColorSpace(.sRGB) ?? result
            let overlay = NSColor.tertiaryLabelColor.usingColorSpace(.sRGB) ?? .tertiaryLabelColor
            result = base.blended(withFraction: overlay.alphaComponent, of: overlay.withAlphaComponent(1)) ?? base
        }
        return Color(nsColor: result)
    }
}
