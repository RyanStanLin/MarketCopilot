import Foundation

public struct DataHealth: Equatable, Sendable {
    public enum Channel: String, Sendable { case polling = "Polling", webSocket = "WebSocket", cache = "Cache" }
    public var updatedAt: Date?
    public var channel: Channel
    public var issue: String?
    public init(updatedAt: Date? = nil, channel: Channel = .cache, issue: String? = nil) {
        self.updatedAt = updatedAt; self.channel = channel; self.issue = issue
    }
}
