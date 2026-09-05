import Foundation

/// `GET /lifecycle-macs`
///
/// Property names look odd because `.convertFromSnakeCase` maps `total_3yr` to
/// `total3Yr` (it capitalizes the first *letter* of each component).
struct LifecyclePayload: Decodable {
    let total3Yr: Int?
    let total4Yr: Int?
    let total5Yr: Int?
    let tenants: [LifecycleTenant]
}

struct LifecycleMac: Decodable, Hashable, Identifiable {
    let jamfID: Int?
    let name: String?
    let serial: String?
    let ageMonths: Double?
    let building: String?
    let monthsToNext: Double?
    let nextTier: String?

    enum CodingKeys: String, CodingKey {
        case jamfID = "id"
        case name, serial, ageMonths, building, monthsToNext, nextTier
    }

    var id: String { "\(jamfID ?? 0)|\(serial ?? name ?? "")" }
    var displayName: String { name?.isEmpty == false ? name! : (serial ?? "Unnamed Mac") }
}

struct LifecycleTier: Decodable, Hashable {
    let count: Int?
    let computers: [LifecycleMac]?
}

struct LifecycleTenant: Decodable, Hashable, Identifiable {
    let tenant: String
    let threeYear: LifecycleTier?
    let fourYear: LifecycleTier?
    let fiveYear: LifecycleTier?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case tenant, error
        case threeYear = "3yr"
        case fourYear = "4yr"
        case fiveYear = "5yr"
    }

    var id: String { tenant }
}

/// `GET /os-versions`
struct OSVersionsPayload: Decodable {
    struct Apple: Decodable {
        struct Release: Decodable {
            let version: String?
            let build: String?
            let posted: String?
        }
        let latest: Release?
        let latestMajor: Int?
    }

    struct Totals: Decodable {
        let total: Int?
        let onLatest: Int?
        let behindPatch: Int?
        let oldMajor: Int?
        let hwCapped: Int?
        let unknown: Int?
    }

    struct Offline: Decodable {
        let missing: Int?
        let inventory: Int?
    }

    let apple: Apple?
    let totals: Totals?
    let offline: Offline?
}
