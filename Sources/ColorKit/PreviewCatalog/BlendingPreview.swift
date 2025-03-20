//
//  BlendingPreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.25.
//
//  Description:
//  Interactive preview for testing color blending modes.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import CoreGraphics
import SwiftUI

public struct BlendingPreview: View {
    // MARK: - State
    @State private var foregroundColor = Color.blue
    @State private var backgroundColor = Color.red
    @State private var selectedBlendMode = BlendMode.normal
    @State private var blendAmount: CGFloat = 1.0
    @State private var showPerformanceMetrics = false
    @State private var renderTime: TimeInterval = 0

    // MARK: - Properties
    private let blendModes: [BlendMode] = [
        .normal, .multiply, .screen, .overlay,
        .darken, .lighten, .colorDodge, .colorBurn,
        .softLight, .hardLight, .difference, .exclusion
    ]

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Color Selection
                colorSelectionSection

                // Blend Mode Selection
                blendModeSection

                // Blend Amount
                blendAmountSection

                // Preview
                previewSection

                // Performance Metrics
                if showPerformanceMetrics {
                    performanceSection
                }
            }
            .padding()
        }
        .navigationTitle("Color Blending")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: togglePerformanceMetrics) {
                    Label("Performance", systemImage: "chart.bar")
                }
            }
        }
    }

    // MARK: - View Components
    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Colors")
                .font(.headline)

            ColorPicker("Foreground Color", selection: $foregroundColor)
            ColorPicker("Background Color", selection: $backgroundColor)
        }
    }

    private var blendModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blend Mode")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(blendModes, id: \.self) { mode in
                        BlendModeButton(
                            mode: mode,
                            isSelected: selectedBlendMode == mode,
                            action: { selectedBlendMode = mode }
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var blendAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blend Amount")
                .font(.headline)

            HStack {
                Text("0%")
                    .foregroundColor(.secondary)
                Slider(value: $blendAmount, in: 0...1)
                Text("100%")
                    .foregroundColor(.secondary)
            }

            Text("\(Int(blendAmount * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)

                RoundedRectangle(cornerRadius: 12)
                    .fill(foregroundColor.blended(with: backgroundColor, mode: selectedBlendMode, amount: blendAmount))
            }
            .frame(height: 200)
            .onAppear(perform: measureRenderTime)
            .onChange(of: selectedBlendMode) { _ in measureRenderTime() }
            .onChange(of: foregroundColor) { _ in measureRenderTime() }
            .onChange(of: backgroundColor) { _ in measureRenderTime() }
            .onChange(of: blendAmount) { _ in measureRenderTime() }
        }
    }

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)

            HStack {
                Text("Render Time:")
                    .foregroundColor(.secondary)

                Text(String(format: "%.3f ms", renderTime * 1_000))
                    .font(.system(.body, design: .monospaced))

                Spacer()

                Image(systemName: renderTime < 0.016 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(renderTime < 0.016 ? .green : .yellow)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Actions
    private func togglePerformanceMetrics() {
        withAnimation {
            showPerformanceMetrics.toggle()
            if showPerformanceMetrics {
                measureRenderTime()
            }
        }
    }

    private func measureRenderTime() {
        let start = CFAbsoluteTimeGetCurrent()

        // Force a redraw of the preview
        DispatchQueue.main.async {
            let end = CFAbsoluteTimeGetCurrent()
            renderTime = end - start
        }
    }
}

// MARK: - Supporting Views
private struct BlendModeButton: View {
    let mode: BlendMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(String(describing: mode))
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(.borderless)
    }
}

//// MARK: - Preview

#Preview {
    NavigationView {
        BlendingPreview()
    }
}
