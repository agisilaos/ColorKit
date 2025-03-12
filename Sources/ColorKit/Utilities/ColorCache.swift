//
//  ColorCache.swift
//  ColorKit
//
//  Created by Agisilaos Tsaraboulidis on 12.03.25.
//
//  Description:
//  Provides caching for expensive color operations to improve performance.
//
//  Features:
//  - Thread-safe caching for color conversions
//  - Automatic cache invalidation
//  - Support for different color spaces
//
//  License:
//  MIT License. See LICENSE file for details.
//

import SwiftUI
import Foundation

/// A thread-safe cache for expensive color operations
@available(iOS 14.0, macOS 11.0, *)
public final class ColorCache: @unchecked Sendable {
    /// The shared instance for app-wide caching
    public static let shared = ColorCache()
    
    /// Maximum number of entries to store in each cache
    private let maxCacheSize = 100
    
    /// Cache for LAB color components
    private var labCache = NSCache<NSString, NSArray>()
    
    /// Cache for HSL color components
    private var hslCache = NSCache<NSString, NSArray>()
    
    /// Cache for WCAG luminance values
    private var luminanceCache = NSCache<NSString, NSNumber>()
    
    /// Cache for WCAG contrast ratios
    private var contrastRatioCache = NSCache<NSString, NSNumber>()
    
