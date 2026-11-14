import Foundation

public struct LiveColorSettings: Codable, Equatable, Sendable {
    public var enabled = true
    public var duration: Double = 1.2
    public var metrics = Set(LiveMetricKind.allCases)
    public init() {}

    public func validated() throws -> Self {
        guard duration.isFinite, (0.1...10).contains(duration) else { throw ConfigurationError.invalidLiveColorDuration }
        return self
    }
}
