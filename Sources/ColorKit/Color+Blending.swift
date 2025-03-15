//
//  Color+Blending.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 11.03.25.
//
//  Description:
//  Provides color blending operations similar to those found in graphic design software.
//
//  Features:
//  - Standard blending modes: Normal, Multiply, Screen, Overlay, etc.
//  - Alpha-aware blending
//  - Supports all color blending operations as SwiftUI Color extensions
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI

// MARK: - Blending Modes
public extension Color {
    /// Blends this color with another color using a specific blending mode.
    ///
    /// - Parameters:
    ///   - color: The color to blend with.
    ///   - mode: The blending mode to use.
    ///   - amount: The opacity of the blend, from 0.0 (no effect) to 1.0 (full effect).
    /// - Returns: The blended color.
    func blended(with color: Color, mode: BlendMode, amount: CGFloat = 1.0) -> Color {
        // If amount is 0, return the original color (no blending)
        if amount <= 0 {
            return self
        }
        
        // If amount is 1.0, check the cache for the full blend
        if amount >= 1.0 {
            if let cachedColor = ColorCache.shared.getCachedBlendedColor(color1: self, with: color, blendMode: String(describing: mode)) {
                return cachedColor
            }
        }
        
        // Extract RGB components from both colors
        guard let components1 = cgColor?.components, components1.count >= 3,
              let components2 = color.cgColor?.components, components2.count >= 3 else {
            return self
        }
        
        let r1 = components1[0]
        let g1 = components1[1]
        let b1 = components1[2]
        let a1 = components1.count >= 4 ? components1[3] : 1.0
        
        let r2 = components2[0]
        let g2 = components2[1]
        let b2 = components2[2]
        let a2 = components2.count >= 4 ? components2[3] : 1.0
        
        // Apply the blending function with amount
        let blendResult = mode.blend(base: (r1, g1, b1), blend: (r2, g2, b2))
        
        // Apply the amount blending
        let clampedAmount = max(0, min(1, amount))
        let r = r1 + (blendResult.r - r1) * clampedAmount * a2
        let g = g1 + (blendResult.g - g1) * clampedAmount * a2
        let b = b1 + (blendResult.b - b1) * clampedAmount * a2
        
        // Create the result color
        let resultColor = Color(.sRGB, red: r, green: g, blue: b, opacity: a1)
        
        // Cache the result if amount is 1.0 (full blend)
        if amount >= 1.0 {
            ColorCache.shared.cacheBlendedColor(color1: self, with: color, blendMode: String(describing: mode), result: resultColor)
        }
        
        return resultColor
    }
    
    /// Performs normal blending (standard alpha composition).
    ///
    /// - Parameters:
    ///   - color: The color to blend on top of this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func normal(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .normal, amount: amount)
    }
    
    /// Performs multiply blending, which darkens the image by multiplying color values.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func multiply(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .multiply, amount: amount)
    }
    
    /// Performs screen blending, which lightens by multiplying inverse values.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func screen(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .screen, amount: amount)
    }
    
    /// Performs overlay blending, which combines multiply and screen effects.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func overlay(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .overlay, amount: amount)
    }
    
    /// Performs darken blending, which keeps the darker value for each channel.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func darken(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .darken, amount: amount)
    }
    
    /// Performs lighten blending, which keeps the lighter value for each channel.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func lighten(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .lighten, amount: amount)
    }
    
    /// Performs color dodge blending, which brightens the base color by decreasing contrast.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func colorDodge(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .colorDodge, amount: amount)
    }
    
    /// Performs color burn blending, which darkens the base color by increasing contrast.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func colorBurn(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .colorBurn, amount: amount)
    }
    
    /// Performs hard light blending, similar to overlay but with the layers swapped.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func hardLight(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .hardLight, amount: amount)
    }
    
    /// Performs soft light blending, a softer version of hard light.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func softLight(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .softLight, amount: amount)
    }
    
    /// Performs difference blending, which subtracts the darker from the lighter value.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func difference(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .difference, amount: amount)
    }
    
    /// Performs exclusion blending, similar to difference but with lower contrast.
    ///
    /// - Parameters:
    ///   - color: The color to blend with this color.
    ///   - amount: The opacity of the blend (0.0 to 1.0).
    /// - Returns: The blended color.
    func exclusion(with color: Color, amount: CGFloat = 1.0) -> Color {
        return blended(with: color, mode: .exclusion, amount: amount)
    }
}

// MARK: - Blend Mode Implementation
/// Defines the available color blending modes.
public enum BlendMode {
    /// Normal blending (standard alpha composition).
    case normal
    
    /// Multiply blending (darkens by multiplying values).
    case multiply
    
    /// Screen blending (lightens by multiplying inverse values).
    case screen
    
