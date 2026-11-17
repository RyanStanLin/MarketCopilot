import Foundation
import MarketCore
import SwiftData

@MainActor
final class WorkspaceRepository {
    private let container: ModelContainer
    private let context: ModelContext

    init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        container = try ModelContainer(for: StoredWorkspace.self, configurations: configuration)
        context = ModelContext(container)
    }

    func load() throws -> (AccountConfiguration, RefreshSettings, PortfolioSnapshot?, [Int: Instrument]) {
        guard let record = try context.fetch(FetchDescriptor<StoredWorkspace>()).first else {
            return (AccountConfiguration(), RefreshSettings(), nil, [:])
        }
        let decoder = JSONDecoder()
        let account = try decoder.decode(AccountConfiguration.self, from: record.accountData)
        let settings = try decoder.decode(RefreshSettings.self, from: record.refreshData)
        let snapshot = record.snapshotIdentity == account.identity ? try record.snapshotData.map { try decoder.decode(PortfolioSnapshot.self, from: $0) } : nil
        let instruments = try record.instrumentData.map { try decoder.decode([Int: Instrument].self, from: $0) } ?? [:]
        return (account, settings, snapshot, instruments)
    }

    func save(account: AccountConfiguration, settings: RefreshSettings, snapshot: PortfolioSnapshot?, instruments: [Int: Instrument]) throws {
        let encoder = JSONEncoder()
        let records = try context.fetch(FetchDescriptor<StoredWorkspace>())
        let record = records.first ?? StoredWorkspace(accountData: Data(), refreshData: Data())
        if records.isEmpty { context.insert(record) }
        record.accountData = try encoder.encode(account)
        record.refreshData = try encoder.encode(settings)
        record.snapshotIdentity = account.identity
        record.snapshotData = try snapshot.map(encoder.encode)
        record.instrumentData = try encoder.encode(instruments)
        try context.save()
    }

    func loadAlerts() throws -> [MarketAlertRule] {
        guard let data = try context.fetch(FetchDescriptor<StoredWorkspace>()).first?.alertRuleData else { return [] }
        return try JSONDecoder().decode([MarketAlertRule].self, from: data).map { try $0.validated() }
    }

    func saveAlerts(_ rules: [MarketAlertRule]) throws {
        let records = try context.fetch(FetchDescriptor<StoredWorkspace>())
        let encoder = JSONEncoder()
        let record: StoredWorkspace
        if let existing = records.first { record = existing }
        else {
            record = StoredWorkspace(accountData: try encoder.encode(AccountConfiguration()),
                                     refreshData: try encoder.encode(RefreshSettings()))
            context.insert(record)
        }
        record.alertRuleData = try encoder.encode(rules)
        try context.save()
    }
}
