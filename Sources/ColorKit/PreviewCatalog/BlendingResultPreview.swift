import SwiftUI

/// Presentation for one attempt; failure cannot retain a previously computed color.
enum BlendingPreviewOutcome {
    case success(Color, explanation: String?)
    case failure([String])

    init(base: Color, blend: Color, mode: BlendMode, amount: CGFloat) {
        switch base.blendResult(with: blend, mode: mode, amount: amount) {
        case .success(let color):
            let explanation: String?
            if amount == 0 {
                explanation = "Amount is 0%; the result matches the base."
            } else if ResolvedSRGBA.resolve(blend)?.alpha == 0 {
                explanation = "The blend color is fully transparent; the result matches the base."
            } else {
                explanation = nil
            }
            self = .success(color, explanation: explanation)
        case .failure(let error):
            self = .failure(Self.explanations(for: error))
        }
    }

    static func explanations(for error: ColorBlendError) -> [String] {
        switch error {
        case .invalidAmount:
            return ["Choose a blend amount between 0% and 100%."]
        case .nonfiniteResult:
            return ["This combination produced color values the preview can't use. Try another blend mode or different colors."]
        case let .unavailableInputs(base, blend):
            let messages = [("Base color", base), ("Blend color", blend)].compactMap { name, issue in
                issue.map { "\(name): \(explanation(for: $0))" }
            }
            return messages.isEmpty ? ["These colors couldn't be blended. Try different colors."] : messages
        }
    }

    private static func explanation(for issue: ColorConversionIssue) -> String {
        switch issue {
        case .unresolvedInput:
            return "This color doesn't provide fixed color values for blending. Choose another color."
        case .unsupportedColorModel:
            return "This color uses a format the preview can't blend. Choose an RGB or grayscale color."
        case .invalidComponents:
            return "This color contains values the preview can't use. Choose another color."
        case .colorSpaceConversionFailed:
            return "This color's values couldn't be converted for blending. Choose another color."
        case .outOfSRGBGamut:
            return "This color is outside the supported range for this conversion. Choose another color."
        case .nonfiniteResult:
            return "Converting this color produced values the preview can't use. Choose another color."
        }
    }
}

struct BlendingResultPreview: View {
    let outcome: BlendingPreviewOutcome

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Result")
                .font(.headline)

            switch outcome {
            case let .success(color, explanation):
                Label("Success", systemImage: "checkmark.circle")
                ZStack {
                    Color.white
                    TransparencyChecks().fill(Color(white: 0.8))
                    color
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)

                if let explanation {
                    Text(explanation)
                }
            case .failure(let explanations):
                Label("Result unavailable", systemImage: "exclamationmark.triangle")
                ForEach(explanations, id: \.self) { explanation in
                    Text(explanation)
                }
            }

            Text("Blend amount and blend opacity control the effect. The result keeps the base color's opacity.")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TransparencyChecks: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let size: CGFloat = 16
        for row in 0..<Int(ceil(rect.height / size)) {
            for column in 0..<Int(ceil(rect.width / size)) where (row + column).isMultiple(of: 2) {
                path.addRect(CGRect(x: CGFloat(column) * size, y: CGFloat(row) * size, width: size, height: size))
            }
        }
        return path
    }
}
