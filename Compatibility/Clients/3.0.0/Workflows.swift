import ColorKit
import SwiftUI

func colorWorkflow() {
    let color = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6)
    _ = Color(hex: "336699")
    _ = color.rgbaComponents()
    _ = color.hslComponents()
    _ = color.labComponents()
    _ = color.cmykComponents()
    _ = color.relativeLuminanceValue()
    _ = color.simulated(for: .deuteranopia)
    let makeConfiguration = AccessibilityEnhancer.Configuration.init(targetLevel:strategy:maxPerceptualDistance:preferDarker:)
    _ = makeConfiguration(.AA, .preserveHue, 30, false)
    let configuration = AccessibilityEnhancer.Configuration(
        targetLevel: .AA, strategy: .preserveHue, maxPerceptualDistance: 30, preferDarker: false
    )
    let enhancer = AccessibilityEnhancer(configuration: configuration)
    _ = AccessibilityEnhancer.Configuration()
    _ = AccessibilityEnhancer()
    _ = enhancer.enhanceColor(color, against: .white)
    _ = enhancer.enhanceColorResult(color, against: .white)
    _ = enhancer.suggestAccessibleVariants(for: color, against: .white, count: 3)
    let generator = AccessiblePaletteGenerator(configuration: .init(
        targetLevel: .AA, paletteSize: 5, includeBlackAndWhite: true
    ))
    _ = AccessiblePaletteGenerator()
    let colors = generator.generatePalette(from: color)
    _ = generator.generateAssessedPalette(from: color, against: .white)
    let entries = PaletteExporter.createPalette(from: colors)
    _ = PaletteExporter.PaletteEntry(name: "Seed", color: color)
    _ = PaletteExporter.export(palette: entries, to: .json, paletteName: "Client")
}

func themeInitializers() -> ColorTheme {
    let colors = ThemeColorSet(base: .blue, light: .white, dark: .black)
    let status = StatusColorSet(success: .green, warning: .yellow, error: .red)
    _ = ColorTheme(name: "Explicit", primary: colors, secondary: colors, accent: colors,
                   background: colors, text: colors, status: status)
    _ = ColorTheme(name: "Full", primary: .blue, secondary: .gray, accent: .purple,
                   background: .white, text: .black, success: .green, warning: .yellow, error: .red)
    return ColorTheme(name: "Defaults", primary: .blue, secondary: .gray, accent: .purple,
                      background: .white, text: .black)
}

@MainActor
func themeAndPreviewWorkflow() {
    let theme = themeInitializers()
    let manager = ThemeManager.shared
    manager.register(theme: theme)
    manager.switchToTheme(named: theme.name)
    manager.switchTo(theme: theme)
    _ = manager.currentTheme
    _ = manager.availableThemes
    _ = manager.$currentTheme
    _ = Color.themed(.primary)
    _ = MainCatalogView()
    _ = PerformanceBenchmark()
    _ = ColorComparisonView(color1: .black, color2: .white)
    _ = ColorSpaceInspectorView(color: .blue)
    _ = WCAGComplianceModifier(foreground: .black, background: .white)
    _ = ColorBlindnessPreviewModifier(type: .achromatopsia)
    _ = Text("Client").colorBlindnessPreview(type: .protanopia)
}
