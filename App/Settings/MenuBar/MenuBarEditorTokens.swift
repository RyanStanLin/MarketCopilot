import AppKit
import SwiftUI

/// Geometry from Figma 19:519. Controls retain their native macOS appearance.
enum MenuBarEditorTokens {
    static let width: CGFloat = 717
    static let height: CGFloat = 50
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
    static let shape = UnevenRoundedRectangle(topLeadingRadius: 11, bottomLeadingRadius: 11,
                                               bottomTrailingRadius: 20, topTrailingRadius: 20)
}
