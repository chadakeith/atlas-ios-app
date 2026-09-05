import Foundation

struct WorkloadCounts: Decodable, Hashable {
    let openTotal: Int?
    let openTickets: Int?
    let openTasks: Int?
    let closedToday: Int?
    let closedWeek: Int?
    let netToday: Int?
    let staleAsana: Int?
}

/// `GET /productivity/api/summary`
struct ProductivitySummary: Decodable {
    struct Card: Decodable, Identifiable, Hashable {
        let id: String
        let label: String
        let value: Int?
        let hint: String?
    }

    struct Sources: Decodable {
        let autotask: String?
        let asana: String?
    }

    let title: String?
    let subtitle: String?
    let sources: Sources?
    let totals: WorkloadCounts?
    let fromCache: Bool?
    let cacheAgeMinutes: Double?
    let lastUpdated: String?
    let cards: [Card]
}

/// `GET /productivity/api/team`
struct TeamPayload: Decodable {
    struct Member: Decodable, Identifiable, Hashable {
        let id: String
        let name: String?
        let email: String?
        let counts: WorkloadCounts?

        var displayName: String { name?.isEmpty == false ? name! : id }
    }

    let title: String?
    let weekStart: String?
    let today: String?
    let asOf: String?
    let totals: WorkloadCounts?
    let members: [Member]
}
