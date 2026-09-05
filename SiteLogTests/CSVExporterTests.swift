import Foundation
import SwiftData
import Testing
@testable import SiteLog

struct CSVExporterTests {
    @Test func plainFieldsAreNotQuoted() {
        #expect(CSVExporter.escape("Acme Dental") == "Acme Dental")
    }

    @Test func commasQuotesAndNewlinesAreQuoted() {
        #expect(CSVExporter.escape("Raleigh, NC") == "\"Raleigh, NC\"")
        #expect(CSVExporter.escape("24\" iMac") == "\"24\"\" iMac\"")
        #expect(CSVExporter.escape("line one\nline two") == "\"line one\nline two\"")
    }

    @Test func renderJoinsRowsWithCRLF() {
        let csv = CSVExporter.render([["a", "b"], ["1", "2"]])
        #expect(csv == "a,b\r\n1,2\r\n")
    }

    @Test @MainActor func exportsHeaderAndOneRowPerVisit() throws {
        let container = try ModelContainer(
            for: Client.self, Visit.self, Device.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let client = Client(name: "Acme, Inc.", hourlyRate: 120, billingIncrementMinutes: 15)
        context.insert(client)

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let visit = Visit(client: client, startedAt: start, summary: "Swapped the \"bad\" switch")
        visit.endedAt = start.addingTimeInterval(50 * 60)
        visit.locationLabel = "Glenwood Ave, Raleigh"
        context.insert(visit)
        try context.save()

        let csv = CSVExporter.visitsCSV(for: client, asOf: start.addingTimeInterval(86_400))
        let lines = csv.split(separator: "\r\n").map(String.init)

        #expect(lines.count == 2)
        #expect(lines[0] == CSVExporter.header.joined(separator: ","))
        #expect(lines[1].hasPrefix("\"Acme, Inc.\","))
        #expect(lines[1].contains(",0.83,1.00,120,120,"))
        #expect(lines[1].contains("\"Glenwood Ave, Raleigh\""))
        #expect(lines[1].contains("\"Swapped the \"\"bad\"\" switch\""))
    }
}
