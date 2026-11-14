#if DEBUG
import AppKit
import MarketCore
import SwiftUI

@MainActor
enum NativeValidation {
    static func run(_ store: AppStore) {
        var checks: [String: Bool] = [:]
        var errors: [String] = []
        checks["collapsedGeometry"] = DesignTokens.menuHeight(expanded: false, positionCount: 2, maximum: 1100) == 404
        checks["expandedGeometry"] = DesignTokens.menuHeight(expanded: true, positionCount: 3, maximum: 1100) == 843
        checks["drawerClampsToScreen"] = DesignTokens.menuHeight(expanded: true, positionCount: 20, maximum: 700) == 700
        checks["staticAssetsPresent"] = ["FigmaAvatar", "FigmaUS100", "FigmaNVDA", "FigmaPrediction"].allSatisfy { NSImage(named: $0) != nil }
        checks["followsSystemAppearance"] = NSApp.appearance == nil
        let lightFill = resolveFill(.aqua)
        let darkFill = resolveFill(.darkAqua)
        print("Appearance fill components: light=\(String(describing: lightFill)), dark=\(String(describing: darkFill))")
        checks["fillColorsAdaptToAppearance"] = lightFill.map { $0.0 < 0.01 && abs($0.1 - 0.05) < 0.01 } == true
            && darkFill.map { $0.0 > 0.99 && abs($0.1 - 0.1) < 0.01 } == true
        do {
            let repository = try WorkspaceRepository(inMemory: true)
            var account = AccountConfiguration()
            account.walletAddress = "0x1111111111111111111111111111111111111111"
            let snapshot = PortfolioSnapshot(predictions: PredictionSnapshot(holdingsValue: Decimal(string: "1234.5678")!, cash: Decimal(string: "2.98")!))
            var settings = RefreshSettings(); settings.pollingInterval = 17
            try repository.save(account: account, settings: settings, snapshot: snapshot, instruments: [:])
            let loaded = try repository.load()
            checks["swiftDataAccount"] = loaded.0.walletAddress == account.walletAddress
            checks["swiftDataSettings"] = loaded.1.pollingInterval == 17
            checks["swiftDataExactDecimalCache"] = loaded.2?.predictions?.holdingsValue == Decimal(string: "1234.5678") && loaded.2?.predictions?.cash == Decimal(string: "2.98")
            account.walletAddress = "0x2222222222222222222222222222222222222222"
            try repository.save(account: account, settings: settings, snapshot: nil, instruments: [:])
            checks["swiftDataAccountIsolation"] = try repository.load().2 == nil
        } catch { errors.append("SwiftData: " + error.localizedDescription) }
        do {
            let vault = KeychainVault(service: "in.ryanl.MarketCopilot.validation." + UUID().uuidString)
            let identity = "validation-only"
            var secrets = AccountSecrets()
            secrets.predictionKey = "non-secret-fixture"
            secrets.predictionSecret = "non-secret-value"
            try vault.save(secrets, identity: identity)
            defer { try? vault.clear(identity: identity) }
            checks["keychainRoundTrip"] = try vault.load(identity: identity).predictionKey == "non-secret-fixture"
            checks["keychainIdentityIsolation"] = try vault.load(identity: "different-identity").predictionKey.isEmpty
            try vault.clear(identity: identity)
            checks["keychainDelete"] = try vault.load(identity: identity).predictionKey.isEmpty
        } catch { errors.append("Keychain: " + error.localizedDescription) }
        let directory = URL.cachesDirectory.appending(path: "DesignValidation", directoryHint: .isDirectory)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let report: [String: Any] = ["checks": checks, "errors": errors, "passed": errors.isEmpty && checks.values.allSatisfy { $0 }]
            let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: directory.appending(path: "native-validation.json"))
            print(String(decoding: data, as: UTF8.self))
        } catch { errors.append(error.localizedDescription) }
        if !errors.isEmpty || !checks.values.allSatisfy({ $0 }) { exit(1) }
        NSApp.terminate(nil)
    }

    private static func resolveFill(_ name: NSAppearance.Name) -> (CGFloat, CGFloat)? {
        guard let appearance = NSAppearance(named: name) else { return nil }
        var result: (CGFloat, CGFloat)?
        appearance.performAsCurrentDrawingAppearance {
            if let color = NSColor(named: "FillsOpaqueTertiary")?.usingColorSpace(.deviceRGB) {
                result = (color.redComponent, color.alphaComponent)
            }
        }
        return result
    }
}
#endif
