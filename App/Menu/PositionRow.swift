import MarketCore
import SwiftUI

struct PositionRow: View {
    let position: PerpPosition
    let store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    private var instrument: Instrument? { store.instruments[position.id] }
    private var quote: MarketQuote? { store.quotes[position.id] }
    private var logo: URL? { colorScheme == .dark ? (instrument?.darkLogo ?? instrument?.lightLogo) : instrument?.lightLogo }
    private var fixture: String? { store.isDesignPreview ? (position.id == 2 ? "FigmaUS100" : "FigmaNVDA") : nil }
    private var digits: Int { instrument?.priceDecimals ?? 2 }
    private var quoteHelp: String {
        "Mark: \(MarketFormat.currency(quote?.mark, fractionDigits: digits))\nBid: \(MarketFormat.currency(quote?.bid, fractionDigits: digits))\nAsk: \(MarketFormat.currency(quote?.ask, fractionDigits: digits))"
    }

    var body: some View {
        VStack(spacing: DesignTokens.detailGap) {
            HStack(alignment: .top, spacing: 4) {
                HStack(spacing: DesignTokens.iconGap) {
                    RemoteImage(url: logo, fixtureName: fixture, fallbackSymbol: "chart.line.uptrend.xyaxis")
                        .frame(width: 32, height: 32).clipShape(.rect(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(DesignTokens.tertiary, lineWidth: 1))
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            Text(instrument?.displaySymbol ?? position.symbol).font(DesignTokens.amount)
                                .lineLimit(1).minimumScaleFactor(0.75)
                            Link(destination: URL(string: "https://polymarket.com/perps")!) {
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .font(.system(size: 14)).foregroundStyle(DesignTokens.secondary)
                            }.buttonStyle(PressButtonStyle()).help("Open Polymarket Perps")
                        }.frame(height: 20)
                        Text("\(position.isLong ? "Long" : "Short") \(position.leverage)x")
                            .font(DesignTokens.caption).foregroundStyle(DesignTokens.secondary)
                            .frame(height: 15).contentTransition(.numericText())
                            .help(position.cross ? "Cross margin" : "Isolated margin")
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(MarketFormat.currency(position.unrealizedPnl, signed: true))
                        .font(DesignTokens.amount).frame(height: 20).contentTransition(.numericText())
                    Text(MarketFormat.percent(position.returnOnEquity)).font(DesignTokens.caption)
                        .frame(height: 15).contentTransition(.numericText())
                }.fixedSize().foregroundStyle(DesignTokens.primary)
            }.frame(height: 35)
            HStack(spacing: 0) {
                PositionMetric(value: MarketFormat.currency(quote?.mark, fractionDigits: digits), label: "Now", helpText: quoteHelp)
                PositionMetric(value: MarketFormat.currency(position.entryPrice, fractionDigits: digits), label: "Entry", alignment: .center)
                PositionMetric(value: MarketFormat.currency(position.liquidationPrice, fractionDigits: digits), label: "Liq. price", alignment: .trailing)
            }.padding(.leading, DesignTokens.detailIndent)
            HStack(spacing: 0) {
                PositionMetric(value: MarketFormat.currency(position.positionValue), label: "Position")
                PositionMetric(value: MarketFormat.currency(position.margin), label: "Margin", alignment: .center)
                PositionMetric(value: MarketFormat.currency(position.cumulativeFunding, fractionDigits: 4), label: "Funding", alignment: .trailing,
                               helpText: "Cumulative funding, using the official account's signed value.")
            }.padding(.leading, DesignTokens.detailIndent)
        }
        .padding(.vertical, 6)
        .animation(DesignTokens.numberAnimation, value: position)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("position-\(position.id)")
    }
}
