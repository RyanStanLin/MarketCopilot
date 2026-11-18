import AppKit

@MainActor
final class MenuBarScrollDriver {
    weak var scrollView: NSScrollView?
    var onScrollChange: () -> Void = {}
    private var boundsObserver: NSObjectProtocol?

    func attach(_ view: NSScrollView) {
        if scrollView !== view {
            detach()
            view.contentView.postsBoundsChangedNotifications = true
            boundsObserver = NotificationCenter.default.addObserver(forName: NSView.boundsDidChangeNotification,
                object: view.contentView, queue: .main) { [weak self] _ in
                    Task { @MainActor in self?.onScrollChange() }
                }
        }
        scrollView = view
        if view.drawsBackground { view.drawsBackground = false }
        if view.contentView.drawsBackground { view.contentView.drawsBackground = false }
        view.contentView.wantsLayer = true
        view.contentView.clipsToBounds = true
        view.contentView.layer?.masksToBounds = true
        if !view.hasHorizontalScroller { view.hasHorizontalScroller = true }
        if view.hasVerticalScroller { view.hasVerticalScroller = false }
        if view.autohidesScrollers { view.autohidesScrollers = false }
        if view.scrollerStyle != .overlay { view.scrollerStyle = .overlay }
        if view.verticalScrollElasticity != .none { view.verticalScrollElasticity = .none }
        if view.horizontalScrollElasticity != .automatic { view.horizontalScrollElasticity = .automatic }
        if !view.usesPredominantAxisScrolling { view.usesPredominantAxisScrolling = true }
        let insets = NSEdgeInsets(top: 0, left: MenuBarEditorTokens.inset, bottom: 1,
                                 right: MenuBarEditorTokens.inset)
        let current = view.scrollerInsets
        if current.top != insets.top || current.left != insets.left || current.bottom != insets.bottom || current.right != insets.right {
            view.scrollerInsets = insets
        }
        onScrollChange()
    }

    var edgeDistances: (leading: CGFloat, trailing: CGFloat) {
        guard let view = scrollView, let document = view.documentView else { return (0, 0) }
        let minimum = -view.contentInsets.left
        let maximum = max(minimum, document.frame.width - view.contentView.bounds.width + view.contentInsets.right)
        guard maximum - minimum > 0.5 else { return (0, 0) }
        return (abs(view.contentView.bounds.minX - minimum), abs(maximum - view.contentView.bounds.minX))
    }

    func detach() {
        if let boundsObserver { NotificationCenter.default.removeObserver(boundsObserver) }
        boundsObserver = nil
        scrollView = nil
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
