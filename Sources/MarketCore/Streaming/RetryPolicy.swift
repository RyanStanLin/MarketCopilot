import Foundation

public enum RetryPolicy {
    public static func delay(attempt: Int, retryAfter: TimeInterval? = nil, jitter: Double = 0.5) -> TimeInterval {
        let exponential = min(30, pow(2.0, Double(min(5, max(0, attempt)))))
        let randomized = min(30, exponential * (0.8 + min(1, max(0, jitter)) * 0.4))
        return max(randomized, max(0, retryAfter ?? 0))
    }
}
