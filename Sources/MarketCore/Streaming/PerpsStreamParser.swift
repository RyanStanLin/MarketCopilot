import Foundation

enum PerpsStreamEvent: Sendable {
    case portfolio(PerpsSnapshot)
    case quote(Int, MarketQuote)
    case accountChanged
}

struct PerpsStreamParser: Sendable {
    private var sequences: [String: Int64] = [:]

    mutating func parse(_ text: String) throws -> [PerpsStreamEvent] {
        let envelope = try JSONDecoder().decode(Envelope.self, from: Data(text.utf8))
        guard let channel = envelope.ch else { return [] }
        if let sequence = envelope.sq {
            if let previous = sequences[channel], sequence <= previous { return [] }
            sequences[channel] = sequence
        }
        guard let object = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any], let payload = object["data"] else { return [] }
        let decoder = JSONDecoder()
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.fragmentsAllowed])
        if channel == "portfolio" {
            return [.portfolio(try decoder.decode(PerpsWire.Portfolio.self, from: data).snapshot)]
        }
        let timestamp = envelope.ts.map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? .now
        if channel.hasPrefix("tickers::") {
            let values = payload is [Any] ? try decoder.decode([Ticker].self, from: data) : [try decoder.decode(Ticker.self, from: data)]
            return values.map { .quote($0.iid, MarketQuote(mark: $0.mark.value, timestamp: timestamp)) }
        }
        if channel.hasPrefix("bbo::") {
            let bbo = try decoder.decode(BBO.self, from: data)
            return [.quote(bbo.iid, MarketQuote(bid: bbo.bp.value > 0 ? bbo.bp.value : nil,
                                               ask: bbo.ap.value > 0 ? bbo.ap.value : nil, timestamp: timestamp))]
        }
        if ["fills", "funding", "balances"].contains(channel) { return [.accountChanged] }
        return []
    }

    private struct Envelope: Decodable { let ch: String?; let sq: Int64?; let ts: Int64? }
    private struct Ticker: Decodable { let iid: Int; let mark: APIAmount }
    private struct BBO: Decodable { let iid: Int; let bp: APIAmount; let ap: APIAmount }
}
