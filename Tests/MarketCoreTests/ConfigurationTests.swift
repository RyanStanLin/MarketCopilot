import Foundation
import Testing
@testable import MarketCore

@Suite("Account configuration")
struct ConfigurationTests {
    @Test func validatesAddressesWithoutConfusingSignerAndAccount() throws {
        var configuration = AccountConfiguration()
        configuration.walletAddress = " 0x1111111111111111111111111111111111111111\n"
        configuration.signerAddress = "0x2222222222222222222222222222222222222222"
        let result = try configuration.validated()
        #expect(result.walletAddress == "0x1111111111111111111111111111111111111111")
        #expect(result.signerAddress != result.walletAddress)
        configuration.signerAddress = "invalid"
        #expect(throws: ConfigurationError.invalidSigner) { try configuration.validated() }
    }

    @Test func rejectsPartialCredentialSetsButAllowsPublicAddressSetup() throws {
        var account = AccountConfiguration()
        account.walletAddress = "0x1111111111111111111111111111111111111111"
        let empty = AccountSecrets()
        #expect(try empty.validated(account: account).prediction == nil)
        var partial = empty
        partial.predictionKey = "test-key"
        #expect(throws: ConfigurationError.incompletePredictionCredentials) { try partial.validated(account: account) }
        partial = empty; partial.perpsSecret = "test-secret"
        #expect(throws: ConfigurationError.incompletePerpsCredentials) { try partial.validated(account: account) }
    }

    @Test func refreshIntervalsEnforceFiniteBoundaries() throws {
        var settings = RefreshSettings()
        settings.pollingInterval = 1; settings.reconciliationInterval = 10
        #expect(try settings.validated() == settings)
        settings.pollingInterval = 300; settings.reconciliationInterval = 600
        #expect(try settings.validated() == settings)
        settings.pollingInterval = 0.99
        #expect(throws: ConfigurationError.invalidRefreshInterval) { try settings.validated() }
        settings.pollingInterval = .nan
        #expect(throws: ConfigurationError.invalidRefreshInterval) { try settings.validated() }
        settings.pollingInterval = 301
        #expect(throws: ConfigurationError.invalidRefreshInterval) { try settings.validated() }
        settings.pollingInterval = 5; settings.reconciliationInterval = 601
        #expect(throws: ConfigurationError.invalidRefreshInterval) { try settings.validated() }
        settings.reconciliationInterval = 9
        #expect(throws: ConfigurationError.invalidRefreshInterval) { try settings.validated() }
    }
}
