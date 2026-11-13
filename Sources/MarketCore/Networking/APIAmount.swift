import Foundation

struct APIAmount: Decodable, Sendable {
    let value: Decimal
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self),
           let number = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")), !number.isNaN {
            value = number
        } else if let number = try? container.decode(Decimal.self), !number.isNaN {
            value = number
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "A finite decimal amount is required.")
        }
    }
}
