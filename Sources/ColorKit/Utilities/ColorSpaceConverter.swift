import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A structure that represents color components in various color spaces
public struct ColorComponents: Sendable {
    /// RGB color components
    public let rgb: (red: Double, green: Double, blue: Double, alpha: Double)
    /// HSL color components
    public let hsl: (hue: Double, saturation: Double, lightness: Double)
    /// HSB color components
    public let hsb: (hue: Double, saturation: Double, brightness: Double)
    /// CMYK color components
    public let cmyk: (cyan: Double, magenta: Double, yellow: Double, key: Double)
    /// LAB color components
    public let lab: (l: Double, a: Double, b: Double)
    /// XYZ color components
    public let xyz: (x: Double, y: Double, z: Double)

    /// A human-readable description of the color components
    public var description: String {
        """
        RGB:
        - Red: \(String(format: "%.2f", rgb.red * 255)) (\(String(format: "%.2f", rgb.red)))
        - Green: \(String(format: "%.2f", rgb.green * 255)) (\(String(format: "%.2f", rgb.green)))
        - Blue: \(String(format: "%.2f", rgb.blue * 255)) (\(String(format: "%.2f", rgb.blue)))
        - Alpha: \(String(format: "%.2f", rgb.alpha))

        HSL:
        - Hue: \(String(format: "%.2f", hsl.hue * 360))°
        - Saturation: \(String(format: "%.2f", hsl.saturation * 100))%
        - Lightness: \(String(format: "%.2f", hsl.lightness * 100))%

        HSB:
        - Hue: \(String(format: "%.2f", hsb.hue * 360))°
        - Saturation: \(String(format: "%.2f", hsb.saturation * 100))%
        - Brightness: \(String(format: "%.2f", hsb.brightness * 100))%

        CMYK:
        - Cyan: \(String(format: "%.2f", cmyk.cyan * 100))%
        - Magenta: \(String(format: "%.2f", cmyk.magenta * 100))%
        - Yellow: \(String(format: "%.2f", cmyk.yellow * 100))%
        - Key: \(String(format: "%.2f", cmyk.key * 100))%

        LAB:
        - L: \(String(format: "%.2f", lab.l))
        - a: \(String(format: "%.2f", lab.a))
        - b: \(String(format: "%.2f", lab.b))

        XYZ:
        - X: \(String(format: "%.2f", xyz.x))
        - Y: \(String(format: "%.2f", xyz.y))
        - Z: \(String(format: "%.2f", xyz.z))
        """
    }
}

/// A utility for converting colors between different color spaces
public struct ColorSpaceConverter {
    private let color: Color

    /// Creates a new color space converter for a specific color
    /// - Parameter color: The color to convert
    public init(color: Color) {
        self.color = color
    }

    /// Get all color components in various color spaces
    /// - Returns: A ColorComponents structure with all color space representations
    public func getAllColorComponents() -> ColorComponents {
        let rgb = color.rgbaComponents()

        // Get HSL
        let hsl = color.hslComponents() ?? (hue: 0, saturation: 0, lightness: 0)

        // Get HSB
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        #if canImport(UIKit)
        UIColor(self.color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        #elseif canImport(AppKit)
        let nsColor = NSColor(self.color)
        // Convert to RGB colorspace first to avoid NSInvalidArgumentException
        if let rgbColor = nsColor.usingColorSpace(.sRGB) {
            rgbColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        }
        #endif

        let hsb = (hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness))

        // Get CMYK
        let cmykComponents = color.cmykComponents() ?? (cyan: 0, magenta: 0, yellow: 0, key: 0)
        let cmyk = (
            cyan: Double(cmykComponents.cyan),
            magenta: Double(cmykComponents.magenta),
            yellow: Double(cmykComponents.yellow),
            key: Double(cmykComponents.key)
        )

        // Get LAB
        let lab = calculateLAB(from: rgb)

        // Get XYZ
        let xyz = calculateXYZ(from: rgb)

        return ColorComponents(
            rgb: rgb,
            hsl: (Double(hsl.hue), Double(hsl.saturation), Double(hsl.lightness)),
            hsb: hsb,
            cmyk: cmyk,
            lab: lab,
            xyz: xyz
        )
    }

    /// Calculate LAB color components from RGB
    private func calculateLAB(from rgb: (red: Double, green: Double, blue: Double, alpha: Double)) -> (l: Double, a: Double, b: Double) {
        // First convert RGB to XYZ
        let xyz = calculateXYZ(from: rgb)

        // XYZ to LAB
        // Using D65 reference white
        let refX: Double = 95.047
        let refY: Double = 100.0
        let refZ: Double = 108.883

        let x = xyz.x / refX
        let y = xyz.y / refY
        let z = xyz.z / refZ

        let fx = x > 0.008856 ? pow(x, 1 / 3) : (7.787 * x) + (16 / 116)
        let fy = y > 0.008856 ? pow(y, 1 / 3) : (7.787 * y) + (16 / 116)
        let fz = z > 0.008856 ? pow(z, 1 / 3) : (7.787 * z) + (16 / 116)

        let l = (116 * fy) - 16
        let a = 500 * (fx - fy)
        let b = 200 * (fy - fz)

        return (l, a, b)
    }

