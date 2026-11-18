import AppKit
import MarketCore
import SwiftUI

/// Geometry from Figma 19:519. Controls retain their native macOS appearance.
enum MenuBarEditorTokens {
    static let width: CGFloat = 717
    static let height: CGFloat = 50
    static let scrollerHeight: CGFloat = 8
    static let overflow: CGFloat = 12
    static let addWidth: CGFloat = 57
    static let inset: CGFloat = 8
    static let gap: CGFloat = 4
    static let tokenHeight: CGFloat = 34
    static let handleWidth: CGFloat = 29
    static let removeWidth: CGFloat = 28
    static let pickerWidth: CGFloat = 100
    static let globalPickerWidth: CGFloat = 180
    static let controlHeight: CGFloat = 24
    static let background = Color(nsColor: .windowBackgroundColor)
    static let tokenBackground = Color(nsColor: .controlBackgroundColor)
    static let border = Color(nsColor: .secondarySystemFill)
    static let shadow = Color(nsColor: .shadowColor)
    static let shape = UnevenRoundedRectangle(topLeadingRadius: 11, bottomLeadingRadius: 11,
                                               bottomTrailingRadius: 20, topTrailingRadius: 20)

    static func tokenWidth(_ token: MenuBarToken) -> CGFloat {
        let contentWidth: CGFloat
        if token.metric.needsTarget {
            let ofWidth = (L10n.text("of") as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 17)]).width
            contentWidth = pickerWidth * 2 + 12 + ofWidth
        } else { contentWidth = globalPickerWidth }
        return ceil(2 + handleWidth + contentWidth + 8 + removeWidth)
    }

    static func preferredWidth(_ tokens: [MenuBarToken]) -> CGFloat {
        let content = tokens.reduce(0) { $0 + tokenWidth($1) } + CGFloat(max(0, tokens.count - 1)) * gap
        return min(width, content + inset * 2 + 8 + addWidth)
    }
}
