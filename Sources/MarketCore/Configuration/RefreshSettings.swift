import Foundation

public struct RefreshSettings: Codable, Equatable, Sendable {
    public var predictionMode: TransportMode = .webSocket
    public var perpsMode: TransportMode = .webSocket
    public var pollingInterval: Double = 5
    public var reconciliationInterval: Double = 60
    public var launchAtLogin = false
    public var language: AppLanguage = .system
    public var predictionCashOffset: Decimal = 0
    public var perpsCashOffset: Decimal = 0
    public var liveColor = LiveColorSettings()
    public var timeSensitiveNotifications = true
    public var menuBarTokens = MenuBarToken.defaultLayout
    public init() {}

    enum CodingKeys: String, CodingKey {
        case predictionMode, perpsMode, pollingInterval, reconciliationInterval, launchAtLogin, language
        case predictionCashOffset, perpsCashOffset, cashOffset, liveColor, timeSensitiveNotifications
        case menuBarTokens
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        predictionMode = try values.decodeIfPresent(TransportMode.self, forKey: .predictionMode) ?? .webSocket
        perpsMode = try values.decodeIfPresent(TransportMode.self, forKey: .perpsMode) ?? .webSocket
        pollingInterval = try values.decodeIfPresent(Double.self, forKey: .pollingInterval) ?? 5
        reconciliationInterval = try values.decodeIfPresent(Double.self, forKey: .reconciliationInterval) ?? 60
        launchAtLogin = try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        language = try values.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        liveColor = try values.decodeIfPresent(LiveColorSettings.self, forKey: .liveColor) ?? LiveColorSettings()
        timeSensitiveNotifications = try values.decodeIfPresent(Bool.self, forKey: .timeSensitiveNotifications) ?? true
        menuBarTokens = try values.decodeIfPresent([MenuBarToken].self, forKey: .menuBarTokens) ?? MenuBarToken.defaultLayout
        predictionCashOffset = try values.decodeIfPresent(Decimal.self, forKey: .predictionCashOffset) ?? 0
        // Older versions applied one combined offset. Preserve it once under Perps.
        perpsCashOffset = try values.decodeIfPresent(Decimal.self, forKey: .perpsCashOffset)
            ?? values.decodeIfPresent(Decimal.self, forKey: .cashOffset) ?? 0
    }

    public func encode(to encoder: any Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(predictionMode, forKey: .predictionMode)
        try values.encode(perpsMode, forKey: .perpsMode)
        try values.encode(pollingInterval, forKey: .pollingInterval)
        try values.encode(reconciliationInterval, forKey: .reconciliationInterval)
        try values.encode(launchAtLogin, forKey: .launchAtLogin)
        try values.encode(language, forKey: .language)
        try values.encode(liveColor, forKey: .liveColor)
        try values.encode(timeSensitiveNotifications, forKey: .timeSensitiveNotifications)
        try values.encode(menuBarTokens, forKey: .menuBarTokens)
        try values.encode(predictionCashOffset, forKey: .predictionCashOffset)
        try values.encode(perpsCashOffset, forKey: .perpsCashOffset)
    }

    public func validated() throws -> Self {
        _ = try liveColor.validated()
        guard !predictionCashOffset.isNaN, !perpsCashOffset.isNaN else { throw ConfigurationError.invalidCashOffset }
        guard pollingInterval.isFinite, (1...300).contains(pollingInterval),
              reconciliationInterval.isFinite, (10...600).contains(reconciliationInterval) else {
            throw ConfigurationError.invalidRefreshInterval
        }
        return self
    }
}
