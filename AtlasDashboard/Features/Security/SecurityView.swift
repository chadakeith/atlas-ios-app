import SwiftUI

/// Navigation payload for a list of Macs behind one security finding.
struct SecurityFindingRoute: Hashable {
    let title: String
    let tenant: String
    let computers: [SecurityComputer]
}

struct SecurityView: View {
    @Environment(AppModel.self) private var model
    @State private var state: LoadState<SecurityPayload> = .idle

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            RemoteContent(state: state, retry: { await load(force: false) }) { payload in
                List {
                    Section {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(SecurityCheck.all) { check in
                                let count = payload[keyPath: check.total]
                                StatCard(label: check.label, value: Formatting.count(count), tint: .severity(count))
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } header: {
                        Text("Fleet-wide")
                    } footer: {
                        if let fleet = payload.totalFleet {
                            Text("Across \(fleet.formatted()) Macs in Jamf Pro. Missing and inventory Macs are excluded.")
                        }
                    }

                    Section("By client") {
                        ForEach(payload.tenants.sorted { $0.findings > $1.findings }) { tenant in
                            NavigationLink(value: tenant) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(tenant.tenant).font(.headline)
                                        if let error = tenant.error, !error.isEmpty {
                                            Text(error).font(.caption).foregroundStyle(.orange).lineLimit(1)
                                        } else if let fleet = tenant.fleet {
                                            Text("\(fleet.formatted()) Macs").font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(tenant.findings.formatted())
                                        .font(.title3.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(Color.severity(tenant.findings))
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Security")
            .navigationDestination(for: SecurityTenant.self) { tenant in
                SecurityTenantView(tenant: tenant)
            }
            .navigationDestination(for: SecurityFindingRoute.self) { route in
                SecurityFindingView(route: route)
            }
            .toolbar { DashboardToolbar { await load(force: true) } }
            .refreshable { await load(force: false) }
            .task(id: model.sessionGeneration) { await load(force: false) }
        }
    }

    private func load(force: Bool) async {
        if !state.isLoaded || force { state = .loading }
        do {
            state = .loaded(try await model.api.security(force: force))
        } catch {
            state = .failed(error)
            model.handle(error)
        }
    }
}

struct SecurityTenantView: View {
    let tenant: SecurityTenant

    var body: some View {
        List {
            if let error = tenant.error, !error.isEmpty {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
            Section {
                ForEach(SecurityCheck.all) { check in
                    let metric = tenant[keyPath: check.metric]
                    let count = metric?.count
                    if let count, count > 0, let computers = metric?.computers, !computers.isEmpty {
                        NavigationLink(value: SecurityFindingRoute(title: check.label, tenant: tenant.tenant, computers: computers)) {
                            checkRow(check, count: count)
                        }
                    } else {
                        checkRow(check, count: count)
                    }
                }
            } footer: {
                if let fleet = tenant.fleet {
                    Text("\(fleet.formatted()) Macs in this tenant. A dash means the smart group is not configured.")
                }
            }
        }
        .navigationTitle(tenant.tenant)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func checkRow(_ check: SecurityCheck, count: Int?) -> some View {
        HStack {
            Label(check.label, systemImage: check.systemImage)
            Spacer()
            Text(Formatting.count(count))
                .monospacedDigit()
                .foregroundStyle(Color.severity(count))
        }
    }
}

struct SecurityFindingView: View {
    let route: SecurityFindingRoute

    var body: some View {
        List(route.computers) { computer in
            VStack(alignment: .leading, spacing: 2) {
                Text(computer.displayName).font(.headline)
                HStack {
                    if let serial = computer.serial, !serial.isEmpty {
                        Text(serial).font(.system(.subheadline, design: .monospaced))
                    }
                    Spacer()
                    Text("seen \(Formatting.relative(computer.lastCheckinDate))")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(route.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            Text("\(route.tenant) · \(route.computers.count) Macs")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(.bar)
        }
    }
}

#if DEBUG
#Preview {
    SecurityView()
        .environment(AppModel(defaults: .preview))
}
#endif
