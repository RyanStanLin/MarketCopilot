import AppKit
import SwiftUI

final class StatusHostingView: NSHostingView<StatusLabel> {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
