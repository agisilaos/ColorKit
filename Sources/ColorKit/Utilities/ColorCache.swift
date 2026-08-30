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

import Foundation
import SwiftUI

/// A thread-safe cache for expensive color operations.
///
/// Colors without an exact identity in a supported color space bypass caching.
/// Cache keys preserve component values and operation parameters without rounding.
public final class ColorCache: @unchecked Sendable {
    /// The shared instance for app-wide caching
    public static let shared = ColorCache()

    /// Maximum number of entries to store in each cache
    private let maxCacheSize = 100

    /// Cache for LAB color components
    private let labCache = NSCache<NSString, NSArray>()

    /// Cache for HSL color components
    private let hslCache = NSCache<NSString, NSArray>()

    /// Cache for WCAG luminance values
    private let luminanceCache = NSCache<NSString, NSNumber>()

    /// Cache for WCAG contrast ratios
    private let contrastRatioCache = NSCache<NSString, NSNumber>()

    /// Cache for blended colors
#if canImport(AppKit)
    private let blendedColorCache = NSCache<NSString, NSColor>()
    private let interpolatedColorCache = NSCache<NSString, NSColor>()
#elseif canImport(UIKit)
    private let blendedColorCache = NSCache<NSString, UIColor>()
    private let interpolatedColorCache = NSCache<NSString, UIColor>()
#endif

    /// Creates an independent cache for internal use and tests.
    init() {
        // Set cache limits
        labCache.countLimit = maxCacheSize
        hslCache.countLimit = maxCacheSize
        luminanceCache.countLimit = maxCacheSize
        contrastRatioCache.countLimit = maxCacheSize
        blendedColorCache.countLimit = maxCacheSize
        interpolatedColorCache.countLimit = maxCacheSize
    }

    // MARK: - LAB Caching

    /// Gets cached LAB components for a color, or nil if not cached
    func getCachedLABComponents(for color: Color) -> (L: CGFloat, a: CGFloat, b: CGFloat)? {
        guard let key = cacheKey(for: color) else { return nil }
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
        guard let key = cacheKey(for: color) else { return }
        let array = [L, a, b] as NSArray
        labCache.setObject(array, forKey: key)
    }

    // MARK: - HSL Caching

    /// Gets cached HSL components for a color, or nil if not cached
    func getCachedHSLComponents(for color: Color) -> (hue: CGFloat, saturation: CGFloat, lightness: CGFloat)? {
        guard let key = cacheKey(for: color) else { return nil }
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
        guard let key = cacheKey(for: color) else { return }
        let array = [hue, saturation, lightness] as NSArray
        hslCache.setObject(array, forKey: key)
    }

    // MARK: - WCAG Caching

    /// Get cached luminance for a color
    /// - Parameter color: The color to get cached luminance for
    /// - Returns: The cached luminance value if available, nil otherwise
    public func getCachedLuminance(for color: Color) -> Double? {
        guard let key = cacheKey(for: color) else { return nil }
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
        guard let key = cacheKey(for: color) else { return }
        luminanceCache.setObject(NSNumber(value: luminance), forKey: key)
    }

