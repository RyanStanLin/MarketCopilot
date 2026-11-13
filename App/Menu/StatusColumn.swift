import SwiftUI

struct StatusColumn: View {
    let value: String
    let title: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: -3) {
            Text(value).font(DesignTokens.statusAmount).frame(height: 16).contentTransition(.numericText())
            Text(title).font(DesignTokens.statusCaption).frame(height: 13)
        }
    }
}
