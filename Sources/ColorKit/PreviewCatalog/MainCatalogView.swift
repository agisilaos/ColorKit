//
//  MainCatalogView.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 20.03.25.
//
//  Description:
//  Main navigation view for the ColorKit Preview Catalog.
//  Provides access to all preview features and demos.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// The main navigation view for the ColorKit Preview Catalog
public struct MainCatalogView: View {
    // MARK: - State

    @State private var selectedFeature: PreviewFeature?
    @State private var searchText = ""

    // MARK: - Properties

    private let features = PreviewFeature.allCases

    public var body: some View {
        NavigationView {
            List {
                ForEach(searchResults) { feature in
                    NavigationLink(
                        destination: feature.destination,
                        tag: feature,
                        selection: $selectedFeature
                    ) {
                        FeatureRow(feature: feature)
                    }
                }
            }
            .navigationTitle("ColorKit Catalog")
            .searchableIfAvailable(text: $searchText, prompt: "Search features")
        }
    }

    private var searchResults: [PreviewFeature] {
        if searchText.isEmpty {
            return features
        }
        return features.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Preview Features

enum PreviewFeature: String, CaseIterable, Identifiable {
    case colorSpaces = "Color Spaces"
    case blending = "Color Blending"
    case gradients = "Gradient Generation"
    case accessibility = "Accessibility Tools"
    case themes = "Theme Builder"
    case performance = "Performance Insights"
    case debugger = "Color Debugger"
    case paletteStudio = "Palette Studio"
    case animation = "Color Animation"

    var id: String { rawValue }

    var name: String { rawValue }

    var description: String {
        switch self {
        case .colorSpaces:
            return "Explore color space conversions and representations"
        case .blending:
            return "Test different color blending modes and effects"
        case .gradients:
            return "Create and customize beautiful gradients"
        case .accessibility:
            return "Check color contrast and simulate color blindness"
        case .themes:
            return "Build and preview custom color themes"
        case .performance:
            return "Measure and optimize color operations"
        case .debugger:
            return "Debug and inspect colors in detail"
        case .paletteStudio:
            return "Generate and export color palettes with accessibility in mind"
        case .animation:
            return "Experiment with color transitions and animations"
        }
    }

    var icon: String {
        switch self {
        case .colorSpaces:
            return "paintpalette"
        case .blending:
            return "circle.lefthalf.filled"
        case .gradients:
            return "rainbow"
        case .accessibility:
            return "eye"
        case .themes:
            return "paintbrush"
        case .performance:
            return "chart.bar"
        case .debugger:
            return "magnifyingglass"
        case .paletteStudio:
            return "square.stack.3d.up"
        case .animation:
            return "sparkles.tv"
        }
    }

    @ViewBuilder @MainActor var destination: some View {
        switch self {
        case .colorSpaces:
            ColorSpacePreview()
        case .blending:
            BlendingPreview()
        case .gradients:
            GradientPreview()
        case .accessibility:
            ColorKit.WCAG.demoView()
        case .themes:
            ThemePreview()
        case .performance:
            PerformanceBenchmark()
        case .debugger:
            ColorDebuggerPreview()
        case .paletteStudio:
            PaletteStudioPreview()
        case .animation:
            ColorAnimationPreview()
        }
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let feature: PreviewFeature

    var body: some View {
        HStack {
            Image(systemName: feature.icon)
                .foregroundColor(.accentColor)
                .font(.title2)
                .frame(width: 30)

            VStack(alignment: .leading) {
                Text(feature.name)
                    .font(.headline)
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    MainCatalogView()
}

extension View {
    @ViewBuilder
    func searchableIfAvailable(text: Binding<String>, prompt: String) -> some View {
        if #available(iOS 15.0, *) {
            self.searchable(text: text, prompt: prompt)
        } else {
            self
        }
    }
}
