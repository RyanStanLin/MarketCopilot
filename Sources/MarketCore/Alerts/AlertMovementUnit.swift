public enum AlertMovementUnit: String, Codable, CaseIterable, Sendable, Identifiable {
    case percent, priceChange
    public var id: String { rawValue }
    public var title: String { L10n.text(self == .percent ? "Relative change (%)" : "Price change") }
}
