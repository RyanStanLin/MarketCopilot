import AppKit
import SwiftUI

struct MenuBarComboBox: NSViewRepresentable {
    let choices: [MenuBarChoice]
    let selection: String?
    let placeholder: String
    let onSelect: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NSComboBox {
        let box = NSComboBox()
        box.controlSize = .regular
        box.font = .systemFont(ofSize: 13)
        box.isEditable = true
        box.completes = true
        box.hasVerticalScroller = true
        box.numberOfVisibleItems = 12
        box.delegate = context.coordinator
        box.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return box
    }

    func updateNSView(_ box: NSComboBox, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        coordinator.isUpdating = true
        defer { coordinator.isUpdating = false }
        if coordinator.choices != choices {
            box.removeAllItems()
            box.addItems(withObjectValues: choices.map(\.title))
            coordinator.choices = choices
        }
        box.placeholderString = placeholder
        box.setAccessibilityLabel(placeholder)
        let selected = choices.firstIndex { $0.id == selection }
        if let selected {
            if box.indexOfSelectedItem != selected { box.selectItem(at: selected) }
            let title = choices[selected].title
            if !coordinator.isEditing { box.stringValue = title }
            box.toolTip = title
        } else if !coordinator.isEditing {
            if box.indexOfSelectedItem >= 0 { box.deselectItem(at: box.indexOfSelectedItem) }
            box.stringValue = ""
            box.toolTip = placeholder
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSComboBoxDelegate {
        var parent: MenuBarComboBox
        var choices: [MenuBarChoice] = []
        var isUpdating = false
        var isEditing = false

        init(parent: MenuBarComboBox) { self.parent = parent }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard !isUpdating, let box = notification.object as? NSComboBox,
                  choices.indices.contains(box.indexOfSelectedItem) else { return }
            parent.onSelect(choices[box.indexOfSelectedItem].id)
        }

        func controlTextDidBeginEditing(_ notification: Notification) { isEditing = true }

        func controlTextDidEndEditing(_ notification: Notification) {
            isEditing = false
            guard let box = notification.object as? NSComboBox else { return }
            if choices.indices.contains(box.indexOfSelectedItem), choices[box.indexOfSelectedItem].title == box.stringValue {
                parent.onSelect(choices[box.indexOfSelectedItem].id)
            } else if let choice = choices.first(where: { $0.title == box.stringValue }) {
                parent.onSelect(choice.id)
            } else {
                box.stringValue = choices.first(where: { $0.id == parent.selection })?.title ?? ""
            }
        }
    }
}
