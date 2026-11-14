import SwiftUI

struct PositionIcon: View {
    let url: URL?
    var fixture: String?
    var symbol = "chart.line.uptrend.xyaxis"

    var body: some View {
        RemoteImage(url: url, fixtureName: fixture, fallbackSymbol: symbol)
            .background(DesignTokens.accent)
            .clipShape(.rect(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(DesignTokens.tertiary, lineWidth: 1))
            .padding(.vertical, 2)
    }
}
