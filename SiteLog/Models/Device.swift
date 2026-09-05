import Foundation
import SwiftData

/// A piece of hardware at a client site, identified by serial number.
@Model
final class Device {
    var serialNumber: String
    var nickname: String
    var modelName: String
    var assignedTo: String
    var notes: String
    var addedAt: Date

    var client: Client?

    init(
        serialNumber: String,
        nickname: String = "",
        modelName: String = "",
        assignedTo: String = "",
        notes: String = "",
        client: Client? = nil,
        addedAt: Date = .now
    ) {
        self.serialNumber = SerialNumber.normalize(serialNumber)
        self.nickname = nickname
        self.modelName = modelName
        self.assignedTo = assignedTo
        self.notes = notes
        self.client = client
        self.addedAt = addedAt
    }

    /// Best display name: nickname, then model, then the serial itself.
    var displayName: String {
        if !nickname.isEmpty { return nickname }
        if !modelName.isEmpty { return modelName }
        return serialNumber
    }

    func matches(_ query: String) -> Bool {
        let fields = [serialNumber, nickname, modelName, assignedTo, client?.name ?? ""]
        return fields.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}
