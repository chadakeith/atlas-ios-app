import SwiftUI

/// The live timer shown at the top of the Visits tab while you are on site.
struct ActiveVisitCard: View {
    @Bindable var visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(visit.client?.name ?? "No client")
                        .font(.title3.weight(.semibold))
                    if let label = visit.locationLabel {
                        Label(label, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Arrived \(visit.startedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    Text(Formatters.duration(visit.elapsed(asOf: timeline.date)))
                        .font(.system(.title, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                }
            }

            TextField("What are you working on?", text: $visit.summary, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.roundedBorder)

            Toggle("Billable", isOn: $visit.isBillable)
                .font(.subheadline)

            Button(role: .destructive) {
                visit.endedAt = .now
            } label: {
                Label("End visit", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 6)
    }
}
