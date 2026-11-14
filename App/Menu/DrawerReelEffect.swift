import SwiftUI

struct DrawerReelEffect: ViewModifier, Animatable {
    let viewportHeight: CGFloat
    nonisolated var topStrength: CGFloat
    nonisolated var bottomStrength: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    nonisolated var animatableData: AnimatableValues<CGFloat, CGFloat> {
        get { AnimatableValues(topStrength, bottomStrength) }
        set {
            topStrength = min(1, max(0, newValue.value.0))
            bottomStrength = min(1, max(0, newValue.value.1))
        }
    }

    func body(content: Content) -> some View {
        content.visualEffect { view, geometry in
            view.layerEffect(ShaderLibrary.drawerReel(
                .float2(Float(geometry.size.width), Float(geometry.size.height)),
                .float(Float(geometry.frame(in: .scrollView(axis: .vertical)).minY)),
                .float(Float(viewportHeight)), .float(Float(DesignTokens.scrollEdgeHeight)),
                .float(Float(topStrength)), .float(Float(bottomStrength)),
                .float(Float(DesignTokens.drawerMinimumScale)), .float(Float(DesignTokens.scrollBlurRadius)),
                .float(reduceMotion ? 0 : 1)),
                maxSampleOffset: CGSize(width: 40, height: 40))
        }
    }
}
