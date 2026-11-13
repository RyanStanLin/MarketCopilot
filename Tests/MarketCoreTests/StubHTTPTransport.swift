import Foundation
@testable import MarketCore

actor StubHTTPTransport: HTTPTransport {
    struct Reply: Sendable {
        var body: String
        var status = 200
        var headers: [String: String] = [:]
    }
    var requests: [URLRequest] = []
    private var replies: [String: [Reply]]
    init(_ replies: [String: [Reply]]) { self.replies = replies }

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let path = request.url!.path
        guard var values = replies[path], !values.isEmpty else { throw URLError(.resourceUnavailable) }
        let reply = values.removeFirst()
        replies[path] = values
        return (Data(reply.body.utf8), HTTPURLResponse(url: request.url!, statusCode: reply.status,
                                                     httpVersion: "HTTP/1.1", headerFields: reply.headers)!)
    }
}
