//
//  ColorInspectorModifier.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  Provides a view modifier to add a color inspector to any view.
//
//  Features:
//  - Adds a color inspector overlay to any view
//  - Allows inspecting colors in real-time
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

/// A view modifier that adds a color inspector to a view
public struct ColorInspectorModifier: ViewModifier {
    private let color: Color
    private let backgroundColor: Color
    private let position: Position
    private let showContrastInfo: Bool

    /// The position of the color inspector
    public enum Position: Sendable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }

    /// Creates a new color inspector modifier
    /// - Parameters:
    ///   - color: The color to inspect
    ///   - backgroundColor: The background color (for contrast calculations)
    ///   - position: The position of the inspector
    ///   - showContrastInfo: Whether to show contrast information
    public init(color: Color, backgroundColor: Color = .white, position: Position = .bottomTrailing, showContrastInfo: Bool = true) {
        self.color = color
        self.backgroundColor = backgroundColor
        self.position = position
        self.showContrastInfo = showContrastInfo
    }

    public func body(content: Content) -> some View {
        let pos = position // Capture position in a local variable
        content
            .overlay(
                ColorInspectorView(
                    color: color,
                    backgroundColor: backgroundColor,
                    showContrastInfo: showContrastInfo
                )
                .padding()
                .alignmentGuide(pos == .topLeading || pos == .bottomLeading ? .leading : .trailing) { d in
                    pos == .topLeading || pos == .bottomLeading ? d[.leading] : d[.trailing]
                }
                .alignmentGuide(pos == .topLeading || pos == .topTrailing ? .top : .bottom) { d in
                    pos == .topLeading || pos == .topTrailing ? d[.top] : d[.bottom]
                },
                alignment: positionAlignment
            )
    }

    private var positionAlignment: Alignment {
        switch position {
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        }
    }
}

public extension View {
    /// Adds a color inspector to the view
    /// - Parameters:
    ///   - color: The color to inspect
    ///   - backgroundColor: The background color (for contrast calculations)
    ///   - position: The position of the inspector
    ///   - showContrastInfo: Whether to show contrast information
    /// - Returns: A view with a color inspector
    func colorInspector(
        color: Color,
        backgroundColor: Color = .white,
        position: ColorInspectorModifier.Position = .bottomTrailing,
        showContrastInfo: Bool = true
    ) -> some View {
        self.modifier(
            ColorInspectorModifier(
                color: color,
                backgroundColor: backgroundColor,
                position: position,
                showContrastInfo: showContrastInfo
            )
        )
    }
}
