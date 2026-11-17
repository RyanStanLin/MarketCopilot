public enum AlertMetric: String, Codable, Sendable {
    case price, profit, returnPercent, liquidationBuffer, funding, activePosition
}
