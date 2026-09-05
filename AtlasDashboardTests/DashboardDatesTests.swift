import Foundation
import Testing
@testable import AtlasDashboard

struct DashboardDatesTests {
    @Test func millisecondEpochsAreScaled() {
        let date = DashboardDates.epoch(1_755_561_600_000)
        #expect(date == Date(timeIntervalSince1970: 1_755_561_600))
    }

    @Test func secondEpochsPassThrough() {
        let date = DashboardDates.epoch(1_755_000_000)
        #expect(date == Date(timeIntervalSince1970: 1_755_000_000))
    }

    @Test func zeroAndNilMeanNever() {
        #expect(DashboardDates.epoch(0) == nil)
        #expect(DashboardDates.epoch(nil) == nil)
        #expect(DashboardDates.epoch(-5) == nil)
    }

    @Test func dayStringsParse() throws {
        let day = try #require(DashboardDates.day(from: "2026-09-05"))
        let components = Calendar.current.dateComponents([.year, .month, .day], from: day)
        #expect(components.year == 2026)
        #expect(components.month == 9)
        #expect(components.day == 5)
        #expect(DashboardDates.day(from: "not a date") == nil)
    }

    @Test func serverStampsParse() {
        #expect(DashboardDates.stamp(from: "2026-09-05 06:12:44") != nil)
        #expect(DashboardDates.stamp(from: "2026-09-05T06:10:00-04:00") != nil)
        #expect(DashboardDates.stamp(from: "yesterday") == nil)
    }

    @Test func lenientIntAcceptsEveryShapeTheServerHasSent() throws {
        struct Row: Decodable { let v: LenientInt? }
        let decoder = JSONDecoder()
        #expect(try decoder.decode(Row.self, from: Data(#"{"v": 1755000000}"#.utf8)).v?.value == 1_755_000_000)
        #expect(try decoder.decode(Row.self, from: Data(#"{"v": 1755000000.0}"#.utf8)).v?.value == 1_755_000_000)
        #expect(try decoder.decode(Row.self, from: Data(#"{"v": "1755000000"}"#.utf8)).v?.value == 1_755_000_000)
        #expect(try decoder.decode(Row.self, from: Data(#"{"v": null}"#.utf8)).v?.value == nil)
        #expect(try decoder.decode(Row.self, from: Data(#"{"v": "n/a"}"#.utf8)).v?.value == nil)
        #expect(try decoder.decode(Row.self, from: Data(#"{}"#.utf8)).v == nil)
    }
}
