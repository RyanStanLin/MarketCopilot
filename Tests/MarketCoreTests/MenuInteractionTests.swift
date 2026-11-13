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
        let collapsed = MenuInteraction.frame(topLeft: top, width: 308, height: 327)
        let expanded = MenuInteraction.frame(topLeft: top, width: 308, height: 662)
        #expect(collapsed.maxY == 1000); #expect(expanded.maxY == 1000)
        for progress in [0.0, 0.2, 0.5, 0.8, 1.0] {
            let y = collapsed.minY + (expanded.minY - collapsed.minY) * progress
            let height = collapsed.height + (expanded.height - collapsed.height) * progress
            #expect(y + height == 1000)
            #expect(collapsed.minX == expanded.minX)
        }
    }
}
