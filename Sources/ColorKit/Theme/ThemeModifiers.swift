//
//  ThemeModifiers.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides SwiftUI view modifiers for themed components.
//
//  Features:
//  - Text styling with themed colors
//  - Button styling with themed colors
//  - Background styling with themed colors
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

// MARK: - Text Modifiers

/// A modifier that applies themed text styling based on a predefined type.
public struct ThemedTextModifier: ViewModifier {
    /// Represents different types of themed text styles.
    public enum TextType {
        /// Primary text style, used for main content.
        case primary
        /// Secondary text style, used for supporting content.
        case secondary
        /// Tertiary text style, used for less prominent text.
        case tertiary
    }

    private let type: TextType
    @Environment(\.colorTheme)
    private var theme

    /// Initializes a themed text modifier.
    /// - Parameter type: The type of text style to apply.
    public init(_ type: TextType = .primary) {
        self.type = type
    }

    public func body(content: Content) -> some View {
        switch type {
        case .primary:
            content.foregroundColor(theme.text.base)
        case .secondary:
            content.foregroundColor(theme.text.light)
        case .tertiary:
            content.foregroundColor(theme.text.dark)
        }
    }
}

// MARK: - Button Modifiers

/// A modifier that applies themed button styling based on a predefined type.
public struct ThemedButtonModifier: ViewModifier {
    /// Represents different types of themed button styles.
    public enum ButtonType {
        /// Primary button style, used for main actions.
        case primary
        /// Secondary button style, used for alternative actions.
        case secondary
        /// Accent button style, used for highlighting actions.
        case accent
    }

    private let type: ButtonType
    @Environment(\.colorTheme)
    private var theme

    /// Initializes a themed button modifier.
    /// - Parameter type: The type of button style to apply.
    public init(_ type: ButtonType = .primary) {
        self.type = type
    }

    public func body(content: Content) -> some View {
        switch type {
        case .primary:
            content
                .foregroundColor(.white)
                .background(theme.primary.base)
                .cornerRadius(8)
        case .secondary:
            content
                .foregroundColor(.white)
                .background(theme.secondary.base)
                .cornerRadius(8)
        case .accent:
            content
                .foregroundColor(.white)
                .background(theme.accent.base)
                .cornerRadius(8)
        }
    }
}

// MARK: - Background Modifiers

/// Represents different elevation levels for themed backgrounds.
/// Elevation determines the background color used for UI elements.
public enum BackgroundElevation {
    /// Default background level, typically used as the base layer.
    case base
    /// Elevated background, used for containers, cards, or popovers.
    case elevated
    /// Lowered background, often used for contrast or overlays.
    case lowered
}

/// A modifier that applies a themed background based on an elevation level.
public struct ThemedBackgroundModifier: ViewModifier {
    private let elevation: BackgroundElevation
    @Environment(\.colorTheme)
    private var theme

    /// Initializes a themed background modifier.
    /// - Parameter elevation: The elevation level of the background.
    public init(_ elevation: BackgroundElevation = .base) {
        self.elevation = elevation
    }

    public func body(content: Content) -> some View {
        content
            .background(
                Group {
                    switch elevation {
                    case .base:
                        theme.background.base
                    case .elevated:
                        theme.background.light
                    case .lowered:
                        theme.background.dark
                    }
                }
            )
    }
}

// MARK: - View Extensions

public extension View {
    /// Applies themed text styling to a view.
    /// - Parameter type: The type of text styling to apply.
    /// - Returns: A view with the applied text styling.
    func themedText(_ type: ThemedTextModifier.TextType = .primary) -> some View {
        modifier(ThemedTextModifier(type))
    }

    /// Applies themed button styling to a view.
    /// - Parameter type: The type of button styling to apply.
    /// - Returns: A view with the applied button styling.
    func themedButton(_ type: ThemedButtonModifier.ButtonType = .primary) -> some View {
        modifier(ThemedButtonModifier(type))
    }

    /// Applies a themed background to a view.
    /// - Parameter elevation: The elevation level of the background.
    /// - Returns: A view with the applied background styling.
    func themedBackground(_ elevation: BackgroundElevation = .base) -> some View {
        modifier(ThemedBackgroundModifier(elevation))
    }
}
