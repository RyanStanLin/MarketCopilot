import AppKit

final class MenuBarToolPanel: NSPanel {
    var onCancel: () -> Void = {}
    private let previewHeader = MenuBarPreviewHeader(frame: .zero)
    override var title: String { didSet { previewHeader.updateTitle(title) } }
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
        previewHeader.onClose = { [weak self] in self?.onCancel() }
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
        previewHeader.translatesAutoresizingMaskIntoConstraints = false
        editor.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(previewHeader)
        backdrop.addSubview(editor)
        NSLayoutConstraint.activate([
            previewHeader.topAnchor.constraint(equalTo: backdrop.topAnchor),
            previewHeader.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            previewHeader.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            previewHeader.heightAnchor.constraint(equalToConstant: MenuBarEditorTokens.previewHeaderHeight),
            editor.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            editor.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            editor.topAnchor.constraint(equalTo: previewHeader.bottomAnchor),
            editor.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor)
        ])
    }

    func frameSize(forEditorSize size: NSSize) -> NSSize {
        NSSize(width: size.width, height: size.height + MenuBarEditorTokens.previewHeaderHeight)
    }

    override func cancelOperation(_ sender: Any?) { onCancel() }
}
