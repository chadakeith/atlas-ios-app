# SiteLog

**The on-site visit logger for IT consultants and field techs.**

Tap *Start* when you walk in the door. SiteLog runs the clock, tags the visit
with the site, and lets you scan device serial numbers off the back of a Mac
while you work. Tap *End* on the way out. Every visit is priced against the
client's hourly rate and billing increment, and the whole history exports as
CSV for invoicing.

Built with SwiftUI and SwiftData for iOS 17+. No accounts, no server. Your
data stays on your phone.

See [docs/BRAINSTORM.md](docs/BRAINSTORM.md) for how this idea was chosen over
the alternatives.

## What is in v0.1

| Area | Status |
|------|--------|
| Clients with contact info, hourly rate, and billing increment (1–60 min) | ✅ |
| Start / end visits with a live timer, summary, notes, billable toggle | ✅ |
| Automatic location tag (when-in-use permission, one fix per visit) | ✅ |
| Devices per client, serial scan via VisionKit Live Text and barcodes | ✅ |
| Serial cleanup (barcode "S" prefix, "Serial:" labels, casing) | ✅ |
| Per-client totals and CSV export through the share sheet | ✅ |
| Unit tests for billing math, serial normalization, CSV escaping | ✅ |
| GitHub Actions build + test on an iOS simulator | ✅ |

## Open it

Requirements: macOS with **Xcode 16 or newer** (the project uses Xcode 16's
folder-synchronized groups, so new Swift files you drop into `SiteLog/` are
picked up automatically).

```bash
git clone https://github.com/chadakeith/atlas-ios-app.git
cd atlas-ios-app
open SiteLog.xcodeproj
```

1. Select the **SiteLog** scheme and an iPhone simulator, press **Run**.
2. To run on a real phone (needed for the camera scanner and location), open
   the SiteLog target → *Signing & Capabilities* and pick your Team. Xcode
   will register the bundle ID `com.atlascarolina.SiteLog` for you.
3. **⌘U** runs the unit tests.

The camera scanner falls back to a typed serial field on the simulator.

If the `.xcodeproj` ever gets mangled, `project.yml` regenerates it with
[XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen && xcodegen`.

## Layout

```
SiteLog/
  App/            SiteLogApp (entry point), RootView (tab bar)
  Models/         Client, Visit, Device  (SwiftData @Model)
  Features/
    Visits/       Timer card, start sheet, visit list and detail
    Clients/      Client list, detail with totals + CSV export, editor
    Devices/      Device list, form, VisionKit serial scanner
  Services/       LocationService, CSVExporter, CSVFile (Transferable)
  Support/        Formatters, SerialNumber normalizer, preview data
SiteLogTests/     Swift Testing suites
```

## Roadmap

**v0.2 – make it yours**
- App icon and launch polish
- Site info per client: Wi-Fi, ISP, door codes, key contacts (the "Runbook" idea)
- Photo attachments on visits
- Mileage per visit from the location tag

**v0.3 – get paid**
- PDF visit report / invoice-ready summary
- QuickBooks Online: push a visit as an invoice line
- iCloud sync via CloudKit (SwiftData makes this a one-line change once the
  schema is stable)

**v1.0 – App Store**
- Free tier: 2 clients. Pro unlock (one-time purchase) for unlimited clients
  and export
- Privacy nutrition labels: Camera (device scanning), Location (visit tagging),
  nothing leaves the device
- TestFlight with a handful of MSP friends first

## Shipping checklist

- [ ] Enroll in the Apple Developer Program ($99/yr) at developer.apple.com
- [ ] Set your Team in Signing & Capabilities
- [ ] Add a 1024×1024 app icon to `SiteLog/Assets.xcassets/AppIcon.appiconset`
- [ ] Create the app record in App Store Connect with bundle ID `com.atlascarolina.SiteLog`
- [ ] Product → Archive → Distribute to TestFlight
- [ ] Screenshots (6.7" and 6.1" iPhone), description, keywords, privacy answers
- [ ] Submit for review
