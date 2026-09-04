import SwiftUI
import Testing

@testable import ColorKit

struct EnhancementDistanceBudgetTests {
    @Test("Positive variant requests return one diagnostic for invalid configuration")
    func invalidVariantBudget() {
        let original = Color.black
        let enhancer = AccessibilityEnhancer(configuration: .init(maxPerceptualDistance: .nan))
        let results = enhancer.suggestAccessibleVariantResults(for: original, against: .white, count: 3)

        #expect(results.count == 1)
        #expect(results.first?.color == original)
        #expect(results.first?.status == .invalidConfiguration)
        #expect(results.first?.meetsTarget == false)
    }

    @Test("A small positive budget excludes an over-budget passing fallback")
    func smallBudget() throws {
        let original = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
        let enhancer = AccessibilityEnhancer(configuration: .init(maxPerceptualDistance: 1))
        let result = enhancer.enhanceColorResult(original, against: .white)

        guard case let .available(difference) = original.comparisonResult(with: result.color) else {
            Issue.record("Expected a measurable candidate")
            return
        }
        #expect(difference.perceptualDifference <= 1)
        #expect(result.status == .bestEffort)
    }

    @Test("Zero budget preserves a below-target original", arguments: AdjustmentStrategy.allCases.map(\.rawValue))
    func zeroBudget(strategyName: String) throws {
        let strategy = try #require(AdjustmentStrategy(rawValue: strategyName))
        let original = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
        let enhancer = AccessibilityEnhancer(configuration: .init(
            strategy: strategy,
            maxPerceptualDistance: 0
        ))

        let result = enhancer.enhanceColorResult(original, against: .white)

        #expect(result.color == original)
        #expect(result.status == .bestEffort)
        #expect(result.meetsTarget == false)
        #expect(result.perceptualDistance == 0)
        #expect(result.maximumPerceptualDistance == 0)
        #expect(result.isWithinPerceptualDistanceBudget == true)
    }

    @Test("Invalid budgets outrank a passing diagnostic contrast", arguments: [-1.0, 100.0001, Double.nan, .infinity, -.infinity])
    func invalidBudgets(budget: Double) {
        let enhancer = AccessibilityEnhancer(configuration: .init(maxPerceptualDistance: budget))
        let result = enhancer.enhanceColorResult(.black, against: .white)

        #expect(result.color == .black)
        #expect(result.status == .invalidConfiguration)
        #expect(result.meetsTarget == false)
        #expect(result.contrastRatio == 21)
        #expect(result.perceptualDistance == nil)
        #expect(result.isWithinPerceptualDistanceBudget == nil)
        if budget.isNaN {
            #expect(enhancer.configuration.maxPerceptualDistance.isNaN)
            #expect(result.maximumPerceptualDistance?.isNaN == true)
        } else {
            #expect(enhancer.configuration.maxPerceptualDistance == budget)
            #expect(result.maximumPerceptualDistance == budget)
        }
    }

    @Test("Already passing inputs remain identical at both valid endpoints", arguments: [0.0, -0.0, 100.0])
    func passingOriginal(budget: Double) {
        let result = Color.black.enhancementResult(with: .white, maxPerceptualDistance: budget)
        #expect(result.color == .black)
        #expect(result.status == .meetsTarget)
        #expect(result.perceptualDistance == 0)
        #expect(result.isWithinPerceptualDistanceBudget == true)
    }

    @Test("Exact distance is inclusive with no floating-point overshoot allowance")
    func exactDistanceBoundary() throws {
        let original = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
        func enhance(_ budget: Double) -> ColorAccessibilityResult {
            AccessibilityEnhancer(configuration: .init(
                strategy: .preserveHue, maxPerceptualDistance: budget, preferDarker: true
            )).enhanceColorResult(original, against: .white)
        }
        let passing = enhance(100)
        try #require(passing.meetsTarget)
        let boundary = try measuredDistance(original, passing.color)
        let exact = enhance(boundary)
        let above = enhance(boundary.nextUp)
        let below = enhance(boundary.nextDown)

        #expect(exact.color == passing.color)
        #expect(exact.perceptualDistance == boundary)
        #expect(exact.isWithinPerceptualDistanceBudget == true)
        #expect(above.color == passing.color)
        #expect(below.status == .bestEffort)
        #expect(below.color != passing.color)
        #expect(try measuredDistance(original, below.color) <= boundary.nextDown)
    }

