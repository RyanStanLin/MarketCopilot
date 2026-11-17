import Foundation
import SwiftData

@Model
final class StoredWorkspace {
    @Attribute(.unique) var id: String
    var accountData: Data
    var refreshData: Data
    var snapshotData: Data?
    var snapshotIdentity: String
    var instrumentData: Data?
    var alertRuleData: Data?

    init(accountData: Data, refreshData: Data) {
        id = "workspace"; self.accountData = accountData; self.refreshData = refreshData
        snapshotIdentity = ""
    }
}
