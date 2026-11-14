import SwiftUI

struct DrawerReelEffect: ViewModifier {
    let viewportHeight: CGFloat
    let topActive: Bool
    let bottomActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.visualEffect { view, geometry in
            view.distortionEffect(ShaderLibrary.drawerReel(
                .float2(Float(geometry.size.width), Float(geometry.size.height)),
                .float(Float(geometry.frame(in: .scrollView(axis: .vertical)).minY)),
                .float(Float(viewportHeight)), .float(Float(DesignTokens.scrollShadowHeight)),
                .float(topActive && !reduceMotion ? 1 : 0), .float(bottomActive && !reduceMotion ? 1 : 0)),
                maxSampleOffset: CGSize(width: 40, height: 40))
        }
    }
}
