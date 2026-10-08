import ColorKit
import SwiftUI
import Testing

struct HexParsingTests {
    @Test(arguments: ["FFGGGG", "12zzzzzz", "12345Z", "0x1234", "+FFFFF", "00 000"])
    func rejectsNonHexadecimalCharacters(_ input: String) {
        #expect(Color(hex: input) == nil)
    }

    @Test(arguments: [
        ("#FF0000", "#FF0000FF"),
        ("00ff00", "#00FF00FF"),
        (" \n#33669980\t", "#33669980")
    ])
    func preservesValidRGBAndRGBA(_ input: String, _ expected: String) throws {
        let color = try #require(Color(hex: input))
        #expect(color.hexValue() == expected)
    }
}
