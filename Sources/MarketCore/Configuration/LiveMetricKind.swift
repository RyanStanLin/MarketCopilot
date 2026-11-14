public enum LiveMetricKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case portfolio, cash, now, entry, liquidation, position, margin, funding, profit, returnOnEquity
    case predictionValue, average, current, shares, leverage, outcomePrice
    public var id: String { rawValue }
    public var title: String {
        let key = switch self {
        case .portfolio: "Portfolio"
        case .cash: "Cash"
        case .now: "Now"
        case .entry: "Entry"
        case .liquidation: "Liq. price"
        case .position: "Position"
        case .margin: "Margin"
        case .funding: "Funding"
        case .profit: "Profit"
        case .returnOnEquity: "Return percentage"
        case .predictionValue: "Value"
        case .average: "Average"
        case .current: "Current"
        case .shares: "Shares"
        case .leverage: "Leverage"
        case .outcomePrice: "Outcome token price"
        }
        return L10n.text(key)
    }
}
