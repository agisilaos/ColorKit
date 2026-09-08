import SwiftUI

/// The first observable blocker for one component conversion.
public enum ColorConversionIssue: Error, Sendable, Equatable {
    /// No fixed color is available; this does not establish whether appearance resolution would help.
    case unresolvedInput
    /// The source has no color space or uses a model other than RGB or grayscale.
    case unsupportedColorModel
    /// Source components are malformed or nonfinite, or alpha is outside 0–1.
    case invalidComponents
    /// The platform could not produce a valid extended-sRGB snapshot.
    case colorSpaceConversionFailed
    /// A bounded representation would require clipping a channel outside 0–1.
    case outOfSRGBGamut
    /// Conversion arithmetic or a required XYZ dependency produced nonfinite coordinates.
    case nonfiniteResult
}

/// Finite nonlinear extended-sRGB components with separate, unpremultiplied alpha.
public struct SRGBAComponents: Sendable, Equatable {
    /// The red channel, which may be below zero or above one.
    public let red: Double
    /// The green channel, which may be below zero or above one.
    public let green: Double
    /// The blue channel, which may be below zero or above one.
    public let blue: Double
    /// Opacity in 0–1; zero does not erase the RGB channels.
    public let alpha: Double
}

/// Bounded-sRGB HSL coordinates, independent of opacity.
public struct HSLComponents: Sendable, Equatable {
    /// Hue in turns, from zero up to but excluding one; achromatic colors use zero.
    public let hue: Double
    /// Saturation in 0–1.
    public let saturation: Double
    /// Lightness in 0–1.
    public let lightness: Double
}

/// Bounded-sRGB HSV coordinates, named HSB for consistency with SwiftUI.
public struct HSBComponents: Sendable, Equatable {
    /// Hue in turns, from zero up to but excluding one; achromatic colors use zero.
    public let hue: Double
    /// Saturation in 0–1, independent of opacity.
    public let saturation: Double
    /// The maximum RGB channel in 0–1, independent of opacity.
    public let brightness: Double
}

/// Algebraic sRGB complements in 0–1, independent of opacity.
///
/// These coordinates use no printer or ink profile and do not predict printed appearance.
public struct CMYKComponents: Sendable, Equatable {
    /// The cyan fraction.
    public let cyan: Double
    /// The magenta fraction.
    public let magenta: Double
    /// The yellow fraction.
    public let yellow: Double
    /// The black fraction; black uses C = M = Y = 0 and K = 1.
    public let key: Double
}

/// Finite D65 XYZ coordinates on the reference-white Y = 100 scale, independent of opacity.
///
/// Coordinates are not percentages and are not bounded to 0–100.
public struct XYZComponents: Sendable, Equatable {
    /// The X tristimulus coordinate.
    public let x: Double
    /// The Y tristimulus coordinate.
    public let y: Double
    /// The Z tristimulus coordinate.
    public let z: Double
}

/// Finite CIE L*a*b* coordinates relative to D65 white (95.047, 100, 108.883).
///
/// Opacity does not affect these coordinates. Extended inputs are not clamped to conventional LAB ranges.
public struct LABComponents: Sendable, Equatable {
    /// L*, conventionally 0–100 for ordinary surface colors, but unbounded for extended inputs.
    public let lightness: Double
    /// The a* green–red coordinate, without an imposed range.
    public let a: Double
    /// The b* blue–yellow coordinate, without an imposed range.
    public let b: Double
}

/// Independent component conversions derived from one fixed, uncomposited sRGBA snapshot.
///
/// A failed representation does not discard successful ones. Results do not consult legacy caches
/// or change with appearance. Numeric representations other than sRGBA omit alpha; retrieve it
/// from ``srgba``. A successful conversion makes no claim about contrast or displayed appearance.
public struct ColorComponentConversionResults: Sendable {
    /// Extended sRGBA, available whenever fixed resolution succeeds.
    public let srgba: Result<SRGBAComponents, ColorConversionIssue>
    /// HSL, unavailable outside the sRGB gamut.
    public let hsl: Result<HSLComponents, ColorConversionIssue>
    /// HSB, unavailable outside the sRGB gamut.
    public let hsb: Result<HSBComponents, ColorConversionIssue>
    /// Algebraic CMYK, unavailable outside the sRGB gamut.
    public let cmyk: Result<CMYKComponents, ColorConversionIssue>
    /// D65 XYZ, unavailable when its calculation produces nonfinite coordinates.
    public let xyz: Result<XYZComponents, ColorConversionIssue>
    /// D65 LAB, unavailable when XYZ or LAB cannot be calculated finitely.
    public let lab: Result<LABComponents, ColorConversionIssue>
    /// Uppercase #RRGGBBAA, with nearest-byte rounding (ties upward), unavailable outside sRGB.
    ///
    /// Quantization loses at most 0.5/255 per channel, including alpha; no gamut mapping occurs.
    public let hex: Result<String, ColorConversionIssue>
}