    @Test("Best effort improves contrast without spending beyond the budget")
    func bestExaminedCandidate() throws {
        let original = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
        let result = AccessibilityEnhancer(configuration: .init(
            maxPerceptualDistance: 25, preferDarker: true
        )).enhanceColorResult(original, against: .white)

        #expect(result.status == .bestEffort)
        // On the existing 0.05 lightness path, 50% gray is the best eligible step;
        // the next step (45% gray) passes AA but exceeds this budget.
        #expect(abs(try #require(result.contrastRatio) - 3.976653) < 0.00001)
        #expect(try measuredDistance(original, result.color) <= 25)
        #expect(result.color != original)
    }

    @Test("Budget evidence is authoritative across strategies and preferences",
          arguments: AdjustmentStrategy.allCases.map(\.rawValue), [false, true])
    func strategyBudgets(strategyName: String, preferDarker: Bool) throws {
        let strategy = try #require(AdjustmentStrategy(rawValue: strategyName))
        let original = Color(.sRGB, red: 0.7, green: 0.7, blue: 1)
        let originalContrast = try #require(original.accessibilityResult(against: .white).contrastRatio)
        for budget in [0.001, 5, 15, 30, 100] {
            let result = AccessibilityEnhancer(configuration: .init(
                strategy: strategy, maxPerceptualDistance: budget, preferDarker: preferDarker
            )).enhanceColorResult(original, against: .white)
            let distance = try measuredDistance(original, result.color)
            #expect(distance <= budget)
            #expect(result.perceptualDistance == distance)
            #expect(result.maximumPerceptualDistance == budget)
            #expect(result.isWithinPerceptualDistanceBudget == true)
            #expect(try #require(result.contrastRatio) >= originalContrast)
        }
    }

    @Test("Minimum change cannot overlook a closer passing hue-fallback candidate")
    func minimumChangeIncludesFallbacks() throws {
        let original = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
        let minimum = original.enhancementResult(with: .white, strategy: .minimumChange, maxPerceptualDistance: 100)
        let hue = original.enhancementResult(with: .white, strategy: .preserveHue, maxPerceptualDistance: 100)
        #expect(minimum.meetsTarget)
        #expect(hue.meetsTarget)
        #expect(try measuredDistance(original, minimum.color) <= measuredDistance(original, hue.color))
    }

    @Test("Search continues past over-budget lightness candidates into an eligible hue fallback")
    func laterEligibleFallback() throws {
        let original = Color(hue: 0, saturation: 0.2, lightness: 0.3)
        let result = original.enhancementResult(
            with: .black, targetLevel: .AAA, strategy: .preserveLightness, maxPerceptualDistance: 5
        )
        // Earlier hue-shifting candidates leave the budget. The later hue fallback
        // returns to it at 35% lightness and improves on their contrast (below 2.34).
        let expected = Color(hue: 0, saturation: 0.2, lightness: 0.35)
        #expect(result.status == .bestEffort)
        #expect(try measuredDistance(result.color, expected) < 0.00001)
        #expect(try #require(result.contrastRatio) > 2.62)
        #expect(try measuredDistance(original, result.color) <= 5)
    }

    @Test("Repeated equal-contrast endpoints retain the first zero-distance original")
    func stableOriginalTie() {
        let original = Color.black
        let background = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        let result = original.enhancementResult(with: background, targetLevel: .AAA, maxPerceptualDistance: 100)
        #expect(result.status == .bestEffort)
        #expect(result.color == original)
        #expect(result.perceptualDistance == 0)
    }

