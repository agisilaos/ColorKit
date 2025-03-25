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

/// Represents the result of a WCAG compliance check between two colors.
/// This struct stores the contrast ratio and whether the colors pass various WCAG compliance levels.
public struct WCAGComplianceResult {
    /// The calculated contrast ratio between two colors.
    public let contrastRatio: Double

    /// Whether the colors pass the AA compliance level for normal text.
    public let passesAA: Bool

    /// Whether the colors pass the AA compliance level for large text (18pt+).
    public let passesAALarge: Bool

    /// Whether the colors pass the AAA compliance level for normal text.
    public let passesAAA: Bool

    /// Whether the colors pass the AAA compliance level for large text (18pt+).
    public let passesAAALarge: Bool

    /// Returns the highest WCAG compliance level that the colors pass.
    /// If none are met, it returns `nil`.
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

    /// Returns a list of all WCAG compliance levels that the colors pass.
    public var passes: [WCAGContrastLevel] {
        var result: [WCAGContrastLevel] = []
        if passesAALarge { result.append(.AALarge) }
        if passesAA { result.append(.AA) }
        if passesAAALarge { result.append(.AAALarge) }
        if passesAAA { result.append(.AAA) }
        return result
    }
}