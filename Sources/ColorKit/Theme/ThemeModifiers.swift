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
///
/// This modifier provides consistent text styling across your application by
/// using colors from the current theme. It supports different text types for
/// various levels of emphasis and hierarchy.
///
/// Example usage:
/// ```swift
/// // Apply primary text style
/// Text("Main Content")
///     .modifier(ThemedTextModifier(.primary))
///
/// // Or use the convenience modifier
/// Text("Secondary Content")
///     .themedText(.secondary)
///
/// // Create a themed text component
/// struct ThemedLabel: View {
///     let text: String
///     let type: ThemedTextModifier.TextType
///
///     var body: some View {
///         Text(text)
///             .themedText(type)
///     }
/// }
/// ```
public struct ThemedTextModifier: ViewModifier {
    /// Represents different types of themed text styles.
    ///
    /// Each text type corresponds to a different level of emphasis in the
    /// visual hierarchy, using appropriate colors from the current theme.
    public enum TextType {
        /// Primary text style, used for main content.
        ///
        /// This style uses the base text color from the theme and should be
        /// used for:
        /// - Body text
        /// - Headlines
        /// - Important information
        case primary

        /// Secondary text style, used for supporting content.
        ///
        /// This style uses a lighter text color from the theme and should be
        /// used for:
        /// - Subtitles
        /// - Descriptions
        /// - Less important information
        case secondary

        /// Tertiary text style, used for less prominent text.
        ///
        /// This style uses the darkest text color from the theme and should be
        /// used for:
        /// - Metadata
        /// - Timestamps
        /// - Supporting details
        case tertiary
    }

    private let type: TextType
    @Environment(\.colorTheme)
    private var theme

    /// Initializes a themed text modifier.
    ///
    /// Example:
    /// ```swift
    /// Text("Important Message")
    ///     .modifier(ThemedTextModifier(.primary))
    /// ```
    ///
    /// - Parameter type: The type of text style to apply (default: .primary)
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
///
/// This modifier provides consistent button styling across your application by
/// using colors from the current theme. It supports different button types for
/// various levels of emphasis and interaction.
///
/// Example usage:
/// ```swift
/// // Apply primary button style
/// Button("Save") {
///     // Action
/// }
/// .modifier(ThemedButtonModifier(.primary))
///
/// // Or use the convenience modifier
/// Button("Cancel") {
///     // Action
/// }
/// .themedButton(.secondary)
///
/// // Create a themed button component
/// struct ThemedButton: View {
///     let title: String
///     let type: ThemedButtonModifier.ButtonType
///     let action: () -> Void
///
///     var body: some View {
///         Button(title, action: action)
///             .themedButton(type)
///             .padding()
///     }
/// }
/// ```
public struct ThemedButtonModifier: ViewModifier {
    /// Represents different types of themed button styles.
    ///
    /// Each button type corresponds to a different level of emphasis in the
    /// interface, using appropriate colors from the current theme.
    public enum ButtonType {
        /// Primary button style, used for main actions.
        ///
        /// This style uses the primary color from the theme and should be
        /// used for:
        /// - Main call-to-action buttons
        /// - Form submission buttons
        /// - Key user actions
        case primary

        /// Secondary button style, used for alternative actions.
        ///
        /// This style uses the secondary color from the theme and should be
        /// used for:
        /// - Alternative options
        /// - Less important actions
        /// - Supporting functionality
        case secondary

        /// Accent button style, used for highlighting actions.
        ///
        /// This style uses the accent color from the theme and should be
        /// used for:
        /// - Special features
        /// - Premium actions
        /// - Highlighted functionality
        case accent
    }

    private let type: ButtonType
    @Environment(\.colorTheme)
    private var theme

    /// Initializes a themed button modifier.
    ///
    /// Example:
    /// ```swift
    /// Button("Submit") {
    ///     // Action
    /// }
    /// .modifier(ThemedButtonModifier(.primary))
    /// ```
    ///
    /// - Parameter type: The type of button style to apply (default: .primary)
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
///
/// Elevation determines the background color used for UI elements, creating
/// visual hierarchy through subtle color variations. Each level corresponds
/// to a different background color from the current theme.
///
/// Example usage:
/// ```swift
/// VStack {
///     // Base level content
///     Text("Main Content")
///         .themedBackground(.base)
///
///     // Elevated card
///     VStack {
///         Text("Card Content")
///     }
///     .themedBackground(.elevated)
///
///     // Lowered section
///     HStack {
///         Text("Footer")
///     }
///     .themedBackground(.lowered)
/// }
/// ```
public enum BackgroundElevation {
    /// Default background level, typically used as the base layer.
    ///
    /// This level uses the base background color from the theme and should
    /// be used for:
    /// - Main content areas
    /// - Default view backgrounds
    /// - Primary surfaces
    case base