    @Test("Pairwise deduplication switches at the Delta E 00 threshold",
          arguments: [(0.45207030, false), (0.45207037, true)])
    func distinctnessBoundary(hue: Double, isDistinct: Bool) throws {
        let original = Color(hue: hue, saturation: 1, lightness: 0.3)
        let first = original.enhancementResult(with: .white, strategy: .preserveHue, maxPerceptualDistance: 100)
        let second = original.enhancementResult(with: .white, strategy: .preserveSaturation, maxPerceptualDistance: 100)
        let delta = try measuredDistance(first.color, second.color)
        // These nearby fixed-color fixtures bracket 5 without inventing a tolerance
        // or injecting fabricated measurements into the public enhancement seam.
        try #require(abs(delta - 5) < 0.001)
        #expect((delta >= 5) == isDistinct)
        let results = original.suggestAccessibleVariantResults(with: .white, count: 2, maxPerceptualDistance: 100)
        try #require(results.count == 2)
        #expect(results[0].color == first.color)
        #expect((results[1].color == second.color) == isDistinct)
    }

    @Test("Unattainable AAA never permits an over-budget endpoint")
    func unattainableTarget() throws {
        let gray = Color(.sRGB, red: 0.5, green: 0.5, blue: 0.5)
        let result = gray.enhancementResult(with: gray, targetLevel: .AAA, maxPerceptualDistance: 10)
        #expect(result.status == .bestEffort)
        #expect(try measuredDistance(gray, result.color) <= 10)
        #expect(try #require(result.contrastRatio) < 7)
    }

