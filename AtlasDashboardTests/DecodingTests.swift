import Foundation
import Testing
@testable import AtlasDashboard

struct DecodingTests {
    @Test func overviewDecodes() throws {
        let overview = try Fixtures.decode(Overview.self, from: Fixtures.overviewJSON)
        #expect(overview.total == 41)
        #expect(overview.healthPct == 96)
        #expect(overview.deltaWeek == -6)
        #expect(overview.metrics.count == 6)
        #expect(overview.metrics.first?.label == "Missing Computers")
        #expect(overview.metrics.last?.delta == nil)
        #expect(overview.history?.count == 10)
        #expect(overview.history?.first?.day != nil)
    }

    @Test func missingMacsMapToSections() throws {
        let payload = try Fixtures.decode(ComputerSectionsPayload.self, from: Fixtures.missingMacsJSON)
        let sections = payload.sections
        #expect(sections.count == 4)
        #expect(sections.totalCount == 4)
        #expect(sections[0].items.first?.displayName == "ATL-MBP-014")
        #expect(sections[0].items[1].mdm == "Jamf + Addigy")
        #expect(sections[2].error == "401 Unauthorized")
        #expect(sections[2].items.isEmpty)
    }

    @Test func missingDevicesMapToSections() throws {
        let payload = try Fixtures.decode(MobileSectionsPayload.self, from: Fixtures.missingDevicesJSON)
        #expect(payload.sections.count == 2)
        #expect(payload.sections[0].items.count == 2)
        #expect(payload.sections[0].items[1].lastCheckinDate == nil)
    }

    @Test func sectionSearchKeepsOnlyMatches() throws {
        let sections = try Fixtures.decode(ComputerSectionsPayload.self, from: Fixtures.missingMacsJSON).sections
        let byUser = sections.filtered(by: "jordan")
        #expect(byUser.count == 1)
        #expect(byUser[0].items.count == 1)
        #expect(byUser[0].count == 1)

        let byTenant = sections.filtered(by: "debtbook")
        #expect(byTenant.map(\.tenant) == ["DebtBook"])

        #expect(sections.filtered(by: "   ").count == sections.count)
    }

    @Test func securityDecodesAndCountsFindings() throws {
        let payload = try Fixtures.decode(SecurityPayload.self, from: Fixtures.securityJSON)
        #expect(payload.totalFleet == 612)
        #expect(payload.tenants.count == 2)
        let atlas = payload.tenants[0]
        #expect(atlas.findings == 4) // protect 1 + trust 2 + fv_off 1
        #expect(atlas.connect?.count == nil)
        #expect(atlas.trust?.computers?.count == 2)
        #expect(atlas.protect?.computers?.first?.jamfID == 12)
        #expect(payload.tenants[1].error == "Timeout")
        #expect(payload.tenants[1].findings == 0)
    }

    @Test func lifecycleDecodesNumericTierKeys() throws {
        let payload = try Fixtures.decode(LifecyclePayload.self, from: Fixtures.lifecycleJSON)
        #expect(payload.total3yr == 38)
        #expect(payload.total5yr == 14)
        let atlas = payload.tenants[0]
        #expect(atlas.threeYear?.count == 1)
        #expect(atlas.fourYear?.count == 0)
        #expect(atlas.fiveYear?.computers?.first?.nextTier == "overdue")
        #expect(atlas.threeYear?.computers?.first?.ageMonths == 40.2)
    }

    @Test func osVersionsDecodes() throws {
        let payload = try Fixtures.decode(OSVersionsPayload.self, from: Fixtures.osVersionsJSON)
        #expect(payload.apple?.latest?.version == "26.6.2")
        #expect(payload.apple?.latestMajor == 26)
        #expect(payload.totals?.onLatest == 412)
        #expect(payload.totals?.hwCapped == 22)
        #expect(payload.offline?.inventory == 30)
    }

    @Test func productivityDecodes() throws {
        let summary = try Fixtures.decode(ProductivitySummary.self, from: Fixtures.productivitySummaryJSON)
        #expect(summary.cards.count == 5)
        #expect(summary.totals?.openTotal == 37)
        #expect(summary.cacheAgeMinutes == 2.5)

        let team = try Fixtures.decode(TeamPayload.self, from: Fixtures.teamJSON)
        #expect(team.members.count == 3)
        #expect(team.members[0].displayName == "Chad")
        #expect(team.members[0].counts?.openTotal == 11)
        #expect(team.members[1].counts?.staleAsana == 0)
        #expect(team.weekStart == "2026-08-31")
    }

    @Test func unknownKeysAreIgnored() throws {
        let json = """
        {"email": "chad@atlascarolina.com", "admin": true, "something_new": {"nested": 1}}
        """
        let me = try Fixtures.decode(AccessMe.self, from: json)
        #expect(me.email == "chad@atlascarolina.com")
        #expect(me.admin == true)
    }
}
