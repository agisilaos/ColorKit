import ColorKit
import SwiftUI

func scenarios() -> [Scenario] {
    let red = Color(.sRGB, red: 1, green: 0, blue: 0, opacity: 1)
    let black = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    let white = Color(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
    let gray = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8, opacity: 1)
    var cases = [
        Scenario(
            description: ScenarioDescription(
                id: "hsl-red",
                purpose: "Convert fixed red to HSL components",
                inputs: "sRGB RGBA (1, 0, 0, 1)",
                settings: "hslComponents()",
                expected: "HSL (0, 1, 0.5), tolerance 0.001",
                unit: "conversion",
                modes: [.empty, .primed]
            ),
            input: red,
            operation: { $0.hslComponents() },
            validate: { value in
                guard let value else { throw BenchmarkError.invalidFixture("Missing HSL") }
                try requireFixture(
                    abs(value.hue) < 0.001 && abs(value.saturation - 1) < 0.001
                        && abs(value.lightness - 0.5) < 0.001,
                    "Incorrect HSL red"
                )
            }
        ),
        Scenario(
            description: ScenarioDescription(
                id: "lab-red",
                purpose: "Convert fixed red to D65 LAB components",
                inputs: "sRGB RGBA (1, 0, 0, 1)",
                settings: "labComponents()",
                expected: "LAB (53.2408, 80.0925, 67.2032), tolerance 0.001",
                unit: "conversion",
                modes: [.empty, .primed]
            ),
            input: red,
            operation: { $0.labComponents() },
            validate: { value in
                guard let value else { throw BenchmarkError.invalidFixture("Missing LAB") }
                try requireFixture(
                    abs(value.L - 53.2408) < 0.001 && abs(value.a - 80.0925) < 0.001
                        && abs(value.b - 67.2032) < 0.001,
                    "Incorrect LAB red"
                )
            }
        ),
        Scenario(
            description: ScenarioDescription(
                id: "comparison-black-white",
                purpose: "Compute all public color-comparison metrics",
                inputs: "sRGB RGBA first (0, 0, 0, 1), second (1, 1, 1, 1)",
                settings: "comparisonResult(with:)",
                expected: "Available CIEDE2000 100 and contrast 21",
                unit: "comparison",
                modes: [.unused]
            ),
            input: (black, white),
            operation: { $0.0.comparisonResult(with: $0.1) },
            validate: { value in
                guard case let .available(difference) = value else {
                    throw BenchmarkError.invalidFixture("Unavailable comparison")
                }
                try requireFixture(
                    difference.perceptualDifferenceMetric == .ciede2000
                        && abs(difference.perceptualDifference - 100) < 0.001
                        && abs(difference.contrastRatio - 21) < 0.001
                        && difference.rgbDifference.red == 1 && difference.rgbDifference.green == 1
                        && difference.rgbDifference.blue == 1 && difference.hslDifference.hue == 0
                        && difference.hslDifference.saturation == 0 && difference.hslDifference.lightness == 100
                        && difference.wcagComplianceLevels.count == WCAGContrastLevel.allCases.count,
                    "Incorrect full comparison"
                )
            }
        )
    ]

    for (id, original, budget, expected, isAlreadyCompliant) in [
        ("enhancement-compliant", black, 100.0, ColorAccessibilityResult.Status.meetsTarget, true),
        ("enhancement-adjusted", gray, 100.0, .meetsTarget, false),
        ("enhancement-best-effort", gray, 25.0, .bestEffort, false)
    ] {
        let enhancer = AccessibilityEnhancer(configuration: .init(
            targetLevel: .AA, strategy: .preserveHue, maxPerceptualDistance: budget, preferDarker: true
        ))
        cases.append(Scenario(
            description: ScenarioDescription(
                id: id,
                purpose: "Budgeted enhancement: \(id.replacingOccurrences(of: "enhancement-", with: ""))",
                inputs: "sRGB RGBA foreground \(isAlreadyCompliant ? "(0, 0, 0, 1)" : "(0.8, 0.8, 0.8, 1)"), background (1, 1, 1, 1)",
                settings: "AA, preserveHue, preferDarker true, distance budget \(budget)",
                expected: "\(expected); distance <= \(budget); best effort improves contrast; compliant preserves input",
                unit: "enhancement",
                modes: isAlreadyCompliant ? [.unused] : [.empty, .primed]
            ),
            input: (original, white),
            operation: { enhancer.enhanceColorResult($0.0, against: $0.1) },
            validate: { value in
                let actual = value.color.accessibilityResult(against: white)
                guard case let .available(difference) = original.comparisonResult(with: value.color),
                      let contrast = value.contrastRatio, let distance = value.perceptualDistance
                else {
                    throw BenchmarkError.invalidFixture("Missing enhancement evidence")
                }
                try requireFixture(
                    value.status == expected && value.isWithinPerceptualDistanceBudget == true
                        && distance <= budget && abs(distance - difference.perceptualDifference) < 0.001
                        && actual.contrastRatio == value.contrastRatio && contrast.isFinite,
                    "Incorrect enhancement evidence"
                )
                if isAlreadyCompliant {
                    try requireFixture(value.color == original && distance == 0, "Changed compliant input")
                } else if expected == .bestEffort {
                    try requireFixture(abs(contrast - 3.976653) < 0.00001, "Incorrect best effort")
                }
            }
        ))
    }

    let generator = AccessiblePaletteGenerator(configuration: .init(
        targetLevel: .AA, paletteSize: 5, includeBlackAndWhite: true
    ))
    cases.append(Scenario(
        description: ScenarioDescription(
            id: "palette-red-five",
            purpose: "Generate and assess one five-color palette (stochastic candidate search)",
            inputs: "sRGB RGBA seed (1, 0, 0, 1), background (1, 1, 1, 1)",
            settings: "AA, paletteSize 5, includeBlackAndWhite true; internal unseeded random hue shifts; candidate work varies; priming uses a different generated palette",
            expected: "Five entries, seed first; each assessment matches its color against white; entries need not all pass AA",
            unit: "palette",
            modes: [.empty, .primed]
        ),
        input: (red, white),
        operation: { generator.generateAssessedPalette(from: $0.0, against: $0.1) },
        validate: { values in
            try requireFixture(values.count == 5 && values.first?.color == red, "Incorrect palette size or seed")
            for value in values {
                let assessment = value.color.accessibilityResult(against: white)
                try requireFixture(
                    value.contrastRatio != nil && value.contrastRatio == assessment.contrastRatio
                        && value.status == assessment.status && value.targetLevel == .AA,
                    "Incorrect palette assessment"
                )
            }
        }
    ))
    return cases
}
