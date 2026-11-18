import MarketCore
import SwiftUI

struct MenuBarDropDelegate: DropDelegate {
    let store: AppStore
    let targetID: UUID?
    @Binding var draggedID: UUID?
    let reduceMotion: Bool

    func validateDrop(info: DropInfo) -> Bool {
        draggedID != nil && info.hasItemsConforming(to: [MenuBarDragType.token])
    }

    func dropEntered(info: DropInfo) {
        guard let draggedID, let targetID, draggedID != targetID else { return }
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) {
            store.moveMenuBarToken(draggedID, to: targetID)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }

    func performDrop(info: DropInfo) -> Bool {
        guard let id = draggedID else { return false }
        if targetID == nil, let last = store.refreshSettings.menuBarTokens.last, last.id != id {
            withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) {
                store.moveMenuBarToken(id, to: last.id)
            }
        }
        draggedID = nil
        return true
    }
}
