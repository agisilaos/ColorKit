---
status: accepted
---

# Add an unambiguous color blend mode spelling

ColorKit adds `public typealias ColorBlendMode = BlendMode` so clients importing both SwiftUI and ColorKit can name its blend mode explicitly without a selective import; this is preferred over documenting selective imports as the only solution. The alias preserves the existing enum's type identity, cases, signatures, and behavior, without deprecation, a replacement enum, or additional conformances. Bare `BlendMode` remains ambiguous under those imports, and `ColorKit.BlendMode` is not a reliable workaround because the public `ColorKit` enum shadows the module name.

Client documentation recommends `ColorBlendMode` for explicit declarations, collections, and typed method references, while retaining inferred calls such as `mode: .multiply`. A single disambiguation note will explain that `BlendMode` remains supported but ambiguous when both modules are imported.
