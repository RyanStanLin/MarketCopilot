import Foundation

public struct AlertReading: Equatable, Sendable {
    public var value: Decimal
    public var timestamp: Date
    public var freshnessTimestamp: Date
    public init(_ value: Decimal, at timestamp: Date, dependingOn sourceTimestamp: Date? = nil) {
        self.value = value; self.timestamp = timestamp
        freshnessTimestamp = min(timestamp, sourceTimestamp ?? timestamp)
    }
}
