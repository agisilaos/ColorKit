import AppKit
import SwiftUI

// A SwiftPM executable avoids an Xcode project and signing setup.
@main
struct ContrastPairReportApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let report = PairReport(pairs: CommandLine.arguments.contains("--empty") ? Samples.empty : Samples.pairs)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 820),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Contrast Pair Report"
        window.minSize = NSSize(width: 780, height: 350)
        window.contentView = NSHostingView(rootView: ReportView(report: report))
        window.center()
        window.makeKeyAndOrderFront(nil)
        app.activate()
        app.run()
    }
}

struct ReportView: View {
    let report: PairReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Contrast pair report").font(.title)
                Text("Explicit pairs only. This report does not establish whole-app accessibility compliance.")
                Text(report.summary).font(.headline)
                Text("Ratios are displayed to two decimals; outcomes use the unrounded measurement.")
                    .font(.caption)
                // The report is immutable. Position preserves duplicates; labels are never identity.
                ForEach(report.rows.indices, id: \.self) { index in
                    assessment(report.rows[index])
                    Divider()
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func assessment(_ row: PairAssessment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(row.pair.label).font(.headline)
            Text("Target: \(row.pair.target.rawValue) • Required: \(PairAssessment.ratioText(row.pair.target.minimumRatio))")
            switch row.result {
            case .available(let measurement):
                HStack(spacing: 16) {
                    swatch(row.pair.foreground, label: "Foreground")
                    swatch(row.pair.background, label: "Background")
                    Text("Measured: \(PairAssessment.ratioText(measurement.ratio))")
                    Text(row.outcome.rawValue).bold()
                }
            case .unavailable(let issues):
                Text(row.outcome.rawValue).bold()
                Text("Foreground: \(PairAssessment.issueText(issues.foreground))")
                Text("Background: \(PairAssessment.issueText(issues.background))")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func swatch(_ color: Color, label: String) -> some View {
        HStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(.primary, lineWidth: 1))
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            Text(label)
        }
    }
}

// Explicit sRGB values are independent of the host's appearance.
enum Samples {
    static let pairs: [ContrastPair] = [
        .init(label: "Body text", foreground: .black, background: .white, target: .AAA),
        .init(label: "Body text", foreground: Color(.sRGB, white: 0.7), background: .white, target: .AA),
        .init(label: "Body text", foreground: .black, background: .white, target: .AAA),
        .init(label: "Large heading", foreground: .black, background: .white, target: .AALarge),
        .init(label: "Translucent surface", foreground: .black, background: .white.opacity(0.5), target: .AAALarge),
        .init(label: "Unresolved pair", foreground: .primary, background: .primary, target: .AA)
    ]
    static let empty: [ContrastPair] = []
}
