import AppKit
import SwiftUI

/// Measurements and semantic colors from Figma 2:4070 and 1:3545.
enum DesignTokens {
    static let menuWidth: CGFloat = 308
    static let inset: CGFloat = 14
    static let cornerRadius: CGFloat = 16
    static let iconSize: CGFloat = 32
    static let avatarSize: CGFloat = 16
    static let rowGap: CGFloat = 10
    static let detailGap: CGFloat = 12
    static let iconGap: CGFloat = 8
    static let detailIndent: CGFloat = 40
    static let headerHeight: CGFloat = 24
    static let separatorHeight: CGFloat = 11
    static let metricHeight: CGFloat = 35
    static let positionHeight: CGFloat = 141
    static let statusHeight: CGFloat = 26
    static let collapsedHeight: CGFloat = 327
    static let primary = Color(nsColor: .labelColor)
    static let secondary = Color(nsColor: .secondaryLabelColor)
    static let tertiary = Color(nsColor: .tertiaryLabelColor)
    static let separator = Color(nsColor: .separatorColor)
    static let iconFill = Color("FillsOpaqueTertiary")
    static let subtleBorder = Color("LabelsSeximal")
    static let drawerBorder = Color("LabelsQuinary")
    static let accent = Color(nsColor: .systemBlue)
    static let heading = Font.system(size: 13, weight: .bold)
    static let amount = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let metric = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12)
    static let action = Font.system(size: 11)
    static let statusAmount = Font.system(size: 13)
    static let statusCaption = Font.system(size: 10)
    static let drawerAnimation = Animation.spring(response: 0.38, dampingFraction: 0.88)
    static let numberAnimation = Animation.easeInOut(duration: 0.28)
    static let pressAnimation = Animation.spring(response: 0.22, dampingFraction: 0.72)

    static func drawerHeight(positionCount: Int) -> CGFloat {
        let count = max(1, positionCount)
        return 2 + 16 + headerHeight + 12 + CGFloat(count) * positionHeight + CGFloat(count - 1) * rowGap
    }

    static func menuHeight(expanded: Bool, positionCount: Int, maximum: CGFloat) -> CGFloat {
        guard expanded else { return collapsedHeight }
        return min(maximum, collapsedHeight - separatorHeight + drawerHeight(positionCount: positionCount))
    }
}
