import CoreGraphics
import Foundation
import SwiftUI

/// A color vision deficiency supported by ColorKit's fixed-color simulation.
public enum ColorVisionDeficiency: CaseIterable, Identifiable, Sendable {
    /// Absence of functioning long-wavelength cones.
    case protanopia

    /// Absence of functioning medium-wavelength cones.
    case deuteranopia

    /// Absence of functioning short-wavelength cones.
    case tritanopia

    /// The deficiency itself provides a stable identity.
    public var id: Self { self }

    var matrix: ColorVisionMatrix {
        // Machado, Oliveira, and Fernandes (2009), severity 1.0.
        switch self {
        case .protanopia:
            return ColorVisionMatrix(
                red: .init(red: 0.152286, green: 1.052583, blue: -0.204868),
                green: .init(red: 0.114503, green: 0.786281, blue: 0.099216),
                blue: .init(red: -0.003882, green: -0.048116, blue: 1.051998)
            )
        case .deuteranopia:
            return ColorVisionMatrix(
                red: .init(red: 0.367322, green: 0.860646, blue: -0.227968),
                green: .init(red: 0.280085, green: 0.672501, blue: 0.047413),
                blue: .init(red: -0.011820, green: 0.042940, blue: 0.968881)
            )
        case .tritanopia:
            return ColorVisionMatrix(
                red: .init(red: 1.255528, green: -0.076749, blue: -0.178779),
                green: .init(red: -0.078411, green: 0.930809, blue: 0.147602),
                blue: .init(red: 0.004733, green: 0.691367, blue: 0.303900)
            )
        }
    }
}

struct ColorVisionMatrix: Sendable {
    struct Row: Sendable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat

        func applying(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
            self.red * red + self.green * green + self.blue * blue
        }
    }

    let red: Row
    let green: Row
    let blue: Row

    func applying(red: CGFloat, green: CGFloat, blue: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        (
            red: self.red.applying(red: red, green: green, blue: blue),
            green: self.green.applying(red: red, green: green, blue: blue),
            blue: self.blue.applying(red: red, green: green, blue: blue)
        )
    }
}

public extension Color {
    /// Simulates this fixed color for a supported color vision deficiency.
    ///
    /// Returns `nil` for dynamic, semantic, pattern, unsupported, nonfinite, or
    /// out-of-gamut colors. The simulation preserves the input color's opacity.
    ///
    /// - Parameter deficiency: The color vision deficiency to simulate.
    /// - Returns: The simulated color in sRGB, or `nil` when the input cannot be resolved safely.
    func simulated(for deficiency: ColorVisionDeficiency) -> Color? {
        guard let source = ResolvedSRGBA.resolve(self), source.isInSRGBGamut else { return nil }
        let transformed = deficiency.matrix.applying(
            red: source.red.linearizedSRGB,
            green: source.green.linearizedSRGB,
            blue: source.blue.linearizedSRGB
        )
        return Color(
            .sRGB,
            red: transformed.red.clampedToUnitRange.nonlinearSRGB,
            green: transformed.green.clampedToUnitRange.nonlinearSRGB,
            blue: transformed.blue.clampedToUnitRange.nonlinearSRGB,
            opacity: source.alpha
        )
    }
}

private extension CGFloat {
    var linearizedSRGB: Self {
        self <= 0.04045 ? self / 12.92 : pow((self + 0.055) / 1.055, 2.4)
    }

    var nonlinearSRGB: Self {
        self <= 0.0031308 ? self * 12.92 : 1.055 * pow(self, 1 / 2.4) - 0.055
    }

    var clampedToUnitRange: Self {
        Swift.min(Swift.max(self, 0), 1)
    }
}
