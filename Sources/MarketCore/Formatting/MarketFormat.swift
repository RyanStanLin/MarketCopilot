import Foundation

public enum MarketFormat {
    public static func currency(_ value: Decimal?, fractionDigits: Int = 2, signed: Bool = false) -> String {
        guard let value, !value.isNaN else { return "—" }
        let format = Decimal.FormatStyle.Currency(code: "USD", locale: Locale(identifier: "en_US"))
            .precision(.fractionLength(fractionDigits))
        let text = value.formatted(format)
        return signed && value > 0 ? "+" + text : text
    }

    public static func percent(_ value: Decimal) -> String {
        let text = (value * 100).formatted(.number.locale(Locale(identifier: "en_US")).precision(.fractionLength(2)))
        return (value > 0 ? "+" : "") + text + "%"
    }
}
