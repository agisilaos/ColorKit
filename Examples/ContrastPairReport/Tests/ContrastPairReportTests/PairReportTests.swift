import ColorKit
@testable import ContrastPairReport
import Foundation
import SwiftUI
import Testing

struct PairReportTests {
    @Test
    func samplesPreserveOrderDuplicatesTargetsAndCounts() {
        let report = PairReport(pairs: Samples.pairs)
        #expect(report.rows.map(\.pair.label) == [
            "Body text", "Body text", "Body text", "Large heading", "Translucent surface", "Unresolved pair"
        ])
        #expect(report.rows.map(\.pair.target) == [.AAA, .AA, .AAA, .AALarge, .AAALarge, .AA])
        #expect(report.rows.map(\.outcome) == [
            .meetsTarget, .belowTarget, .meetsTarget, .meetsTarget, .unavailable, .unavailable
        ])
        #expect(report.rows[0].result == report.rows[2].result)
        #expect(report.rows[0].result.ratio == 21)
        #expect(report.count(.meetsTarget) == 3)
        #expect(report.count(.belowTarget) == 1)
        #expect(report.count(.unavailable) == 2)
        #expect(report.summary == "Meets target: 3 • Below target: 1 • Unavailable: 2")
    }

    @Test
    func emptyReport() {
        let report = PairReport(pairs: Samples.empty)
        #expect(report.rows.isEmpty)
        #expect(report.summary == "No pairs assessed.")
        #expect(report.count(.meetsTarget) == 0)
        #expect(report.count(.belowTarget) == 0)
        #expect(report.count(.unavailable) == 0)
    }

    @Test
    func independentIssuesAndNoInventedRatio() {
        let report = PairReport(pairs: Samples.pairs)
        guard case .unavailable(let surface) = report.rows[4].result,
              case .unavailable(let unresolved) = report.rows[5].result else {
            Issue.record("Expected unavailable samples")
            return
        }
        #expect(surface.foreground.isEmpty)
        #expect(surface.background == [.translucentBackground])
        #expect(unresolved.foreground == [.unresolved])
        #expect(unresolved.background == [.unresolved])
        #expect(report.rows[4].result.ratio == nil)
        #expect(report.rows[5].result.ratio == nil)
        #expect(PairAssessment.issueText(surface.foreground) == "No issues reported")
        #expect(PairAssessment.issueText(surface.background) == "Background is not opaque")
        #expect(PairAssessment.issueText(unresolved.foreground) == "Cannot resolve to fixed, finite sRGB components")
    }

    @Test
    func gamutAndOpacityIssuesAreBothRetained() {
        let row = PairAssessment(pair: .init(
            label: "P3",
            foreground: Color(.displayP3, red: 1, green: 0, blue: 0),
            background: Color(.displayP3, red: 1, green: 0, blue: 0, opacity: 0.5),
            target: .AA
        ))
        guard case .unavailable(let issues) = row.result else {
            Issue.record("Expected out-of-gamut inputs")
            return
        }
        #expect(issues.foreground == [.outOfSRGBGamut])
        #expect(issues.background == [.outOfSRGBGamut, .translucentBackground])
        #expect(PairAssessment.issueText(issues.background) == "Outside the sRGB gamut; Background is not opaque")
    }

    @Test(arguments: WCAGContrastLevel.allCases)
    func roundingDoesNotChangeClassification(target: WCAGContrastLevel) throws {
        // Invert WCAG's transfer function to make real public-API measurements
        // just below and just above each target. Both display the target ratio.
        for offset in [-0.0001, 0.0001] {
            let desiredRatio = target.minimumRatio + offset
            let luminance = 1.05 / desiredRatio - 0.05
            let component = 1.055 * pow(luminance, 1 / 2.4) - 0.055
            let row = PairAssessment(pair: .init(
                label: "Boundary", foreground: Color(.sRGB, white: component), background: .white, target: target
            ))
            let ratio = try #require(row.result.ratio)
            #expect(abs(ratio - desiredRatio) < 0.00001)
            #expect(PairAssessment.ratioText(ratio) == PairAssessment.ratioText(target.minimumRatio))
            #expect(row.outcome == (offset < 0 ? .belowTarget : .meetsTarget))
        }
    }

    @Test
    func foregroundOpacityKeepsDirectionalMeaning() {
        let pair = ContrastPair(label: "Overlay", foreground: .black.opacity(0.5), background: .white, target: .AA)
        let row = PairAssessment(pair: pair)
        #expect(row.result == pair.foreground.contrastResult(with: pair.background))
        #expect(row.result.ratio != nil)
        let reversed = PairAssessment(pair: .init(
            label: pair.label, foreground: pair.background, background: pair.foreground, target: pair.target
        ))
        #expect(reversed.outcome == .unavailable)
    }
}
