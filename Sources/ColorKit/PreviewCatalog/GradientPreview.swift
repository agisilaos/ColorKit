//
//  GradientPreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.25.
//
//  Description:
//  Interactive preview for creating and customizing gradients.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import CoreGraphics
import SwiftUI

/// A preview view for creating and customizing gradients
public struct GradientPreview: View {
    // MARK: - State

    @State private var gradientColors: [Color] = [.blue, .purple]
    @State private var gradientStops: [CGFloat] = [0.0, 1.0]
    @State private var gradientType: GradientType = .linear
    @State private var startPoint: UnitPoint = .leading
    @State private var endPoint: UnitPoint = .trailing
    @State private var showCode = false

    // MARK: - Properties

    private let presetStartPoints: [UnitPoint] = [
        .topLeading, .top, .topTrailing,
        .leading, .center, .trailing,
        .bottomLeading, .bottom, .bottomTrailing
    ]

    private let presetEndPoints: [UnitPoint] = [
        .topLeading, .top, .topTrailing,
        .leading, .center, .trailing,
        .bottomLeading, .bottom, .bottomTrailing
    ]

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Preview
                previewSection

                // Gradient Type
                gradientTypeSection

                // Colors
                colorSection

                // Points
                pointsSection

                // Code Preview
                codePreviewSection
            }
            .padding()
        }
        .navigationTitle("Gradient Generator")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: { showCode.toggle() },
                    label: { Label("Show Code", systemImage: "doc.plaintext") }
                )
            }
        }
    }

    // MARK: - View Components

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)

            Group {
                switch gradientType {
                case .linear:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: gradientColors,
                            startPoint: startPoint,
                            endPoint: endPoint
                        ))
                case .radial:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RadialGradient(
                            colors: gradientColors,
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        ))
                case .angular:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AngularGradient(
                            colors: gradientColors,
                            center: .center
                        ))
                }
            }
            .frame(height: 200)
        }
    }

    private var gradientTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gradient Type")
                .font(.headline)

            Picker("Gradient Type", selection: $gradientType) {
                ForEach(GradientType.allCases) { type in
                    Text(type.name).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Colors")
                    .font(.headline)

                Spacer()

                Button(action: addColor) {
                    Label("Add Color", systemImage: "plus.circle.fill")
                }
                .disabled(gradientColors.count >= 5)
            }

            ForEach(gradientColors.indices, id: \.self) { index in
                HStack {
                    ColorPicker("Color \(index + 1)", selection: $gradientColors[index])

                    if gradientColors.count > 2 {
                        Button(
                            action: { removeColor(at: index) },
                            label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        )
                    }
                }
            }
        }
    }

    private var pointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Control Points")
                .font(.headline)

            if gradientType != .radial {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Start Point")
                        .font(.subheadline)

                    PointGrid(selectedPoint: $startPoint, points: presetStartPoints)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("End Point")
                        .font(.subheadline)

                    PointGrid(selectedPoint: $endPoint, points: presetEndPoints)
                }
            }
        }
    }

    private var codePreviewSection: some View {
        Group {
            if showCode {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Code")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(generateCode())
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func addColor() {
        guard gradientColors.count < 5 else { return }
        gradientColors.append(.gray)
        gradientStops.append(1.0)
    }

    private func removeColor(at index: Int) {
        guard gradientColors.count > 2 else { return }
        gradientColors.remove(at: index)
        gradientStops.remove(at: index)
    }

    private func generateCode() -> String {
        switch gradientType {
        case .linear:
            return """
            LinearGradient(
                colors: \(formatColors()),
                startPoint: \(formatPoint(startPoint)),
                endPoint: \(formatPoint(endPoint))
            )
            """
        case .radial:
            return """
            RadialGradient(
                colors: \(formatColors()),
                center: .center,
                startRadius: 0,
                endRadius: 200
            )
            """
        case .angular:
            return """
            AngularGradient(
                colors: \(formatColors()),
                center: .center
            )
            """
        }
    }

    private func formatColors() -> String {
        let colorStrings = gradientColors.map { color -> String in
            "Color(\(color.description))"
        }
        return "[\(colorStrings.joined(separator: ", "))]"
    }

    private func formatPoint(_ point: UnitPoint) -> String {
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

// MARK: - Supporting Types

enum GradientType: String, CaseIterable, Identifiable {
    case linear
    case radial
    case angular

    var id: String { rawValue }

    var name: String {
        switch self {
        case .linear: return "Linear"
        case .radial: return "Radial"
        case .angular: return "Angular"
        }
    }
}

// MARK: - Supporting Views

private struct PointGrid: View {
    @Binding var selectedPoint: UnitPoint
    let points: [UnitPoint]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(points, id: \.self) { point in
                Button(
                    action: { selectedPoint = point },
                    label: {
                        Circle()
                            .fill(selectedPoint == point ? Color.accentColor : Color.secondary.opacity(0.2))
                            .frame(width: 24, height: 24)
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        GradientPreview()
    }
}
