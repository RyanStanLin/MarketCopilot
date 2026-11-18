import Foundation

public struct MenuBarToken: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var metric: MenuBarMetric
    public var target: MenuBarTarget?

    public init(id: UUID = UUID(), metric: MenuBarMetric, target: MenuBarTarget? = nil) {
        self.id = id; self.metric = metric; self.target = target
    }

    public static var defaultLayout: [Self] {
        [Self(metric: .totalPortfolioWithOffset), Self(metric: .totalCashWithOffset)]
    }
}
