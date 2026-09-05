import SwiftData
import SwiftUI

struct StartVisitSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Client.name) private var clients: [Client]

    @State private var selectedClient: Client?
    @State private var isBillable = true
    @State private var tagLocation = true
    @State private var locationService = LocationService()

    private let preselectedClient: Client?

    init(preselectedClient: Client? = nil) {
        self.preselectedClient = preselectedClient
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Client", selection: $selectedClient) {
                        Text("Choose a client").tag(Client?.none)
                        ForEach(clients) { client in
                            Text(client.name).tag(Optional(client))
                        }
                    }
                }

                Section {
                    Toggle("Billable", isOn: $isBillable)
                    Toggle("Tag with my location", isOn: $tagLocation)
                } footer: {
                    if locationService.isDenied && tagLocation {
                        Text("Location access is off for SiteLog. Turn it on in Settings to tag visits automatically.")
                    }
                }
            }
            .navigationTitle("Start visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { start() }
                        .disabled(selectedClient == nil)
                }
            }
            .onAppear {
                if selectedClient == nil {
                    selectedClient = preselectedClient ?? clients.first
                }
            }
        }
    }

    private func start() {
        guard let client = selectedClient else { return }
        let visit = Visit(client: client, isBillable: isBillable)
        context.insert(visit)
        dismiss()

        guard tagLocation else { return }
        let service = locationService
        Task {
            guard let fix = await service.currentFix() else { return }
            visit.latitude = fix.coordinate.latitude
            visit.longitude = fix.coordinate.longitude
            visit.locationLabel = fix.label
        }
    }
}
