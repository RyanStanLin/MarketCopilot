import Foundation

public struct PredictionPosition: Codable, Equatable, Sendable {
    public var tokenID: String
    public var conditionID: String

    public init(tokenID: String, conditionID: String) {
        self.tokenID = tokenID; self.conditionID = conditionID
    }
}
