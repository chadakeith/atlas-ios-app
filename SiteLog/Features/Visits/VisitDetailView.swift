import SwiftUI

struct VisitDetailView: View {
    @Bindable var visit: Visit

    var body: some View {
        Form {
            Section("Visit") {
                LabeledContent("Client", value: visit.client?.name ?? "No client")
                DatePicker("Arrived", selection: $visit.startedAt)

                if let endedAt = visit.endedAt {
                    DatePicker(
                        "Left",
                        selection: Binding(
                            get: { endedAt },
                            set: { visit.endedAt = $0 }
                        ),
                        in: visit.startedAt...
                    )
                } else {
                    Button("End visit now") { visit.endedAt = .now }
                }

                LabeledContent("Duration", value: Formatters.duration(visit.duration))
                if let label = visit.locationLabel {
                    LabeledContent("Location", value: label)
                }
            }

            Section("Billing") {
                Toggle("Billable", isOn: $visit.isBillable)
                if let client = visit.client {
                    let increment = client.billingIncrementMinutes
                    LabeledContent(
                        "Billable time",
                        value: Formatters.hours(visit.billableSeconds(incrementMinutes: increment))
                    )
                    LabeledContent(
                        "Amount",
                        value: Formatters.money(visit.amount(rate: client.hourlyRate, incrementMinutes: increment))
                    )
                }
            }

            Section("Summary") {
                TextField("One line for the invoice", text: $visit.summary, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section("Notes") {
                TextEditor(text: $visit.notes)
                    .frame(minHeight: 140)
            }
        }
        .navigationTitle(visit.startedAt.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
    }
}
