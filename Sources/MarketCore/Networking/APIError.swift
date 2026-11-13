import Foundation

public struct APIError: LocalizedError, Equatable, Sendable {
    public let status: Int
    public let reason: String
    public let retryAfter: TimeInterval?
    public init(status: Int, reason: String, retryAfter: TimeInterval? = nil) {
        self.status = status; self.reason = reason; self.retryAfter = retryAfter
    }
    public var isAuthenticationFailure: Bool { status == 401 || status == 403 }
    public var errorDescription: String? { reason }
}
