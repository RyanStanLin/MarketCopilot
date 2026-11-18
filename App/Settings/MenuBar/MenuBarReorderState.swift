import MarketCore
import Observation
import SwiftUI

@MainActor @Observable
final class MenuBarReorderState {
    private(set) var activeID: UUID?
    private(set) var isSettling = false
    private(set) var order: [UUID] = []
    var frames: [UUID: CGRect] = [:]
    private var pointer = CGPoint.zero
    private var grabOffset = CGSize.zero
    private var direction: CGFloat = 0
    var isLifted: Bool { activeID != nil && !isSettling }

    func tokens(from tokens: [MenuBarToken]) -> [MenuBarToken] {
        guard activeID != nil else { return tokens }
        let byID = Dictionary(uniqueKeysWithValues: tokens.map { ($0.id, $0) })
        let ordered = order.compactMap { byID[$0] }
        let known = Set(order)
        return ordered + tokens.filter { !known.contains($0.id) }
    }

    func update(id: UUID, value: DragGesture.Value, tokens: [MenuBarToken], reduceMotion: Bool) {
        if activeID == nil {
            guard let frame = frames[id] else { return }
            activeID = id
            order = tokens.map(\.id)
            pointer = value.startLocation
            grabOffset = CGSize(width: value.startLocation.x - frame.midX, height: value.startLocation.y - frame.midY)
            isSettling = false
        }
        guard activeID == id, !isSettling else { return }
        let delta = value.location.x - pointer.x
        if abs(delta) > 0.1 { direction = delta > 0 ? 1 : -1 }
        pointer = value.location
        reorder(reduceMotion: reduceMotion)
    }

    func offset(for id: UUID) -> CGSize {
        guard activeID == id, !isSettling, let frame = frames[id] else { return .zero }
        return CGSize(width: pointer.x - grabOffset.width - frame.midX,
                      height: min(6, max(-6, pointer.y - grabOffset.height - frame.midY)))
    }

    func edgeVelocity(viewportWidth: CGFloat) -> CGFloat {
        guard isLifted else { return 0 }
        let left = MenuBarEditorTokens.inset
        let right = viewportWidth - MenuBarEditorTokens.inset
        let band: CGFloat = 28
        if pointer.x < left + band { return -360 * min(1, max(0, (left + band - pointer.x) / band)) }
        if pointer.x > right - band { return 360 * min(1, max(0, (pointer.x - right + band) / band)) }
        return 0
    }

    func scrolled(direction: CGFloat, reduceMotion: Bool) {
        self.direction = direction
        reorder(reduceMotion: reduceMotion)
    }

    private func reorder(reduceMotion: Bool) {
        guard let activeID, let current = order.firstIndex(of: activeID), direction != 0 else { return }
        let center = pointer.x - grabOffset.width
        var destination = current
        if direction > 0 {
            while destination + 1 < order.count,
                  let next = frames[order[destination + 1]], center > next.midX + MenuBarEditorTokens.gap {
                destination += 1
            }
        } else {
            while destination > 0,
                  let previous = frames[order[destination - 1]], center < previous.midX - MenuBarEditorTokens.gap {
                destination -= 1
            }
        }
        guard destination != current else { return }
        withAnimation(reduceMotion ? nil : DesignTokens.pressAnimation) {
            let token = order.remove(at: current)
            order.insert(token, at: destination)
        }
    }

    func settle(reduceMotion: Bool) {
        guard activeID != nil else { return }
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) {
            isSettling = true
        } completion: { [weak self] in self?.reset() }
    }

    func reset() {
        activeID = nil; isSettling = false; order = []
        pointer = .zero; grabOffset = .zero; direction = 0
    }
}
