//
//  ThemePreview.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.25.
//
//  Description:
//  Interactive preview for creating and testing color themes.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A preview view for creating and testing color themes
public struct ThemePreview: View {
    // MARK: - State

    @State private var primaryColor = Color.blue
    @State private var secondaryColor = Color.purple
    @State private var accentColor = Color.orange
    @State private var isDarkMode = false
    @State private var showCode = false

    // MARK: - Body

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Theme Colors
                themeColorSection

                // Appearance Toggle
                appearanceSection

                // Preview Components
                previewSection

                // Code Preview
                codePreviewSection
            }
            .padding()
        }
        .navigationTitle("Theme Builder")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: { showCode.toggle() },
                    label: { Label("Show Code", systemImage: "doc.plaintext") }
                )
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    // MARK: - View Components

    private var themeColorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Theme Colors")
                .font(.headline)

            ColorPicker("Primary Color", selection: $primaryColor)
            ColorPicker("Secondary Color", selection: $secondaryColor)
            ColorPicker("Accent Color", selection: $accentColor)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline)

            Toggle("Dark Mode", isOn: $isDarkMode)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.headline)

            // Navigation Bar
            previewNavigationBar

            // Buttons
            previewButtons

            // Cards
            previewCards

            // List Items
            previewListItems
        }
    }

    private var previewNavigationBar: some View {
        HStack {
            Text("Navigation")
                .font(.headline)
            Spacer()
            Button("Action") {}
        }
        .padding()
        .background(primaryColor.opacity(0.1))
        .cornerRadius(8)
    }

    private var previewButtons: some View {
        HStack(spacing: 12) {
            Button("Primary") {}
                .buttonStyle(FilledButtonStyle(color: primaryColor))
            Button("Secondary") {}
                .buttonStyle(OutlineButtonStyle(color: secondaryColor))
            Button("Accent") {}
                .buttonStyle(FilledButtonStyle(color: accentColor))
        }
    }

    private var previewCards: some View {
        VStack(spacing: 12) {
            // Primary Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary Card")
                    .font(.headline)
                Text("A card using the primary color theme")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(primaryColor.opacity(0.1))
            .cornerRadius(8)

            // Secondary Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Secondary Card")
                    .font(.headline)
                Text("A card using the secondary color theme")
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(secondaryColor.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var previewListItems: some View {
        VStack(spacing: 1) {
            ForEach(0..<3) { index in
                HStack {
                    Circle()
                        .fill(index == 0 ? primaryColor : index == 1 ? secondaryColor : accentColor)
                        .frame(width: 24, height: 24)

                    Text("List Item \(index + 1)")

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
            }
        }
        .cornerRadius(8)
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

    // MARK: - Helpers

    private func generateCode() -> String {
        """
        struct Theme {
            static let primary = Color(\(primaryColor.description))
            static let secondary = Color(\(secondaryColor.description))
            static let accent = Color(\(accentColor.description))

            static func adaptiveColor(
                light: Color,
                dark: Color
            ) -> Color {
                Color.adaptive(
                    light: light,
                    dark: dark
                )
            }
        }
        """
    }
}

struct FilledButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(color)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 2)
            )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ThemePreview()
    }
}
