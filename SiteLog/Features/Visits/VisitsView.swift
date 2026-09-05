import SwiftData
import SwiftUI

struct VisitsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Visit.startedAt, order: .reverse) private var visits: [Visit]
    @Query(sort: \Client.name) private var clients: [Client]

    @State private var isStartingVisit = false

    private var activeVisit: Visit? { visits.first { $0.isActive } }
    private var completedVisits: [Visit] { visits.filter { !$0.isActive } }

    var body: some View {
        NavigationStack {
            List {
                if let activeVisit {
                    Section("On site now") {
                        ActiveVisitCard(visit: activeVisit)
                    }
                } else {
                    Section {
                        Button {
                            isStartingVisit = true
                        } label: {
                            Label("Start a visit", systemImage: "play.fill")
                                .font(.headline)
                        }
                        .disabled(clients.isEmpty)
                    } footer: {
                        if clients.isEmpty {
                            Text("Add a client in the Clients tab before starting your first visit.")
                        }
                    }
                }

                ForEach(groupedVisits, id: \.day) { group in
                    Section(group.day.formatted(date: .complete, time: .omitted)) {
                        ForEach(group.visits) { visit in
                            NavigationLink(value: visit) {
                                VisitRow(visit: visit)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                context.delete(group.visits[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Visits")
            .navigationDestination(for: Visit.self) { visit in
                VisitDetailView(visit: visit)
            }
            .sheet(isPresented: $isStartingVisit) {
                StartVisitSheet()
            }
        }
    }

    private struct DayGroup {
        let day: Date
        let visits: [Visit]
    }

    private var groupedVisits: [DayGroup] {
        let calendar = Calendar.current
        let byDay = Dictionary(grouping: completedVisits) { calendar.startOfDay(for: $0.startedAt) }
        return byDay.keys.sorted(by: >).map { DayGroup(day: $0, visits: byDay[$0] ?? []) }
    }
}

struct VisitRow: View {
    let visit: Visit

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(visit.client?.name ?? "No client")
                    .font(.headline)
                Text(visit.summary.isEmpty ? "No summary" : visit.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.duration(visit.duration))
                    .monospacedDigit()
                if !visit.isBillable {
                    Text("Non-billable")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    VisitsView()
        .modelContainer(PreviewData.container)
}
#endif
