import Foundation
import MarketCore

/// Read-only public connectivity check. It never reads account credentials.
@main
struct MarketProbe {
    static func main() async throws {
        let configuration = try APIConfiguration.bundled()
        let http = HTTPClient()
        let time = try await http.get(Int64.self, base: configuration.clob, path: "/time")
        print("CLOB server time: OK (\(time))")
        let prediction = PredictionClient(configuration: configuration, http: http)
        let value = try await prediction.holdingsValue(wallet: "0x0000000000000000000000000000000000000001")
        print("Prediction v2 public value decoding: OK (test address value \(value))")
        let perps = PerpsClient(configuration: configuration, http: http)
        let instruments = try await perps.instruments()
        guard let id = instruments.keys.sorted().first else { throw URLError(.zeroByteResource) }
        let quotes = try await perps.quotes(instrumentIDs: [id])
        guard quotes[id]?.mark != nil, quotes[id]?.bid != nil, quotes[id]?.ask != nil else { throw URLError(.cannotParseResponse) }
        print("Perps instruments and mark/bid/ask: OK (\(instruments.count) instruments)")
        let connection = NativeSocketFactory().connect(to: configuration.perpsSocket)
        do {
            let request: [String: Any] = ["id": 1, "req": "sub", "chs": ["tickers::\(id)"]]
            try await connection.send(String(decoding: JSONSerialization.data(withJSONObject: request), as: UTF8.self))
            var receivedQuote = false
            for _ in 0..<5 {
                let message = try await connection.receive()
                let object = try JSONSerialization.jsonObject(with: Data(message.utf8)) as? [String: Any]
                if (object?["ch"] as? String)?.hasPrefix("tickers::") == true {
                    receivedQuote = true; break
                }
            }
            await connection.close()
            guard receivedQuote else { throw URLError(.cannotParseResponse) }
            print("Perps native WebSocket ticker: OK")
        } catch { await connection.close(); throw error }
    }
}
