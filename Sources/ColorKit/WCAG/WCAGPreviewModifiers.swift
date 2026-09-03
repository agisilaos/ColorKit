import SwiftUI

/// A view modifier that displays WCAG compliance information for text against its background
public struct WCAGComplianceModifier: ViewModifier {
    private let foregroundColor: Color
    private let backgroundColor: Color
    private let showDetails: Bool

    public init(foreground: Color, background: Color, showDetails: Bool = true) {
        self.foregroundColor = foreground
        self.backgroundColor = background
        self.showDetails = showDetails
    }

    public func body(content: Content) -> some View {
        let compliance = foregroundColor.wcagCompliance(with: backgroundColor)

        return VStack(alignment: .leading, spacing: 8) {
            content
                .foregroundColor(foregroundColor)
                .padding()
                .background(backgroundColor)
                .cornerRadius(8)

            if showDetails {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Contrast Ratio: \(String(format: "%.2f", compliance.contrastRatio)):1")
                        .font(.subheadline)

                    HStack {
                        ForEach(WCAGContrastLevel.allCases) { level in
                            let passes = compliance.contrastRatio >= level.minimumRatio

                            HStack(spacing: 4) {
                                if #available(macOS 11.0, *) {
                                    Image(systemName: passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(passes ? .green : .red)
                                }

                                Text(level.rawValue)
                                    .font(.caption)
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

/// A deprecated compatibility modifier that leaves content unchanged.
@available(*, deprecated, message: "Transform fixed colors with Color.simulated(for:) instead.")
public struct ColorBlindnessPreviewModifier: ViewModifier {
    /// The cases accepted by the legacy arbitrary-view modifier.
    @available(*, deprecated, message: "Use ColorVisionDeficiency for fixed-color simulation.")
    public enum ColorBlindnessType: String, CaseIterable, Identifiable {
        case normal = "Normal Vision"
        case protanopia = "Protanopia (Red-Blind)"
        case deuteranopia = "Deuteranopia (Green-Blind)"
        case tritanopia = "Tritanopia (Blue-Blind)"
        case achromatopsia = "Achromatopsia (No Color)"

        public var id: String { rawValue }
    }

    /// Creates a no-op compatibility modifier.
    ///
    /// - Parameter type: The legacy simulation selection. It is accepted but not applied.
    @available(*, deprecated, message: "Transform fixed colors with Color.simulated(for:) instead.")
    public init(type: ColorBlindnessType) {
        _ = type
    }

    public func body(content: Content) -> some View {
        content
    }
}

/// The deprecated matrix container used by the legacy preview API.
@available(*, deprecated, message: "Transform fixed colors with Color.simulated(for:) instead.")
public struct ColorEffect: Sendable {
    let matrix: [CGFloat]

    init(matrix: [CGFloat]) {
        precondition(matrix.count == 20, "Color matrix must have 20 elements")
        self.matrix = matrix
    }

    public static let identity = ColorEffect(matrix: Array(repeating: 0, count: 20).indices.map { index in
        // Set diagonal elements to 1
        if index % 5 == 0 && index < 16 {
            return 1
        }
        return 0
    })

    public static let protanopia = ColorEffect(matrix: [
        0.567, 0.433, 0, 0, 0,
        0.558, 0.442, 0, 0, 0,
        0, 0.242, 0.758, 0, 0,
        0, 0, 0, 1, 0
    ])

    public static let deuteranopia = ColorEffect(matrix: [
        0.625, 0.375, 0, 0, 0,
        0.7, 0.3, 0, 0, 0,
        0, 0.3, 0.7, 0, 0,
        0, 0, 0, 1, 0
    ])

    public static let tritanopia = ColorEffect(matrix: [
        0.95, 0.05, 0, 0, 0,
        0, 0.433, 0.567, 0, 0,
        0, 0.475, 0.525, 0, 0,
        0, 0, 0, 1, 0
    ])

    public static let grayscale = ColorEffect(matrix: [
        0.299, 0.587, 0.114, 0, 0,
        0.299, 0.587, 0.114, 0, 0,
        0.299, 0.587, 0.114, 0, 0,
        0, 0, 0, 1, 0
    ])
}

extension View {
    /// Apply WCAG compliance checking to a view
    public func wcagCompliance(foreground: Color, background: Color, showDetails: Bool = true) -> some View {
        self.modifier(WCAGComplianceModifier(foreground: foreground, background: background, showDetails: showDetails))
    }

    /// A deprecated compatibility modifier that leaves this view unchanged.
    ///
    /// - Parameter type: The legacy simulation selection. It is accepted but not applied.
    /// - Returns: This view with a no-op compatibility modifier.
    @available(*, deprecated, message: "Transform fixed colors with Color.simulated(for:) instead.")
    public func colorBlindnessPreview(type: ColorBlindnessPreviewModifier.ColorBlindnessType) -> some View {
        self.modifier(ColorBlindnessPreviewModifier(type: type))
    }
}
