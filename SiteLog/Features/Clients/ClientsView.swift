import SwiftData
import SwiftUI

struct ClientsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Client.name) private var clients: [Client]

    @State private var isAddingClient = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(clients) { client in
                    NavigationLink(value: client) {
                        ClientRow(client: client)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(clients[index])
                    }
                }
            }
            .overlay {
                if clients.isEmpty {
                    ContentUnavailableView(
                        "No clients yet",
                        systemImage: "building.2",
                        description: Text("Add the sites you visit. Each client keeps its own rate, visits, and devices.")
                    )
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add client", systemImage: "plus") {
                        isAddingClient = true
                    }
                }
            }
            .navigationDestination(for: Client.self) { client in
                ClientDetailView(client: client)
            }
            .navigationDestination(for: Visit.self) { visit in
                VisitDetailView(visit: visit)
            }
            .navigationDestination(for: Device.self) { device in
                DeviceDetailView(device: device)
            }
            .sheet(isPresented: $isAddingClient) {
                ClientEditorView()
            }
        }
    }
}

struct ClientRow: View {
    let client: Client

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if client.hasActiveVisit {
                Image(systemName: "record.circle.fill")
                    .foregroundStyle(.red)
                    .accessibilityLabel("Visit in progress")
            }
        }
    }

    private var subtitle: String {
        let visits = client.visits.count
        let devices = client.devices.count
        return "\(visits) visit\(visits == 1 ? "" : "s") · \(devices) device\(devices == 1 ? "" : "s")"
    }
}

#if DEBUG
#Preview {
    ClientsView()
        .modelContainer(PreviewData.container)
}
#endif
