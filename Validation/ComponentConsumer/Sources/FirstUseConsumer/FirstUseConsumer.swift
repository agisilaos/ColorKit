import ColorKit
import SwiftUI
#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// An external package target: every check uses the same public API as an adopting app.
@main
private enum FirstUseConsumer {
    @MainActor static func main() throws {
        let black = Color(.sRGB, red: 0, green: 0, blue: 0)
        let white = Color(.sRGB, red: 1, green: 1, blue: 1)
        let gray = Color(.sRGB, red: 0.6, green: 0.6, blue: 0.6)
        let hex = try black.componentConversionResults().hex.get()
        precondition(hex == "#000000FF", "Fixed black must retain zero components")
        let conversions = Color(.displayP3, red: 1, green: 0, blue: 0).componentConversionResults()
        _ = try conversions.srgba.get()
        _ = try conversions.xyz.get()
        _ = try conversions.lab.get()
        guard case .failure(.outOfSRGBGamut) = conversions.hex else {
            fatalError("P3 red must retain extended coordinates while declining Hex")
        }
        print("PASS fixed conversion and partial availability")

        switch black.contrastResult(with: white) {
        case .available(let measurement):
            precondition(abs(measurement.ratio - 21) < 0.000001, "Expected black-on-white contrast")
            precondition(measurement.passingLevels.contains(.AA), "Expected WCAG AA pass")
        case .unavailable:
            fatalError("Fixed black and white must be measurable")
        }
        precondition(gray.accessibilityResult(against: white, targetLevel: .AA).status == .bestEffort,
                     "A measurable shortfall is not unavailable")
        let translucent = Color(.sRGB, red: 0, green: 0, blue: 0, opacity: 0.9)
        guard case .available = translucent.contrastResult(with: white),
              case .unavailable(let issues) = white.contrastResult(with: translucent) else {
            fatalError("Only a translucent foreground can be composited")
        }
        precondition(issues.foreground.isEmpty && !issues.background.isEmpty,
                     "Issues must identify the translucent background")
        print("PASS contrast, WCAG target and directional availability")

        let requests: [(Color, Double, ColorAccessibilityResult.Status?)] = [
            (black, 30, .meetsTarget), (gray, 0, .bestEffort),
            (.primary, 30, .unavailable), (black, -1, .invalidConfiguration),
            (translucent, 30, .unavailable),
            // A search may pass or return best effort; do not freeze its chosen candidate.
            (gray, 30, nil)
        ]
        for (input, budget, expected) in requests {
            let result = input.enhancementResult(with: white, targetLevel: .AA, maxPerceptualDistance: budget)
            if let expected {
                precondition(result.status == expected, "Unexpected enhancement outcome for budget \(budget)")
            }
            switch result.status {
            case .meetsTarget, .bestEffort:
                guard let ratio = result.contrastRatio,
                      case .available(let measured) = result.color.contrastResult(with: white),
                      case .available(let difference) = input.comparisonResult(with: result.color) else {
                    fatalError("A verifiable candidate must retain contrast and distance evidence")
                }
                precondition(abs(ratio - measured.ratio) < 0.000001, "Candidate contrast must match its evidence")
                precondition(result.meetsTarget == measured.passingLevels.contains(.AA), "Check the requested target")
                precondition(result.isWithinPerceptualDistanceBudget == true
                             && difference.perceptualDifference <= budget, "Candidate must respect the hard budget")
                if budget == 0 {
                    precondition(result.perceptualDistance == 0 && result.color == input,
                                 "Zero budget must preserve the original")
                }
            case .unavailable:
                precondition(expected == .unavailable && !result.meetsTarget && result.perceptualDistance == nil,
                             "Missing distance must not become an apparent success")
            case .invalidConfiguration:
                precondition(expected == .invalidConfiguration && !result.meetsTarget && result.contrastRatio == 21,
                             "Invalid configuration must not succeed even with passing diagnostic contrast")
            }
            if input == translucent {
                precondition((result.contrastRatio ?? 0) >= result.minimumContrastRatio,
                             "This unavailable adjustment should retain passing diagnostic contrast")
            }
            print("PASS enhancement: \(result.status), budget \(budget)")
        }

        guard case .failure(.unresolvedInput) = Color.primary.componentConversionResults().srgba else {
            fatalError("Appearance-dependent primary must require caller-side capture")
        }
        // Follow the platform capture guidance linked from the API map.
        #if canImport(AppKit)
        _ = NSApplication.shared
        for name in [NSAppearance.Name.aqua, .darkAqua] {
            var fixed: CGColor?
            NSAppearance(named: name)?.performAsCurrentDrawingAppearance {
                fixed = NSColor(Color.primary).usingColorSpace(.extendedSRGB)?.cgColor
            }
            guard let fixed else { fatalError("AppKit appearance capture unavailable") }
            _ = try Color(fixed).componentConversionResults().srgba.get()
            _ = try Color(fixed).componentConversionResults().lab.get()
            print("PASS explicit appearance capture: \(name.rawValue)")
        }
        #else
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            let fixed = Color(UIColor(Color.primary).resolvedColor(with: traits).cgColor)
            _ = try fixed.componentConversionResults().srgba.get()
            _ = try fixed.componentConversionResults().lab.get()
            print("PASS explicit appearance capture: \(style.rawValue)")
        }
        #endif
    }
}
