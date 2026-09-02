import SwiftUI
import Testing

@testable import ColorKit

struct ColorComparisonPresentationTests {
    @Test("Available presentation labels component and raw CIEDE2000 values")
    func availablePresentationUsesRawCIEDE2000Value() {
        let result = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            .comparisonResult(
                with: Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
            )
        guard case let .available(difference) = result else {
            Issue.record("Expected an available comparison")
            return
        }
        let value = ColorComparisonPresentation.perceptualDifferenceValue(for: difference)

        #expect(ColorComparisonPresentation.rgbDifferenceTitle == "RGB Component Difference")
        #expect(ColorComparisonPresentation.hslDifferenceTitle == "HSL Component Difference")
        #expect(
            ColorComparisonPresentation.perceptualDifferenceTitle
                == "CIEDE2000 Difference (ΔE00)"
        )
        #expect(value == "100.00")
        #expect(value.contains("%") == false)
    }

    @Test("Unavailable presentation explains every input issue")
    func unavailablePresentationExplainsIssues() {
        let result = ColorComparisonResult.unavailable(
            ColorComparisonIssues(
                firstColor: [.translucent, .outOfSRGBGamut],
                secondColor: [.unresolved]
            )
        )

        let presentation = ColorComparisonPresentation(result: result)

        #expect(ColorComparisonPresentation.unavailableTitle == "Comparison unavailable")
        #expect(presentation.issueMessages == [
            "Color 1 is translucent and needs an explicit backing color.",
            "Color 1 is outside the sRGB gamut.",
            "Color 2 could not be resolved."
        ])
    }
}
