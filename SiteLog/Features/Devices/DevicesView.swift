import SwiftData
import SwiftUI

struct DevicesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Device.addedAt, order: .reverse) private var devices: [Device]

    @State private var searchText = ""
    @State private var isAddingDevice = false

    private var filteredDevices: [Device] {
        let query = searchText.trimmed
        guard !query.isEmpty else { return devices }
        return devices.filter { $0.matches(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredDevices) { device in
                    NavigationLink(value: device) {
                        DeviceRow(device: device)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        context.delete(filteredDevices[index])
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Serial, name, model, or client")
            .overlay {
                if devices.isEmpty {
                    ContentUnavailableView(
                        "No devices yet",
                        systemImage: "laptopcomputer.and.iphone",
                        description: Text("Point the camera at a serial number label to add the first one.")
                    )
                } else if filteredDevices.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .navigationTitle("Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add device", systemImage: "plus.viewfinder") {
                        isAddingDevice = true
                    }
                }
            }
            .navigationDestination(for: Device.self) { device in
                DeviceDetailView(device: device)
            }
            .sheet(isPresented: $isAddingDevice) {
                NewDeviceSheet()
            }
        }
    }
}

struct DeviceRow: View {
    let device: Device

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(device.displayName)
                .font(.headline)
            HStack(spacing: 6) {
                Text(device.serialNumber)
                    .font(.system(.subheadline, design: .monospaced))
                if let clientName = device.client?.name {
                    Text("·")
                    Text(clientName)
                        .lineLimit(1)
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    DevicesView()
        .modelContainer(PreviewData.container)
}
#endif
