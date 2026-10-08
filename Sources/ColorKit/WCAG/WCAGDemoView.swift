import SwiftUI

/// A demo view that showcases the WCAG compliance checker functionality
public struct WCAGDemoView: View {
    @State private var foregroundColor = Color(.sRGB, red: 0, green: 0.478, blue: 1)
    @State private var backgroundColor = Color(.sRGB, red: 1, green: 1, blue: 1)
    @State private var text: String = "Sample Text"
    @State private var fontSize: Double = 16
    @State private var selectedDeficiency = ColorVisionDeficiency.protanopia
    @State private var showSimulation: Bool = false

    public init() {}

    public var body: some View {
        let assessment = WCAGDemoAssessment(
            foreground: foregroundColor,
            background: backgroundColor,
            deficiency: showSimulation ? selectedDeficiency : nil
        )
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("WCAG Compliance Checker")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Color Pickers
                VStack(alignment: .leading, spacing: 10) {
                    Text("Colors")
                        .font(.headline)

                    ColorPicker("Text Color", selection: $foregroundColor)
                    ColorPicker("Background Color", selection: $backgroundColor)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Text Settings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Text Settings")
                        .font(.headline)

                    TextField("Sample Text", text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    HStack {
                        Text("Font Size: \(Int(fontSize))pt")
                        Slider(value: $fontSize, in: 8...72, step: 1)
                    }

                    Text("Large Text (≥18pt or ≥14pt bold)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Color Vision Deficiency Simulation
                VStack(alignment: .leading, spacing: 10) {
                    Text("Fixed-Color CVD Simulation")
                        .font(.headline)

                    Toggle("Show Simulated Colors", isOn: $showSimulation)

                    if showSimulation {
                        Picker("Type", selection: $selectedDeficiency) {
                            ForEach(ColorVisionDeficiency.allCases) { deficiency in
                                Text(deficiency.previewPresentation.name).tag(deficiency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Preview")
                        .font(.headline)

                    if let pair = assessment.pair {
                        Text(text)
                            .font(.system(size: fontSize))
                            .wcagCompliance(foreground: pair.foreground, background: pair.background, showDetails: false)
                    } else {
                        Label(
                            "Simulation unavailable for these colors",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Compliance Details
                VStack(alignment: .leading, spacing: 10) {
                    Text("Compliance Details")
                        .font(.headline)

                    if let ratio = assessment.contrastRatio {
                        WCAGDemoComplianceDetails(ratio: ratio, fontSize: fontSize)
                    } else {
                        Text("Contrast unavailable")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

/// The selected pair shown by the demo, with its current contrast assessment.
struct WCAGDemoAssessment {
    let pair: (foreground: Color, background: Color)?
    let contrastRatio: Double?

    init(foreground: Color, background: Color, deficiency: ColorVisionDeficiency?) {
        let pair: (foreground: Color, background: Color)?
        if let deficiency {
            if let simulatedForeground = foreground.simulated(for: deficiency),
               let simulatedBackground = background.simulated(for: deficiency) {
                pair = (simulatedForeground, simulatedBackground)
            } else {
                pair = nil
            }
        } else {
            pair = (foreground, background)
        }
        self.pair = pair
        contrastRatio = pair.flatMap { $0.foreground.contrastResult(with: $0.background).ratio }
    }
}

/// Compliance presentation for the demo's regular-weight sample text.
struct WCAGDemoComplianceDetails: View {
    let ratio: Double
    let fontSize: Double

    var isLargeText: Bool {
        fontSize >= 18
    }

    func isRelevant(_ level: WCAGContrastLevel) -> Bool {
        level == .AALarge || level == .AAALarge ? isLargeText : true
    }

    var highestLevel: WCAGContrastLevel? {
        WCAGContrastLevel.allCases.last(where: { isRelevant($0) && ratio >= $0.minimumRatio })
    }

    var body: some View {
        Text("Contrast Ratio: \(String(format: "%.2f", ratio)):1")
            .fontWeight(.medium)

        Divider()

        Text("WCAG 2.1 Compliance:")
            .fontWeight(.medium)

        ForEach(WCAGContrastLevel.allCases) { level in
            let passes = ratio >= level.minimumRatio
            let isRelevant = isRelevant(level)

            HStack {
                Image(systemName: isRelevant ? (passes ? "checkmark.circle.fill" : "xmark.circle.fill") : "minus.circle")
                    .foregroundColor(isRelevant ? (passes ? .green : .red) : .secondary)

                Text(level.rawValue)
                    .fontWeight(.medium)

                Spacer()

                Text(isRelevant ? level.description : "Not applicable to this text size")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .opacity(isRelevant ? 1.0 : 0.5)
        }

        Divider()

        if let highestLevel {
            Text("Highest Compliance Level: \(highestLevel.rawValue)")
                .fontWeight(.medium)
        } else {
            Text("Does not meet any compliance level")
                .fontWeight(.medium)
                .foregroundColor(.red)
        }
    }
}

#Preview {
    WCAGDemoView()
}
