import SwiftUI

struct AccessibilityLabSimulationSwatch: View {
    let color: Color
    let deficiency: ColorVisionDeficiency

    var body: some View {
        if let simulated = color.simulated(for: deficiency) {
            Rectangle().fill(simulated)
        } else {
            Rectangle()
                .fill(Color.secondary.opacity(0.1))
                .overlay(Image(systemName: "exclamationmark.triangle.fill"))
                .accessibilityLabel("Simulation unavailable for this color")
        }
    }
}

extension ColorVisionDeficiency {
    var previewPresentation: (name: String, description: String) {
        switch self {
        case .protanopia:
            return ("Protanopia", "Full-severity simulation of an absent long-wavelength cone response")
        case .deuteranopia:
            return ("Deuteranopia", "Full-severity simulation of an absent medium-wavelength cone response")
        case .tritanopia:
            return ("Tritanopia", "Full-severity simulation of an absent short-wavelength cone response")
        }
    }
}
