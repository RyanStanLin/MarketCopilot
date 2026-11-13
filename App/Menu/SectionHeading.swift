import SwiftUI

struct SectionHeading: View {
    let title: LocalizedStringKey

    var body: some View {
        Text(title).font(DesignTokens.heading).foregroundStyle(DesignTokens.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: DesignTokens.headerHeight)
    }
}
