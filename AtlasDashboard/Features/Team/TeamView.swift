import SwiftUI

/// Productivity board: Autotask tickets + Asana tasks per person.
struct TeamView: View {
    @Environment(AppModel.self) private var model
    @State private var summary: LoadState<ProductivitySummary> = .idle
    @State private var team: LoadState<TeamPayload> = .idle

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    InlineState(state: summary, retry: { await loadSummary(force: false) }) { payload in
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(payload.cards) { card in
                                StatCard(label: card.label, value: Formatting.count(card.value), hint: card.hint,
                                         tint: card.id.hasPrefix("closed") ? .green : .primary)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    Text("Team")
                } footer: {
                    if let payload = summary.value {
                        Text(footer(for: payload))
                    }
                }

                Section("By person") {
                    InlineState(state: team, retry: { await loadTeam(force: false) }) { payload in
                        ForEach(payload.members.sorted { ($0.counts?.openTotal ?? 0) > ($1.counts?.openTotal ?? 0) }) { member in
                            MemberRow(member: member)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Team")
            .toolbar {
                DashboardToolbar {
                    await loadSummary(force: true)
                    await loadTeam(force: true)
                }
            }
            .refreshable {
                await loadSummary(force: false)
                await loadTeam(force: false)
            }
            .task(id: model.sessionGeneration) {
                await loadSummary(force: false)
                await loadTeam(force: false)
            }
        }
    }

    private func footer(for payload: ProductivitySummary) -> String {
        var parts: [String] = []
        if let sources = payload.sources {
            parts.append("Autotask \(sources.autotask ?? "?") · Asana \(sources.asana ?? "?")")
        }
        if let age = payload.cacheAgeMinutes {
            parts.append("cached \(age.formatted(.number.precision(.fractionLength(0)))) min ago")
        }
        return parts.joined(separator: " · ")
    }

    private func loadSummary(force: Bool) async {
        if !summary.isLoaded || force { summary = .loading }
        do { summary = .loaded(try await model.api.productivitySummary(force: force)) } catch { summary = .failed(error); model.handle(error) }
    }

    private func loadTeam(force: Bool) async {
        if !team.isLoaded || force { team = .loading }
        do { team = .loaded(try await model.api.productivityTeam(force: force)) } catch { team = .failed(error); model.handle(error) }
    }
}

private struct MemberRow: View {
    let member: TeamPayload.Member

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(initials)
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.displayName).font(.headline)
                Text("\(Formatting.count(member.counts?.openTickets)) tickets · \(Formatting.count(member.counts?.openTasks)) Asana")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let stale = member.counts?.staleAsana, stale > 0 {
                    Text("\(stale) stale Asana")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatting.count(member.counts?.openTotal))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                Text("\(Formatting.count(member.counts?.closedToday)) today · \(Formatting.count(member.counts?.closedWeek)) wk")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
    }

    private var initials: String {
        let words = member.displayName.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }.map(String.init)
        return letters.joined().uppercased()
    }
}

#if DEBUG
#Preview {
    TeamView()
        .environment(AppModel(defaults: .preview))
}
#endif