    /// Overlay blending (combines multiply and screen).
    case overlay
    
    /// Darken blending (keeps the darker value for each channel).
    case darken
    
    /// Lighten blending (keeps the lighter value for each channel).
    case lighten
    
    /// Color dodge blending (brightens by decreasing contrast).
    case colorDodge
    
    /// Color burn blending (darkens by increasing contrast).
    case colorBurn
    
    /// Hard light blending (similar to overlay but with layers swapped).
    case hardLight
    
    /// Soft light blending (softer version of hard light).
    case softLight
    
    /// Difference blending (subtracts darker from lighter).
    case difference
    
    /// Exclusion blending (similar to difference but with lower contrast).
    case exclusion
    
    /// Applies the blend mode to a base color and a blend color.
    ///
    /// - Parameters:
    ///   - base: A tuple containing the base color's RGB components.
    ///   - blend: A tuple containing the blend color's RGB components.
    /// - Returns: A tuple containing the resulting RGB components.
    func blend(base: (r: CGFloat, g: CGFloat, b: CGFloat), blend: (r: CGFloat, g: CGFloat, b: CGFloat)) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        switch self {
        case .normal:
            return blend
            
        case .multiply:
            return (
                r: base.r * blend.r,
                g: base.g * blend.g,
                b: base.b * blend.b
            )
            
        case .screen:
            return (
                r: 1 - (1 - base.r) * (1 - blend.r),
                g: 1 - (1 - base.g) * (1 - blend.g),
                b: 1 - (1 - base.b) * (1 - blend.b)
            )
            
        case .overlay:
            return (
                r: overlayComponent(base: base.r, blend: blend.r),
                g: overlayComponent(base: base.g, blend: blend.g),
                b: overlayComponent(base: base.b, blend: blend.b)
            )
            
        case .darken:
            return (
                r: min(base.r, blend.r),
                g: min(base.g, blend.g),
                b: min(base.b, blend.b)
            )
            
        case .lighten:
            return (
                r: max(base.r, blend.r),
                g: max(base.g, blend.g),
                b: max(base.b, blend.b)
            )
            
        case .colorDodge:
            return (
                r: colorDodgeComponent(base: base.r, blend: blend.r),
                g: colorDodgeComponent(base: base.g, blend: blend.g),
                b: colorDodgeComponent(base: base.b, blend: blend.b)
            )
            
        case .colorBurn:
            return (
                r: colorBurnComponent(base: base.r, blend: blend.r),
                g: colorBurnComponent(base: base.g, blend: blend.g),
                b: colorBurnComponent(base: base.b, blend: blend.b)
            )
            
        case .hardLight:
            return (
                r: hardLightComponent(base: base.r, blend: blend.r),
                g: hardLightComponent(base: base.g, blend: blend.g),
                b: hardLightComponent(base: base.b, blend: blend.b)
            )
            
        case .softLight:
            return (
                r: softLightComponent(base: base.r, blend: blend.r),
                g: softLightComponent(base: base.g, blend: blend.g),
                b: softLightComponent(base: base.b, blend: blend.b)
            )
            
        case .difference:
            return (
                r: abs(base.r - blend.r),
                g: abs(base.g - blend.g),
                b: abs(base.b - blend.b)
            )
            
        case .exclusion:
            return (
                r: base.r + blend.r - 2 * base.r * blend.r,
                g: base.g + blend.g - 2 * base.g * blend.g,
                b: base.b + blend.b - 2 * base.b * blend.b
            )
        }
    }
    
    // MARK: - Helper Functions
    
    /// Helper function for overlay and hard light blending
    private func overlayComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if base < 0.5 {
            return 2 * base * blend
        } else {
            return 1 - 2 * (1 - base) * (1 - blend)
        }
    }
    
    /// Helper function for hard light blending
    private func hardLightComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        return overlayComponent(base: blend, blend: base)
    }
    
    /// Helper function for soft light blending
    private func softLightComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if blend < 0.5 {
            return base - (1 - 2 * blend) * base * (1 - base)
        } else {
            let d = base <= 0.25 ? ((16 * base - 12) * base + 4) * base : sqrt(base)
            return base + (2 * blend - 1) * (d - base)
        }
    }
    
    /// Helper function for color dodge blending
    private func colorDodgeComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if blend >= 1 {
            return 1
        } else if blend <= 0 {
            return base
        } else {
            return min(1, base / (1 - blend))
        }
    }
    
    /// Helper function for color burn blending
    private func colorBurnComponent(base: CGFloat, blend: CGFloat) -> CGFloat {
        if blend <= 0 {
            return 0
        } else if blend >= 1 {
            return base
        } else {
            return 1 - min(1, (1 - base) / blend)
        }
    }
} 
