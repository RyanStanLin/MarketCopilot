import Foundation
import CoreGraphics

public enum MenuInteraction {
    /// Both global and local event monitors must leave status-item clicks to its action.
    public static func shouldDismiss(point: CGPoint, menuFrame: CGRect, statusFrame: CGRect) -> Bool {
        !menuFrame.contains(point) && !statusFrame.contains(point)
    }

    /// AppKit coordinates grow upward. Growing downward must preserve this top edge.
    public static func frame(topLeft: CGPoint, width: CGFloat, height: CGFloat) -> CGRect {
        CGRect(x: topLeft.x, y: topLeft.y - height, width: width, height: height)
    }
}
