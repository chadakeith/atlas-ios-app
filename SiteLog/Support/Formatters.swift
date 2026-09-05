import Foundation

enum Formatters {
    static let currencyCode: String = Locale.current.currency?.identifier ?? "USD"

    /// `1:23:45` style, used for live timers and visit rows.
    static func duration(_ seconds: TimeInterval) -> String {
        Duration.seconds(max(0, seconds)).formatted(.time(pattern: .hourMinuteSecond))
    }

    /// `2.25 h` style, used for totals.
    static func hours(_ seconds: TimeInterval) -> String {
        let hours = seconds / 3600
        return hours.formatted(.number.precision(.fractionLength(0...2))) + " h"
    }

    static func money(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: currencyCode))
    }
}

extension Decimal {
    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
