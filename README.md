# Atlas Dashboard for iOS

A native iPhone and iPad companion to **dashboard.atlassolutions.tech**. It reads
the same JSON endpoints the web dashboard uses and shows the numbers the team
checks most, with pull-to-refresh and a "recompute on server" action.

| Tab | What it shows | Endpoints |
|-----|---------------|-----------|
| **Overview** | Fleet health %, open issues with weekly delta, the six hero metrics, 30-day trend | `/overview` |
| **Missing** | Macs and iOS devices in each client's Missing smart group, searchable, with detail and copy-serial | `/missing-macs`, `/missing-devices` |
| **Security** | Protect / Trust / Connect gaps, FileVault, bootstrap and secure token, per client with drill-down to the Macs | `/security` |
| **Fleet** | Mac lifecycle tiers (3+/4+/5+ years) per client, macOS version compliance vs Apple's current release | `/lifecycle-macs`, `/os-versions` |
| **Team** | Productivity board: open tickets and Asana tasks per person, closed today and this week | `/productivity/api/summary`, `/productivity/api/team` |

Built with SwiftUI, Swift Charts, and `URLSession`. No SDKs, no backend of its own.
iOS 17+.

## How sign-in works

The dashboard server has no auth of its own; the host is protected by a Google
login in front of it (Cloudflare Access or oauth2-proxy). The app handles that
two ways:

1. **Browser sign-in (default).** Settings → *Sign in with Google* opens the
   dashboard in an embedded web view. When the dashboard page loads, the app
   copies the session cookies into `URLSession` and closes the sheet. Every
   JSON call then rides on that cookie until it expires, at which point the
   sign-in prompt comes back.
2. **Cloudflare Access service token (optional).** If the host is behind
   Cloudflare Access, create a service token (Zero Trust → Access → Service
   Auth) and paste the Client ID / Secret in Settings. The app sends them as
   `CF-Access-Client-Id` / `CF-Access-Client-Secret` headers and never needs the
   browser. The token is stored in the Keychain.

If a JSON request comes back as HTML, lands on another host, or returns 401/403,
the app treats it as "signed out" rather than a decode error.

## Open it

Requirements: macOS with **Xcode 16 or newer**.

```bash
git clone https://github.com/chadakeith/atlas-ios-app.git
cd atlas-ios-app
open AtlasDashboard.xcodeproj
```

1. Select the **AtlasDashboard** scheme and an iPhone simulator, press **Run**.
2. Tap the ⋯ menu → **Settings**, confirm the server address, then **Sign in with Google**.
3. For a real device, open the AtlasDashboard target → *Signing & Capabilities*
   and pick your Team. Bundle ID: `com.atlascarolina.AtlasDashboard`.
4. **⌘U** runs the unit tests (payload decoding, login-wall detection, URL
   building, epoch handling).

If the `.xcodeproj` ever gets mangled, `project.yml` regenerates it with
[XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen && xcodegen`.

## Layout

```
AtlasDashboard/
  App/          AtlasDashboardApp (entry), RootView (tab bar + sheets)
  Core/         AppModel (settings, session), DashboardAPI (client), Keychain, LoadState
  Models/       Codable payloads: Overview, Devices, Security, Fleet, Productivity
  Features/     One folder per tab, plus Settings (SettingsView, SignInView)
  Support/      Formatting, StatCard/DeltaBadge, sample Fixtures for previews and tests
AtlasDashboardTests/
docs/BRAINSTORM.md   Idea shortlist, why this one, and where the earlier SiteLog scaffold lives (commit 67ed683)
```

Sample payloads in `Support/Fixtures.swift` mirror the shapes in
`atlas_dashboard_server.py`, so previews work without a network and the tests
catch decoding regressions when an endpoint changes.

## Roadmap

**v0.2**
- Inventory and Unassigned tabs (`/inventory`, `/unassigned`, and device variants)
- Contract audit summary (`/audit-data`) with the stale-summaries banner
- Home Screen widget with health % and open issues (needs a shared App Group for the cookie)
- App icon

**v0.3**
- Push a device to the Jamf web console from the detail screen (per-tenant URL is in the payload)
- Collab notes on devices (`/collab-notes`), read then write
- Security exceptions view

**Distribution**
- Internal use only: TestFlight is enough (up to 100 internal testers, no App Review).
- If it ever goes to the public App Store, the sign-in will need the dashboard to
  expose an OAuth flow with a redirect URI, since Apple frowns on embedded Google login.

## Shipping checklist

- [ ] Apple Developer Program at developer.apple.com
- [ ] Set your Team in Signing & Capabilities
- [ ] 1024×1024 icon into `AtlasDashboard/Assets.xcassets/AppIcon.appiconset`
- [ ] App record in App Store Connect with bundle ID `com.atlascarolina.AtlasDashboard`
- [ ] Product → Archive → Distribute to TestFlight → add the team as internal testers
