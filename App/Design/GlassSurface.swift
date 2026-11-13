import AppKit
import SwiftUI

struct GlassSurface: NSViewRepresentable {
    func makeNSView(context: Context) -> NSGlassEffectView {
        let view = NSGlassEffectView()
        view.cornerRadius = DesignTokens.cornerRadius
        view.style = .regular
        return view
    }

    func updateNSView(_ nsView: NSGlassEffectView, context: Context) {}
}
