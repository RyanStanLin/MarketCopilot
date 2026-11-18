import AppKit

final class MenuBarToolPanel: NSPanel {
    var onCancel: () -> Void = {}
    private let previewToolbar = MenuBarPreviewToolbar()
    override var title: String { didSet { previewToolbar.titleField.stringValue = title } }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(contentRect: .zero, styleMask: [.titled, .closable, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .windowBackgroundColor
        hasShadow = true
        isFloatingPanel = true
        level = .floating
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        titlebarSeparatorStyle = .none
        toolbarStyle = .unifiedCompact
        toolbar = previewToolbar.makeToolbar()
        previewToolbar.onClose = { [weak self] in self?.onCancel() }
        for kind: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
            standardWindowButton(kind)?.isHidden = true
        }
    }

    override func cancelOperation(_ sender: Any?) { onCancel() }
}
