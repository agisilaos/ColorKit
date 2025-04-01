//
//  WCAGContrastLevel.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Defines the WCAG contrast ratio levels for accessibility.
//
//  License:
//  MIT License. See LICENSE file for details.
//

/// Represents the WCAG (Web Content Accessibility Guidelines) contrast ratio levels.
///
/// WCAG defines different levels of contrast requirements to ensure text and interactive
/// elements are readable by users with various visual abilities:
///
/// - AA: The minimum level for most web content
/// - AAA: The highest level of contrast accessibility
///
/// Each level has two variants:
/// - Standard: For normal text (below 18pt)
/// - Large: For large text (18pt and above)
///
/// Example usage:
/// ```swift
/// // Check if colors meet AA standard
/// let textColor = Color.blue
/// let backgroundColor = Color.white
/// let ratio = textColor.contrastRatio(with: backgroundColor)
///
/// if ratio >= WCAGContrastLevel.AA.minimumRatio {
///     print("Meets AA standard")
/// }
///
/// // Get required ratio for large text
/// let largeTextRatio = WCAGContrastLevel.AALarge.minimumRatio
/// print("Need \(largeTextRatio):1 contrast for large text")
/// ```
public enum WCAGContrastLevel: String, CaseIterable, Identifiable, Sendable {
    /// Level AA for large text (18pt or 14pt bold and above).
    /// Requires a minimum contrast ratio of 3:1.
    case AALarge = "AA Large"

    /// Level AA for normal text.
    /// Requires a minimum contrast ratio of 4.5:1.
    case AA = "AA"

    /// Level AAA for large text (18pt or 14pt bold and above).
    /// Requires a minimum contrast ratio of 4.5:1.
    case AAALarge = "AAA Large"

    /// Level AAA for normal text.
    /// Requires a minimum contrast ratio of 7:1.
    case AAA = "AAA"

    /// Unique identifier for the contrast level.
    public var id: String { rawValue }

    /// The minimum contrast ratio required for this level.
    ///
    /// WCAG contrast ratios are expressed as a ratio of luminance values
    /// between foreground and background colors. The ratio ranges from 1:1
    /// (no contrast) to 21:1 (maximum contrast, black on white).
    ///
    /// The minimum ratios are:
    /// - 3.0:1 for AA Large
    /// - 4.5:1 for AA and AAA Large
    /// - 7.0:1 for AAA
    ///
    /// Example:
    /// ```swift
    /// let level = WCAGContrastLevel.AA
    /// print("Minimum ratio: \(level.minimumRatio):1")
    /// ```
    public var minimumRatio: Double {
        switch self {
        case .AALarge:
            return 3.0
        case .AA:
            return 4.5
        case .AAALarge:
            return 4.5
        case .AAA:
            return 7.0
        }
    }

    /// A human-readable description of the WCAG level.
    ///
    /// This property provides a clear explanation of what the level represents,
    /// including whether it applies to normal or large text.
    ///
    /// Example:
    /// ```swift
    /// let level = WCAGContrastLevel.AALarge
    /// print(level.description) // "AA level for large text (18pt+)"
    /// ```
    public var description: String {
        switch self {
        case .AALarge:
            return "AA level for large text (18pt+)"
        case .AA:
            return "AA level for normal text"
        case .AAALarge:
            return "AAA level for large text (18pt+)"
        case .AAA:
            return "AAA level for normal text"
        }
    }
}
