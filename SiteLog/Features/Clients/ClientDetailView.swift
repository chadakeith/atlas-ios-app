import SwiftUI

struct ClientDetailView: View {
    var client: Client

    @State private var isEditing = false
    @State private var isAddingDevice = false
    @State private var isStartingVisit = false

    private var sortedVisits: [Visit] {
        client.visits.sorted { $0.startedAt > $1.startedAt }
    }

    private var sortedDevices: [Device] {
        client.devices.sorted { $0.addedAt > $1.addedAt }
    }

    var body: some View {
        List {
            Section {
                if !client.contactName.isEmpty {
                    LabeledContent("Contact", value: client.contactName)
                }
                if !client.contactEmail.isEmpty {
                    LabeledContent("Email", value: client.contactEmail)
                }
                if !client.phone.isEmpty {
                    LabeledContent("Phone", value: client.phone)
                }
                if !client.address.isEmpty {
                    LabeledContent("Address", value: client.address)
                }
                LabeledContent("Rate", value: "\(Formatters.money(client.hourlyRate)) per hour")
                LabeledContent("Rounding", value: "Up to \(client.billingIncrementMinutes) min")
            }

            Section("Totals") {
                LabeledContent("Visits", value: "\(client.visits.count)")
                LabeledContent("Time on site", value: Formatters.hours(client.totalSeconds()))
                LabeledContent("Billable", value: Formatters.money(client.totalAmount()))
            }

            Section("Visits") {
                if sortedVisits.isEmpty {
                    Text("No visits yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(sortedVisits) { visit in
                    NavigationLink(value: visit) {
                        VisitRow(visit: visit)
                    }
                }
            }

            Section("Devices") {
                if sortedDevices.isEmpty {
                    Text("No devices yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(sortedDevices) { device in
                    NavigationLink(value: device) {
                        DeviceRow(device: device)
                    }
                }
            }

            if !client.notes.isEmpty {
                Section("Notes") {
                    Text(client.notes)
                }
            }
        }
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Start visit", systemImage: "play.fill") {
                        isStartingVisit = true
                    }
                    .disabled(client.hasActiveVisit)

                    Button("Add device", systemImage: "plus.viewfinder") {
                        isAddingDevice = true
                    }

                    Button("Edit client", systemImage: "pencil") {
                        isEditing = true
                    }

                    Divider()

                    ShareLink(
                        item: CSVFile(
                            fileName: "\(client.name) visits.csv",
                            text: CSVExporter.visitsCSV(for: client)
                        ),
                        preview: SharePreview("\(client.name) visits", image: Image(systemName: "tablecells"))
                    ) {
                        Label("Export visits as CSV", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            ClientEditorView(client: client)
        }
        .sheet(isPresented: $isAddingDevice) {
            NewDeviceSheet(client: client)
        }
        .sheet(isPresented: $isStartingVisit) {
            StartVisitSheet(preselectedClient: client)
        }
    }
}
