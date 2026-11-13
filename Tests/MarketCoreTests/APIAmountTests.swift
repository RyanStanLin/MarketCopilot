import Foundation
import Testing
@testable import MarketCore

@Suite("Financial decimal decoding")
struct APIAmountTests {
    @Test func exactStringAndNumberAmountsNeverPassThroughDouble() throws {
        let decoder = JSONDecoder()
        let string = try decoder.decode(APIAmount.self, from: Data(#""123456789.123456789""#.utf8))
        let number = try decoder.decode(APIAmount.self, from: Data("123456789.123456789".utf8))
        #expect(string.value == Decimal(string: "123456789.123456789"))
        #expect(number.value == Decimal(string: "123456789.123456789"))
    }

    @Test func malformedAndUnavailableAmountsAreRejected() {
        let cases = [#""""#, #""12oops""#, #""NaN""#, #""Infinity""#, "null"]
        for payload in cases {
            #expect(throws: DecodingError.self) { try JSONDecoder().decode(APIAmount.self, from: Data(payload.utf8)) }
        }
    }
}