    @Test("Unavailable distance retains a passing composited diagnostic contrast")
    func translucentOriginal() throws {
        let original = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.9)
        let assessment = original.accessibilityResult(against: .white)
        try #require(assessment.meetsTarget)
        let result = original.enhancementResult(with: .white)
        #expect(result.color == original)
        #expect(result.status == .unavailable)
        #expect(result.contrastRatio == assessment.contrastRatio)
        #expect(result.perceptualDistance == nil)
        #expect(result.maximumPerceptualDistance == 30)
        #expect(result.isWithinPerceptualDistanceBudget == nil)
        #expect(result.meetsTarget == false)
    }

    @Test("Unresolved or out-of-gamut originals do not start an enhancement search")
    func unavailableOriginals() throws {
        let space = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let wide = Color(try #require(CGColor(colorSpace: space, components: [1.2, 0.2, 0.3, 1])))
        for original in [Color.primary, wide] {
            let result = original.enhancementResult(with: .white)
            #expect(result.color == original)
            #expect(result.status == .unavailable)
            #expect(result.contrastRatio == nil)
            #expect(result.perceptualDistance == nil)
        }
    }

    @Test("An unavailable background retains independently measurable zero distance")
    func unavailableBackground() {
        for background in [Color.primary, Color.white.opacity(0.5)] {
            let result = Color.black.enhancementResult(with: background)
            #expect(result.color == .black)
            #expect(result.status == .unavailable)
            #expect(result.contrastRatio == nil)
            #expect(result.perceptualDistance == 0)
            #expect(result.isWithinPerceptualDistanceBudget == true)
            #expect(result.meetsTarget == false)
        }
    }

    @Test("Ordinary assessments carry no enhancement metadata")
    func ordinaryAssessment() {
        let result = Color.black.accessibilityResult(against: .white)
        #expect(result.status == .meetsTarget)
        #expect(result.perceptualDistance == nil)
        #expect(result.maximumPerceptualDistance == nil)
        #expect(result.isWithinPerceptualDistanceBudget == nil)
    }

    @Test("Result conveniences propagate the requested budget and preserve the default")
    func convenienceBudgets() {
        let original = Color(.sRGB, red: 0.8, green: 0.8, blue: 0.8)
        #expect(original.enhancementResult(with: .white).maximumPerceptualDistance == 30)
        let variants = original.suggestAccessibleVariantResults(with: .white, count: 3, maxPerceptualDistance: 0)
        #expect(variants.count == 1)
        #expect(variants.first?.color == original)
        #expect(variants.first?.maximumPerceptualDistance == 0)
        #expect(variants.first?.status == .bestEffort)
    }

    @Test("Nonpositive variant counts precede configuration validation", arguments: [0, -1, Int.min])
    func emptyVariantRequests(count: Int) {
        let enhancer = AccessibilityEnhancer(configuration: .init(maxPerceptualDistance: .nan))
        #expect(enhancer.suggestAccessibleVariantResults(for: .primary, against: .white, count: count).isEmpty)
    }

    @Test("Unavailable variant requests return exactly one diagnostic")
    func unavailableVariants() {
        let original = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.9)
        let results = original.suggestAccessibleVariantResults(with: .white, count: 10)
        #expect(results.count == 1)
        #expect(results.first?.color == original)
        #expect(results.first?.status == .unavailable)
        #expect(results.first?.contrastRatio != nil)
    }

    @Test("Variants preserve strategy order, retain best effort, and obey two separate distance rules")
    func orderedDistinctVariants() throws {
        let original = Color(.sRGB, red: 0.7, green: 0.7, blue: 1)
        let budget = 15.0
        let enhancer = AccessibilityEnhancer(configuration: .init(maxPerceptualDistance: budget))
        let results = enhancer.suggestAccessibleVariantResults(for: original, against: .white, count: Int.max)
        try #require(results.isEmpty == false)
        #expect(results.count <= 5)
        #expect(results.contains { $0.status == .bestEffort })

        let expectedCandidates = AdjustmentStrategy.allCases.map { strategy in
            original.enhancementResult(with: .white, strategy: strategy, maxPerceptualDistance: budget)
        } + [AccessibilityEnhancer(configuration: .init(
            maxPerceptualDistance: budget, preferDarker: true
        )).enhanceColorResult(original, against: .white)]
        var remaining = expectedCandidates[...]
        for (index, result) in results.enumerated() {
            let match = try #require(remaining.firstIndex { $0.color == result.color })
            remaining = remaining.suffix(from: remaining.index(after: match))
            #expect(try measuredDistance(original, result.color) <= budget)
            for previous in results.prefix(index) {
                #expect(try measuredDistance(previous.color, result.color) >= 5)
            }
        }
    }

    @Test("Legacy colors and CIE76 variant arrays ignore budgets", arguments: AdjustmentStrategy.allCases.map(\.rawValue))
    func legacyCompatibility(strategyName: String) throws {
        let strategy = try #require(AdjustmentStrategy(rawValue: strategyName))
        let original = Color(.sRGB, red: 0.7, green: 0.7, blue: 1)
        let reference = AccessibilityEnhancer(configuration: .init(strategy: strategy))
        let expected = reference.enhanceColor(original, against: .white)
        let expectedVariants = reference.suggestAccessibleVariants(for: original, against: .white, count: 10)
        for budget in [0, 1, 100, -1, Double.nan, .infinity] {
            let enhancer = AccessibilityEnhancer(configuration: .init(strategy: strategy, maxPerceptualDistance: budget))
            #expect(enhancer.enhanceColor(original, against: .white) == expected)
            #expect(enhancer.suggestAccessibleVariants(for: original, against: .white, count: 10) == expectedVariants)
        }
    }

    private func measuredDistance(_ first: Color, _ second: Color, sourceLocation: SourceLocation = #_sourceLocation) throws -> Double {
        let distance: Double?
        if case let .available(difference) = first.comparisonResult(with: second) {
            distance = difference.perceptualDifference
        } else {
            distance = nil
        }
        return try #require(distance, sourceLocation: sourceLocation)
    }
}
