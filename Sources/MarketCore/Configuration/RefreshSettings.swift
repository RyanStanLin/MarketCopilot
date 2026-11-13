import Foundation

public struct RefreshSettings: Codable, Equatable, Sendable {
    public var predictionMode: TransportMode = .webSocket
    public var perpsMode: TransportMode = .webSocket
    public var pollingInterval: Double = 5
    public var reconciliationInterval: Double = 60
    public var launchAtLogin = false
    public var language: AppLanguage = .system
    public var cashOffset: Decimal = 0
    public init() {}

    enum CodingKeys: String, CodingKey {
        case predictionMode, perpsMode, pollingInterval, reconciliationInterval, launchAtLogin, language, cashOffset
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        predictionMode = try values.decodeIfPresent(TransportMode.self, forKey: .predictionMode) ?? .webSocket
        perpsMode = try values.decodeIfPresent(TransportMode.self, forKey: .perpsMode) ?? .webSocket
        pollingInterval = try values.decodeIfPresent(Double.self, forKey: .pollingInterval) ?? 5
        reconciliationInterval = try values.decodeIfPresent(Double.self, forKey: .reconciliationInterval) ?? 60
        launchAtLogin = try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        language = try values.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        cashOffset = try values.decodeIfPresent(Decimal.self, forKey: .cashOffset) ?? 0
    }

    public func validated() throws -> Self {
        guard !cashOffset.isNaN else { throw ConfigurationError.invalidCashOffset }
        guard pollingInterval.isFinite, (1...300).contains(pollingInterval),
              reconciliationInterval.isFinite, (10...600).contains(reconciliationInterval) else {
            throw ConfigurationError.invalidRefreshInterval
        }
        return self
    }
}
