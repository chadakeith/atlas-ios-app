import SwiftData
import SwiftUI

/// Shared fields for creating and editing a device.
struct DeviceFormFields: View {
    @Binding var serialNumber: String
    @Binding var nickname: String
    @Binding var modelName: String
    @Binding var assignedTo: String
    @Binding var notes: String
    @Binding var client: Client?

    @Query(sort: \Client.name) private var clients: [Client]
    @State private var isScanning = false

    var body: some View {
        Section("Serial number") {
            HStack {
                TextField("Serial number", text: $serialNumber)
                    .font(.system(.body, design: .monospaced))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button {
                    isScanning = true
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Scan serial number")
            }
            .sheet(isPresented: $isScanning) {
                ScanSerialSheet { scanned in
                    serialNumber = scanned
                }
            }
        }

        Section("Details") {
            TextField("Nickname (Front desk iMac)", text: $nickname)
            TextField("Model (MacBook Air 13-inch)", text: $modelName)
            TextField("Assigned to", text: $assignedTo)
                .textInputAutocapitalization(.words)
            Picker("Client", selection: $client) {
                Text("None").tag(Client?.none)
                ForEach(clients) { option in
                    Text(option.name).tag(Optional(option))
                }
            }
        }

        Section("Notes") {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
        }
    }
}

/// Create a new device. Optionally preselect the client it belongs to.
struct NewDeviceSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var serialNumber = ""
    @State private var nickname = ""
    @State private var modelName = ""
    @State private var assignedTo = ""
    @State private var notes = ""
    @State private var client: Client?

    private let preselectedClient: Client?

    init(client: Client? = nil) {
        preselectedClient = client
    }

    var body: some View {
        NavigationStack {
            Form {
                DeviceFormFields(
                    serialNumber: $serialNumber,
                    nickname: $nickname,
                    modelName: $modelName,
                    assignedTo: $assignedTo,
                    notes: $notes,
                    client: $client
                )
            }
            .navigationTitle("New device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(SerialNumber.normalize(serialNumber).isEmpty)
                }
            }
            .onAppear {
                if client == nil { client = preselectedClient }
            }
        }
    }

    private func save() {
        let device = Device(
            serialNumber: serialNumber,
            nickname: nickname.trimmed,
            modelName: modelName.trimmed,
            assignedTo: assignedTo.trimmed,
            notes: notes,
            client: client
        )
        context.insert(device)
        dismiss()
    }
}

/// Edits an existing device in place. SwiftData autosaves changes.
struct DeviceDetailView: View {
    @Bindable var device: Device

    var body: some View {
        Form {
            DeviceFormFields(
                serialNumber: $device.serialNumber,
                nickname: $device.nickname,
                modelName: $device.modelName,
                assignedTo: $device.assignedTo,
                notes: $device.notes,
                client: $device.client
            )
            Section {
                LabeledContent("Added", value: device.addedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle(device.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            device.serialNumber = SerialNumber.normalize(device.serialNumber)
        }
    }
}
