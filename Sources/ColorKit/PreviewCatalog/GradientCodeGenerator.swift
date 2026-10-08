import SwiftUI

@MainActor
enum GradientCodeGenerator {
    static func source(colors: [Color], type: GradientType, startPoint: UnitPoint, endPoint: UnitPoint) -> String? {
        guard let colors = formatColors(colors) else { return nil }
        switch type {
        case .linear:
            return """
            LinearGradient(
                colors: \(colors),
                startPoint: \(formatPoint(startPoint)),
                endPoint: \(formatPoint(endPoint))
            )
            """
        case .radial:
            return """
            RadialGradient(
                colors: \(colors),
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            """
        case .angular:
            return """
            AngularGradient(
                colors: \(colors),
                center: .center
            )
            """
        }
    }

    private static func formatColors(_ colors: [Color]) -> String? {
        var literals: [String] = []
        for color in colors {
            guard let literal = ThemeCodeGenerator.literal(color) else { return nil }
            literals.append(literal)
        }
        return "[\(literals.joined(separator: ", "))]"
    }

    private static func formatPoint(_ point: UnitPoint) -> String {
        switch point {
        case .topLeading: return ".topLeading"
        case .top: return ".top"
        case .topTrailing: return ".topTrailing"
        case .leading: return ".leading"
        case .center: return ".center"
        case .trailing: return ".trailing"
        case .bottomLeading: return ".bottomLeading"
        case .bottom: return ".bottom"
        case .bottomTrailing: return ".bottomTrailing"
        default: return ".center"
        }
    }
}
