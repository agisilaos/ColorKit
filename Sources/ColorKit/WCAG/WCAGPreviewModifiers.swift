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
                                Image(systemName: passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(passes ? .green : .red)
                                
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

/// A view modifier that displays a color blindness simulation preview
public struct ColorBlindnessPreviewModifier: ViewModifier {
    public enum ColorBlindnessType: String, CaseIterable, Identifiable {
        case normal = "Normal Vision"
        case protanopia = "Protanopia (Red-Blind)"
        case deuteranopia = "Deuteranopia (Green-Blind)"
        case tritanopia = "Tritanopia (Blue-Blind)"
        case achromatopsia = "Achromatopsia (No Color)"
        
        public var id: String { rawValue }
    }
    
    private let type: ColorBlindnessType
    
    public init(type: ColorBlindnessType) {
        self.type = type
    }
    
    public func body(content: Content) -> some View {
        content
            .colorEffect(colorBlindnessEffect())
            .overlay(
                Text(type.rawValue)
                    .font(.caption)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .padding(4),
                alignment: .topLeading
            )
    }
    
    private func colorBlindnessEffect() -> ColorEffect {
        switch type {
        case .normal:
            return ColorEffect.identity
        case .protanopia:
            return ColorEffect.protanopia
        case .deuteranopia:
            return ColorEffect.deuteranopia
        case .tritanopia:
            return ColorEffect.tritanopia
        case .achromatopsia:
            return ColorEffect.grayscale
        }
    }
}

/// A color effect for simulating different types of color blindness
public struct ColorEffect: Sendable {
    let matrix: [CGFloat]
    
    public static let identity = ColorEffect(matrix: [
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0
    ])
    
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

// Extension to apply color effects to views
extension View {
    func colorEffect(_ effect: ColorEffect) -> some View {
        #if os(iOS)
        return self.colorMultiply(.white) // Placeholder for iOS (would need Core Image filter)
        #else
        return self.colorMultiply(.white) // Placeholder for macOS
        #endif
    }
    
    /// Apply WCAG compliance checking to a view
    public func wcagCompliance(foreground: Color, background: Color, showDetails: Bool = true) -> some View {
        self.modifier(WCAGComplianceModifier(foreground: foreground, background: background, showDetails: showDetails))
    }
    
    /// Apply color blindness simulation to a view
    public func colorBlindnessPreview(type: ColorBlindnessPreviewModifier.ColorBlindnessType) -> some View {
        self.modifier(ColorBlindnessPreviewModifier(type: type))
    }
} 