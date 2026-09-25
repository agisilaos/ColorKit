import ColorKit
import SwiftUI

// Preserve ordinary, typed, inferred, and unbound references to shipped entry points.
func paletteRandomnessClient<R: RandomNumberGenerator>(_ color: Color, using random: inout R) {
    let generator = AccessiblePaletteGenerator()
    let typed: (Color) -> [Color] = generator.generatePalette
    let inferred = generator.generatePalette
    let unbound = AccessiblePaletteGenerator.generatePalette
    let assessed: (Color, Color) -> [ColorAccessibilityResult] = generator.generateAssessedPalette
    let inferredAssessed = generator.generateAssessedPalette
    let unboundAssessed = AccessiblePaletteGenerator.generateAssessedPalette
    _ = typed(color)
    _ = inferred(color)
    _ = unbound(generator)(color)
    _ = assessed(color, .white)
    _ = inferredAssessed(color, .white)
    _ = unboundAssessed(generator)(color, .white)
    _ = generator.generatePalette(from: color)
    _ = generator.generateAssessedPalette(from: color, against: .white)
    _ = color.generateAccessiblePalette()
    _ = generator.generatePalette(from: color, using: &random)
    _ = generator.generateAssessedPalette(from: color, against: .white, using: &random)
    let controlled: (Color, inout R) -> [Color] = generator.generatePalette(from:using:)
    let controlledAssessment: (Color, Color, inout R) -> [ColorAccessibilityResult] =
        generator.generateAssessedPalette(from:against:using:)
    _ = controlled(color, &random)
    _ = controlledAssessment(color, .white, &random)
}
