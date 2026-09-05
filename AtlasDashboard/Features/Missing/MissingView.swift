import SwiftUI
import UIKit

struct MissingView: View {
    enum Kind: String, CaseIterable, Identifiable {
        case macs = "Macs"
        case mobile = "iPhone & iPad"
        var id: String { rawValue }
    }

    @Environment(AppModel.self) private var model
    @State private var kind: Kind = .macs
    @State private var macs: LoadState<[DeviceSection]> = .idle
    @State private var mobile: LoadState<[DeviceSection]> = .idle
    @State private var search = ""

    private var current: LoadState<[DeviceSection]> { kind == .macs ? macs : mobile }

    var body: some View {
        NavigationStack {
            RemoteContent(state: current, retry: { await load(kind, force: false) }) { sections in
                let visible = sections.filtered(by: search)
                List {
                    if search.isEmpty {
                        Section {
                            LabeledContent("Total missing", value: sections.totalCount.formatted())
                            let failures = sections.filter { $0.error != nil }.count
                            if failures > 0 {
                                LabeledContent("Clients not reachable", value: failures.formatted())
                                    .foregroundStyle(.orange)
                            }
                        } footer: {
                            Text("Devices in each client's Missing smart group: no check-in for over two weeks.")
                        }
                    }

                    ForEach(visible) { section in
                        Section {
                            if let error = section.error, section.items.isEmpty {
                                Label(error, systemImage: "exclamationmark.triangle")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else if section.items.isEmpty {
                                Text("Nothing missing")
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(section.items) { device in
                                NavigationLink(value: device) {
                                    DeviceRow(device: device)
                                }
                            }
                        } header: {
                            HStack {
                                Text(section.tenant)
                                Spacer()
                                Text(Formatting.count(section.count ?? section.items.count))
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $search, prompt: "Name, serial, user, or site")
                .overlay {
                    if visible.isEmpty && !search.isEmpty {
                        ContentUnavailableView.search(text: search)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Device type", selection: $kind) {
                    ForEach(Kind.allCases) { kind in
                        Text(kind.rawValue).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("Missing")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ManagedDevice.self) { device in
                DeviceDetailView(device: device)
            }
            .toolbar { DashboardToolbar { await load(kind, force: true) } }
            .refreshable { await load(kind, force: false) }
            .task(id: model.sessionGeneration) {
                await load(.macs, force: false)
                await load(.mobile, force: false)
            }
        }
    }

    private func load(_ kind: Kind, force: Bool) async {
        switch kind {
        case .macs:
            if !macs.isLoaded || force { macs = .loading }
            do { macs = .loaded(try await model.api.missingMacs(force: force)) } catch { macs = .failed(error); model.handle(error) }
        case .mobile:
            if !mobile.isLoaded || force { mobile = .loading }
            do { mobile = .loaded(try await model.api.missingDevices(force: force)) } catch { mobile = .failed(error); model.handle(error) }
        }
    }
}

struct DeviceRow: View {
    let device: ManagedDevice

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatting.relative(device.lastCheckinDate))
                    .font(.subheadline)
                    .monospacedDigit()
                if let mdm = device.mdm, !mdm.isEmpty {
                    Text(mdm)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var subtitle: String {
        [device.model, device.username].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · ")
    }
}

struct DeviceDetailView: View {
    let device: ManagedDevice

    var body: some View {
        List {
            Section {
                row("Serial", device.serial, monospaced: true)
                row("Model", device.model)
                row("User", device.username)
                LabeledContent("Last check-in", value: checkin)
                row("Managed by", device.mdm)
            }
            Section("Location") {
                row("Building", device.building)
                row("Inventory location", device.location)
                row("Ordered", device.orderDate)
            }
            if let notes = device.notes, !notes.isEmpty {
                Section("Notes") { Text(notes) }
            }
        }
        .navigationTitle(device.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let serial = device.serial, !serial.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("Copy serial", systemImage: "doc.on.doc") {
                        UIPasteboard.general.string = serial
                    }
                }
            }
        }
    }

    private var checkin: String {
        guard let date = device.lastCheckinDate else { return "Never" }
        return "\(date.formatted(date: .abbreviated, time: .shortened)) (\(Formatting.relative(date)))"
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String?, monospaced: Bool = false) -> some View {
        if let value, !value.isEmpty {
            LabeledContent(label) {
                Text(value)
                    .font(monospaced ? .system(.body, design: .monospaced) : .body)
                    .textSelection(.enabled)
            }
        }
    }
}

#if DEBUG
#Preview {
    MissingView()
        .environment(AppModel(defaults: .preview))
}
#endif
