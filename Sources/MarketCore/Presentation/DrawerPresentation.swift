import CoreGraphics

/// One presentation value controls both the clipped SwiftUI drawer and its AppKit window.
public struct DrawerPresentation: Sendable {
    public let progress: CGFloat
    public let drawerHeight: CGFloat
    public let separatorHeight: CGFloat
    public let menuHeight: CGFloat

    public init(progress: CGFloat, expandedHeight: CGFloat, collapsedHeight: CGFloat, separatorHeight: CGFloat) {
        self.progress = min(1, max(0, progress))
        drawerHeight = max(0, expandedHeight) * self.progress
        self.separatorHeight = separatorHeight * (1 - self.progress)
        menuHeight = collapsedHeight - separatorHeight + drawerHeight + self.separatorHeight
    }
}
