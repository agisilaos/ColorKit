import SwiftUI

/// A demo view that showcases the WCAG compliance checker functionality
public struct WCAGDemoView: View {
    @State private var foregroundColor: Color = .blue
    @State private var backgroundColor: Color = .white
    @State private var text: String = "Sample Text"
    @State private var fontSize: Double = 16
    @State private var selectedColorBlindnessType: ColorBlindnessPreviewModifier.ColorBlindnessType = .normal
    @State private var showColorBlindnessPreview: Bool = false

    public init() {}

    public var body: some View {
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

                // Color Blindness Simulation
                VStack(alignment: .leading, spacing: 10) {
                    Text("Color Blindness Simulation")
                        .font(.headline)

                    Toggle("Show Color Blindness Preview", isOn: $showColorBlindnessPreview)

                    if showColorBlindnessPreview {
                        Picker("Type", selection: $selectedColorBlindnessType) {
                            ForEach(ColorBlindnessPreviewModifier.ColorBlindnessType.allCases) { type in
                                Text(type.rawValue).tag(type)
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

                    if showColorBlindnessPreview {
                        Text(text)
                            .font(.system(size: fontSize))
                            .wcagCompliance(foreground: foregroundColor, background: backgroundColor)
                            .colorBlindnessPreview(type: selectedColorBlindnessType)
                    } else {
                        Text(text)
                            .font(.system(size: fontSize))
                            .wcagCompliance(foreground: foregroundColor, background: backgroundColor)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // Compliance Details
                VStack(alignment: .leading, spacing: 10) {
                    Text("Compliance Details")
                        .font(.headline)

                    let compliance = foregroundColor.wcagCompliance(with: backgroundColor)
                    let isLargeText = fontSize >= 18 || (fontSize >= 14 && true) // Assuming bold for simplicity

                    Text("Contrast Ratio: \(String(format: "%.2f", compliance.contrastRatio)):1")
                        .fontWeight(.medium)

                    Divider()

                    Text("WCAG 2.1 Compliance:")
                        .fontWeight(.medium)

                    ForEach(WCAGContrastLevel.allCases) { level in
                        let passes = compliance.contrastRatio >= level.minimumRatio
                        let isRelevant = level == .AALarge || level == .AAALarge ? isLargeText : true

                        HStack {
                            Image(systemName: passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(passes ? .green : .red)

                            Text(level.rawValue)
                                .fontWeight(.medium)

                            Spacer()

                            Text(level.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .opacity(isRelevant ? 1.0 : 0.5)
                    }

                    Divider()

                    if let highestLevel = compliance.highestLevel {
                        Text("Highest Compliance Level: \(highestLevel.rawValue)")
                            .fontWeight(.medium)
                    } else {
                        Text("Does not meet any compliance level")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
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

#Preview {
    WCAGDemoView()
}
