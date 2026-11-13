import Foundation
import CoreGraphics
import Testing
@testable import MarketCore

@Suite("Menu presentation")
struct MenuInteractionTests {
    @Test func statusItemClickIsNotAnOutsideDismissBeforeItsToggleAction() {
        let menu = CGRect(x: 100, y: 300, width: 308, height: 327)
        let status = CGRect(x: 100, y: 630, width: 86, height: 26)
        #expect(!MenuInteraction.shouldDismiss(point: CGPoint(x: 120, y: 640), menuFrame: menu, statusFrame: status))
        #expect(!MenuInteraction.shouldDismiss(point: CGPoint(x: 200, y: 400), menuFrame: menu, statusFrame: status))
        #expect(MenuInteraction.shouldDismiss(point: CGPoint(x: 500, y: 400), menuFrame: menu, statusFrame: status))
    }

    @Test func drawerResizeKeepsTopAndLeftEdgesFixedThroughoutTheAnimation() {
        let top = CGPoint(x: 120, y: 1000)
        for progress in [0.0, 0.2, 0.5, 0.8, 1.0] {
            let presentation = DrawerPresentation(progress: progress, expandedHeight: 346,
                                                  collapsedHeight: 327, separatorHeight: 11)
            let frame = MenuInteraction.frame(topLeft: top, width: 308, height: presentation.menuHeight)
            #expect(frame.maxY == 1000)
            #expect(frame.minX == 120)
            #expect(frame.width == 308)
        }
    }

    @Test func drawerAndSeparatorShareOneProgressWithoutChangingTheirCombinedLayout() {
        let expected: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (0, 0, 11, 327), (0.25, 86.5, 8.25, 410.75), (0.5, 173, 5.5, 494.5),
            (0.75, 259.5, 2.75, 578.25), (1, 346, 0, 662)
        ]
        for (progress, drawer, separator, menu) in expected {
            let value = DrawerPresentation(progress: progress, expandedHeight: 346,
                                           collapsedHeight: 327, separatorHeight: 11)
            #expect(value.drawerHeight == drawer)
            #expect(value.separatorHeight == separator)
            #expect(value.menuHeight == menu)
            #expect(value.menuHeight - value.drawerHeight - value.separatorHeight == 316)
        }
    }

    @Test func springOvershootCannotRevealDrawerPastItsViewportOrMoveCollapsedContent() {
        let opening = DrawerPresentation(progress: 1.04, expandedHeight: 346,
                                         collapsedHeight: 327, separatorHeight: 11)
        #expect(opening.progress == 1)
        #expect(opening.drawerHeight == 346)
        #expect(opening.separatorHeight == 0)
        #expect(opening.menuHeight == 662)
        let closing = DrawerPresentation(progress: -0.04, expandedHeight: 346,
                                         collapsedHeight: 327, separatorHeight: 11)
        #expect(closing.progress == 0)
        #expect(closing.drawerHeight == 0)
        #expect(closing.separatorHeight == 11)
        #expect(closing.menuHeight == 327)
    }
}
