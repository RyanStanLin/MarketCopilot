import AppKit
import MarketCore

@MainActor
final class MenuBarPreviewToolbar: NSObject, NSToolbarDelegate {
    static let closeID = NSToolbarItem.Identifier("menuBarPreview.close")
    static let titleID = NSToolbarItem.Identifier("menuBarPreview.title")
    var onClose: () -> Void = {}
    let titleField = NSTextField(labelWithString: "")

    override init() {
        super.init()
        titleField.font = .systemFont(ofSize: 13, weight: .semibold)
        titleField.textColor = .labelColor
        titleField.lineBreakMode = .byTruncatingTail
    }

    func makeToolbar() -> NSToolbar {
        let toolbar = NSToolbar(identifier: "MarketCopilot.MenuBarPreview")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.sizeMode = .small
        toolbar.allowsUserCustomization = false
        return toolbar
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.closeID, Self.titleID, .flexibleSpace]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: identifier)
        if identifier == Self.closeID {
            let button = NSButton(image: NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: L10n.text("Close"))!,
                                  target: self, action: #selector(close))
            button.isBordered = false
            button.contentTintColor = .secondaryLabelColor
            button.symbolConfiguration = .init(pointSize: 12, weight: .semibold)
            button.toolTip = L10n.text("Close")
            button.setAccessibilityLabel(L10n.text("Close"))
            item.view = button
        } else if identifier == Self.titleID {
            item.view = titleField
        } else { return nil }
        item.label = identifier == Self.closeID ? L10n.text("Close") : titleField.stringValue
        return item
    }

    @objc private func close() { onClose() }
}
