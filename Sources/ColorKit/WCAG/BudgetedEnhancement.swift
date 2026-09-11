import SwiftUI

/// Selects only verifiable, in-budget candidates from the existing strategy paths.
struct BudgetedEnhancement {
    let configuration: AccessibilityEnhancer.Configuration

    func result(for original: Color, against background: Color) -> ColorAccessibilityResult {
        let budget = configuration.maxPerceptualDistance
        let originalContrast = StrictWCAGContrast.measure(foreground: original, background: background).ratio
        guard AccessibilityEnhancer.Configuration.isValidDistanceBudget(budget) else {
            return result(color: original, contrast: originalContrast, distance: nil)
        }
        let resolvedOriginal = ResolvedSRGBA.resolve(original)
        let originalResult = result(
            color: original,
            contrast: originalContrast,
            distance: distance(from: resolvedOriginal, to: original)
        )
        guard originalResult.status == .bestEffort, budget > 0 else { return originalResult }

        var passing: ColorAccessibilityResult?
        var bestEffort = originalResult
        func examine(_ candidate: Color) {
            guard let distance = distance(from: resolvedOriginal, to: candidate), distance <= budget,
                  let contrast = StrictWCAGContrast.measure(foreground: candidate, background: background).ratio
            else { return }
            let candidateResult = result(color: candidate, contrast: contrast, distance: distance)
            if candidateResult.meetsTarget {
                if passing == nil || (
                    configuration.strategy == .minimumChange &&
                    distance < (passing?.perceptualDistance ?? .infinity)
                ) {
                    passing = candidateResult
                }
            } else if contrast > (bestEffort.contrastRatio ?? 0) || (
                contrast == bestEffort.contrastRatio &&
                distance < (bestEffort.perceptualDistance ?? .infinity)
            ) {
                bestEffort = candidateResult
            }
        }
        let fallback = EnhancementCandidateSearch(configuration: configuration).candidate(
            for: original,
            against: background
        ) { candidate in
            examine(candidate)
            return false
        }
        examine(fallback)

        return passing ?? bestEffort
    }

    private func distance(from original: ResolvedSRGBA?, to candidate: Color) -> Double? {
        Color.perceptualDistance(first: original, second: ResolvedSRGBA.resolve(candidate))
    }

    private func result(color: Color, contrast: Double?, distance: Double?) -> ColorAccessibilityResult {
        ColorAccessibilityResult(
            color: color,
            targetLevel: configuration.targetLevel,
            contrastRatio: contrast,
            perceptualDistance: distance,
            maximumPerceptualDistance: configuration.maxPerceptualDistance
        )
    }
}
