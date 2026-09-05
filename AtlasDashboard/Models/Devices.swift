import Foundation

/// One Mac, iPad, or iPhone row as the Missing / Inventory endpoints return it.
struct ManagedDevice: Decodable, Hashable, Identifiable {
    let name: String?
    let serial: String?
    let model: String?
    let username: String?
    let lastCheckin: LenientInt?
    let location: String?
    let notes: String?
    let building: String?
    let orderDate: String?
    /// "Jamf", "Addigy", or "Jamf + Addigy"
    let mdm: String?

    var id: String {
        let serialPart = serial?.isEmpty == false ? serial! : "no-serial"
        return "\(serialPart)|\(name ?? "")"
    }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        if let serial, !serial.isEmpty { return serial }
        return "Unnamed device"
    }

    var lastCheckinDate: Date? { DashboardDates.epoch(lastCheckin?.value) }
}

/// A client's slice of a device list. Built from either the Mac or the mobile payload.
struct DeviceSection: Identifiable, Hashable {
    let tenant: String
    let count: Int?
    let items: [ManagedDevice]
    let error: String?

    var id: String { tenant }
}

/// `GET /missing-macs`, `/inventory`, `/unassigned` — items live under `computers`.
struct ComputerSectionsPayload: Decodable {
    struct Section: Decodable {
        let tenant: String
        let count: Int?
        let computers: [ManagedDevice]?
        let error: String?
    }

    let total: Int?
    let tenants: [Section]

    var sections: [DeviceSection] {
        tenants.map { DeviceSection(tenant: $0.tenant, count: $0.count, items: $0.computers ?? [], error: $0.error) }
    }
}

/// `GET /missing-devices`, `/inventory-devices` — items live under `devices`.
struct MobileSectionsPayload: Decodable {
    struct Section: Decodable {
        let tenant: String
        let count: Int?
        let devices: [ManagedDevice]?
        let error: String?
    }

    let total: Int?
    let tenants: [Section]

    var sections: [DeviceSection] {
        tenants.map { DeviceSection(tenant: $0.tenant, count: $0.count, items: $0.devices ?? [], error: $0.error) }
    }
}

extension Array where Element == DeviceSection {
    var totalCount: Int {
        reduce(0) { $0 + ($1.count ?? $1.items.count) }
    }

    /// Sections whose devices match the query (by any visible field), empty sections dropped.
    func filtered(by query: String) -> [DeviceSection] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return self }
        return compactMap { section in
            let matches = section.items.filter { device in
                [device.name, device.serial, device.model, device.username, device.location, device.building, section.tenant]
                    .compactMap { $0 }
                    .contains { $0.localizedCaseInsensitiveContains(needle) }
            }
            guard !matches.isEmpty else { return nil }
            return DeviceSection(tenant: section.tenant, count: matches.count, items: matches, error: section.error)
        }
    }
}
