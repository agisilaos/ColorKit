//
//  02-accessibility-sample.swift
//  ColorKit
//
//  Created for the AccessibilityGuide tutorial.
//
//  Description:
//  Example showing potentially inaccessible color combinations
//  that may not meet WCAG accessibility requirements.
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

struct ContentView: View {
    @State private var useAccessibleColors = false

    // Potentially inaccessible color combinations
    private let primaryColor = Color.purple
    private let accentColor = Color(red: 0.6, green: 0.2, blue: 0.8)
    private let backgroundColor = Color(red: 0.95, green: 0.95, blue: 1.0)
    private let textColor = Color(red: 0.5, green: 0.4, blue: 0.7)
    private let linkColor = Color.blue.opacity(0.6)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                Text("Accessibility Sample")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)

                // Potentially low-contrast text
                Text("This text has potentially low contrast with the background.")
                    .font(.body)
                    .foregroundColor(textColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(10)

                // Card with potentially inaccessible colors
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sample Card")
                        .font(.headline)
                        .foregroundColor(primaryColor)

                    Text("This card contains content with potentially inaccessible color combinations that might not meet WCAG contrast requirements.")
                        .foregroundColor(textColor)

                    Button(action: {}) {
                        Text("Learn More")
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(accentColor)
                            .foregroundColor(.white.opacity(0.9))
                            .cornerRadius(8)
                    }

                    Text("Visit our documentation")
                        .font(.caption)
                        .foregroundColor(linkColor)
                        .underline()
                }
                .padding()
                .background(backgroundColor)
                .cornerRadius(10)
                .shadow(radius: 2)

                Spacer()
            }
            .padding()
            .background(Color.white)
        }
    }
}

#Preview {
    ContentView()
}
