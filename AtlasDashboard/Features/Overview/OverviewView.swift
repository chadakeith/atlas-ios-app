import Charts
import SwiftUI

struct OverviewView: View {
    @Environment(AppModel.self) private var model
    @State private var state: LoadState<Overview> = .idle

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            RemoteContent(state: state, retry: { await load(force: false) }) { overview in
                ScrollView {
                    VStack(spacing: 16) {
                        HealthCard(overview: overview)

                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(overview.metrics) { metric in
                                StatCard(
                                    label: metric.label,
                                    value: Formatting.count(metric.count),
                                    hint: metric.hint,
                                    delta: metric.delta,
                                    tint: .severity(metric.count)
                                )
                            }
                        }

                        if let history = overview.history, history.count > 1 {
                            HistoryCard(points: history)
                        }

                        if let stamp = Formatting.stamp(overview.generatedAt) {
                            Text("Server snapshot \(stamp)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Atlas")
            .toolbar { DashboardToolbar { await load(force: true) } }
            .refreshable { await load(force: false) }
            .task(id: model.sessionGeneration) { await load(force: false) }
        }
    }

    private func load(force: Bool) async {
        if !state.isLoaded || force { state = .loading }
        do {
            state = .loaded(try await model.api.overview(force: force))
        } catch {
            state = .failed(error)
            model.handle(error)
        }
    }
}

private struct HealthCard: View {
    let overview: Overview

    var body: some View {
        HStack(spacing: 20) {
            if let pct = overview.healthPct {
                Gauge(value: Double(pct), in: 0...100) {
                    Text("Health")
                } currentValueLabel: {
                    Text("\(pct)%")
                        .font(.headline)
                        .monospacedDigit()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(pct >= 95 ? .green : (pct >= 85 ? .yellow : .red))
                .scaleEffect(1.35)
                .frame(width: 84, height: 84)
                .accessibilityLabel("Fleet health \(pct) percent")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Open issues")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(Formatting.count(overview.total))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    DeltaBadge(delta: overview.deltaWeek)
                }
                if let devices = overview.totalDevices {
                    Text("across \(devices.formatted()) managed devices")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    Label("\(Formatting.count(overview.completedToday)) today", systemImage: "checkmark.circle")
                    Label("\(Formatting.count(overview.completedWeek)) this week", systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.green)
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct HistoryCard: View {
    struct Point: Identifiable {
        let day: Date
        let total: Int
        var id: Date { day }
    }

    let points: [Overview.HistoryPoint]

    private var series: [Point] {
        points.compactMap { point in
            guard let day = point.day, let total = point.total else { return nil }
            return Point(day: day, total: total)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Open issues, last \(series.count) days")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(series) { point in
                AreaMark(x: .value("Day", point.day), y: .value("Open", point.total))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(.linearGradient(
                        colors: [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom))
                LineMark(x: .value("Day", point.day), y: .value("Open", point.total))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: max(1, series.count / 4))) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 160)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#if DEBUG
#Preview {
    OverviewView()
        .environment(AppModel(defaults: .preview))
}
#endif
