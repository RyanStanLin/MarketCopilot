public enum WalletType: Int, Codable, CaseIterable, Sendable, Identifiable {
    case externallyOwned = 0, legacyProxy = 1, legacySafe = 2, depositWallet = 3
    public var id: Int { rawValue }
    public var title: String {
        let title = switch self {
        case .externallyOwned: "EOA"
        case .legacyProxy: "Legacy Proxy (Magic / Google)"
        case .legacySafe: "Legacy Safe (external wallet)"
        case .depositWallet: "Deposit Wallet"
        }
        return L10n.text(title)
    }
}
