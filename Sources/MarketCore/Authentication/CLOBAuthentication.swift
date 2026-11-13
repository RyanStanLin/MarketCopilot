import CryptoKit
import Foundation

public enum CLOBAuthentication {
    public static func signature(secret: String, timestamp: String, method: String, path: String, body: String = "") throws -> String {
        var normalized = secret.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        normalized += String(repeating: "=", count: (4 - normalized.count % 4) % 4)
        guard let data = Data(base64Encoded: normalized), !data.isEmpty else {
            throw APIError(status: 401, reason: "The Prediction API secret must be valid base64.")
        }
        let payload = Data((timestamp + method.uppercased() + path + body).utf8)
        let mac = HMAC<SHA256>.authenticationCode(for: payload, using: SymmetricKey(data: data))
        return Data(mac).base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
    }

    public static func headers(credentials: PredictionCredentials, signer: String, timestamp: String, path: String) throws -> [String: String] {
        ["POLY_ADDRESS": signer, "POLY_API_KEY": credentials.apiKey, "POLY_PASSPHRASE": credentials.passphrase,
         "POLY_TIMESTAMP": timestamp,
         "POLY_SIGNATURE": try signature(secret: credentials.secret, timestamp: timestamp, method: "GET", path: path)]
    }
}
