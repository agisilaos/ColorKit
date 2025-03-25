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

/// Represents the WCAG contrast ratio levels
public enum WCAGContrastLevel: String, CaseIterable, Identifiable, Sendable {
    case AALarge = "AA Large"
    case AA = "AA"
    case AAALarge = "AAA Large"
    case AAA = "AAA"

    public var id: String { rawValue }

    /// The minimum contrast ratio required for this level
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

    /// Description of the WCAG level
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
