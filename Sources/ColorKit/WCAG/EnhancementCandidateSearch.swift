import SwiftUI

/// The shared, bounded candidate paths. The acceptance rule belongs to the caller:
/// legacy enhancement stops on its contrast threshold; budgeted enhancement collects
/// the paths before ranking eligible candidates. The returned fallback is examined too.
struct EnhancementCandidateSearch {
    let configuration: AccessibilityEnhancer.Configuration

    func candidate(
        for color: Color,
        against backgroundColor: Color,
        accepting isAccepted: (Color) -> Bool
    ) -> Color {
        switch configuration.strategy {
        case .preserveHue:
            return enhancePreservingHue(color, against: backgroundColor, accepting: isAccepted)
        case .preserveSaturation:
            return enhancePreservingSaturation(color, against: backgroundColor, accepting: isAccepted)
        case .preserveLightness:
            return enhancePreservingLightness(color, against: backgroundColor, accepting: isAccepted)
        case .minimumChange:
            return enhanceWithMinimumChange(color, against: backgroundColor, accepting: isAccepted)
        }
    }

    private func enhancePreservingHue(
        _ color: Color,
        against backgroundColor: Color,
        accepting isAccepted: (Color) -> Bool
    ) -> Color {
        guard let hsl = color.hslComponents() else { return color }

        // Start with the original color's HSL values
        let hue = hsl.hue
        var saturation = hsl.saturation
        var lightness = hsl.lightness

        // Determine if we need to make the color lighter or darker
        let bgLuminance = backgroundColor.wcagRelativeLuminance()
        let needDarker = bgLuminance > 0.5

        // If we prefer the opposite of what's needed, adjust saturation more
        let adjustLightness = needDarker == configuration.preferDarker

        // Adjust lightness and saturation in small steps
        let maxSteps = 20
        var currentColor = color

        for _ in 0..<maxSteps {
            if adjustLightness {
                // Adjust lightness
                if needDarker {
                    lightness = max(0, lightness - 0.05)
                } else {
                    lightness = min(1, lightness + 0.05)
                }
            } else {
                // Adjust saturation
                saturation = min(1, saturation + 0.05)
            }

            // Create the adjusted color
            currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)

            // Check if it meets the contrast requirements
            if isAccepted(currentColor) {
                return currentColor
            }

            // If we've adjusted saturation a lot and still not meeting requirements, adjust lightness too
            if saturation > 0.9 && !adjustLightness {
                if needDarker {
                    lightness = max(0, lightness - 0.05)
                } else {
                    lightness = min(1, lightness + 0.05)
                }
                currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)
            }
        }

        // If we couldn't find a suitable color, fall back to black or white
        return needDarker ? Color.black : Color.white
    }

    private func enhancePreservingSaturation(
        _ color: Color,
        against backgroundColor: Color,
        accepting isAccepted: (Color) -> Bool
    ) -> Color {
        guard let hsl = color.hslComponents() else { return color }

        // Start with the original color's HSL values
        var hue = hsl.hue
        let saturation = hsl.saturation
        var lightness = hsl.lightness

        // Determine if we need to make the color lighter or darker
        let bgLuminance = backgroundColor.wcagRelativeLuminance()
        let needDarker = bgLuminance > 0.5

        // Adjust hue and lightness in small steps
        let maxSteps = 20
        var currentColor = color

        for _ in 0..<maxSteps {
            // Adjust lightness
            if needDarker {
                lightness = max(0, lightness - 0.05)
            } else {
                lightness = min(1, lightness + 0.05)
            }

            // Adjust hue slightly
            hue = fmod(hue + 0.02, 1.0)

            // Create the adjusted color
            currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)

            // Check if it meets the contrast requirements
            if isAccepted(currentColor) {
                return currentColor
            }
        }

        // If we couldn't find a suitable color, fall back to black or white
        return needDarker ? Color.black : Color.white
    }

    private func enhancePreservingLightness(
        _ color: Color,
        against backgroundColor: Color,
        accepting isAccepted: (Color) -> Bool
    ) -> Color {
        guard let hsl = color.hslComponents() else { return color }

        // Start with the original color's HSL values
        var hue = hsl.hue
        var saturation = hsl.saturation
        let lightness = hsl.lightness

        // Adjust hue and saturation in small steps
        let maxSteps = 20
        var currentColor = color

        for _ in 0..<maxSteps {
            // Adjust saturation
            saturation = min(1, saturation + 0.05)

            // Adjust hue slightly
            hue = fmod(hue + 0.02, 1.0)

            // Create the adjusted color
            currentColor = Color(hue: hue, saturation: saturation, lightness: lightness)

            // Check if it meets the contrast requirements
            if isAccepted(currentColor) {
                return currentColor
            }
        }

        // If we couldn't find a suitable color with preserved lightness,
        // we need to adjust lightness as a last resort
        return enhancePreservingHue(color, against: backgroundColor, accepting: isAccepted)
    }

    private func enhanceWithMinimumChange(
        _ color: Color,
        against backgroundColor: Color,
        accepting isAccepted: (Color) -> Bool
    ) -> Color {
        guard let lab = color.labComponents() else { return color }

        // Start with the original color's LAB values
        let originalL = lab.L
        let originalA = lab.a
        let originalB = lab.b

        // Determine if we need to make the color lighter or darker
        let bgLuminance = backgroundColor.wcagRelativeLuminance()
        let needDarker = bgLuminance > 0.5

        // Adjust LAB values in small steps
        let maxSteps = 30
        var currentColor = color
        for step in 0..<maxSteps {
            // Preserve the historical schedule: the old >20 branch was unreachable.
            let stepSize = step > 10 ? 4.0 : 2.0

            // Adjust L (lightness) based on whether we need darker or lighter
            let newL = needDarker
                ? max(0, originalL - CGFloat(step) * CGFloat(stepSize))
                : min(100, originalL + CGFloat(step) * CGFloat(stepSize))

            // Make small adjustments to a and b to maintain perceptual similarity
            let newA = originalA + CGFloat(sin(Double(step) * 0.2) * 2)
            let newB = originalB + CGFloat(cos(Double(step) * 0.2) * 2)

            // Create the adjusted color
            currentColor = Color(L: newL, a: newA, b: newB)

            // Check if it meets the contrast requirements
            if isAccepted(currentColor) {
                return currentColor
            }
        }

        // If we couldn't find a suitable color with minimum change,
        // fall back to a more aggressive strategy
        return enhancePreservingHue(color, against: backgroundColor, accepting: isAccepted)
    }
}
