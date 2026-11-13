import SwiftUI
import MarketCore

struct MenuHeader: View {
    let store: AppStore

    var body: some View {
        HStack {
            Text("Market").foregroundStyle(DesignTokens.primary)
            Spacer(minLength: 8)
            Button(action: store.openSettings) {
                HStack(spacing: 8) {
                    Text(store.accountName == "Connect account" ? L10n.text("Connect account") : store.accountName)
                        .foregroundStyle(DesignTokens.secondary).lineLimit(1)
                    RemoteImage(url: store.avatarURL, fixtureName: store.isDesignPreview ? "FigmaAvatar" : nil,
                                fallbackSymbol: "person.crop.circle.fill", size: DesignTokens.avatarSize)
                        .frame(width: DesignTokens.avatarSize, height: DesignTokens.avatarSize)
                        .clipShape(.circle)
                        .overlay(Circle().strokeBorder(DesignTokens.iconFill, lineWidth: 1))
                }
            }
            .buttonStyle(PressButtonStyle())
            .menuHover(.profile, id: "account")
            .help("Account settings")
            .accessibilityIdentifier("accountSettings")
        }
        .font(DesignTokens.heading)
        .frame(height: DesignTokens.headerHeight)
    }
}
