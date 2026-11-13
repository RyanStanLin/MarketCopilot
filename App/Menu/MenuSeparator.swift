import SwiftUI

struct MenuSeparator: View {
    var body: some View {
        Rectangle().fill(DesignTokens.separator)
            .frame(height: 1)
            .frame(height: DesignTokens.separatorHeight)
            .accessibilityHidden(true)
    }
}
