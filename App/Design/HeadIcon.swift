import SwiftUI

struct HeadIcon: View {
    let symbol: String
    var highlighted = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17))
            .foregroundStyle(highlighted ? Color.white : DesignTokens.secondary)
            .frame(width: DesignTokens.iconSize, height: DesignTokens.iconSize)
            .background(highlighted ? DesignTokens.accent : DesignTokens.iconFill, in: .circle)
            .overlay(Circle().strokeBorder(DesignTokens.subtleBorder, lineWidth: 1))
            .accessibilityHidden(true)
    }
}
