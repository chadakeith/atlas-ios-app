import Foundation
import SwiftData

/// One trip to a client site, from arrival to departure.
@Model
final class Visit {
    var startedAt: Date
    var endedAt: Date?
    var summary: String
    var notes: String
    var isBillable: Bool

    var latitude: Double?
    var longitude: Double?
    /// Human-readable place name captured when the visit started.
    var locationLabel: String?

    var client: Client?

    init(
        client: Client?,
        startedAt: Date = .now,
        isBillable: Bool = true,
        summary: String = "",
        notes: String = ""
    ) {
        self.client = client
        self.startedAt = startedAt
        self.isBillable = isBillable
        self.summary = summary
        self.notes = notes
    }

    var isActive: Bool { endedAt == nil }

    /// Seconds between start and end, or start and `now` while the visit is running.
    func elapsed(asOf now: Date = .now) -> TimeInterval {
        max(0, (endedAt ?? now).timeIntervalSince(startedAt))
    }

    var duration: TimeInterval { elapsed() }

    /// Elapsed time rounded up to the client's billing increment. Zero for
    /// non-billable visits.
    func billableSeconds(incrementMinutes: Int, asOf now: Date = .now) -> TimeInterval {
        let raw = elapsed(asOf: now)
        guard isBillable, raw > 0 else { return 0 }
        let increment = TimeInterval(max(1, incrementMinutes) * 60)
        return (raw / increment).rounded(.up) * increment
    }

    /// Billable time multiplied by the rate, rounded to cents.
    func amount(rate: Decimal, incrementMinutes: Int, asOf now: Date = .now) -> Decimal {
        let hours = Decimal(billableSeconds(incrementMinutes: incrementMinutes, asOf: now) / 3600)
        return (hours * rate).rounded(scale: 2)
    }
}
