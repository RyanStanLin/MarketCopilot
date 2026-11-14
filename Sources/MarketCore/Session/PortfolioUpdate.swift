public enum PortfolioUpdate: Sendable {
    case predictions(PredictionSnapshot)
    case perps(PerpsSnapshot)
    case quotes([Int: MarketQuote])
    case instruments([Int: Instrument])
    case profile(AccountProfile)
    case status(MarketProduct, String)
    case health(MarketProduct, DataHealth)
    case busy(Bool)
}
