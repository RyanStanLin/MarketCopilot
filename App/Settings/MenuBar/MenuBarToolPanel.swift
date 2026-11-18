import AppKit

final class MenuBarToolPanel: NSPanel {
    var onCancel: () -> Void = {}
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .utilityWindow, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isFloatingPanel = true
        level = .floating
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
    }

    override func cancelOperation(_ sender: Any?) { onCancel() }
}
