import SwiftUI

/// Lifecycle (Mac age tiers) and macOS version compliance.
struct FleetView: View {
    @Environment(AppModel.self) private var model
    @State private var lifecycle: LoadState<LifecyclePayload> = .idle
    @State private var versions: LoadState<OSVersionsPayload> = .idle

    private let three = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    private let two = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    InlineState(state: lifecycle, retry: { await loadLifecycle(force: false) }) { payload in
                        LazyVGrid(columns: three, spacing: 10) {
                            StatCard(label: "3+ years", value: Formatting.count(payload.total3Yr), tint: .yellow)
                            StatCard(label: "4+ years", value: Formatting.count(payload.total4Yr), tint: .orange)
                            StatCard(label: "5+ years", value: Formatting.count(payload.total5Yr), tint: .red)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                        ForEach(payload.tenants) { tenant in
                            NavigationLink(value: tenant) {
                                HStack {
                                    Text(tenant.tenant)
                                    Spacer()
                                    tierChips(tenant)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Mac lifecycle")
                } footer: {
                    Text("Age from the ABM order date. Macs age out of the managed fleet at 5 years.")
                }

                Section {
                    InlineState(state: versions, retry: { await loadVersions(force: false) }) { payload in
                        if let latest = payload.apple?.latest?.version {
                            LabeledContent("Apple's current macOS", value: latest)
                        }
                        if let totals = payload.totals {
                            LazyVGrid(columns: two, spacing: 10) {
                                StatCard(label: "On latest", value: Formatting.count(totals.onLatest), tint: .green)
                                StatCard(label: "Behind on patches", value: Formatting.count(totals.behindPatch), hint: "Current major, older point release", tint: .yellow)
                                StatCard(label: "On old macOS", value: Formatting.count(totals.oldMajor), hint: "Hardware can go newer", tint: .red)
                                StatCard(label: "Hardware-capped", value: Formatting.count(totals.hwCapped), hint: "Newest macOS the hardware supports", tint: .purple)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            if let unknown = totals.unknown, unknown > 0 {
                                LabeledContent("Unknown version", value: unknown.formatted())
                            }
                        }
                        if let offline = payload.offline {
                            LabeledContent("Excluded (missing / inventory)", value: "\(Formatting.count(offline.missing)) / \(Formatting.count(offline.inventory))")
                        }
                    }
                } header: {
                    Text("macOS versions")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Fleet")
            .navigationDestination(for: LifecycleTenant.self) { tenant in
                LifecycleTenantView(tenant: tenant)
            }
            .toolbar {
                DashboardToolbar {
                    await loadLifecycle(force: true)
                    await loadVersions(force: true)
                }
            }
            .refreshable {
                await loadLifecycle(force: false)
                await loadVersions(force: false)
            }
            .task(id: model.sessionGeneration) {
                await loadLifecycle(force: false)
                await loadVersions(force: false)
            }
        }
    }

    private func tierChips(_ tenant: LifecycleTenant) -> some View {
        HStack(spacing: 6) {
            chip(tenant.threeYear?.count, .yellow)
            chip(tenant.fourYear?.count, .orange)
            chip(tenant.fiveYear?.count, .red)
        }
        .font(.caption.weight(.semibold))
        .monospacedDigit()
    }

    private func chip(_ count: Int?, _ color: Color) -> some View {
        Text(Formatting.count(count))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(color.opacity(count ?? 0 > 0 ? 0.18 : 0.06), in: Capsule())
            .foregroundStyle(count ?? 0 > 0 ? color : .secondary)
    }

    private func loadLifecycle(force: Bool) async {
        if !lifecycle.isLoaded || force { lifecycle = .loading }
        do { lifecycle = .loaded(try await model.api.lifecycle(force: force)) } catch { lifecycle = .failed(error); model.handle(error) }
    }

    private func loadVersions(force: Bool) async {
        if !versions.isLoaded || force { versions = .loading }
        do { versions = .loaded(try await model.api.osVersions(force: force)) } catch { versions = .failed(error); model.handle(error) }
    }
}

struct LifecycleTenantView: View {
    let tenant: LifecycleTenant

    var body: some View {
        List {
            tier("5+ years", tenant.fiveYear, .red)
            tier("4+ years", tenant.fourYear, .orange)
            tier("3+ years", tenant.threeYear, .yellow)
            if let error = tenant.error, !error.isEmpty {
                Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
            }
        }
        .navigationTitle(tenant.tenant)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func tier(_ title: String, _ tier: LifecycleTier?, _ color: Color) -> some View {
        let macs = tier?.computers ?? []
        if !macs.isEmpty {
            Section {
                ForEach(macs.sorted { ($0.ageMonths ?? 0) > ($1.ageMonths ?? 0) }) { mac in
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mac.displayName).font(.headline)
                            Text([mac.serial, mac.building].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Formatting.months(mac.ageMonths))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(color)
                            if let next = mac.nextTier {
                                Text(next == "overdue" ? "past 5 yr" : "\(Formatting.months(mac.monthsToNext)) to 5 yr")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text(title)
                    Spacer()
                    Text(macs.count.formatted()).monospacedDigit()
                }
            }
        }
    }
}

/// `RemoteContent` for a single `List` section: keeps the rest of the list usable
/// while one data source loads or fails.
struct InlineState<Value, Content: View>: View {
    @Environment(AppModel.self) private var model

    let state: LoadState<Value>
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            HStack {
                ProgressView()
                Text("Loading…").foregroundStyle(.secondary)
            }
        case .failed(let error):
            if let apiError = error as? APIError, case .needsSignIn = apiError {
                Button("Sign in to load", systemImage: "person.badge.key") { model.isShowingSignIn = true }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Retry") { Task { await retry() } }
                        .font(.footnote)
                }
            }
        case .loaded(let value):
            content(value)
        }
    }
}

#if DEBUG
#Preview {
    FleetView()
        .environment(AppModel(defaults: .preview))
}
#endif
