import AppKit
import MarketCore

/// Explicit full-width header avoids the toolbar's reserved traffic-light gutter.
final class MenuBarPreviewHeader: NSView {
    var onClose: () -> Void = {}
    let titleField = NSTextField(labelWithString: "")
    private let closeButton = NSButton()
    override var mouseDownCanMoveWindow: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: nil)
        closeButton.isBordered = false
        closeButton.contentTintColor = .secondaryLabelColor
        closeButton.symbolConfiguration = .init(pointSize: 12, weight: .semibold)
        closeButton.target = self
        closeButton.action = #selector(close)
        titleField.font = .systemFont(ofSize: 13, weight: .semibold)
        titleField.textColor = .labelColor
        titleField.lineBreakMode = .byTruncatingTail
        titleField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for view in [closeButton, titleField] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
            titleField.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 8),
            titleField.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleField.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12)
        ])
        updateTitle("")
    }

    required init?(coder: NSCoder) { nil }

    func updateTitle(_ title: String) {
        titleField.stringValue = title
        titleField.setAccessibilityLabel(title)
        closeButton.toolTip = L10n.text("Close")
        closeButton.setAccessibilityLabel(L10n.text("Close"))
    }

    @objc private func close() { onClose() }
}
