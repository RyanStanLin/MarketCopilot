import Foundation
import MarketCore

extension AppStore {
    func statusTokenValue(_ token: MenuBarToken) -> StatusTokenValue {
        let metric = token.metric
        let caption: String
        let value: Decimal?
        let kind: LiveMetricKind
        let text: String
        if metric.needsTarget {
            caption = [token.target?.displayName ?? L10n.text("Choose a market"), metric.title].joined(separator: " · ")
            let result = menuBarPositionValue(token)
            value = result.number; text = result.text; kind = result.kind
        } else {
            value = menuBarGlobalValue(metric)
            caption = menuBarGlobalCaption(metric)
            text = MarketFormat.currency(value)
            switch metric {
            case .totalCash, .totalCashWithOffset, .predictionCash, .predictionCashWithOffset, .perpsCash, .perpsCashWithOffset:
                kind = .cash
            default: kind = .portfolio
            }
        }
        let helpTitle = metric.needsTarget ? caption : metric.title
        return StatusTokenValue(id: token.id, metric: metric, value: text, caption: caption, number: value,
                                liveMetric: kind, help: helpTitle + ": " + (metric == .appIcon ? "MarketCopilot" : text))
    }

    private func menuBarGlobalValue(_ metric: MenuBarMetric) -> Decimal? {
        switch metric {
        case .totalPortfolioWithOffset: statusPortfolio
        case .totalCashWithOffset: statusCash
        case .totalPortfolio: snapshot.portfolio
        case .totalCash: snapshot.cash
        case .predictionPortfolioWithOffset: balances.predictionPortfolio
        case .predictionCashWithOffset: balances.predictionCash
        case .predictionPortfolio: snapshot.predictions?.portfolio
        case .predictionCash: snapshot.predictions?.cash
        case .perpsPortfolioWithOffset: balances.perpsPortfolio
        case .perpsCashWithOffset: balances.perpsCash
        case .perpsPortfolio: snapshot.perps?.portfolio
        case .perpsCash: snapshot.perps?.cash
        default: nil
        }
    }

    private func menuBarGlobalCaption(_ metric: MenuBarMetric) -> String {
        switch metric {
        case .appIcon: "MarketCopilot"
        case .totalPortfolio, .totalPortfolioWithOffset: L10n.text("Portfolio")
        case .totalCash, .totalCashWithOffset: L10n.text("Cash")
        case .predictionPortfolio, .predictionPortfolioWithOffset: L10n.text("Predictions Portfolio")
        case .predictionCash, .predictionCashWithOffset: L10n.text("Predictions Cash")
        case .perpsPortfolio, .perpsPortfolioWithOffset: L10n.text("Perps Portfolio")
        case .perpsCash, .perpsCashWithOffset: L10n.text("Perps Cash")
        default: metric.title
        }
    }

    private func menuBarPositionValue(_ token: MenuBarToken) -> (number: Decimal?, text: String, kind: LiveMetricKind) {
        guard let target = token.target, isCurrentMenuBarAccount(target) else { return (nil, "—", .position) }
        let metric = token.metric
        let perp = target.product == .perps ? positions.first { String($0.id) == target.marketID } : nil
        let prediction = target.product == .predictions ? predictionPositions.first { $0.id == target.marketID } : nil
        let quote = target.product == .perps ? Int(target.marketID).flatMap { quotes[$0] } : nil
        let price = target.product == .perps ? quote?.mark : prediction?.currentPrice
        let entry = target.product == .perps ? perp?.entryPrice : prediction?.averagePrice
        let profit = target.product == .perps ? perp?.unrealizedPnl : prediction?.unrealizedPnl
        let digits = Int(target.marketID).flatMap { instruments[$0]?.priceDecimals } ?? 2
        let number: Decimal?
        let kind: LiveMetricKind
        switch metric {
        case .position: number = target.product == .perps ? perp?.positionValue : prediction?.currentValue; kind = target.product == .perps ? .position : .predictionValue
        case .price: number = price; kind = target.product == .perps ? .now : .current
        case .entry: number = entry; kind = target.product == .perps ? .entry : .average
        case .profit, .profitDirection: number = profit; kind = .profit
        case .returnPercentage: number = target.product == .perps ? perp?.returnOnEquity : prediction?.returnOnEquity; kind = .returnOnEquity
        case .quantity: number = target.product == .perps ? perp.map { abs($0.size) } : prediction?.shares; kind = .shares
        case .priceChange, .priceChangePercentage, .priceDirection:
            number = price.flatMap { current in entry.flatMap { original in
                if metric == .priceChangePercentage {
                    guard original > 0 else { return nil }
                    return (current - original) / original
                }
                return current - original
            } }; kind = .now
        case .bid: number = quote?.bid; kind = .now
        case .ask: number = quote?.ask; kind = .now
        case .liquidation: number = perp?.liquidationPrice; kind = .liquidation
        case .margin: number = perp?.margin; kind = .margin
        case .funding: number = perp?.cumulativeFunding; kind = .funding
        case .leverage: number = perp.map { Decimal($0.leverage) }; kind = .leverage
        case .side:
            let text = perp.map { L10n.text($0.isLong ? "Long" : "Short") } ?? prediction?.outcome.map(L10n.text) ?? "—"
            return (nil, text, .position)
        default: return (nil, "—", .position)
        }
        guard let number, !number.isNaN else { return (nil, "—", kind) }
        let text: String
        switch metric {
        case .returnPercentage, .priceChangePercentage: text = MarketFormat.percent(number)
        case .profitDirection: text = L10n.text(number > 0 ? "Profit" : number < 0 ? "Loss" : "Flat")
        case .priceDirection: text = L10n.text(number > 0 ? "Up" : number < 0 ? "Down" : "Flat")
        case .quantity: text = NSDecimalNumber(decimal: number).stringValue
        case .leverage: text = L10n.format("%lldx", perp?.leverage ?? 0)
        case .price, .entry, .priceChange, .bid, .ask:
            text = target.product == .predictions ? MarketFormat.cents(number)
                : MarketFormat.currency(number, fractionDigits: digits, signed: metric == .priceChange)
        case .funding: text = MarketFormat.currency(number, fractionDigits: 4, signed: true)
        default: text = MarketFormat.currency(number, signed: metric == .profit)
        }
        return (number, text, kind)
    }
}
