import ColorKit

// No default branches: adding cases can break existing source clients.
func status(_ value: ColorAccessibilityResult.Status) -> Int {
    switch value {
    case .meetsTarget: 0
    case .bestEffort: 1
    case .unavailable: 2
    case .invalidConfiguration: 3
    }
}

func comparison(_ value: ColorComparisonResult) -> Double? {
    switch value {
    case .available(let difference): difference.perceptualDifference
    case .unavailable(let issues): issues.firstColor.isEmpty ? 0 : nil
    }
}

func contrast(_ value: ColorContrastResult) -> Double? {
    switch value {
    case .available(let measurement): measurement.ratio
    case .unavailable(let issues): issues.background.isEmpty ? 0 : nil
    }
}

func metric(_ value: PerceptualDifferenceMetric) -> Int {
    switch value {
    case .ciede2000: 0
    case .legacyRGBDistance: 1
    }
}

func comparisonIssue(_ value: ColorComparisonInputIssue) -> Int {
    switch value {
    case .unresolved: 0
    case .translucent: 1
    case .outOfSRGBGamut: 2
    }
}

func contrastIssue(_ value: ContrastInputIssue) -> Int {
    switch value {
    case .unresolved: 0
    case .outOfSRGBGamut: 1
    case .translucentBackground: 2
    }
}

func strategy(_ value: AdjustmentStrategy) -> Int {
    switch value {
    case .preserveHue: 0
    case .preserveSaturation: 1
    case .preserveLightness: 2
    case .minimumChange: 3
    }
}

func level(_ value: WCAGContrastLevel) -> Int {
    switch value {
    case .AALarge: 0
    case .AA: 1
    case .AAALarge: 2
    case .AAA: 3
    }
}

func format(_ value: PaletteExportFormat) -> Int {
    switch value {
    case .json: 0
    case .css: 1
    case .svg: 2
    case .ase: 3
    case .png: 4
    }
}

func deficiency(_ value: ColorVisionDeficiency) -> Int {
    switch value {
    case .protanopia: 0
    case .deuteranopia: 1
    case .tritanopia: 2
    }
}

func legacyDeficiency(_ value: ColorBlindnessPreviewModifier.ColorBlindnessType) -> Int {
    switch value {
    case .normal: 0
    case .protanopia: 1
    case .deuteranopia: 2
    case .tritanopia: 3
    case .achromatopsia: 4
    }
}

func switchGradientColorSpace(_ value: GradientColorSpace) -> Int {
    switch value {
    case .rgb: 0
    case .hsl: 1
    case .lab: 2
    }
}

func switchColorInspectorModifierPosition(_ value: ColorInspectorModifier.Position) -> Int {
    switch value {
    case .topLeading: 0
    case .topTrailing: 1
    case .bottomLeading: 2
    case .bottomTrailing: 3
    }
}

func switchBlendMode(_ value: BlendMode) -> Int {
    switch value {
    case .normal: 0
    case .multiply: 1
    case .screen: 2
    case .overlay: 3
    case .darken: 4
    case .lighten: 5
    case .colorDodge: 6
    case .colorBurn: 7
    case .hardLight: 8
    case .softLight: 9
    case .difference: 10
    case .exclusion: 11
    }
}

func switchGradientDirection(_ value: GradientDirection) -> Int {
    switch value {
    case .topLeadingToBottomTrailing: 0
    case .topTrailingToBottomLeading: 1
    case .bottomLeadingToTopTrailing: 2
    case .bottomTrailingToTopLeading: 3
    case .topToBottom: 4
    case .bottomToTop: 5
    case .leadingToTrailing: 6
    case .trailingToLeading: 7
    }
}

func switchThemeColorRole(_ value: ThemeColorRole) -> Int {
    switch value {
    case .primary: 0
    case .primaryLight: 1
    case .primaryDark: 2
    case .secondary: 3
    case .secondaryLight: 4
    case .secondaryDark: 5
    case .accent: 6
    case .accentLight: 7
    case .accentDark: 8
    case .background: 9
    case .backgroundElevated: 10
    case .backgroundLowered: 11
    case .text: 12
    case .textSecondary: 13
    case .textTertiary: 14
    case .success: 15
    case .warning: 16
    case .error: 17
    }
}

func switchThemedTextModifierTextType(_ value: ThemedTextModifier.TextType) -> Int {
    switch value {
    case .primary: 0
    case .secondary: 1
    case .tertiary: 2
    }
}

func switchThemedButtonModifierButtonType(_ value: ThemedButtonModifier.ButtonType) -> Int {
    switch value {
    case .primary: 0
    case .secondary: 1
    case .accent: 2
    }
}

func switchBackgroundElevation(_ value: BackgroundElevation) -> Int {
    switch value {
    case .base: 0
    case .elevated: 1
    case .lowered: 2
    }
}
