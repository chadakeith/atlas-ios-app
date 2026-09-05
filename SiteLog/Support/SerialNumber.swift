import Foundation

enum SerialNumber {
    /// Cleans up a serial captured by camera or typed by hand.
    ///
    /// Apple box barcodes encode the serial with a leading "S"
    /// (e.g. `SC02XG1ABJGH5`). Live Text sometimes picks up the "Serial"
    /// label or stray punctuation as well. This strips all of that and
    /// upper-cases the result.
    static func normalize(_ raw: String) -> String {
        var value = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        // Drop a "SERIAL:" / "SERIAL NO." / "S/N" prefix picked up by text recognition.
        for prefix in ["SERIAL NUMBER", "SERIAL NO.", "SERIAL NO", "SERIAL", "S/N", "SN"] {
            if value.hasPrefix(prefix) {
                value = String(value.dropFirst(prefix.count))
                break
            }
        }

        value = value.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        // Apple serials are 12 characters (pre-2021) or 10 characters
        // (randomized format). A barcode "S" prefix makes them 13 or 11.
        if (value.count == 13 || value.count == 11), value.hasPrefix("S") {
            value = String(value.dropFirst())
        }

        return value
    }
}
