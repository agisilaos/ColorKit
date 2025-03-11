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

/// A modifier that applies themed text styling
@available(iOS 14.0, macOS 11.0, *)
public struct ThemedTextModifier: ViewModifier {
    /// The type of text
    public enum TextType {
        case primary
        case secondary
        case tertiary
    }
    
    private let type: TextType
    @Environment(\.colorTheme) private var theme
    
    /// Creates a new themed text modifier
    /// - Parameter type: The type of text
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

/// A modifier that applies themed button styling
@available(iOS 14.0, macOS 11.0, *)
public struct ThemedButtonModifier: ViewModifier {
    /// The type of button
    public enum ButtonType {
        case primary
        case secondary
        case accent
    }
    
    private let type: ButtonType
    @Environment(\.colorTheme) private var theme
    
    /// Creates a new themed button modifier
    /// - Parameter type: The type of button
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

/// Background elevation levels
@available(iOS 14.0, macOS 11.0, *)
public enum BackgroundElevation {
    case base
    case elevated
    case lowered
}

/// A modifier that applies a themed background
@available(iOS 14.0, macOS 11.0, *)
public struct ThemedBackgroundModifier: ViewModifier {
    private let elevation: BackgroundElevation
    @Environment(\.colorTheme) private var theme
    
    /// Creates a new themed background modifier
    /// - Parameter elevation: The elevation level of the background
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

@available(iOS 14.0, macOS 11.0, *)
public extension View {
    /// Applies themed text styling
    /// - Parameter type: The type of text
    /// - Returns: A view with themed text styling
    func themedText(_ type: ThemedTextModifier.TextType = .primary) -> some View {
        modifier(ThemedTextModifier(type))
    }
    
    /// Applies themed button styling
    /// - Parameter type: The type of button
    /// - Returns: A view with themed button styling
    func themedButton(_ type: ThemedButtonModifier.ButtonType = .primary) -> some View {
        modifier(ThemedButtonModifier(type))
    }
    
    /// Applies a themed background
    /// - Parameter elevation: The elevation level of the background
    /// - Returns: A view with a themed background
    func themedBackground(_ elevation: BackgroundElevation = .base) -> some View {
        modifier(ThemedBackgroundModifier(elevation))
    }
} 