    /// Get cached contrast ratio between two colors
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    /// - Returns: The cached contrast ratio if available, nil otherwise
    public func getCachedContrastRatio(for color1: Color, with color2: Color) -> Double? {
        guard let key = contrastCacheKey(for: color1, with: color2) else { return nil }
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
    public func cacheContrastRatio(for color1: Color, with color2: Color, ratio: Double) {
        guard let key = contrastCacheKey(for: color1, with: color2) else { return }
        contrastRatioCache.setObject(NSNumber(value: ratio), forKey: key)
    }

    /// Clears all caches
    public func clearCache() {
        labCache.removeAllObjects()
        hslCache.removeAllObjects()
        luminanceCache.removeAllObjects()
        contrastRatioCache.removeAllObjects()
        blendedColorCache.removeAllObjects()
        interpolatedColorCache.removeAllObjects()
    }

    /// Clears the LAB components cache
    public func clearLABCache() {
        labCache.removeAllObjects()
    }

    /// Clears the HSL components cache
    public func clearHSLCache() {
        hslCache.removeAllObjects()
    }

    /// Clears the luminance cache
    public func clearLuminanceCache() {
        luminanceCache.removeAllObjects()
    }

    /// Clears the contrast ratio cache
    public func clearContrastCache() {
        contrastRatioCache.removeAllObjects()
    }

    // MARK: - Color Blending Caching

    /// Get cached blended color
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - blendMode: The blend mode used
    /// - Returns: The cached blended color if available, nil otherwise
    public func getCachedBlendedColor(color1: Color, with color2: Color, blendMode: String) -> Color? {
        guard let key = blendCacheKey(for: color1, with: color2, blendMode: blendMode) else { return nil }

        #if canImport(AppKit)
        return blendedColorCache.object(forKey: key).map { Color($0) }
        #elseif canImport(UIKit)
        return blendedColorCache.object(forKey: key).map { Color($0) }
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
    public func cacheBlendedColor(color1: Color, with color2: Color, blendMode: String, result: Color) {
        guard let key = blendCacheKey(for: color1, with: color2, blendMode: blendMode) else { return }
        cacheColor(result, forKey: key)
    }

    private func cacheColor(_ color: Color, forKey key: NSString) {
        guard let cgColor = color.cgColor else { return }

        #if canImport(AppKit)
        if let nsColor = NSColor(cgColor: cgColor) {
            blendedColorCache.setObject(nsColor, forKey: key)
        }
        #elseif canImport(UIKit)
        blendedColorCache.setObject(UIColor(cgColor: cgColor), forKey: key)
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
    ///   - amount: The interpolation amount
    ///   - colorSpace: The color space used for interpolation
    /// - Returns: The cached interpolated color if available, nil otherwise
    public func getCachedInterpolatedColor(color1: Color, with color2: Color, amount: CGFloat, colorSpace: String) -> Color? {
        guard let key = interpolationCacheKey(for: color1, with: color2, amount: amount, colorSpace: colorSpace) else { return nil }

        #if canImport(AppKit)
        return interpolatedColorCache.object(forKey: key).map { Color($0) }
        #elseif canImport(UIKit)
        return interpolatedColorCache.object(forKey: key).map { Color($0) }
        #else
        return nil
        #endif
    }

    /// Cache interpolated color
    /// - Parameters:
    ///   - color1: The first color
    ///   - color2: The second color
    ///   - amount: The interpolation amount
    ///   - colorSpace: The color space used for interpolation
    ///   - result: The resulting interpolated color
    public func cacheInterpolatedColor(color1: Color, with color2: Color, amount: CGFloat, colorSpace: String, result: Color) {
        guard let key = interpolationCacheKey(for: color1, with: color2, amount: amount, colorSpace: colorSpace) else { return }
        guard let cgColor = result.cgColor else { return }

        #if canImport(AppKit)
        if let nsColor = NSColor(cgColor: cgColor) {
            interpolatedColorCache.setObject(nsColor, forKey: key)
        }
        #elseif canImport(UIKit)
        let uiColor = UIColor(cgColor: cgColor)
        interpolatedColorCache.setObject(uiColor, forKey: key)
        #endif
    }

    /// Clear all cached interpolated colors
    public func clearInterpolatedColorCache() {
        interpolatedColorCache.removeAllObjects()
    }

    // MARK: - Helper Methods

    private static let SUPPORTED_SPACE_NAMES: Set<String> = [
        CGColorSpace.sRGB as String,
        CGColorSpace.linearSRGB as String,
        CGColorSpace.extendedSRGB as String,
        CGColorSpace.extendedLinearSRGB as String,
        CGColorSpace.displayP3 as String,
        CGColorSpace.genericGrayGamma2_2 as String,
        CGColorSpace.linearGray as String,
        CGColorSpace.extendedGray as String,
        CGColorSpace.extendedLinearGray as String
    ]

    private func cacheKey(for color: Color) -> NSString? {
        guard let cgColor = color.cgColor,
              let space = cgColor.colorSpace,
              let name = space.name,
              Self.SUPPORTED_SPACE_NAMES.contains(name as String),
              let supportedSpace = CGColorSpace(name: name),
              CFEqual(space, supportedSpace),
              let components = cgColor.components,
              components.count == supportedSpace.numberOfComponents + 1,
              components.allSatisfy({ $0.isFinite }) else { return nil }

        let componentBits = components.map { String(Double($0).bitPattern, radix: 16) }
        return "\(name):\(componentBits.joined(separator: ","))" as NSString
    }

    private func contrastCacheKey(for color1: Color, with color2: Color) -> NSString? {
        guard let key1 = cacheKey(for: color1),
              let key2 = cacheKey(for: color2) else { return nil }
        let keys = [key1 as String, key2 as String].sorted()
        return keys.joined(separator: "|") as NSString
    }

    private func blendCacheKey(for color1: Color, with color2: Color, blendMode: String) -> NSString? {
        guard let key1 = cacheKey(for: color1),
              let key2 = cacheKey(for: color2) else { return nil }
        return "\(key1)|\(key2)|\(blendMode)" as NSString
    }

    private func interpolationCacheKey(for color1: Color, with color2: Color, amount: CGFloat, colorSpace: String) -> NSString? {
        guard amount.isFinite,
              let key1 = cacheKey(for: color1),
              let key2 = cacheKey(for: color2) else { return nil }
        let amountBits = String(Double(amount).bitPattern, radix: 16)
        return "\(key1)|\(key2)|\(amountBits)|\(colorSpace)" as NSString
    }
}
