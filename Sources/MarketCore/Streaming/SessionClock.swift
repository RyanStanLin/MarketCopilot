import Foundation

public protocol SessionClock: Sendable {
    var now: Date { get }
    func sleep(seconds: TimeInterval) async throws
}

public struct SystemSessionClock: SessionClock {
    public init() {}
    public var now: Date { .now }
    public func sleep(seconds: TimeInterval) async throws {
        try await ContinuousClock().sleep(for: .seconds(max(0, seconds)))
    }
}
