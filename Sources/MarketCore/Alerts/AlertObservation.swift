public struct AlertObservation: Sendable {
    public var targetID: String
    public var readings: [AlertMetric: AlertReading]
    public init(targetID: String, readings: [AlertMetric: AlertReading]) {
        self.targetID = targetID; self.readings = readings
    }
}
