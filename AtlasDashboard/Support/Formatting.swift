import Foundation
import SwiftUI

enum Formatting {
    static func count(_ value: Int?) -> String {
        guard let value else { return "—" }
        return value.formatted()
    }

    static func signed(_ value: Int) -> String {
        value > 0 ? "+\(value.formatted())" : value.formatted()
    }

    static func relative(_ date: Date?) -> String {
        guard let date else { return "never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    static func months(_ value: Double?) -> String {
        guard let value else { return "—" }
        if value >= 12 {
            let years = value / 12
            return years.formatted(.number.precision(.fractionLength(1))) + " yr"
        }
        return value.formatted(.number.precision(.fractionLength(0))) + " mo"
    }

    static func stamp(_ text: String?) -> String? {
        guard let text, let date = DashboardDates.stamp(from: text) else { return text }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}

/// Green when a count dropped, red when it rose, grey when flat or unknown.
struct DeltaBadge: View {
    let delta: Int?

    var body: some View {
        if let delta {
            Label(Formatting.signed(delta), systemImage: symbol)
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.12), in: Capsule())
                .accessibilityLabel(accessibility)
        }
    }

    private var symbol: String {
        guard let delta else { return "minus" }
        if delta < 0 { return "arrow.down.right" }
        if delta > 0 { return "arrow.up.right" }
        return "minus"
    }

    private var color: Color {
        guard let delta, delta != 0 else { return .secondary }
        return delta < 0 ? .green : .red
    }

    private var accessibility: String {
        guard let delta else { return "no change data" }
        if delta == 0 { return "unchanged this week" }
        return delta < 0 ? "down \(-delta) this week" : "up \(delta) this week"
    }
}

/// Stat card used across screens: label, big number, optional hint and delta.
struct StatCard: View {
    let label: String
    let value: String
    var hint: String? = nil
    var delta: Int? = nil
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(alignment: .firstTextBaseline) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                DeltaBadge(delta: delta)
            }
            if let hint, !hint.isEmpty {
                Text(hint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

extension Color {
    /// Zero findings reads green, otherwise escalate with size.
    static func severity(_ count: Int?) -> Color {
        guard let count else { return .secondary }
        if count == 0 { return .green }
        if count < 5 { return .yellow }
        if count < 20 { return .orange }
        return .red
    }
}
