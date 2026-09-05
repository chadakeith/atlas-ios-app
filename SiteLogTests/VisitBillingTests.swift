import Foundation
import SwiftData
import Testing
@testable import SiteLog

@MainActor
struct VisitBillingTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Client.self, Visit.self, Device.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return container.mainContext
    }

    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    @Test func elapsedUsesEndDateWhenPresent() throws {
        let context = try makeContext()
        let client = Client(name: "Acme", hourlyRate: 120)
        context.insert(client)
        let visit = Visit(client: client, startedAt: start)
        context.insert(visit)
        visit.endedAt = start.addingTimeInterval(45 * 60)

        #expect(visit.isActive == false)
        #expect(visit.elapsed(asOf: start.addingTimeInterval(9_999)) == 45 * 60)
    }

    @Test func elapsedUsesNowWhileActive() throws {
        let context = try makeContext()
        let visit = Visit(client: nil, startedAt: start)
        context.insert(visit)

        #expect(visit.isActive)
        #expect(visit.elapsed(asOf: start.addingTimeInterval(600)) == 600)
    }

    @Test func billableSecondsRoundUpToIncrement() throws {
        let context = try makeContext()
        let visit = Visit(client: nil, startedAt: start)
        context.insert(visit)
        visit.endedAt = start.addingTimeInterval(16 * 60)

        #expect(visit.billableSeconds(incrementMinutes: 15) == 30 * 60)
        #expect(visit.billableSeconds(incrementMinutes: 30) == 30 * 60)
        #expect(visit.billableSeconds(incrementMinutes: 1) == 16 * 60)
    }

    @Test func exactMultipleDoesNotRoundUp() throws {
        let context = try makeContext()
        let visit = Visit(client: nil, startedAt: start)
        context.insert(visit)
        visit.endedAt = start.addingTimeInterval(60 * 60)

        #expect(visit.billableSeconds(incrementMinutes: 15) == 60 * 60)
    }

    @Test func nonBillableVisitsAreFree() throws {
        let context = try makeContext()
        let visit = Visit(client: nil, startedAt: start, isBillable: false)
        context.insert(visit)
        visit.endedAt = start.addingTimeInterval(2 * 60 * 60)

        #expect(visit.billableSeconds(incrementMinutes: 15) == 0)
        #expect(visit.amount(rate: 200, incrementMinutes: 15) == 0)
    }

    @Test func amountIsRateTimesRoundedHours() throws {
        let context = try makeContext()
        let visit = Visit(client: nil, startedAt: start)
        context.insert(visit)
        visit.endedAt = start.addingTimeInterval(50 * 60) // rounds to 1 h at 15-min increments

        #expect(visit.amount(rate: 125, incrementMinutes: 15) == 125)
        #expect(visit.amount(rate: 125, incrementMinutes: 10) == 125) // 50 min is an exact multiple of 10
        #expect(visit.amount(rate: 90, incrementMinutes: 60) == 90)
    }

    @Test func amountRoundsToCents() throws {
        let context = try makeContext()
        let visit = Visit(client: nil, startedAt: start)
        context.insert(visit)
        visit.endedAt = start.addingTimeInterval(20 * 60) // exactly a third of an hour

        #expect(visit.amount(rate: 100, incrementMinutes: 1) == Decimal(string: "33.33"))
    }

    @Test func clientTotalsSumEveryVisit() throws {
        let context = try makeContext()
        let client = Client(name: "Acme", hourlyRate: 100, billingIncrementMinutes: 15)
        context.insert(client)

        let first = Visit(client: client, startedAt: start)
        first.endedAt = start.addingTimeInterval(30 * 60)
        let second = Visit(client: client, startedAt: start.addingTimeInterval(86_400))
        second.endedAt = second.startedAt.addingTimeInterval(70 * 60) // rounds to 75 min
        let freebie = Visit(client: client, startedAt: start.addingTimeInterval(172_800), isBillable: false)
        freebie.endedAt = freebie.startedAt.addingTimeInterval(60 * 60)
        for visit in [first, second, freebie] { context.insert(visit) }
        try context.save()

        #expect(client.visits.count == 3)
        #expect(client.totalSeconds() == (30 + 70 + 60) * 60)
        #expect(client.totalAmount() == 50 + 125)
    }
}
