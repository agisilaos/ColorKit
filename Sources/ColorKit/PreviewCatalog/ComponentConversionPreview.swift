import SwiftUI

/// A small client of the result API; the existing color-space preview remains independent.
struct ComponentConversionPreview: View {
    @State private var sample = ComponentConversionSample.black

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("Input color", selection: $sample) {
                ForEach(ComponentConversionSample.allCases) { sample in
                    Text(sample.rawValue).tag(sample)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()

            ComponentConversionInspection(sample: sample)
        }
        .navigationTitle("Component Results")
    }
}

enum ComponentConversionSample: String, CaseIterable, Identifiable {
    case black = "Fixed sRGB black"
    case wideGamut = "Display P3 red"
    case unresolved = "Dynamic primary"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .black: return Color(.sRGB, red: 0, green: 0, blue: 0)
        case .wideGamut: return Color(.displayP3, red: 1, green: 0, blue: 0)
        case .unresolved: return .primary
        }
    }

    var explanation: String {
        switch self {
        case .black:
            return "Zero is a valid component value. Black has zero hue by convention and 100% CMYK black."
        case .wideGamut:
            return "This red is outside sRGB. Extended sRGBA and finite XYZ/LAB remain available; bounded conversions would require clipping."
        case .unresolved:
            return "The swatch follows appearance, but .primary has no fixed components here. Resolve it for an explicit appearance before converting."
        }
    }
}

struct ComponentConversionInspection: View {
    let sample: ComponentConversionSample

    var body: some View {
        // One call supplies every row, including partial failures.
        let rows = ComponentConversionRow.rows(for: sample.color.componentConversionResults())
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sample.color
                    .frame(height: 44)
                    .overlay(Rectangle().stroke(Color.secondary, lineWidth: 1))
                    .accessibilityHidden(true)
                Text(sample.rawValue).font(.title2).accessibilityAddTraits(.isHeader)
                Text(sample.explanation)
                Text("All values share one fixed, uncomposited sRGBA snapshot. No automatic appearance resolution or gamut clipping. Alpha is retained only in sRGBA and Hex.")
                    .font(.footnote)
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.title).font(.headline)
                        Text(row.isAvailable ? "Available" : "Unavailable").font(.subheadline)
                        Text(row.units).font(.footnote)
                        Text(row.detail).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityLabel(Text(row.title))
                    .accessibilityValue(Text("\(row.isAvailable ? "Available" : "Unavailable"). \(row.units). \(row.detail)"))
                    .accessibilityIdentifier("conversion-\(row.title)")
                    Divider()
                }
                Text("Values are rounded for display. XYZ and LAB are coordinates, not percentages. CMYK uses no printer profile. The swatch is not a display-accuracy guarantee.")
                    .font(.footnote)
            }
            .padding()
            .accessibilityElement(children: .contain)
        }
    }
}

/// Presentation only: failures never enter the numeric formatter.
struct ComponentConversionRow: Identifiable {
    let title: String
    let units: String
    let detail: String
    let isAvailable: Bool
    var id: String { title }

    init<Value>(_ title: String, units: String, result: Result<Value, ColorConversionIssue>, format: (Value) -> String) {
        self.title = title
        self.units = units
        switch result {
        case .success(let value):
            detail = format(value)
            isAvailable = true
        case .failure(let issue):
            detail = Self.explanation(for: issue)
            isAvailable = false
        }
    }

    static func rows(for result: ColorComponentConversionResults) -> [Self] {
        [
            Self("sRGBA", units: "Extended sRGB fractions; alpha 0–1", result: result.srgba) {
                "Red \(number($0.red)), green \(number($0.green)), blue \(number($0.blue)), alpha \(number($0.alpha))"
            },
            Self("HSL", units: "Hue in degrees; saturation and lightness 0–100%", result: result.hsl) {
                "Hue \(number($0.hue * 360))°, saturation \(number($0.saturation * 100))%, lightness \(number($0.lightness * 100))%"
            },
            Self("HSB", units: "Hue in degrees; saturation and brightness 0–100%", result: result.hsb) {
                "Hue \(number($0.hue * 360))°, saturation \(number($0.saturation * 100))%, brightness \(number($0.brightness * 100))%"
            },
            Self("CMYK", units: "Algebraic components shown as 0–100%", result: result.cmyk) {
                "Cyan \(number($0.cyan * 100))%, magenta \(number($0.magenta * 100))%, yellow \(number($0.yellow * 100))%, black \(number($0.key * 100))%"
            },
            Self("XYZ", units: "D65 reference white Y = 100; unbounded", result: result.xyz) {
                "X \(number($0.x)), Y \(number($0.y)), Z \(number($0.z))"
            },
            Self("LAB", units: "CIE L*a*b*, D65; extended values are unbounded", result: result.lab) {
                "L* \(number($0.lightness)), a* \(number($0.a)), b* \(number($0.b))"
            },
            Self("Hex", units: "sRGB #RRGGBBAA; rounded 8-bit channels", result: result.hex) { $0 }
        ]
    }

    private static func number(_ value: Double) -> String {
        // NumberFormatter supports the catalog's iOS 14 deployment target.
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func explanation(for issue: ColorConversionIssue) -> String {
        switch issue {
        case .unresolvedInput:
            return "No fixed components. Named or dynamic colors may need explicit appearance resolution."
        case .unsupportedColorModel:
            return "The source needs an RGB or grayscale color space."
        case .invalidComponents:
            return "Components must be finite and alpha must be between 0 and 1."
        case .colorSpaceConversionFailed:
            return "The platform could not convert this input to extended sRGB."
        case .outOfSRGBGamut:
            return "Outside sRGB: this representation would require clipping."
        case .nonfiniteResult:
            return "This conversion could not produce finite coordinates."
        }
    }
}

#Preview {
    ComponentConversionPreview()
}
