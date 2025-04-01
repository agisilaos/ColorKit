//
//  ColorAnimationPreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 15.03.2025.
//
//  Description:
//  A preview component for demonstrating color animations and transitions.
//
//  Features:
//  - Real-time color interpolation preview
//  - Multiple interpolation modes (RGB, HSL, LAB)
//  - Customizable animation duration and easing
//  - Performance metrics and FPS monitoring
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview component for demonstrating color animations and transitions
public struct ColorAnimationPreview: View {
    // MARK: - State Properties

    @State private var startColor: Color = .blue
    @State private var endColor: Color = .red
    @State private var currentColor: Color = .blue
    @State private var animationDuration: Double = 1.0
    @State private var isAnimating = false
    @State private var selectedInterpolation: ColorInterpolation = .rgb
    @State private var showPerformanceMetrics = false
    @State private var frameCount: Int = 0
    @State private var lastFrameTime = Date()
    @State private var fps: Double = 0

    // MARK: - Constants

    private enum ColorInterpolation: String, CaseIterable {
        case rgb = "RGB"
        case hsl = "HSL"
        case lab = "LAB"

        var description: String {
            switch self {
            case .rgb: return "Linear RGB interpolation"
            case .hsl: return "Perceptual HSL interpolation"
            case .lab: return "Perceptually uniform LAB interpolation"
            }
        }
    }

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Color Animation")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Color Selection
                colorSelectionSection

                // Animation Preview
                animationPreviewSection

                // Animation Controls
                controlsSection

                // Performance Metrics
                if showPerformanceMetrics {
                    performanceSection
                }
            }
            .padding()
        }
        .onAppear {
            startPerformanceMonitoring()
        }
    }

    // MARK: - Sections

    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Colors")
                .font(.headline)

            // Note: ColorPicker is not supported in Previews, so we're using buttons to randomize the color for demonstration purposes.

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Start Color")
                        .font(.subheadline)
                    Button {
                        randomizeColor(target: "start")
                    } label: {
                        Text("Randomize Start Color")
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(startColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading) {
                    Text("End Color")
                        .font(.subheadline)
                    Button {
                        randomizeColor(target: "end")
                    } label: {
                        Text("Randomize End Color")
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(endColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    private var animationPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.headline)

            RoundedRectangle(cornerRadius: 15)
                .fill(currentColor)
                .frame(height: 200)
                .overlay(
                    Text(currentColor.hexString() ?? "#000000")
                        .font(.system(.title2, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                )
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Animation Controls")
                .font(.headline)

            Picker("Interpolation Mode", selection: $selectedInterpolation) {
                ForEach(ColorInterpolation.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            Text(selectedInterpolation.description)
                .font(.caption)
                .foregroundColor(.secondary)

            Slider(value: $animationDuration, in: 0.1...3.0) {
                Text("Duration: \(String(format: "%.1f", animationDuration))s")
            }

            Toggle("Show Performance Metrics", isOn: $showPerformanceMetrics)

            Button(action: startAnimation) {
                Label(isAnimating ? "Stop Animation" : "Start Animation",
                      systemImage: isAnimating ? "stop.fill" : "play.fill")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isAnimating ? Color.red : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Performance Metrics")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("FPS")
                        .font(.subheadline)
                    Text(String(format: "%.1f", fps))
                        .font(.system(.title, design: .monospaced))
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("Frame Count")
                        .font(.subheadline)
                    Text("\(frameCount)")
                        .font(.system(.title, design: .monospaced))
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }

    // MARK: - Actions

    private func startAnimation() {
        isAnimating.toggle()
        if isAnimating {
            withAnimation(
                Animation
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
            ) {
                switch selectedInterpolation {
                case .rgb:
                    // Linear RGB interpolation
                    currentColor = endColor
                case .hsl:
                    // HSL interpolation for more perceptually pleasing transitions
                    if let endHSL = endColor.hslComponents() {
                        currentColor = Color(
                            hue: endHSL.hue,
                            saturation: endHSL.saturation,
                            lightness: endHSL.lightness
                        )
                    }
                case .lab:
                    // LAB interpolation for perceptually uniform transitions
                    if let endLAB = endColor.labComponents() {
                        currentColor = Color(
                            L: endLAB.L,
                            a: endLAB.a,
                            b: endLAB.b
                        )
                    }
                }
            }
        } else {
            withAnimation(.easeInOut(duration: animationDuration)) {
                currentColor = startColor
            }
        }
    }

    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                guard self.isAnimating else { return }
                self.frameCount += 1
                let currentTime = Date()
                let timeInterval = currentTime.timeIntervalSince(self.lastFrameTime)
                self.fps = 1.0 / timeInterval
                self.lastFrameTime = currentTime
            }
        }
    }

    // MARK: - Helper Methods

    /// Generates a random color.
    /// Note: This method is used in Previews because ColorPicker is not supported.
    private func randomizeColor(target: String) {
        let newColor = Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )

        if target == "start" {
            startColor = newColor
        } else if target == "end" {
            endColor = newColor
        }
    }
}

// MARK: - Preview

#Preview {
    ColorAnimationPreview()
}
