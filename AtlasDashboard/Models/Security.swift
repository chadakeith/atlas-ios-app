import Foundation

/// `GET /security` — Jamf Pro tenants only.
struct SecurityPayload: Decodable {
    let totalProtect: Int?
    let totalTrust: Int?
    let totalConnect: Int?
    let totalFleet: Int?
    let totalProtectSilent: Int?
    let totalTrustSilent: Int?
    let totalFvOff: Int?
    let totalFvKey: Int?
    let totalBootstrap: Int?
    let totalSecureToken: Int?
    let tenants: [SecurityTenant]
}

struct SecurityComputer: Decodable, Hashable, Identifiable {
    let jamfID: Int?
    let name: String?
    let serial: String?
    let lastCheckin: LenientInt?

    enum CodingKeys: String, CodingKey {
        case jamfID = "id"
        case name, serial, lastCheckin
    }

    var id: String { "\(jamfID ?? 0)|\(serial ?? name ?? "")" }
    var displayName: String { name?.isEmpty == false ? name! : (serial ?? "Unnamed Mac") }
    var lastCheckinDate: Date? { DashboardDates.epoch(lastCheckin?.value) }
}

struct SecurityMetric: Decodable, Hashable {
    let count: Int?
    let computers: [SecurityComputer]?
    let source: String?
    let group: String?
}

struct SecurityTenant: Decodable, Hashable, Identifiable {
    let tenant: String
    let fleet: Int?
    let protect: SecurityMetric?
    let protectSilent: SecurityMetric?
    let trust: SecurityMetric?
    let trustSilent: SecurityMetric?
    let connect: SecurityMetric?
    let fvOff: SecurityMetric?
    let fvKey: SecurityMetric?
    let bootstrap: SecurityMetric?
    let secureToken: SecurityMetric?
    let error: String?

    var id: String { tenant }

    /// Sum of every finding bucket, used to sort the worst tenants first.
    var findings: Int {
        SecurityCheck.all.reduce(0) { $0 + (self[keyPath: $1.metric]?.count ?? 0) }
    }
}

/// The security buckets the dashboard tracks, in display order.
struct SecurityCheck: Identifiable, Hashable {
    let id: String
    let label: String
    let systemImage: String
    let metric: KeyPath<SecurityTenant, SecurityMetric?>
    let total: KeyPath<SecurityPayload, Int?>

    static func == (lhs: SecurityCheck, rhs: SecurityCheck) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static let all: [SecurityCheck] = [
        SecurityCheck(id: "protect", label: "Protect not installed", systemImage: "shield.slash", metric: \.protect, total: \.totalProtect),
        SecurityCheck(id: "protect_silent", label: "Protect silent", systemImage: "shield.lefthalf.filled.slash", metric: \.protectSilent, total: \.totalProtectSilent),
        SecurityCheck(id: "trust", label: "Trust not installed", systemImage: "network.slash", metric: \.trust, total: \.totalTrust),
        SecurityCheck(id: "trust_silent", label: "Trust silent", systemImage: "network.badge.shield.half.filled", metric: \.trustSilent, total: \.totalTrustSilent),
        SecurityCheck(id: "connect", label: "Connect not installed", systemImage: "person.crop.circle.badge.xmark", metric: \.connect, total: \.totalConnect),
        SecurityCheck(id: "fv_off", label: "FileVault off", systemImage: "lock.open", metric: \.fvOff, total: \.totalFvOff),
        SecurityCheck(id: "fv_key", label: "FileVault key missing", systemImage: "key.slash", metric: \.fvKey, total: \.totalFvKey),
        SecurityCheck(id: "bootstrap", label: "Bootstrap token missing", systemImage: "cpu", metric: \.bootstrap, total: \.totalBootstrap),
        SecurityCheck(id: "secure_token", label: "Secure token missing", systemImage: "person.badge.key", metric: \.secureToken, total: \.totalSecureToken),
    ]
}
