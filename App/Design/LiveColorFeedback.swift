import AppKit
import MarketCore
import SwiftUI

struct LiveColorFeedback: ViewModifier {
    let value: Decimal?
    let metric: LiveMetricKind
    let baseline: Color
    @Environment(\.liveColorSettings) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sequence = 0
    @State private var increasing = true

    func body(content: Content) -> some View {
        let enabled = settings.enabled && settings.metrics.contains(metric)
        content.keyframeAnimator(initialValue: 0.0, trigger: sequence) { view, strength in
            view.foregroundStyle(baseline.mix(with: tint, by: enabled ? strength : 0))
        } keyframes: { _ in
            MoveKeyframe(1)
            CubicKeyframe(0, duration: reduceMotion ? min(0.2, settings.duration) : settings.duration)
        }
        .onChange(of: value) { old, new in
            guard enabled, let old, let new, !old.isNaN, !new.isNaN, old != new else { return }
            increasing = new > old
            sequence &+= 1
        }
    }

    private var tint: Color {
        var result = increasing ? NSColor.systemGreen : NSColor.systemRed
        let appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        appearance?.performAsCurrentDrawingAppearance {
            let label = NSColor.secondaryLabelColor.usingColorSpace(.sRGB) ?? .secondaryLabelColor
            result = result.blended(withFraction: label.alphaComponent, of: label.withAlphaComponent(1)) ?? result
        }
        return Color(nsColor: result)
    }
}

extension View {
    func liveColor(_ value: Decimal?, metric: LiveMetricKind, baseline: Color = DesignTokens.secondary) -> some View {
        modifier(LiveColorFeedback(value: value, metric: metric, baseline: baseline))
    }
}
