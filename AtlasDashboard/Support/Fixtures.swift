#if DEBUG
import Foundation

/// Realistic sample payloads (shapes copied from atlas_dashboard_server.py) used by
/// previews and unit tests. Names are invented.
enum Fixtures {
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    static func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }

    static let overviewJSON = """
    {
      "total": 41, "missing": 17, "missing_macs": 12, "missing_ios": 5,
      "delta_week": -6, "since": "2026-08-29",
      "completed_today": 2, "completed_week": 9,
      "health_pct": 96, "total_devices": 1084,
      "metrics": [
        {"key": "missing_macs", "label": "Missing Computers", "hint": "Macs in the Missing Mac smart group", "tab": "missing", "mode": "mac", "count": 12, "delta": -3},
        {"key": "missing_ios", "label": "Missing iOS", "hint": "iPads / iPhones in the Missing Devices smart group", "tab": "missing", "mode": "device", "count": 5, "delta": 1},
        {"key": "security_agents", "label": "Jamf Agents", "hint": "Protect / Trust / Connect not installed", "tab": "security", "mode": "agents", "count": 9, "delta": -2},
        {"key": "security_posture", "label": "Mac Security", "hint": "FileVault, bootstrap token, secure token", "tab": "security", "mode": "posture", "count": 7, "delta": 0},
        {"key": "audit", "label": "Contract Audit Issues", "hint": "Clients with a contract issue on the Audit page", "tab": "audit", "count": 4, "delta": -1},
        {"key": "audit_software", "label": "Software Audit Issues", "hint": "Clients with device-coverage gaps", "tab": "audit", "mode": "software", "count": 4, "delta": null}
      ],
      "context": [],
      "history": [
        {"date": "2026-08-27", "total": 52}, {"date": "2026-08-28", "total": 50}, {"date": "2026-08-29", "total": 47},
        {"date": "2026-08-30", "total": 47}, {"date": "2026-08-31", "total": 45}, {"date": "2026-09-01", "total": 46},
        {"date": "2026-09-02", "total": 44}, {"date": "2026-09-03", "total": 43}, {"date": "2026-09-04", "total": 42},
        {"date": "2026-09-05", "total": 41}
      ],
      "month_churn": {"added": 6, "removed": 2},
      "generated_at": "2026-09-05 06:12:44"
    }
    """

    static let missingMacsJSON = """
    {
      "tenants": [
        {"tenant": "Atlas", "count": 2, "error": null, "url": "https://ckeith.jamfcloud.com", "computers": [
          {"name": "ATL-MBP-014", "serial": "C02XG1ABJGH5", "model": "MacBook Pro (14-inch, 2023)", "username": "jordan.lee", "last_checkin": 1755561600000, "location": "", "notes": "", "building": "Raleigh HQ", "order_date": "2023-04-12", "mdm": "Jamf"},
          {"name": "ATL-MBA-003", "serial": "SJQ4K7PLM2", "model": "MacBook Air (13-inch, M2, 2022)", "username": "", "last_checkin": 1754000000000, "location": "Shelf B", "notes": "Loaner", "building": "", "order_date": "", "mdm": "Jamf + Addigy"}
        ]},
        {"tenant": "DebtBook", "count": 1, "error": null, "computers": [
          {"name": "DB-LAPTOP-221", "serial": "FVFXK2Q3M9", "model": "MacBook Pro (16-inch, 2021)", "username": "sam.p", "last_checkin": 1756000000000, "location": "", "notes": "", "building": "", "order_date": "2021-11-02", "mdm": "Jamf"}
        ]},
        {"tenant": "C-Telco", "count": null, "error": "401 Unauthorized", "computers": []},
        {"tenant": "LIFE Fellowship", "count": 1, "error": null, "source": "addigy", "computers": [
          {"name": "Office iMac", "serial": "C02ZW0ABCDEF", "model": "iMac 24-inch", "username": "frontdesk", "last_checkin": 1755000000, "location": "", "notes": "", "building": "", "order_date": "", "mdm": "Addigy", "source": "addigy"}
        ]}
      ],
      "total": 4
    }
    """

    static let missingDevicesJSON = """
    {
      "tenants": [
        {"tenant": "Project Hope", "count": 2, "error": null, "devices": [
          {"name": "Classroom iPad 07", "serial": "DMPZ1ABCDEF", "model": "iPad (9th generation)", "username": "", "last_checkin": 1755561600000, "location": "Cart 2", "notes": "", "building": "Main", "order_date": "2022-08-15", "mdm": "Jamf"},
          {"name": "Nurse iPhone", "serial": "F2LZ9ABCDEF", "model": "iPhone 14", "username": "nurse", "last_checkin": 0, "location": "", "notes": "Lost?", "building": "", "order_date": "", "mdm": "Jamf"}
        ]},
        {"tenant": "Atlas", "count": 0, "error": null, "devices": []}
      ],
      "total": 2
    }
    """

    static let securityJSON = """
    {
      "total_protect": 6, "total_trust": 11, "total_connect": 3, "total_fleet": 612,
      "total_protect_active": 590, "total_protect_silent": 4, "total_trust_active": 580, "total_trust_silent": 2,
      "total_fv_off": 5, "total_fv_key": 2, "total_bootstrap": 3, "total_secure_token": 1,
      "tenants": [
        {"tenant": "Atlas", "url": "https://ckeith.jamfcloud.com", "fleet": 44,
         "protect": {"count": 1, "computers": [{"id": 12, "name": "ATL-MBP-002", "serial": "C02AAA111222", "last_checkin": 1756100000000}], "source": "smart_group", "group": "Jamf Protect Not Installed"},
         "protect_silent": {"count": 0, "computers": [], "source": "smart_group"},
         "trust": {"count": 2, "computers": [{"id": 13, "name": "ATL-MBP-003", "serial": "C02BBB111222", "last_checkin": 1756100000000}, {"id": 14, "name": "ATL-MBA-009", "serial": "C02CCC111222", "last_checkin": 0}], "source": "smart_group"},
         "trust_silent": {"count": 0, "computers": [], "source": "smart_group"},
         "connect": {"count": null, "computers": [], "source": "not_applicable"},
         "fv_off": {"count": 1, "computers": [{"id": 20, "name": "ATL-IMAC-001", "serial": "C02DDD111222", "last_checkin": 1756100000000}], "source": "smart_group"},
         "fv_key": {"count": 0, "computers": [], "source": "smart_group"},
         "bootstrap": {"count": 0, "computers": [], "source": "smart_group"},
         "secure_token": {"count": 0, "computers": [], "source": "smart_group"},
         "error": null},
        {"tenant": "Heights", "url": "https://heightsphiladelphia.jamfcloud.com", "fleet": null,
         "protect": {"count": null, "computers": []}, "trust": {"count": null, "computers": []}, "connect": {"count": null, "computers": []},
         "fv_off": {"count": null, "computers": []}, "fv_key": {"count": null, "computers": []}, "bootstrap": {"count": null, "computers": []}, "secure_token": {"count": null, "computers": []},
         "error": "Timeout"}
      ]
    }
    """

    static let lifecycleJSON = """
    {
      "total_3yr": 38, "total_4yr": 21, "total_5yr": 14,
      "tenants": [
        {"tenant": "Atlas", "url": "https://ckeith.jamfcloud.com",
         "3yr": {"count": 1, "computers": [{"id": 31, "name": "ATL-MBP-010", "serial": "C02EEE111222", "anchor_epoch": 1651363200, "age_source": "abm_order_date", "age_months": 40.2, "building": "Raleigh HQ", "months_to_next": 19.8, "next_tier": "5yr"}]},
         "4yr": {"count": 0, "computers": []},
         "5yr": {"count": 1, "computers": [{"id": 32, "name": "ATL-IMAC-001", "serial": "C02DDD111222", "anchor_epoch": 1546300800, "age_source": "abm_order_date", "age_months": 63.4, "building": "", "months_to_next": 3.4, "next_tier": "overdue"}]},
         "error": null}
      ]
    }
    """

    static let osVersionsJSON = """
    {
      "apple": {"latest": {"version": "26.6.2", "build": "25G123", "posted": "2026-08-20"}, "latest_major": 26, "by_major": {"26": {"version": "26.6.2"}}},
      "totals": {"total": 598, "on_latest": 412, "behind_patch": 96, "old_major": 61, "hw_capped": 22, "unknown": 7},
      "majors": [],
      "offline": {"missing": 12, "inventory": 30, "devices": []}
    }
    """

    static let productivitySummaryJSON = """
    {
      "title": "Productivity Dashboard",
      "subtitle": "37 open across the team · 6 closed today · 28 closed this week",
      "sources": {"autotask": "live", "asana": "live"},
      "totals": {"open_tickets": 22, "open_tasks": 15, "open_total": 37, "opened_today": 4, "closed_today": 6, "closed_week": 28, "net_today": -2, "stale_asana": 3},
      "from_cache": true, "cache_age_minutes": 2.5, "last_updated": "2026-09-05T06:10:00-04:00",
      "cards": [
        {"id": "open_total", "label": "Open on plate", "value": 37, "hint": "22 Autotask · 15 Asana"},
        {"id": "open_tickets", "label": "Open tickets", "value": 22, "hint": "Autotask assigned"},
        {"id": "open_tasks", "label": "Open Asana", "value": 15, "hint": "Tasks assigned"},
        {"id": "closed_today", "label": "Closed today", "value": 6, "hint": "Tickets + tasks"},
        {"id": "closed_week", "label": "Closed this week", "value": 28, "hint": "Week of 2026-08-31"}
      ]
    }
    """

    static let teamJSON = """
    {
      "title": "Productivity Dashboard", "version": "1.9", "timezone": "America/New_York",
      "as_of": "2026-09-05T06:10:00-04:00", "week_start": "2026-08-31", "today": "2026-09-05",
      "sources": {"autotask": "live", "asana": "live"},
      "totals": {"open_tickets": 22, "open_tasks": 15, "open_total": 37, "closed_today": 6, "closed_week": 28, "net_today": -2, "stale_asana": 3},
      "members": [
        {"id": "chad", "name": "Chad", "email": "chad@atlascarolina.com", "counts": {"open_tickets": 5, "open_tasks": 6, "open_total": 11, "opened_today": 1, "closed_today": 2, "closed_week": 9, "net_today": -1, "stale_asana": 1}, "autotask": {"open": [], "closed_today": [], "closed_week": []}, "asana": {"open": [], "closed_today": [], "closed_week": []}},
        {"id": "grayson", "name": "Grayson", "counts": {"open_tickets": 8, "open_tasks": 3, "open_total": 11, "closed_today": 3, "closed_week": 10, "net_today": -2, "stale_asana": 0}},
        {"id": "marcus", "name": "Marcus", "counts": {"open_tickets": 9, "open_tasks": 6, "open_total": 15, "closed_today": 1, "closed_week": 9, "net_today": 1, "stale_asana": 2}}
      ]
    }
    """

    // Decoded conveniences for previews.
    static var overview: Overview { try! decode(Overview.self, from: overviewJSON) }
    static var missingMacs: [DeviceSection] { try! decode(ComputerSectionsPayload.self, from: missingMacsJSON).sections }
    static var missingDevices: [DeviceSection] { try! decode(MobileSectionsPayload.self, from: missingDevicesJSON).sections }
    static var security: SecurityPayload { try! decode(SecurityPayload.self, from: securityJSON) }
    static var lifecycle: LifecyclePayload { try! decode(LifecyclePayload.self, from: lifecycleJSON) }
    static var osVersions: OSVersionsPayload { try! decode(OSVersionsPayload.self, from: osVersionsJSON) }
    static var productivitySummary: ProductivitySummary { try! decode(ProductivitySummary.self, from: productivitySummaryJSON) }
    static var team: TeamPayload { try! decode(TeamPayload.self, from: teamJSON) }
}
#endif
