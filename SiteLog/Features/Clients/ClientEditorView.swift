import SwiftData
import SwiftUI

/// Create or edit a client. Pass `client` to edit; omit it to create.
struct ClientEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let client: Client?

    @State private var name: String
    @State private var contactName: String
    @State private var contactEmail: String
    @State private var phone: String
    @State private var address: String
    @State private var notes: String
    @State private var hourlyRate: Decimal
    @State private var billingIncrementMinutes: Int

    private let incrementChoices = [1, 6, 10, 15, 30, 60]

    init(client: Client? = nil) {
        self.client = client
        _name = State(initialValue: client?.name ?? "")
        _contactName = State(initialValue: client?.contactName ?? "")
        _contactEmail = State(initialValue: client?.contactEmail ?? "")
        _phone = State(initialValue: client?.phone ?? "")
        _address = State(initialValue: client?.address ?? "")
        _notes = State(initialValue: client?.notes ?? "")
        _hourlyRate = State(initialValue: client?.hourlyRate ?? 0)
        _billingIncrementMinutes = State(initialValue: client?.billingIncrementMinutes ?? 15)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Business name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("Contact") {
                    TextField("Contact name", text: $contactName)
                        .textInputAutocapitalization(.words)
                    TextField("Email", text: $contactEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section {
                    TextField("Hourly rate", value: $hourlyRate, format: .currency(code: Formatters.currencyCode))
                        .keyboardType(.decimalPad)
                    Picker("Round visits up to", selection: $billingIncrementMinutes) {
                        ForEach(incrementChoices, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                } header: {
                    Text("Billing")
                } footer: {
                    Text("A 16-minute visit rounded to 15 min bills as 30 minutes.")
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle(client == nil ? "New client" : "Edit client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmed.isEmpty)
                }
            }
        }
    }

    private func save() {
        if let client {
            client.name = name.trimmed
            client.contactName = contactName.trimmed
            client.contactEmail = contactEmail.trimmed
            client.phone = phone.trimmed
            client.address = address.trimmed
            client.notes = notes
            client.hourlyRate = hourlyRate
            client.billingIncrementMinutes = billingIncrementMinutes
        } else {
            let newClient = Client(
                name: name.trimmed,
                contactName: contactName.trimmed,
                contactEmail: contactEmail.trimmed,
                phone: phone.trimmed,
                address: address.trimmed,
                notes: notes,
                hourlyRate: hourlyRate,
                billingIncrementMinutes: billingIncrementMinutes
            )
            context.insert(newClient)
        }
        dismiss()
    }
}
