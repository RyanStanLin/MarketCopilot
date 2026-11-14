import AppKit

final class DrawerScrollProbe: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        lockHorizontalAxis()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        lockHorizontalAxis()
    }

    override func layout() {
        super.layout()
        lockHorizontalAxis()
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func lockHorizontalAxis() {
        guard let scrollView = enclosingScrollView else { return }
        if scrollView.horizontalScrollElasticity != .none { scrollView.horizontalScrollElasticity = .none }
        if scrollView.hasHorizontalScroller { scrollView.hasHorizontalScroller = false }
        if !scrollView.usesPredominantAxisScrolling { scrollView.usesPredominantAxisScrolling = true }
        let clipView = scrollView.contentView
        if clipView.bounds.minX != 0 {
            clipView.scroll(to: NSPoint(x: 0, y: clipView.bounds.minY))
        }
    }
}
