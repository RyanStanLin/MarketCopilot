import Foundation

public struct AlertReading: Equatable, Sendable {
    public var value: Decimal
    public var timestamp: Date
    public init(_ value: Decimal, at timestamp: Date) { self.value = value; self.timestamp = timestamp }
}