    /// Cache for blended colors
    #if canImport(AppKit)
    private var blendedColorCache = NSCache<NSString, NSColor>()
    private var interpolatedColorCache = NSCache<NSString, NSColor>()
    #elseif canImport(UIKit)
    private var blendedColorCache = NSCache<NSString, UIColor>()
    private var interpolatedColorCache = NSCache<NSString, UIColor>()
    #endif
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Set cache limits
        labCache.countLimit = maxCacheSize
        hslCache.countLimit = maxCacheSize
        luminanceCache.countLimit = maxCacheSize
        contrastRatioCache.countLimit = maxCacheSize
    }
    
    /// Generates a cache key for a color
    private func cacheKey(for color: Color) -> NSString {
        guard let components = color.cgColor?.components, components.count >= 3 else {
            return "invalid_color" as NSString
        }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        let a = components.count >= 4 ? components[3] : 1.0
        
        return "\(r),\(g),\(b),\(a)" as NSString
    }
    
    /// Generates a cache key for a pair of colors
    private func cacheKey(for color1: Color, and color2: Color) -> NSString {
        let key1 = cacheKey(for: color1)
        let key2 = cacheKey(for: color2)
        return "\(key1)_\(key2)" as NSString
    }
    
    // MARK: - LAB Caching
    
    /// Gets cached LAB components for a color, or nil if not cached
    func getCachedLABComponents(for color: Color) -> (L: CGFloat, a: CGFloat, b: CGFloat)? {
        let key = cacheKey(for: color)
        guard let array = labCache.object(forKey: key) else { return nil }
        
        guard array.count == 3,
              let L = array[0] as? CGFloat,
              let a = array[1] as? CGFloat,
              let b = array[2] as? CGFloat else {
            return nil
        }
        
        return (L, a, b)
    }
    
    /// Caches LAB components for a color
    func cacheLABComponents(for color: Color, L: CGFloat, a: CGFloat, b: CGFloat) {
        let key = cacheKey(for: color)
        let array = [L, a, b] as NSArray
        labCache.setObject(array, forKey: key)
    }
    
    // MARK: - HSL Caching
    
    /// Gets cached HSL components for a color, or nil if not cached
    func getCachedHSLComponents(for color: Color) -> (hue: CGFloat, saturation: CGFloat, lightness: CGFloat)? {
        let key = cacheKey(for: color)
        guard let array = hslCache.object(forKey: key) else { return nil }
        
        guard array.count == 3,
              let hue = array[0] as? CGFloat,
              let saturation = array[1] as? CGFloat,
              let lightness = array[2] as? CGFloat else {
            return nil
        }
        
        return (hue, saturation, lightness)
    }
    
    /// Caches HSL components for a color
    func cacheHSLComponents(for color: Color, hue: CGFloat, saturation: CGFloat, lightness: CGFloat) {
        let key = cacheKey(for: color)
        let array = [hue, saturation, lightness] as NSArray
        hslCache.setObject(array, forKey: key)
    }
    
    // MARK: - WCAG Caching
    
    /// Get cached luminance for a color
    /// - Parameter color: The color to get cached luminance for
    /// - Returns: The cached luminance value if available, nil otherwise
    public func getCachedLuminance(for color: Color) -> Double? {
        let key = cacheKey(for: color)
        if let cachedValue = luminanceCache.object(forKey: key) {
            return cachedValue.doubleValue
        }
        return nil
    }
    
    /// Cache luminance for a color
    /// - Parameters:
    ///   - color: The color to cache luminance for
    ///   - luminance: The luminance value to cache
    public func cacheLuminance(for color: Color, luminance: Double) {
        let key = cacheKey(for: color)
        luminanceCache.setObject(NSNumber(value: luminance), forKey: key)
    }
    
    /// Get cached contrast ratio between two colors
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    /// - Returns: The cached contrast ratio if available, nil otherwise
    public func getCachedContrastRatio(for color1: Color, and color2: Color) -> Double? {
        let key = contrastCacheKey(for: color1, and: color2)
        if let cachedValue = contrastRatioCache.object(forKey: key) {
            return cachedValue.doubleValue
        }
        return nil
    }
    
    /// Cache contrast ratio between two colors
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - ratio: The contrast ratio to cache
    public func cacheContrastRatio(for color1: Color, and color2: Color, ratio: Double) {
        let key = contrastCacheKey(for: color1, and: color2)
        contrastRatioCache.setObject(NSNumber(value: ratio), forKey: key)
    }
    
    /// Clears all caches
    public func clearAllCaches() {
        labCache.removeAllObjects()
        hslCache.removeAllObjects()
        luminanceCache.removeAllObjects()
        contrastRatioCache.removeAllObjects()
        blendedColorCache.removeAllObjects()
        interpolatedColorCache.removeAllObjects()
    }
    
    /// Generates a contrast cache key for two colors
    private func contrastCacheKey(for color1: Color, and color2: Color) -> NSString {
        let key1 = cacheKey(for: color1)
        let key2 = cacheKey(for: color2)
        // Create a consistent key regardless of color order
        let keys = [key1 as String, key2 as String].sorted()
        return (keys[0] + ":" + keys[1]) as NSString
    }
    
    // MARK: - Color Blending Caching
    
    /// Get cached blended color
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - blendMode: The blend mode used
    /// - Returns: The cached blended color if available, nil otherwise
    public func getCachedBlendedColor(color1: Color, color2: Color, blendMode: String) -> Color? {
        let key = blendCacheKey(for: color1, and: color2, blendMode: blendMode)
        #if canImport(AppKit)
        if let nsColor = blendedColorCache.object(forKey: key) {
            return Color(nsColor)
        }
        return nil
        #elseif canImport(UIKit)
        if let uiColor = blendedColorCache.object(forKey: key) {
            return Color(uiColor)
        }
        return nil
        #else
        return nil
        #endif
    }
    
    /// Cache blended color
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - blendMode: The blend mode used
    ///   - result: The resulting blended color
    public func cacheBlendedColor(color1: Color, color2: Color, blendMode: String, result: Color) {
        let key = blendCacheKey(for: color1, and: color2, blendMode: blendMode)
        #if canImport(AppKit)
        if let cgColor = result.cgColor, let nsColor = NSColor(cgColor: cgColor) {
            blendedColorCache.setObject(nsColor, forKey: key)
        }
        #elseif canImport(UIKit)
        if let cgColor = result.cgColor, let uiColor = UIColor(cgColor: cgColor) {
            blendedColorCache.setObject(uiColor, forKey: key)
        }
        #endif
    }
    
    /// Clear all cached blended colors
    public func clearBlendedColorCache() {
        blendedColorCache.removeAllObjects()
    }
    
    // MARK: - Interpolation Caching
    
    /// Get cached interpolated color
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - fraction: The interpolation fraction
    ///   - colorSpace: The color space used for interpolation
    /// - Returns: The cached interpolated color if available, nil otherwise
    public func getCachedInterpolatedColor(color1: Color, color2: Color, fraction: CGFloat, colorSpace: String) -> Color? {
        let key = interpolationCacheKey(for: color1, and: color2, fraction: fraction, colorSpace: colorSpace)
        #if canImport(AppKit)
        if let nsColor = interpolatedColorCache.object(forKey: key) {
            return Color(nsColor)
        }
        #elseif canImport(UIKit)
        if let uiColor = interpolatedColorCache.object(forKey: key) {
            return Color(uiColor)
        }
        #endif
        return nil
    }
    
    /// Cache interpolated color
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - fraction: The interpolation fraction
    ///   - colorSpace: The color space used for interpolation
    ///   - result: The resulting interpolated color
    public func cacheInterpolatedColor(color1: Color, color2: Color, fraction: CGFloat, colorSpace: String, result: Color) {
        let key = interpolationCacheKey(for: color1, and: color2, fraction: fraction, colorSpace: colorSpace)
        #if canImport(AppKit)
        if let cgColor = result.cgColor, let nsColor = NSColor(cgColor: cgColor) {
            interpolatedColorCache.setObject(nsColor, forKey: key)
        }
        #elseif canImport(UIKit)
        if let cgColor = result.cgColor, let uiColor = UIColor(cgColor: cgColor) {
            interpolatedColorCache.setObject(uiColor, forKey: key)
        }
        #endif
    }
    
    /// Clear all cached interpolated colors
    public func clearInterpolatedColorCache() {
        interpolatedColorCache.removeAllObjects()
    }
    
    // MARK: - Helper Methods
    
    private func blendCacheKey(for color1: Color, and color2: Color, blendMode: String) -> NSString {
        let key1 = cacheKey(for: color1)
        let key2 = cacheKey(for: color2)
        return "\(key1):\(key2):\(blendMode)" as NSString
    }
    
    private func interpolationCacheKey(for color1: Color, and color2: Color, fraction: CGFloat, colorSpace: String) -> NSString {
        let key1 = cacheKey(for: color1)
        let key2 = cacheKey(for: color2)
        // Round fraction to 3 decimal places to avoid too many cache entries
        let roundedFraction = round(fraction * 1000) / 1000
        return "\(key1):\(key2):\(roundedFraction):\(colorSpace)" as NSString
    }
}

// Extension to add z component to CGPoint for 3D color space caching
private extension CGPoint {
    init(x: CGFloat, y: CGFloat, z: CGFloat) {
        self.init(x: x, y: y)
        // Store z in a way that can be retrieved later
        objc_setAssociatedObject(self, "z", z, .OBJC_ASSOCIATION_RETAIN)
    }
    
    var z: CGFloat {
        return objc_getAssociatedObject(self, "z") as? CGFloat ?? 0
    }
} 