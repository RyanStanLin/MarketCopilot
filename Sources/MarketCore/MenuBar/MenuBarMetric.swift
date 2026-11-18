public enum MenuBarMetric: String, CaseIterable, Codable, Sendable, Identifiable {
    case appIcon
    case totalPortfolioWithOffset, totalCashWithOffset, totalPortfolio, totalCash
    case predictionPortfolioWithOffset, predictionCashWithOffset, predictionPortfolio, predictionCash
    case perpsPortfolioWithOffset, perpsCashWithOffset, perpsPortfolio, perpsCash
    case position, price, entry, profit, returnPercentage, profitDirection, side, quantity
    case priceChange, priceChangePercentage, bid, ask, liquidation, margin, funding, leverage

    public var id: String { rawValue }

    public var title: String { L10n.text(titleKey) }
    public var titleKey: String {
        switch self {
        case .appIcon: "App Icon"
        case .totalPortfolioWithOffset: "Total Portfolio with Offset"
        case .totalCashWithOffset: "Total Cash with Offset"
        case .totalPortfolio: "Total Portfolio"
        case .totalCash: "Total Cash"
        case .predictionPortfolioWithOffset: "Predictions Portfolio with Offset"
        case .predictionCashWithOffset: "Predictions Cash with Offset"
        case .predictionPortfolio: "Predictions Portfolio"
        case .predictionCash: "Predictions Cash"
        case .perpsPortfolioWithOffset: "Perps Portfolio with Offset"
        case .perpsCashWithOffset: "Perps Cash with Offset"
        case .perpsPortfolio: "Perps Portfolio"
        case .perpsCash: "Perps Cash"
        case .position: "Position"
        case .price: "Price"
        case .entry: "Entry"
        case .profit: "Profit"
        case .returnPercentage: "Return percentage"
        case .profitDirection: "Profit / Loss"
        case .side: "Side"
        case .quantity: "Quantity"
        case .priceChange: "Price change"
        case .priceChangePercentage: "Price change %"
        case .bid: "Bid"
        case .ask: "Ask"
        case .liquidation: "Liq. price"
        case .margin: "Margin"
        case .funding: "Funding"
        case .leverage: "Leverage"
        }
    }

    public var needsTarget: Bool {
        switch self {
        case .position, .price, .entry, .profit, .returnPercentage, .profitDirection, .side, .quantity,
             .priceChange, .priceChangePercentage, .bid, .ask, .liquidation, .margin, .funding, .leverage: true
        default: false
        }
    }

    public var needsQuote: Bool {
        [.price, .bid, .ask, .priceChange, .priceChangePercentage].contains(self)
    }

    public func supports(_ product: MarketProduct) -> Bool {
        guard needsTarget else { return false }
        switch self {
        case .bid, .ask, .liquidation, .margin, .funding, .leverage: return product == .perps
        default: return true
        }
    }
}
