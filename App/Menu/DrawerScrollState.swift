import Foundation

struct DrawerScrollState: Equatable {
    // Preserve both ends of rubber banding, including offsets below zero and
    // beyond the normal range. A short list has zero extent, but still bounces.
    var offset: CGFloat = 0
    var extent: CGFloat = 0

    var topStrength: CGFloat { strength(for: offset) }
    var bottomStrength: CGFloat { strength(for: extent - offset) }
    var navigationOffset: CGFloat { min(max(0, offset), extent) }

    private func strength(for distance: CGFloat) -> CGFloat {
        let t = min(1, max(0, distance / DesignTokens.scrollActivationDistance))
        // Zero slope and curvature at both ends, including the first scrolled pixel.
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
}
