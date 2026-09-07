---
status: accepted
---

# Preserve gamut in component-conversion results

The new component-conversion API preserves extended sRGBA and finite XYZ/LAB, while
HSL, HSB, CMYK, and Hex report `outOfSRGBGamut` whenever a resolved RGB channel is
outside `0...1`, with no clipping, tolerance, or endpoint snapping. This keeps the
available representations tied to the same color, accepting that even a tiny platform
conversion overshoot near white can make bounded representations unavailable.
Legacy conversion behavior, including HSL clipping, remains unchanged.
