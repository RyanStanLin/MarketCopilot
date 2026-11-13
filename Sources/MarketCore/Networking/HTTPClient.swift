import Foundation

public struct HTTPClient: Sendable {
    private let transport: any HTTPTransport
    public init(transport: any HTTPTransport = URLSessionTransport()) { self.transport = transport }

    public func get<T: Decodable & Sendable>(_ type: T.Type, base: URL, path: String,
                                            query: [URLQueryItem] = [], headers: [String: String] = [:]) async throws -> T {
        let url = base.appending(path: path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false), url.scheme == "https" else {
            throw URLError(.badURL)
        }
        if !query.isEmpty { components.queryItems = query }
        guard let requestURL = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (name, value) in headers { request.setValue(value, forHTTPHeaderField: name) }
        let (data, response) = try await transport.data(for: request)
        guard (200..<300).contains(response.statusCode) else {
            let message: String
            switch response.statusCode {
            case 401: message = "Credentials are invalid or expired. Update them in Account settings."
            case 403: message = "Polymarket denied access. Check credentials and network availability."
            case 404: message = "The requested account or resource was not found."
            case 429: message = "Polymarket rate limit reached. Waiting before retrying."
            case 500...599: message = "Polymarket is temporarily unavailable (HTTP \(response.statusCode))."
            default: message = "Polymarket rejected the request (HTTP \(response.statusCode)). Check the account configuration."
            }
            let retry = response.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw APIError(status: response.statusCode, reason: message, retryAfter: retry)
        }
        do { return try JSONDecoder().decode(type, from: data) }
        catch { throw APIError(status: 0, reason: "The official API returned an unsupported or incomplete response.") }
    }
}