    /// Calculate XYZ color components from RGB
    private func calculateXYZ(from rgb: (red: Double, green: Double, blue: Double, alpha: Double)) -> (x: Double, y: Double, z: Double) {
        // Convert RGB to linear RGB
        let r = rgb.red <= 0.04045 ? rgb.red / 12.92 : pow((rgb.red + 0.055) / 1.055, 2.4)
        let g = rgb.green <= 0.04045 ? rgb.green / 12.92 : pow((rgb.green + 0.055) / 1.055, 2.4)
        let b = rgb.blue <= 0.04045 ? rgb.blue / 12.92 : pow((rgb.blue + 0.055) / 1.055, 2.4)

        // Convert linear RGB to XYZ
        let x = r * 0.4124 + g * 0.3576 + b * 0.1805
        let y = r * 0.2126 + g * 0.7152 + b * 0.0722
        let z = r * 0.0193 + g * 0.1192 + b * 0.9505

        return (x * 100, y * 100, z * 100)
    }
}

public extension Color {
    /// Get color components in all available color spaces
    /// - Returns: A ColorComponents structure with all color space representations
    func colorSpaceComponents() -> ColorComponents {
        let converter = ColorSpaceConverter(color: self)
        return converter.getAllColorComponents()
    }
}

/// A view that displays detailed color information in multiple color spaces
public struct ColorSpaceInspectorView: View {
    private let color: Color
    private let components: ColorComponents

    public init(color: Color) {
        self.color = color
        self.components = color.colorSpaceComponents()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Color preview
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 60, height: 60)
                    .shadow(radius: 2)

                VStack(alignment: .leading) {
                    Text("Color Space Inspector")
                        .font(.headline)

                    if let hex = color.hexValue() {
                        Text(hex)
                            .font(.system(.body, design: .monospaced))
                            .applyTextSelection()
                    }
                }
            }

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // RGB values
                    ColorSpaceSection(
                        title: "RGB",
                        values: [
                            ("R", String(format: "%.0f", components.rgb.red * 255)),
                            ("G", String(format: "%.0f", components.rgb.green * 255)),
                            ("B", String(format: "%.0f", components.rgb.blue * 255)),
                            ("A", String(format: "%.2f", components.rgb.alpha))
                        ]
                    )

                    // HSL values
                    ColorSpaceSection(
                        title: "HSL",
                        values: [
                            ("H", String(format: "%.0f°", components.hsl.hue * 360)),
                            ("S", String(format: "%.0f%%", components.hsl.saturation * 100)),
                            ("L", String(format: "%.0f%%", components.hsl.lightness * 100))
                        ]
                    )

                    // HSB values
                    ColorSpaceSection(
                        title: "HSB",
                        values: [
                            ("H", String(format: "%.0f°", components.hsb.hue * 360)),
                            ("S", String(format: "%.0f%%", components.hsb.saturation * 100)),
                            ("B", String(format: "%.0f%%", components.hsb.brightness * 100))
                        ]
                    )

                    // CMYK values
                    ColorSpaceSection(
                        title: "CMYK",
                        values: [
                            ("C", String(format: "%.0f%%", components.cmyk.cyan * 100)),
                            ("M", String(format: "%.0f%%", components.cmyk.magenta * 100)),
                            ("Y", String(format: "%.0f%%", components.cmyk.yellow * 100)),
                            ("K", String(format: "%.0f%%", components.cmyk.key * 100))
                        ]
                    )

                    // LAB values
                    ColorSpaceSection(
                        title: "LAB",
                        values: [
                            ("L", String(format: "%.1f", components.lab.l)),
                            ("a", String(format: "%.1f", components.lab.a)),
                            ("b", String(format: "%.1f", components.lab.b))
                        ]
                    )

                    // XYZ values
                    ColorSpaceSection(
                        title: "XYZ",
                        values: [
                            ("X", String(format: "%.1f", components.xyz.x)),
                            ("Y", String(format: "%.1f", components.xyz.y)),
                            ("Z", String(format: "%.1f", components.xyz.z))
                        ]
                    )
                }
                .padding()
            }
        }
        .padding()
        .background(backgroundColorView)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var backgroundColorView: some View {
        #if canImport(UIKit)
        return Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        return Color(NSColor.windowBackgroundColor)
        #else
        return Color.white
        #endif
    }
}

private struct ColorSpaceSection: View {
    let title: String
    let values: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(values, id: \.0) { value in
                    HStack {
                        Text(value.0)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 20, alignment: .leading)

                        Text(value.1)
                            .font(.system(.body, design: .monospaced))
                            .applyTextSelection()
                    }
                }
            }
        }
    }
}
