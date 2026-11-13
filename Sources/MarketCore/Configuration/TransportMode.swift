public enum TransportMode: String, Codable, CaseIterable, Sendable, Identifiable {
    case webSocket, polling
    public var id: String { rawValue }
    public var title: String { self == .webSocket ? "WebSocket preferred" : "Polling only" }
}
