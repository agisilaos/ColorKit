import ColorKit
import SwiftUI

// Callers supply fixed colors, capturing a chosen appearance themselves if needed.
struct ContrastPair {
    let label: String
    let foreground: Color
    let background: Color
    let target: WCAGContrastLevel
}

struct PairAssessment {
    let pair: ContrastPair
    let result: ColorContrastResult

    init(pair: ContrastPair) {
        self.pair = pair
        result = pair.foreground.contrastResult(with: pair.background)
    }

    enum Outcome: String {
        case meetsTarget = "Meets target"
        case belowTarget = "Below target"
        case unavailable = "Unavailable"
    }

    var outcome: Outcome {
        guard case .available(let measurement) = result else { return .unavailable }
        return measurement.ratio >= pair.target.minimumRatio ? .meetsTarget : .belowTarget
    }

    static func ratioText(_ ratio: Double) -> String {
        ratio.formatted(.number.precision(.fractionLength(2))) + ":1"
    }

    static func issueText(_ issues: [ContrastInputIssue]) -> String {
        guard !issues.isEmpty else { return "No issues reported" }
        return issues.map { issue in
            switch issue {
            case .unresolved: "Cannot resolve to fixed, finite sRGB components"
            case .outOfSRGBGamut: "Outside the sRGB gamut"
            case .translucentBackground: "Background is not opaque"
            }
        }
        .joined(separator: "; ")
    }
}

struct PairReport {
    let rows: [PairAssessment]

    init(pairs: [ContrastPair]) {
        rows = pairs.map(PairAssessment.init)
    }

    func count(_ outcome: PairAssessment.Outcome) -> Int {
        rows.filter { $0.outcome == outcome }.count
    }

    var summary: String {
        guard !rows.isEmpty else { return "No pairs assessed." }
        return "Meets target: \(count(.meetsTarget)) • Below target: \(count(.belowTarget)) • Unavailable: \(count(.unavailable))"
    }
}
