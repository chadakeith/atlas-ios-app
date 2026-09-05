import Testing
@testable import SiteLog

struct SerialNumberTests {
    @Test func trimsAndUppercases() {
        #expect(SerialNumber.normalize("  c02xg1abjgh5\n") == "C02XG1ABJGH5")
    }

    @Test func stripsBarcodePrefixFromTwelveCharacterSerial() {
        #expect(SerialNumber.normalize("SC02XG1ABJGH5") == "C02XG1ABJGH5")
    }

    @Test func stripsBarcodePrefixFromTenCharacterSerial() {
        #expect(SerialNumber.normalize("SJQ4K7PLM2X") == "JQ4K7PLM2X")
    }

    @Test func keepsTwelveCharacterSerialThatStartsWithS() {
        // Only 11 and 13 character strings are treated as barcode-prefixed.
        #expect(SerialNumber.normalize("SC02XG1ABJGH") == "SC02XG1ABJGH")
    }

    @Test func stripsLabelsPickedUpByLiveText() {
        #expect(SerialNumber.normalize("Serial: C02XG1ABJGH5") == "C02XG1ABJGH5")
        #expect(SerialNumber.normalize("S/N C02XG1ABJGH5") == "C02XG1ABJGH5")
        #expect(SerialNumber.normalize("SERIAL NO. C02XG1ABJGH5") == "C02XG1ABJGH5")
    }

    @Test func emptyInputStaysEmpty() {
        #expect(SerialNumber.normalize("   ") == "")
    }
}
