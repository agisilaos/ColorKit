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
    /// Creates the interactive preview with its default configuration.
    public init() {}

    // MARK: - State

    @State private var baseColor = CGColor(srgbRed: 0, green: 0, blue: 1, alpha: 1)
    @State private var blendColor = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
    @State private var selectedBlendMode = BlendMode.normal
    @State private var blendAmount: CGFloat = 1.0

    // MARK: - Properties

    private let blendModes: [BlendMode] = [
        .normal, .multiply, .screen, .overlay,
        .darken, .lighten, .colorDodge, .colorBurn,
        .softLight, .hardLight, .difference, .exclusion
    ]

    // MARK: - Body

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
            }
            .padding()
        }
        .navigationTitle("Color Blending")
    }

    // MARK: - View Components

    private var colorSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Colors")
                .font(.headline)

            ColorPicker("Base color", selection: $baseColor, supportsOpacity: true)
            ColorPicker("Blend color", selection: $blendColor, supportsOpacity: true)
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
                    .accessibilityLabel("Blend amount")
                    .accessibilityValue("\(Int(blendAmount * 100)) percent")
                Text("100%")
                    .foregroundColor(.secondary)
            }

            Text("\(Int(blendAmount * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var previewSection: some View {
        BlendingResultPreview(outcome: BlendingPreviewOutcome(
            base: Color(baseColor),
            blend: Color(blendColor),
            mode: selectedBlendMode,
            amount: blendAmount
        ))
    }
}

// MARK: - Supporting Views

private struct BlendModeButton: View {
    let mode: BlendMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
                Text(String(describing: mode))
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(.borderless)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        BlendingPreview()
    }
}
