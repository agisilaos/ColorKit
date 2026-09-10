import SwiftUI
import Testing

@testable import ColorKit

struct EnhancementSelectionTests {
    @Test("Selection matches the frozen selector, including diagnostic evidence",
          arguments: AdjustmentStrategy.allCases.map(\.rawValue), [false, true])
    func completeResults(strategyName: String, preferDarker: Bool) throws {
        let strategy = try #require(AdjustmentStrategy(rawValue: strategyName))
        let space = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let wide = Color(try #require(CGColor(colorSpace: space, components: [1.2, 0.2, 0.3, 1])))
        let gray = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        let pale = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
        let nearWhite = Color(.sRGB, red: 0.99, green: 0.99, blue: 0.99)
        let pairs: [(Color, Color)] = [
            (.black, .white), (pale, .white), (pale, .black), (gray, gray),
            (Color(.sRGB, red: 0.7, green: 0.7, blue: 1), .white),
            (Color(hue: 0, saturation: 0.2, lightness: 0.3), .black),
            (nearWhite, Color(.sRGB, red: 0.34919, green: 0.34919, blue: 0.34919)),
            (nearWhite, Color(.sRGB, red: 0.35, green: 0.35, blue: 0.35)),
            (.primary, .white), (wide, .white), (.black.opacity(0.9), .white),
            (.black, .primary), (.black, .white.opacity(0.5))
        ]
        for level in WCAGContrastLevel.allCases {
            for budget in [-0.0, 0, 0.001, 5, 15, 30, 100, -1, 100.0.nextUp, .nan, .infinity, -.infinity] {
                let configuration = AccessibilityEnhancer.Configuration(
                    targetLevel: level,
                    strategy: strategy,
                    maxPerceptualDistance: budget,
                    preferDarker: preferDarker
                )
                for (original, background) in pairs {
                    expectSame(
                        AccessibilityEnhancer(configuration: configuration).enhanceColorResult(original, against: background),
                        ReferenceBudgetedEnhancement(configuration: configuration).result(for: original, against: background)
                    )
                }
            }
        }
    }

    @Test("Every generated distance boundary preserves complete selection",
          arguments: AdjustmentStrategy.allCases.map(\.rawValue), [false, true])
    func candidateBoundaries(strategyName: String, preferDarker: Bool) throws {
        let strategy = try #require(AdjustmentStrategy(rawValue: strategyName))
        let original = Color(.sRGB, red: 0.7, green: 0.7, blue: 1)
        let configuration = AccessibilityEnhancer.Configuration(strategy: strategy, preferDarker: preferDarker)
        var candidates: [Color] = []
        let fallback = EnhancementCandidateSearch(configuration: configuration).candidate(for: original, against: .white) {
            candidates.append($0)
            return false
        }
        candidates.append(fallback)
        var boundaries: Set<Double> = []
        for candidate in candidates {
            if case let .available(difference) = original.comparisonResult(with: candidate) {
                let distance = difference.perceptualDifference
                boundaries.formUnion([distance.nextDown, distance, distance.nextUp])
            }
        }
        try #require(boundaries.isEmpty == false)
        for budget in boundaries.sorted() where (0...100).contains(budget) {
            let bounded = AccessibilityEnhancer.Configuration(
                strategy: strategy, maxPerceptualDistance: budget, preferDarker: preferDarker
            )
            expectSame(
                AccessibilityEnhancer(configuration: bounded).enhanceColorResult(original, against: .white),
                ReferenceBudgetedEnhancement(configuration: bounded).result(for: original, against: .white)
            )
        }
    }

    @Test("Variant arrays preserve complete results, order, and diagnostics",
          arguments: AdjustmentStrategy.allCases.map(\.rawValue), [false, true])
    func variants(strategyName: String, preferDarker: Bool) throws {
        let strategy = try #require(AdjustmentStrategy(rawValue: strategyName))
        for original in [Color(.sRGB, red: 0.7, green: 0.7, blue: 1), .primary, .black] {
            for budget in [0, 15, 100, Double.nan] {
                let configuration = AccessibilityEnhancer.Configuration(
                    targetLevel: .AAA,
                    strategy: strategy,
                    maxPerceptualDistance: budget,
                    preferDarker: preferDarker
                )
                for count in [-1, 0, 1, 3, 10] {
                    let actual = AccessibilityEnhancer(configuration: configuration)
                        .suggestAccessibleVariantResults(for: original, against: .white, count: count)
                    let expected = referenceVariants(original, configuration: configuration, count: count)
                    try #require(actual.count == expected.count)
                    for (actualResult, expectedResult) in zip(actual, expected) {
                        expectSame(actualResult, expectedResult)
                    }
                }
            }
        }
    }

    // The unchanged variant traversal, with each result supplied by the frozen selector.
    private func referenceVariants(
        _ original: Color, configuration: AccessibilityEnhancer.Configuration, count: Int
    ) -> [ColorAccessibilityResult] {
        guard count > 0 else { return [] }
        var variants: [ColorAccessibilityResult] = []
        let strategies = AdjustmentStrategy.allCases.map { ($0, configuration.preferDarker) }
            + [(configuration.strategy, !configuration.preferDarker)]
        for (strategy, preference) in strategies {
            let result = ReferenceBudgetedEnhancement(configuration: .init(
                targetLevel: configuration.targetLevel,
                strategy: strategy,
                maxPerceptualDistance: configuration.maxPerceptualDistance,
                preferDarker: preference
            )).result(for: original, against: .white)
            if result.status == .invalidConfiguration || result.status == .unavailable { return [result] }
            if variants.allSatisfy({ existing in
                guard case let .available(difference) = existing.color.comparisonResult(with: result.color) else { return false }
                return difference.perceptualDifference >= 5
            }) { variants.append(result) }
            if variants.count == count { break }
        }
        return variants
    }

    private func expectSame(
        _ actual: ColorAccessibilityResult, _ expected: ColorAccessibilityResult,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        #expect(actual.color == expected.color, sourceLocation: sourceLocation)
        #expect(actual.targetLevel == expected.targetLevel, sourceLocation: sourceLocation)
        // Bit patterns preserve nil, NaN payloads, signed zero, and exact finite evidence.
        #expect(actual.contrastRatio?.bitPattern == expected.contrastRatio?.bitPattern, sourceLocation: sourceLocation)
        #expect(actual.perceptualDistance?.bitPattern == expected.perceptualDistance?.bitPattern, sourceLocation: sourceLocation)
        #expect(actual.maximumPerceptualDistance?.bitPattern == expected.maximumPerceptualDistance?.bitPattern, sourceLocation: sourceLocation)
        #expect(actual.minimumContrastRatio.bitPattern == expected.minimumContrastRatio.bitPattern, sourceLocation: sourceLocation)
        #expect(actual.status == expected.status, sourceLocation: sourceLocation)
        #expect(actual.meetsTarget == expected.meetsTarget, sourceLocation: sourceLocation)
        #expect(actual.isWithinPerceptualDistanceBudget == expected.isWithinPerceptualDistanceBudget, sourceLocation: sourceLocation)
    }
}
