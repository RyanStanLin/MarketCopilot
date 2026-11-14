import AppKit

final class DrawerScrollProbe: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureScrolling()
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        configureScrolling()
    }

    override func layout() {
        super.layout()
        configureScrolling()
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func configureScrolling() {
        guard let scrollView = enclosingScrollView else { return }
        // Keep trackpad events on NSScrollView's native momentum / rubber-band path,
        // including when one or two positions fit without a scrollable range.
        if scrollView.verticalScrollElasticity != .allowed { scrollView.verticalScrollElasticity = .allowed }
        if scrollView.horizontalScrollElasticity != .none { scrollView.horizontalScrollElasticity = .none }
        if scrollView.hasHorizontalScroller { scrollView.hasHorizontalScroller = false }
        if !scrollView.usesPredominantAxisScrolling { scrollView.usesPredominantAxisScrolling = true }
        let clipView = scrollView.contentView
        if clipView.bounds.minX != 0 {
            clipView.scroll(to: NSPoint(x: 0, y: clipView.bounds.minY))
        }
    }
}
