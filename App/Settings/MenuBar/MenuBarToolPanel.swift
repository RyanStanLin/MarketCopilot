import AppKit

final class MenuBarToolPanel: NSPanel {
    var onCancel: () -> Void = {}
    private let previewToolbar = MenuBarPreviewToolbar()
    override var title: String { didSet { previewToolbar.titleField.stringValue = title } }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init() {
        super.init(contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
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

    func installEditor(_ editor: NSView) {
        let backdrop = NSVisualEffectView()
        backdrop.material = .popover
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        contentView = backdrop
        editor.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(editor)
        let top = (contentLayoutGuide as? NSLayoutGuide)?.topAnchor ?? backdrop.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            editor.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            editor.topAnchor.constraint(equalTo: top),
            editor.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor)
        ])
    }

    func frameSize(forEditorSize size: NSSize) -> NSSize {
        let chrome = max(0, frame.height - contentLayoutRect.height)
        return NSSize(width: size.width, height: size.height + chrome)
    }

    override func cancelOperation(_ sender: Any?) { onCancel() }
}
