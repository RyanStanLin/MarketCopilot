public enum AlertTriggerKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case priceAbove, priceBelow, rapidRise, rapidFall, profitAbove, profitBelow
    case returnAbove, returnBelow, nearLiquidation, fundingAbove, fundingBelow, positionEnded
    public var id: String { rawValue }
    public var title: String {
        let key = switch self {
        case .priceAbove: "Price crosses above"
        case .priceBelow: "Price crosses below"
        case .rapidRise: "Rapid price rise"
        case .rapidFall: "Rapid price fall"
        case .profitAbove: "Unrealized PnL crosses above"
        case .profitBelow: "Unrealized PnL crosses below"
        case .returnAbove: "Return crosses above"
        case .returnBelow: "Return crosses below"
        case .nearLiquidation: "Near liquidation price"
        case .fundingAbove: "Cumulative Funding crosses above"
        case .fundingBelow: "Cumulative Funding crosses below"
        case .positionEnded: "Position leaves active holdings"
        }
        return L10n.text(key)
    }
    public var metric: AlertMetric {
        switch self {
        case .priceAbove, .priceBelow, .rapidRise, .rapidFall: .price
        case .profitAbove, .profitBelow: .profit
        case .returnAbove, .returnBelow: .returnPercent
        case .nearLiquidation: .liquidationBuffer
        case .fundingAbove, .fundingBelow: .funding
        case .positionEnded: .activePosition
        }
    }
    public var isRapidMove: Bool { self == .rapidRise || self == .rapidFall }
    public var needsPrice: Bool { metric == .price || self == .nearLiquidation }
    public var crossesDown: Bool {
        [.priceBelow, .rapidFall, .profitBelow, .returnBelow, .fundingBelow, .nearLiquidation, .positionEnded].contains(self)
    }
    public func supports(_ product: MarketProduct) -> Bool {
        product == .perps || ![.nearLiquidation, .fundingAbove, .fundingBelow].contains(self)
    }
}
