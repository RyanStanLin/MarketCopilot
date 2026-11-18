import AppKit

@MainActor
final class MenuBarScrollDriver {
    weak var scrollView: NSScrollView?

    func attach(_ view: NSScrollView) {
        scrollView = view
        if !view.hasHorizontalScroller { view.hasHorizontalScroller = true }
        if view.hasVerticalScroller { view.hasVerticalScroller = false }
        if view.autohidesScrollers { view.autohidesScrollers = false }
        if view.scrollerStyle != .overlay { view.scrollerStyle = .overlay }
        if view.verticalScrollElasticity != .none { view.verticalScrollElasticity = .none }
        if view.horizontalScrollElasticity != .automatic { view.horizontalScrollElasticity = .automatic }
        if !view.usesPredominantAxisScrolling { view.usesPredominantAxisScrolling = true }
        let insets = NSEdgeInsets(top: 0, left: MenuBarEditorTokens.inset, bottom: 1,
                                 right: MenuBarEditorTokens.addWidth + MenuBarEditorTokens.inset * 2)
        let current = view.scrollerInsets
        if current.top != insets.top || current.left != insets.left || current.bottom != insets.bottom || current.right != insets.right {
            view.scrollerInsets = insets
        }
    }

    @discardableResult
    func scroll(by distance: CGFloat) -> Bool {
        guard abs(distance) > 0.01 else { return false }
        guard let view = scrollView, let document = view.documentView else { return false }
        let clip = view.contentView
        let minimum = -view.contentInsets.left
        let maximum = max(minimum, document.frame.width - clip.bounds.width + view.contentInsets.right)
        let x = min(maximum, max(minimum, clip.bounds.minX + distance))
        guard abs(x - clip.bounds.minX) > 0.01 else { return false }
        clip.scroll(to: NSPoint(x: x, y: clip.bounds.minY))
        view.reflectScrolledClipView(clip)
        return true
    }
}
