import Foundation

public struct RefreshSettings: Codable, Equatable, Sendable {
    public var predictionMode: TransportMode = .webSocket
    public var perpsMode: TransportMode = .webSocket
    public var pollingInterval: Double = 5
    public var reconciliationInterval: Double = 60
    public var launchAtLogin = false
    public init() {}

    public func validated() throws -> Self {
        guard pollingInterval.isFinite, (1...300).contains(pollingInterval),
              reconciliationInterval.isFinite, (10...600).contains(reconciliationInterval) else {
            throw ConfigurationError.invalidRefreshInterval
        }
        return self
    }
}
