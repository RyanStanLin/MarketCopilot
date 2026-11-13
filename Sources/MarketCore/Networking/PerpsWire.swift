import Foundation

enum PerpsWire {
    struct Portfolio: Decodable, Sendable {
        let positions: [Position]
        let margin: Margin
        let timestamp: Int64
        var snapshot: PerpsSnapshot {
            PerpsSnapshot(portfolio: margin.total_account_value.value, cash: margin.available_order_margin.value,
                          positions: positions.filter { $0.size.value != 0 }.map(\.position),
                          timestamp: Date(timeIntervalSince1970: Double(timestamp) / 1000))
        }
    }
    struct Margin: Decodable, Sendable {
        let total_account_value: APIAmount
        let available_order_margin: APIAmount
    }
    struct Position: Decodable, Sendable {
        let instrument_id: Int
        let symbol: String
        let size: APIAmount
        let entry_price: APIAmount
        let leverage: Int
        let cross: Bool
        let initial_margin: APIAmount
        let position_value: APIAmount
        let liquidation_price: APIAmount?
        let unrealized_pnl: APIAmount
        let return_on_equity: APIAmount
        let cumulative_funding: APIAmount
        var position: PerpPosition {
            PerpPosition(id: instrument_id, symbol: symbol, size: size.value, entryPrice: entry_price.value,
                leverage: leverage, cross: cross, margin: initial_margin.value, positionValue: position_value.value,
                liquidationPrice: liquidation_price.flatMap { $0.value > 0 ? $0.value : nil },
                unrealizedPnl: unrealized_pnl.value, returnOnEquity: return_on_equity.value,
                cumulativeFunding: cumulative_funding.value)
        }
    }
    struct InstrumentRow: Decodable, Sendable {
        let instrument_id: Int
        let symbol: String
        let display_symbol: String?
        let quote_asset: String
        let price_decimals: Int
        let logo: Logo?
        struct Logo: Decodable, Sendable { let light: URL?; let dark: URL? }
        var instrument: Instrument {
            let label = display_symbol ?? symbol
            let suffix = "-" + quote_asset
            // Older canonical symbols can retain USD/USDC while quoting in pUSD.
            let display = label.hasSuffix(suffix) ? String(label.dropLast(suffix.count)) : label.split(separator: "-").dropLast().joined(separator: "-")
            return Instrument(id: instrument_id, symbol: symbol,
                              displaySymbol: display.isEmpty ? label : display,
                              priceDecimals: price_decimals, lightLogo: logo?.light, darkLogo: logo?.dark)
        }
    }
    struct Ticker: Decodable, Sendable {
        let instrument_id: Int
        let mark_price: APIAmount
        let timestamp: Int64?
    }
    struct BBO: Decodable, Sendable {
        let instrument_id: Int
        let bid_price: APIAmount
        let ask_price: APIAmount
        let timestamp: Int64?
    }
    struct Credentials: Decodable, Sendable {
        let address: String
        let keys: [Key]
        struct Key: Decodable, Sendable { let proxy: String; let expiry: Int64 }
    }
}
