import MarketCore
import SwiftUI

struct PositionRow: View {
    let position: PerpPosition
    let store: AppStore
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    private var instrument: Instrument? { store.instruments[position.id] }
    private var quote: MarketQuote? { store.quotes[position.id] }
    private var logo: URL? { colorScheme == .dark ? (instrument?.darkLogo ?? instrument?.lightLogo) : instrument?.lightLogo }
    private var fixture: String? { store.isDesignPreview ? (position.symbol.contains("US100") ? "FigmaUS100" : "FigmaNVDA") : nil }
    private var digits: Int { instrument?.priceDecimals ?? 2 }
    private var quoteHelp: String {
        "\(L10n.text("Mark")): \(MarketFormat.currency(quote?.mark, fractionDigits: digits))\n\(L10n.text("Bid")): \(MarketFormat.currency(quote?.bid, fractionDigits: digits))\n\(L10n.text("Ask")): \(MarketFormat.currency(quote?.ask, fractionDigits: digits))"
    }

    var body: some View {
        Button(action: openPosition) {
        VStack(spacing: DesignTokens.detailGap) {
            HStack(alignment: .center, spacing: 4) {
                HStack(alignment: .top, spacing: DesignTokens.iconGap) {
                    PositionIcon(url: logo, fixture: fixture)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .top, spacing: 4) {
                            Text(instrument?.displaySymbol ?? position.symbol).font(DesignTokens.amount)
                                .foregroundStyle(DesignTokens.primary)
                                .lineLimit(1).minimumScaleFactor(0.75)
                            ProfitArrow(profit: position.unrealizedPnl)
                        }.frame(height: 20)
                        PositionToken(label: position.isLong ? "Long" : "Short",
                            detail: L10n.format("%lldx", position.leverage), positive: position.isLong,
                            number: Decimal(position.leverage), metric: .leverage)
                            .help(L10n.text(position.cross ? "Cross margin" : "Isolated margin"))
                    }
                }
                Spacer(minLength: 0)
                PositionProfit(profit: position.unrealizedPnl, percentage: position.returnOnEquity)
            }.frame(height: 41)
            HStack(spacing: 0) {
                PositionMetric(value: MarketFormat.currency(quote?.mark, fractionDigits: digits), label: "Now", helpText: quoteHelp,
                               number: quote?.mark, metric: .now)
                PositionMetric(value: MarketFormat.currency(position.entryPrice, fractionDigits: digits), label: "Entry", alignment: .center,
                               number: position.entryPrice, metric: .entry)
                PositionMetric(value: MarketFormat.currency(position.liquidationPrice, fractionDigits: digits), label: "Liq. price", alignment: .trailing,
                               number: position.liquidationPrice, metric: .liquidation)
            }.padding(.leading, DesignTokens.detailIndent)
            HStack(spacing: 0) {
                PositionMetric(value: MarketFormat.currency(position.positionValue), label: "Position", number: position.positionValue, metric: .position)
                PositionMetric(value: MarketFormat.currency(position.margin), label: "Margin", alignment: .center, number: position.margin, metric: .margin)
                PositionMetric(value: MarketFormat.currency(position.cumulativeFunding, fractionDigits: 4), label: "Funding", alignment: .trailing,
                               helpText: "Cumulative funding, using the official account's signed value.", number: position.cumulativeFunding, metric: .funding)
            }.padding(.leading, DesignTokens.detailIndent)
        }
        .padding(.vertical, 6)
        .frame(height: DesignTokens.positionHeight)
        .contentShape(Rectangle())
        .animation(DesignTokens.numberAnimation, value: position)
        }
        .buttonStyle(PressButtonStyle())
        .disabled(store.perpsWebsiteURL == nil)
        .help("Open Polymarket Perps")
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("position-\(position.id)")
        .menuHover(.position, id: "position-\(position.id)")
    }

    private func openPosition() {
        if let destination = store.perpsWebsiteURL { openURL(destination) }
    }
}
