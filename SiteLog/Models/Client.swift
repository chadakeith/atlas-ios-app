import Foundation
import SwiftData

/// A customer site you do work for. Owns its visits and devices.
@Model
final class Client {
    var name: String
    var contactName: String
    var contactEmail: String
    var phone: String
    var address: String
    var notes: String
    var createdAt: Date

    /// Hourly rate used to price visits.
    var hourlyRate: Decimal

    /// Visits are rounded *up* to this many minutes when billed (15 is the
    /// industry default for IT consulting).
    var billingIncrementMinutes: Int

    @Relationship(deleteRule: .cascade, inverse: \Visit.client)
    var visits: [Visit] = []

    @Relationship(deleteRule: .cascade, inverse: \Device.client)
    var devices: [Device] = []

    init(
        name: String,
        contactName: String = "",
        contactEmail: String = "",
        phone: String = "",
        address: String = "",
        notes: String = "",
        hourlyRate: Decimal = 0,
        billingIncrementMinutes: Int = 15,
        createdAt: Date = .now
    ) {
        self.name = name
        self.contactName = contactName
        self.contactEmail = contactEmail
        self.phone = phone
        self.address = address
        self.notes = notes
        self.hourlyRate = hourlyRate
        self.billingIncrementMinutes = billingIncrementMinutes
        self.createdAt = createdAt
    }

    var hasActiveVisit: Bool {
        visits.contains { $0.isActive }
    }

    /// Raw wall-clock time across all visits, billable or not.
    func totalSeconds(asOf now: Date = .now) -> TimeInterval {
        visits.reduce(0) { $0 + $1.elapsed(asOf: now) }
    }

    /// What you would invoice for every visit at the current rate.
    func totalAmount(asOf now: Date = .now) -> Decimal {
        visits.reduce(Decimal(0)) { partial, visit in
            partial + visit.amount(rate: hourlyRate, incrementMinutes: billingIncrementMinutes, asOf: now)
        }
    }
}
