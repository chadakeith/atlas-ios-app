# App brainstorm

> **Decision (2026-09-05):** we are building the **Atlas Dashboard companion app**
> first: a native front end for the existing dashboard.atlassolutions.tech
> service. It is simpler than any idea below (no data model of its own, no
> server work), it is useful on day one to the whole Atlas team, and it exercises
> the same iOS skills (networking, auth, SwiftUI, charts) that a later public app
> would need. The SiteLog scaffold from the first pass is preserved at commit
> `67ed683` (`git checkout 67ed683`), tagged locally as `sitelog-scaffold`.


Goal: a genuinely useful iOS app that one person can build, ship to the App Store,
and keep improving. Scored 1–5 on the things that actually predict an indie app
getting finished and used.

| # | Idea | Useful | Differentiated | Solo-buildable | Will people pay | Fits Chad's expertise | Total |
|---|------|:-----:|:--------------:|:--------------:|:---------------:|:---------------------:|:-----:|
| 1 | **SiteLog** – on-site visit logger for IT consultants and field techs | 5 | 4 | 5 | 5 | 5 | **24** |
| 2 | Warranty Wallet – photograph receipts, track warranty and return windows | 4 | 2 | 5 | 3 | 2 | 16 |
| 3 | Fleet Pocket – read-only Jamf Pro companion (search devices, view inventory) | 4 | 3 | 3 | 3 | 5 | 18 |
| 4 | Cooldown – 48-hour "buy later" list fed by the Share Sheet | 3 | 3 | 5 | 2 | 1 | 14 |
| 5 | Runbook – offline client documentation (networks, passwords vault, procedures) | 4 | 2 | 3 | 4 | 5 | 18 |
| 6 | Pantry Clock – expiry tracking for groceries | 3 | 1 | 4 | 2 | 1 | 11 |

## Why SiteLog wins

- **Real pain, paid for.** Solo consultants and small MSP techs bill by the visit
  and lose money to sloppy time capture. Most track it in Notes or memory and
  reconstruct it at invoice time.
- **Domain advantage.** Chad lives this workflow (Apple fleet consulting), so
  feature decisions come from experience rather than guesswork, and the first
  users are people he already knows.
- **No backend needed for v1.** SwiftData on-device, iCloud sync later via
  CloudKit. That removes the biggest cause of abandoned indie apps: servers.
- **Native superpowers.** VisionKit reads serial-number labels off the back of a
  Mac or a box in one tap. Core Location tags the visit with the site. Nothing
  a web app can do as well.
- **Clear upgrade path.** Free: 2 clients. Pro (one-time or yearly): unlimited
  clients, CSV/PDF export, QuickBooks invoice push. The QuickBooks angle is a
  natural fit for Atlas Carolina's own bookkeeping.

## Runner-up worth revisiting

**Runbook** could be folded into SiteLog later as a "Site info" tab per client
(Wi-Fi, ISP, key contacts, door codes). It is the same audience, and the two
together look like a small vertical toolkit rather than a timer app.

## Ideas rejected quickly

- Anything requiring a marketplace or two-sided network (needs users on both
  sides on day one).
- Jamf write operations from a phone (support burden, easy to cause real
  damage, Jamf ships its own app).
- Consumer productivity in crowded categories (habits, to-dos, budgeting)
  without a specific wedge.
