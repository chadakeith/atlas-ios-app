#if DEBUG
import Foundation
import SwiftData

/// In-memory store with a little realistic data for SwiftUI previews.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Client.self, Visit.self, Device.self,
            configurations: configuration
        )
        let context = container.mainContext

        let acme = Client(
            name: "Acme Dental",
            contactName: "Dana Reyes",
            contactEmail: "dana@acmedental.example",
            phone: "(919) 555-0134",
            address: "410 Glenwood Ave, Raleigh, NC",
            hourlyRate: 125
        )
        let harbor = Client(name: "Harbor Law Group", hourlyRate: 150, billingIncrementMinutes: 30)
        context.insert(acme)
        context.insert(harbor)

        let yesterday = Visit(client: acme, startedAt: .now.addingTimeInterval(-90_000))
        yesterday.endedAt = yesterday.startedAt.addingTimeInterval(4_100)
        yesterday.summary = "Replaced failing switch in the closet, re-enrolled two Macs."
        yesterday.locationLabel = "Glenwood Ave, Raleigh"
        context.insert(yesterday)

        let running = Visit(client: harbor, startedAt: .now.addingTimeInterval(-1_500))
        running.summary = "Quarterly patching"
        context.insert(running)

        context.insert(Device(serialNumber: "C02XG1ABJGH5", nickname: "Front desk iMac", modelName: "iMac 24-inch", assignedTo: "Reception", client: acme))
        context.insert(Device(serialNumber: "SJQ4K7PLM2", modelName: "MacBook Air 13-inch", assignedTo: "Dana Reyes", client: acme))

        return container
    }()
}
#endif
