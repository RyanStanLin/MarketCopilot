import AppKit
import SwiftUI

struct MenuBarScrollProbe: NSViewRepresentable {
    let driver: MenuBarScrollDriver

    func makeNSView(context: Context) -> Probe { Probe(driver: driver) }
    func updateNSView(_ view: Probe, context: Context) { view.configure() }

    final class Probe: NSView {
        let driver: MenuBarScrollDriver
        init(driver: MenuBarScrollDriver) { self.driver = driver; super.init(frame: .zero) }
        required init?(coder: NSCoder) { nil }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); configure() }
        override func viewDidMoveToSuperview() { super.viewDidMoveToSuperview(); configure() }
        override func layout() { super.layout(); configure() }
        func configure() { if let enclosingScrollView { driver.attach(enclosingScrollView) } }
    }
}
