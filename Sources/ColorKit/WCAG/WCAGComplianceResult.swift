//
//  WCAGComplianceResult.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 25.03.25.
//
//  Description:
//  Represents the result of a WCAG compliance check between two colors.
//
//  License:
//  MIT License. See LICENSE file for details.
//

/// A structure that encapsulates the results of a WCAG accessibility compliance check.
///
/// `WCAGComplianceResult` provides comprehensive information about how well a color
/// combination meets WCAG accessibility guidelines, including:
///
/// - The actual contrast ratio between the colors
/// - Pass/fail status for each WCAG level
/// - Methods to determine compliance levels
///
/// Example usage:
/// ```swift
/// let textColor = Color.blue
/// let backgroundColor = Color.white
///
/// // Check compliance
/// let result = textColor.checkWCAGCompliance(against: backgroundColor)
///
/// // Print the contrast ratio
/// print("Contrast ratio: \(result.contrastRatio):1")
///
/// // Check if suitable for body text
/// if result.passesAA {
///     print("Safe to use for body text")
/// }
///
/// // Get highest passing level
/// if let highest = result.highestLevel {
///     print("Highest compliance: \(highest.description)")
/// }
/// ```
public struct WCAGComplianceResult {
    /// The calculated contrast ratio between the two colors.
    ///
    /// The contrast ratio is a value between 1:1 (no contrast) and 21:1 (black on white).
    /// WCAG guidelines specify minimum ratios for different compliance levels:
    ///
    /// - 3:1 for AA Large
    /// - 4.5:1 for AA and AAA Large
    /// - 7:1 for AAA
    public let contrastRatio: Double

    /// Indicates whether the colors meet Level AA requirements for normal text.
    ///
    /// Level AA for normal text requires a minimum contrast ratio of 4.5:1.
    /// This is considered the minimum level for most web content.
    public let passesAA: Bool

    /// Indicates whether the colors meet Level AA requirements for large text.
    ///
    /// Level AA for large text (18pt or 14pt bold) requires a minimum contrast ratio of 3:1.
    public let passesAALarge: Bool

    /// Indicates whether the colors meet Level AAA requirements for normal text.
    ///
    /// Level AAA for normal text requires a minimum contrast ratio of 7:1.
    /// This is the highest level of contrast accessibility.
    public let passesAAA: Bool

    /// Indicates whether the colors meet Level AAA requirements for large text.
    ///
    /// Level AAA for large text (18pt or 14pt bold) requires a minimum contrast ratio of 4.5:1.
    public let passesAAALarge: Bool

    /// The highest WCAG compliance level that the colors satisfy.
    ///
    /// Returns the most stringent level that the color combination meets, in order:
    /// 1. AAA (normal text)
    /// 2. AAA Large
    /// 3. AA (normal text)
    /// 4. AA Large
    ///
    /// Returns `nil` if no compliance levels are met.
    public var highestLevel: WCAGContrastLevel? {
        if passesAAA {
            return .AAA
        } else if passesAAALarge {
            return .AAALarge
        } else if passesAA {
            return .AA
        } else if passesAALarge {
            return .AALarge
        } else {
            return nil
        }
    }

    /// An array of all WCAG compliance levels that the colors satisfy.
    ///
    /// The levels are returned in ascending order of stringency:
    /// 1. AA Large (least stringent)
    /// 2. AA
    /// 3. AAA Large
    /// 4. AAA (most stringent)
    ///
    /// Example:
    /// ```swift
    /// let result = textColor.checkWCAGCompliance(against: backgroundColor)
    /// for level in result.passes {
    ///     print("✓ Passes \(level.description)")
    /// }
    /// ```
    public var passes: [WCAGContrastLevel] {
        var result: [WCAGContrastLevel] = []
        if passesAALarge { result.append(.AALarge) }
        if passesAA { result.append(.AA) }
        if passesAAALarge { result.append(.AAALarge) }
        if passesAAA { result.append(.AAA) }
        return result
    }
}
