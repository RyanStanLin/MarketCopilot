#if DEBUG
import AppKit
import SwiftUI
import MarketCore

/// Component rendering is independent of screen-recording permission.
/// Native glass compositing is verified separately on a visible desktop.
@MainActor
enum DesignRenderer {
    static func render(_ store: AppStore) {
        store.isMenuOpen = true
        store.refreshSettings.language = .english
        L10n.language = .english
        let directory = URL.cachesDirectory.appending(path: "DesignValidation", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for dark in [false, true] {
                NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
                for state in ["collapsed", "expanded", "predictions"] {
                    let expanded = state != "collapsed"
                    store.isPerpsExpanded = state == "expanded"
                    store.isPredictionsExpanded = state == "predictions"
                    let renderer = ImageRenderer(content: PortfolioMenu(store: store,
                        staticBackdrop: dark ? Color(nsColor: .windowBackgroundColor) : Color(white: 0.84))
                        .environment(\.colorScheme, dark ? .dark : .light)
                        .environment(\.previewHoveredItems, expanded ? [] : ["portfolioPredictions", "settings"])
                        .padding(.horizontal, 48).padding(.top, 40).padding(.bottom, 56)
                        .background(dark ? Color(white: 0.12) : Color(white: 0.82)))
                    renderer.scale = 2
                    var rendered: CGImage?
                    NSApp.effectiveAppearance.performAsCurrentDrawingAppearance { rendered = renderer.cgImage }
                    guard let image = rendered else { continue }
                    let rep = NSBitmapImageRep(cgImage: image)
                    let name = "\(state)-\(dark ? "dark" : "light").png"
                    try rep.representation(using: .png, properties: [:])?.write(to: directory.appending(path: name))
                }
            }
            let heights = "width=308\ncollapsed=404\nexpanded=843\npredictions=862\n"
            try heights.write(to: directory.appending(path: "geometry.txt"), atomically: true, encoding: .utf8)
            print("Design render: \(directory.path)")
        } catch { print("Design render failed: \(error.localizedDescription)") }
        NSApp.terminate(nil)
    }
}
#endif
