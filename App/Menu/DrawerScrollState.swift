import Foundation

struct DrawerScrollState: Equatable {
    var offset: CGFloat = 0
    var remaining: CGFloat = 0

    var topStrength: CGFloat { strength(for: offset) }
    var bottomStrength: CGFloat { strength(for: remaining) }

    private func strength(for distance: CGFloat) -> CGFloat {
        let t = min(1, max(0, distance / DesignTokens.scrollActivationDistance))
        // Zero slope and curvature at both ends, including the first scrolled pixel.
        return t * t * t * (t * (t * 6 - 15) + 10)
    }
}
