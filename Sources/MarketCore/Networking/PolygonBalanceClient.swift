import Foundation

/// Reads Polymarket's official pUSD token; it never signs or submits a transaction.
public struct PolygonBalanceClient: Sendable {
    private let configuration: APIConfiguration
    private let http: HTTPClient

    public init(configuration: APIConfiguration, http: HTTPClient) {
        self.configuration = configuration
        self.http = http
    }

    public func balance(wallet: String) async throws -> Decimal {
        guard AccountConfiguration.isAddress(wallet) else { throw ConfigurationError.invalidWallet }
        let address = wallet.dropFirst(2).lowercased()
        let callData = "0x70a08231" + String(repeating: "0", count: 24) + address
        let requests = [
            RPCRequest(id: 1, method: "eth_chainId", call: nil),
            RPCRequest(id: 2, method: "eth_call", call: .init(to: configuration.predictionCollateral, data: callData))
        ]
        let responses = try await http.post([RPCResponse].self, url: configuration.polygonRPC, body: requests)
        guard let chain = responses.first(where: { $0.id == 1 }), chain.error == nil,
              let chainHex = chain.result, chainHex.hasPrefix("0x"),
              Int(chainHex.dropFirst(2), radix: 16) == configuration.polygonChainID else {
            throw APIError(status: 0, reason: "The balance provider did not confirm Polygon mainnet.")
        }
        guard let response = responses.first(where: { $0.id == 2 }), response.error == nil,
              let hex = response.result, hex.hasPrefix("0x"), hex.count == 66 else {
            throw APIError(status: 0, reason: "The on-chain pUSD balance is temporarily unavailable.")
        }
        var units = Decimal.zero
        for character in hex.dropFirst(2) {
            guard character.isASCII, let digit = character.hexDigitValue else { throw invalidBalance() }
            var multiplier = Decimal(16), multiplied = Decimal.zero
            guard NSDecimalMultiply(&multiplied, &units, &multiplier, .plain) == .noError else { throw invalidBalance() }
            var addition = Decimal(digit), next = Decimal.zero
            guard NSDecimalAdd(&next, &multiplied, &addition, .plain) == .noError else { throw invalidBalance() }
            units = next
        }
        return units / pow(Decimal(10), configuration.collateralDecimals)
    }

    private func invalidBalance() -> APIError {
        APIError(status: 0, reason: "The on-chain balance could not be represented exactly.")
    }

    private struct RPCRequest: Encodable, Sendable {
        let id: Int
        let method: String
        let call: Call?
        struct Call: Encodable, Sendable { let to: String; let data: String }
        enum CodingKeys: String, CodingKey { case jsonrpc, id, method, params }
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode("2.0", forKey: .jsonrpc)
            try container.encode(id, forKey: .id)
            try container.encode(method, forKey: .method)
            var parameters = container.nestedUnkeyedContainer(forKey: .params)
            if let call { try parameters.encode(call); try parameters.encode("latest") }
        }
    }

    private struct RPCResponse: Decodable, Sendable {
        let id: Int
        let result: String?
        let error: RPCError?
        struct RPCError: Decodable, Sendable { let code: Int }
    }
}
