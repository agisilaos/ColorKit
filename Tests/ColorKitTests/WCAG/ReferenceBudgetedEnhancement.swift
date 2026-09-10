import SwiftUI

@testable import ColorKit

// Frozen collect/sort/scan implementation from d2bcf32. Keep independent of production selection.
struct ReferenceBudgetedEnhancement {
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

        var candidates: [ColorAccessibilityResult] = []
        func examine(_ candidate: Color) {
            guard let distance = distance(from: resolvedOriginal, to: candidate), distance <= budget,
                  let contrast = StrictWCAGContrast.measure(foreground: candidate, background: background).ratio
            else { return }
            candidates.append(result(color: candidate, contrast: contrast, distance: distance))
        }
        let fallback = EnhancementCandidateSearch(configuration: configuration).candidate(
            for: original,
            against: background
        ) { candidate in
            examine(candidate)
            return false
        }
        examine(fallback)

        if configuration.strategy == .minimumChange {
            // Explicit offsets preserve strategy order when distances are equal.
            candidates = candidates.enumerated()
                .sorted {
                    let first = $0.element.perceptualDistance ?? .infinity
                    let second = $1.element.perceptualDistance ?? .infinity
                    return first == second ? $0.offset < $1.offset : first < second
                }
                .map(\.element)
        }

        var best = originalResult
        for candidate in candidates {
            if candidate.meetsTarget { return candidate }
            let contrast = candidate.contrastRatio ?? 0
            let bestContrast = best.contrastRatio ?? 0
            if contrast > bestContrast || (
                contrast == bestContrast &&
                (candidate.perceptualDistance ?? .infinity) < (best.perceptualDistance ?? .infinity)
            ) {
                best = candidate
            }
        }
        return best
    }

    private func distance(from original: ResolvedSRGBA?, to candidate: Color) -> Double? {
        guard case let .available(difference) = Color.comparisonResult(first: original, second: ResolvedSRGBA.resolve(candidate)) else { return nil }
        return difference.perceptualDifference
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
