import Foundation

/// Builds a spreadsheet-friendly export of a client's visits. Pure functions
/// so it is easy to unit test without a UI.
enum CSVExporter {
    static let header = [
        "Client", "Date", "Start", "End", "Hours", "Billable hours",
        "Rate", "Amount", "Location", "Summary", "Notes",
    ]

    static func visitsCSV(for client: Client, asOf now: Date = .now) -> String {
        let visits = client.visits.sorted { $0.startedAt < $1.startedAt }
        let rows = visits.map { row(for: $0, client: client, asOf: now) }
        return render([header] + rows)
    }

    static func row(for visit: Visit, client: Client, asOf now: Date = .now) -> [String] {
        let increment = client.billingIncrementMinutes
        let hours = visit.elapsed(asOf: now) / 3600
        let billableHours = visit.billableSeconds(incrementMinutes: increment, asOf: now) / 3600
        let amount = visit.amount(rate: client.hourlyRate, incrementMinutes: increment, asOf: now)

        return [
            client.name,
            dateOnly.string(from: visit.startedAt),
            timeOnly.string(from: visit.startedAt),
            visit.endedAt.map(timeOnly.string(from:)) ?? "",
            decimal(hours),
            decimal(billableHours),
            "\(client.hourlyRate)",
            "\(amount)",
            visit.locationLabel ?? "",
            visit.summary,
            visit.notes,
        ]
    }

    static func render(_ rows: [[String]]) -> String {
        rows.map { $0.map(escape).joined(separator: ",") }.joined(separator: "\r\n") + "\r\n"
    }

    /// RFC 4180 quoting: wrap in quotes when the field contains a comma,
    /// quote, or line break, and double any embedded quotes.
    static func escape(_ field: String) -> String {
        let needsQuoting = field.contains { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }
        guard needsQuoting else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func decimal(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private static let dateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
