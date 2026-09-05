import Foundation

/// `GET /overview` — the hero numbers on the dashboard's first tab.
struct Overview: Decodable {
    struct Metric: Decodable, Identifiable, Hashable {
        let key: String
        let label: String
        let hint: String?
        let tab: String?
        let mode: String?
        let count: Int?
        let delta: Int?

        var id: String { key }
    }

    struct HistoryPoint: Decodable, Identifiable, Hashable {
        let date: String
        let total: Int?

        var id: String { date }
        var day: Date? { DashboardDates.day(from: date) }
    }

    let total: Int?
    let missing: Int?
    let missingMacs: Int?
    let missingIos: Int?
    let deltaWeek: Int?
    let since: String?
    let completedToday: Int?
    let completedWeek: Int?
    let healthPct: Int?
    let totalDevices: Int?
    let metrics: [Metric]
    let history: [HistoryPoint]?
    let generatedAt: String?
}

struct AccessMe: Decodable {
    let email: String
    let admin: Bool?
}

/// `GET /total-macs`, `GET /total-devices`
struct CountPayload: Decodable {
    struct Tenant: Decodable, Identifiable, Hashable {
        let tenant: String
        let count: Int?
        let error: String?
        var id: String { tenant }
    }

    let total: Int?
    let tenants: [Tenant]
}

enum DashboardDates {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static func day(from text: String) -> Date? {
        dayFormatter.date(from: text)
    }

    /// Server stamps like "2026-09-05 06:12:44" (already in US Eastern).
    static func stamp(from text: String) -> Date? {
        stampFormatter.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }

    /// Jamf epochs arrive in milliseconds; a few sources use seconds. Normalize both.
    static func epoch(_ value: Int?) -> Date? {
        guard let value, value > 0 else { return nil }
        let seconds = value > 100_000_000_000 ? Double(value) / 1000 : Double(value)
        return Date(timeIntervalSince1970: seconds)
    }
}

/// Accepts an integer, a float, a numeric string, or null. Jamf sends epochs as
/// integers but Addigy-sourced rows have been seen as floats.
struct LenientInt: Decodable, Hashable {
    let value: Int?

    init(_ value: Int?) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self), double.isFinite {
            value = Int(double)
        } else if let text = try? container.decode(String.self) {
            value = Int(text.trimmingCharacters(in: .whitespaces)) ?? Double(text).map { Int($0) }
        } else {
            value = nil
        }
    }
}
