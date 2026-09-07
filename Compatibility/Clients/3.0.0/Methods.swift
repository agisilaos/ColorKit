import ColorKit
import SwiftUI

// Deliberately nonisolated: these operations did not require MainActor in 3.0.0.
func storedMethods(_ color: Color) {
    let enhance: (Color, WCAGContrastLevel, AdjustmentStrategy, Double) -> ColorAccessibilityResult =
        color.enhancementResult(with:targetLevel:strategy:maxPerceptualDistance:)
    let inferredEnhance = color.enhancementResult(with:targetLevel:strategy:maxPerceptualDistance:)
    let variants: (Color, WCAGContrastLevel, Int, Double) -> [ColorAccessibilityResult] =
        color.suggestAccessibleVariantResults(with:targetLevel:count:maxPerceptualDistance:)
    let inferredVariants = color.suggestAccessibleVariantResults(with:targetLevel:count:maxPerceptualDistance:)
    let compare: (Color) -> ColorComparisonResult = color.comparisonResult(with:)
    let contrast: (Color) -> ColorContrastResult = color.contrastResult(with:)
    let legacy: (Color) -> ColorDifference = color.compare(with:)
    let unboundCompare: (Color) -> (Color) -> ColorComparisonResult = Color.comparisonResult(with:)
    _ = enhance(.white, .AA, .preserveHue, 30)
    _ = inferredEnhance(.white, .AAA, .minimumChange, 10)
    _ = variants(.white, .AA, 3, 30)
    _ = inferredVariants(.white, .AA, 3, 30)
    _ = compare(.white)
    _ = contrast(.white)
    _ = legacy(.white)
    _ = unboundCompare(color)(.white)
    _ = color.enhancementResult(with: .white)
    _ = color.suggestAccessibleVariantResults(with: .white)
}