    /// Elevated background, used for containers, cards, or popovers.
    ///
    /// This level uses a lighter background color from the theme and should
    /// be used for:
    /// - Cards and containers
    /// - Popovers and menus
    /// - Content that should appear raised
    case elevated

    /// Lowered background, often used for contrast or overlays.
    ///
    /// This level uses a darker background color from the theme and should
    /// be used for:
    /// - Footer sections
    /// - Inset content
    /// - Content that should appear recessed
    case lowered
}

/// A modifier that applies a themed background based on an elevation level.
///
/// This modifier provides consistent background styling across your application
/// by using colors from the current theme. It supports different elevation
/// levels to create visual hierarchy.
///
/// Example usage:
/// ```swift
/// // Apply base background
/// Text("Content")
///     .modifier(ThemedBackgroundModifier(.base))
///
/// // Or use the convenience modifier
/// VStack {
///     Text("Card Title")
///     Text("Card Content")
/// }
/// .themedBackground(.elevated)
///
/// // Create a themed card component
/// struct ThemedCard: View {
///     let content: AnyView
///
///     var body: some View {
///         content
///             .padding()
///             .themedBackground(.elevated)
///             .cornerRadius(8)
///     }
/// }
/// ```
public struct ThemedBackgroundModifier: ViewModifier {
    private let elevation: BackgroundElevation
    @Environment(\.colorTheme)
    private var theme

    /// Initializes a themed background modifier.
    ///
    /// Example:
    /// ```swift
    /// Text("Content")
    ///     .modifier(ThemedBackgroundModifier(.elevated))
    /// ```
    ///
    /// - Parameter elevation: The elevation level of the background (default: .base)
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
    ///
    /// This convenience modifier applies themed text colors based on the
    /// specified text type. It uses colors from the current theme to ensure
    /// consistent text styling across your application.
    ///
    /// Example:
    /// ```swift
    /// Text("Main Content")
    ///     .themedText(.primary)
    ///
    /// Text("Supporting Info")
    ///     .themedText(.secondary)
    /// ```
    ///
    /// - Parameter type: The type of text styling to apply (default: .primary)
    /// - Returns: A view with the applied text styling
    func themedText(_ type: ThemedTextModifier.TextType = .primary) -> some View {
        modifier(ThemedTextModifier(type))
    }

    /// Applies themed button styling to a view.
    ///
    /// This convenience modifier applies themed button styling based on the
    /// specified button type. It uses colors from the current theme to ensure
    /// consistent button appearance across your application.
    ///
    /// Example:
    /// ```swift
    /// Button("Save") {
    ///     // Action
    /// }
    /// .themedButton(.primary)
    ///
    /// Button("Cancel") {
    ///     // Action
    /// }
    /// .themedButton(.secondary)
    /// ```
    ///
    /// - Parameter type: The type of button styling to apply (default: .primary)
    /// - Returns: A view with the applied button styling
    func themedButton(_ type: ThemedButtonModifier.ButtonType = .primary) -> some View {
        modifier(ThemedButtonModifier(type))
    }

    /// Applies a themed background to a view.
    ///
    /// This convenience modifier applies a themed background color based on
    /// the specified elevation level. It uses colors from the current theme
    /// to create visual hierarchy through background variations.
    ///
    /// Example:
    /// ```swift
    /// VStack {
    ///     Text("Card Title")
    ///     Text("Card Content")
    /// }
    /// .themedBackground(.elevated)
    /// .cornerRadius(8)
    /// ```
    ///
    /// - Parameter elevation: The elevation level of the background (default: .base)
    /// - Returns: A view with the applied background styling
    func themedBackground(_ elevation: BackgroundElevation = .base) -> some View {
        modifier(ThemedBackgroundModifier(elevation))
    }
}
