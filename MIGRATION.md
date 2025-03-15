# Migration Guide: ColorKit 1.5.0

This guide helps you migrate your code from ColorKit 1.4.x to version 1.5.0. The main changes in this version focus on standardizing parameter naming across the library for better consistency and intuitiveness.

## Breaking Changes

### Parameter Naming Standardization

#### Accessibility Methods
```swift
// Old
color.adjustedForAccessibility(against: background, minimumRatio: 4.5)
color.enhanced(against: background, targetLevel: .AA)
color.suggestAccessibleVariants(against: background, count: 3)
color.wcagContrastRatio(against: background)
color.wcagRelativeLuminance(against: background)

// New
color.adjustedForAccessibility(with: background, minimumRatio: 4.5)
color.enhanced(with: background, targetLevel: .AA)
color.suggestAccessibleVariants(with: background, count: 3)
color.wcagContrastRatio(with: background)
color.wcagRelativeLuminance(with: background)
```

#### Color Cache Methods
```swift
// Old
ColorCache.shared.getCachedContrastRatio(for: color1, and: color2)
ColorCache.shared.cacheContrastRatio(for: color1, and: color2, ratio: 4.5)
ColorCache.shared.getCachedBlendedColor(color1: color1, and: color2, blendMode: mode)
ColorCache.shared.cacheBlendedColor(color1: color1, and: color2, blendMode: mode)
ColorCache.shared.getCachedInterpolatedColor(color1: color1, and: color2, amount: 0.5)
ColorCache.shared.cacheInterpolatedColor(color1: color1, and: color2, amount: 0.5)

// New
ColorCache.shared.getCachedContrastRatio(for: color1, with: color2)
ColorCache.shared.cacheContrastRatio(for: color1, with: color2, ratio: 4.5)
ColorCache.shared.getCachedBlendedColor(color1: color1, with: color2, blendMode: mode)
ColorCache.shared.cacheBlendedColor(color1: color1, with: color2, blendMode: mode)
ColorCache.shared.getCachedInterpolatedColor(color1: color1, with: color2, amount: 0.5)
ColorCache.shared.cacheInterpolatedColor(color1: color1, with: color2, amount: 0.5)
```

#### Blending and Interpolation Methods
```swift
// Old
color1.blend(color2, mode: .normal, alpha: 0.5)
color1.interpolate(to: color2, fraction: 0.5)
color1.blended(color2, mode: .normal, alpha: 0.5)

// New
color1.blend(color2, mode: .normal, amount: 0.5)
color1.interpolate(to: color2, amount: 0.5)
color1.blended(with: color2, mode: .normal, amount: 0.5)
```

#### Gradient Methods
```swift
// Old
color.linearGradient(to: otherColor, fraction: 0.5)
color.monochromaticGradient(fraction: 0.5)

// New
color.linearGradient(to: otherColor, amount: 0.5)
color.monochromaticGradient(amount: 0.5)
```

## Migration Steps

1. **Update Package Dependency**
   ```swift
   // In your Package.swift
   dependencies: [
       .package(url: "https://github.com/yourusername/ColorKit.git", from: "1.5.0")
   ]
   ```

2. **Search and Replace**
   - Search for `against:` and replace with `with:`
   - Search for `and:` and replace with `with:`
   - Search for `alpha:` and replace with `amount:`
   - Search for `fraction:` and replace with `amount:`
   - Search for `blended(color:` and replace with `blended(with:`

3. **Update Documentation**
   - Update any internal documentation or comments that reference the old parameter names
   - Update any code examples in your project's documentation

4. **Run Tests**
   - Run your test suite to catch any missed parameter name updates
   - Pay special attention to tests involving:
     - Color accessibility checks
     - Color caching operations
     - Color blending and interpolation
     - Gradient generation

## Benefits

- More consistent and intuitive parameter naming across the library
- Better alignment with Swift's standard library naming conventions
- Improved code readability and maintainability
- Clearer intent in method signatures

## Support

If you encounter any issues during migration:
1. Check the [ColorKit documentation](https://github.com/yourusername/ColorKit/wiki)
2. Open an issue on the [GitHub repository](https://github.com/yourusername/ColorKit/issues)
3. Contact the maintainers through the project's communication channels

## Next Steps

After completing the migration:
1. Review your codebase for any other potential improvements
2. Consider updating to the latest Swift version if you haven't already
3. Test your app thoroughly, especially color-related features
4. Update your CI/CD pipelines if necessary 