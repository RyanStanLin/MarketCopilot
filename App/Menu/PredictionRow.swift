import MarketCore
import SwiftUI

struct PredictionRow: View {
    let position: PredictionPosition
    let store: AppStore
    @Environment(\.openURL) private var openURL
    private var title: String {
        guard let title = position.title, !title.isEmpty else { return L10n.text("Prediction") }
        return title
    }

    private var destination: URL? {
        let slug = position.eventSlug.flatMap { $0.isEmpty ? nil : $0 } ?? position.slug
        guard let slug, !slug.isEmpty else { return nil }
        return store.predictionWebsiteURL?.appending(component: slug)
    }

    var body: some View {
        Button(action: openPosition) {
            VStack(spacing: DesignTokens.detailGap) {
                HStack(alignment: .top, spacing: 8) {
                    PositionIcon(url: position.icon, fixture: store.isDesignPreview ? "FigmaPrediction" : nil, symbol: "questionmark")
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .top, spacing: 4) {
                            Text(title)
                                .font(DesignTokens.amount).foregroundStyle(DesignTokens.primary)
                                .lineSpacing(2).lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ProfitArrow(profit: position.unrealizedPnl)
                        }.frame(height: 60, alignment: .top)
                        HStack(spacing: 6) {
                            PositionToken(label: position.outcome ?? "—", detail: MarketFormat.cents(position.averagePrice),
                                positive: position.outcomeIndex == 0 || position.outcome?.lowercased() == "yes",
                                number: position.averagePrice, metric: .outcomePrice)
                            Text(L10n.format("%@ Shares", MarketFormat.shares(position.shares)))
                                .font(.system(size: 12, design: .rounded)).frame(height: 15)
                                .contentTransition(.numericText()).liveColor(position.shares, metric: .shares)
                        }
                    }
                }.frame(height: 85, alignment: .top)
                HStack(spacing: 0) {
                    PositionMetric(value: MarketFormat.currency(position.currentValue), label: "Value",
                                   number: position.currentValue, metric: .predictionValue)
                    PositionProfit(profit: position.unrealizedPnl, percentage: position.returnOnEquity)
                }.padding(.leading, DesignTokens.detailIndent)
                HStack(spacing: 0) {
                    PositionMetric(value: MarketFormat.cents(position.averagePrice), label: "Average",
                                   number: position.averagePrice, metric: .average)
                    PositionMetric(value: MarketFormat.cents(position.currentPrice), label: "Current", alignment: .trailing,
                                   number: position.currentPrice, metric: .current)
                }.padding(.leading, DesignTokens.detailIndent)
            }
            .padding(.vertical, 6).frame(height: DesignTokens.predictionHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressButtonStyle())
        .help(title)
        .menuHover(.position, id: "prediction-\(position.id)")
        .accessibilityIdentifier("prediction-\(position.id)")
    }

    private func openPosition() { if let destination { openURL(destination) } }
}
