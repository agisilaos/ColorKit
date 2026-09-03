# Preserve the legacy preview API as a shim

ColorKit's accurate fixed-color API will be `Color.simulated(for:) -> Color?`, taking the public `ColorVisionDeficiency` type shared with `AccessibilityLabPreview` and limited to protanopia, deuteranopia, and tritanopia. The existing `ColorBlindnessPreviewModifier.ColorBlindnessType` and arbitrary-view modifier will remain as deprecated compatibility APIs, including their `normal` and `achromatopsia` cases, so existing clients continue to compile without allowing unsupported cases into the new simulation contract.