public extension Color {
    /// Returns independent component conversions of this fixed color.
    ///
    /// RGB and grayscale sources convert to extended nonlinear sRGB once. Inputs without fixed
    /// components, including named and dynamic colors, require caller-side resolution first.
    /// No ambient appearance, clipping, endpoint tolerance, or background compositing is used.
    /// Alpha must be finite and in 0–1, even for representations that omit it.
    ///
    /// Extended sRGBA and finite XYZ/LAB remain available when HSL, HSB, CMYK, and Hex cannot
    /// represent an out-of-gamut color. Signed extended-sRGB decoding and exact LAB constants
    /// can yield different XYZ/LAB coordinates from legacy accessors, which remain unchanged.
    ///
    /// ```swift
    /// let color = Color(.displayP3, red: 1, green: 0, blue: 0)
    /// let conversions = color.componentConversionResults()
    /// if case .success(let lab) = conversions.lab { print(lab.lightness) }
    /// if case .failure(let issue) = conversions.hex { print(issue) }
    /// ```
    ///
    /// - Returns: Seven independent results, with a shared issue when fixed resolution fails.
    func componentConversionResults() -> ColorComponentConversionResults {
        let resolved = ResolvedSRGBA.resolveResult(self)
        let bounded = resolved.flatMap { snapshot -> Result<BoundedColorConversion, ColorConversionIssue> in
            snapshot.isInSRGBGamut ? .success(BoundedColorConversion(snapshot)) : .failure(.outOfSRGBGamut)
        }
        let xyz = resolved.flatMap(ComponentConversion.xyz)
        return ColorComponentConversionResults(
            srgba: resolved.map {
                SRGBAComponents(red: Double($0.red), green: Double($0.green), blue: Double($0.blue), alpha: Double($0.alpha))
            },
            hsl: bounded.map(\.hsl),
            hsb: bounded.map(\.hsb),
            cmyk: bounded.map(\.cmyk),
            xyz: xyz,
            lab: xyz.flatMap(ComponentConversion.lab),
            hex: bounded.map(\.hex)
        )
    }
}

/// The four bounded representations, calculated together from one in-gamut snapshot.
private struct BoundedColorConversion {
    let hsl: HSLComponents
    let hsb: HSBComponents
    let cmyk: CMYKComponents
    let hex: String

    init(_ rgb: ResolvedSRGBA) {
        let r = Double(rgb.red)
        let g = Double(rgb.green)
        let b = Double(rgb.blue)
        let maximum = max(r, g, b)
        let minimum = min(r, g, b)
        let chroma = maximum - minimum
        let lightness = (maximum + minimum) / 2
        let hue: Double
        if chroma == 0 {
            hue = 0
        } else {
            let sector: Double
            if maximum == r {
                sector = (g - b) / chroma + (g < b ? 6 : 0)
            } else if maximum == g {
                sector = (b - r) / chroma + 2
            } else {
                sector = (r - g) / chroma + 4
            }
            // Rounding near red can reach exactly one turn; zero is the same hue.
            hue = (sector / 6).truncatingRemainder(dividingBy: 1)
        }
        // Subtract before adding near white to avoid rounding the denominator to zero.
        let denominator = lightness > 0.5 ? (1 - maximum) + (1 - minimum) : maximum + minimum
        hsl = HSLComponents(hue: hue, saturation: chroma == 0 ? 0 : chroma / denominator, lightness: lightness)
        hsb = HSBComponents(hue: hue, saturation: maximum == 0 ? 0 : chroma / maximum, brightness: maximum)
        // Divide by maximum directly: 1 - K can round to zero near black.
        cmyk = CMYKComponents(
            cyan: maximum == 0 ? 0 : (maximum - r) / maximum,
            magenta: maximum == 0 ? 0 : (maximum - g) / maximum,
            yellow: maximum == 0 ? 0 : (maximum - b) / maximum,
            key: 1 - maximum
        )
        hex = String(
            format: "#%02X%02X%02X%02X",
            Int((r * 255).rounded()),
            Int((g * 255).rounded()),
            Int((b * 255).rounded()),
            Int((rgb.alpha * 255).rounded())
        )
    }
}

/// New result arithmetic; legacy XYZ/LAB formulas intentionally remain separate.
private enum ComponentConversion {
    static func xyz(_ rgb: ResolvedSRGBA) -> Result<XYZComponents, ColorConversionIssue> {
        func linearize(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            let magnitude = abs(value)
            return magnitude <= 0.04045 ? value / 12.92
                : (value < 0 ? -1 : 1) * pow((magnitude + 0.055) / 1.055, 2.4)
        }
        let r = linearize(rgb.red)
        let g = linearize(rgb.green)
        let b = linearize(rgb.blue)
        let xyz = XYZComponents(
            x: (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) * 100,
            y: (r * 0.2126729 + g * 0.7151522 + b * 0.0721750) * 100,
            z: (r * 0.0193339 + g * 0.1191920 + b * 0.9503041) * 100
        )
        guard xyz.x.isFinite, xyz.y.isFinite, xyz.z.isFinite else { return .failure(.nonfiniteResult) }
        return .success(xyz)
    }

    static func lab(_ xyz: XYZComponents) -> Result<LABComponents, ColorConversionIssue> {
        func transform(_ value: Double) -> Double {
            value > 216.0 / 24_389 ? cbrt(value) : ((24_389.0 / 27) * value + 16) / 116
        }
        let x = transform(xyz.x / 95.047)
        let y = transform(xyz.y / 100)
        let z = transform(xyz.z / 108.883)
        let lab = LABComponents(lightness: 116 * y - 16, a: 500 * (x - y), b: 200 * (y - z))
        guard lab.lightness.isFinite, lab.a.isFinite, lab.b.isFinite else { return .failure(.nonfiniteResult) }
        return .success(lab)
    }
}
