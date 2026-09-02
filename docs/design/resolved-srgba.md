# F07 — Fallible resolved-sRGBA snapshot

Status: implemented.

## Agreed scope

- Introduce an internal immutable optional resolved-sRGBA snapshot obtained through an uncached platform resolver.
- Adopt the snapshot in uncached Hex and CMYK extraction only. Preserve public signatures and compatibility fallbacks.
- Defer migration of cached consumers. Preserve original-component cache identity and never construct cache keys through cached conversions.
- Add cross-representation and failure tests for macOS and iOS.

## Agreed representation and range policy

- The snapshot represents nonlinear sRGB with separate, unpremultiplied alpha.
- Preserve finite extended-range RGB values, including negative values and values greater than one; do not clamp during resolution.
- Failed conversion or any nonfinite component produces no snapshot.
- Hex and CMYK extraction return `nil` when resolved RGB values fall outside 0–1. Neither consumer clips those values or introduces a gamut-mapping policy.
- Preserve existing Hex rounding and CMYK calculations for in-range resolved values.
- Range checks are strict, with no tolerance or endpoint snapping. A tiny platform conversion overshoot near white is out of range and returns `nil` from Hex and CMYK.

## Agreed appearance policy

- Resolve only inputs that expose a fixed `Color.cgColor`.
- Dynamic and semantic colors without fixed components produce no snapshot, preserving `nil` from Hex and CMYK extraction.
- Do not select or consult an ambient light/dark appearance. Callers may supply an already-resolved fixed color.
- Explicit appearance-aware resolution is deferred.

## Agreed alpha policy

- Alpha must be finite and within 0–1; invalid alpha produces no snapshot and is not clamped.
- Preserve RGB independently of alpha, including at alpha zero. Do not premultiply or composite against a background.
- Hex includes alpha using the existing nearest-byte rounding.
- CMYK continues to ignore alpha. Transparent red retains the same CMYK components as opaque red.

## Agreed source policy

- Accept fixed RGB and grayscale inputs when the platform can convert their source color space to extended sRGB.
- This includes sRGB, linear RGB, Display P3, extended-range RGB, and grayscale representations; raw component positions do not establish sRGB values.
- Patterns, other color models, malformed components, and failed conversions produce no snapshot.
- Conversion support is independent of cache eligibility. Supporting conversion of a source does not make it cacheable or change its cache identity.

## Compatibility consequences

- Ordinary in-range sRGB extraction retains existing formatting, rounding, and CMYK arithmetic.
- Grayscale can now produce Hex and CMYK values. Linear RGB and wide-gamut sources are converted rather than interpreted as raw sRGB.
- The inspector already calls `hexValue()` directly, so grayscale Hex can become available while its RGB, HSL, and contrast fields retain their existing behavior. Update the affected Hex assertion without migrating those other fields.
- Existing aggregate callers inherit the changed Hex/CMYK results. Keep their nonoptional compatibility fallbacks unchanged.
- Leave `rgbaComponents()`, `wcagRGBAComponents()`, cached conversions, cache keys, and other conversion algorithms unchanged in this slice.

## Validation plan

- Run macOS and iOS Simulator tests. Xcode 26.5 and an iOS 26.5 iPhone 17 simulator are available locally.
- Compare equivalent interior colors represented as sRGB, linear RGB, Display P3, and grayscale, verifying that fixtures retain their intended source spaces and component layouts.
- Cover ordinary sRGB Hex round trips, rounding, aliases, component formatting, CMYK black handling, and CMYK percentage truncation.
- Verify finite extended-range values survive snapshot resolution while Hex and CMYK reject RGB outside 0–1, including out-of-gamut Display P3.
- Verify alpha preservation at zero, partial opacity, and one; Hex includes alpha and CMYK ignores it.
- Verify unavailable results for dynamic/semantic colors, patterns, unsupported models, malformed/nonfinite components, invalid alpha, and failed conversion. Account for values sanitized by platform construction rather than treating them as surviving invalid fixtures.
- Keep tests of legacy nonoptional fallbacks and original cache identity. Run shared-cache integration tests separately with parallel testing disabled, following existing test isolation.

## Resolver implementation

- Use Core Graphics on both platforms, targeting `extendedSRGB` with relative-colorimetric intent and no conversion options.
- Preserve components directly only when the source space equals standard sRGB or extended sRGB; they share the nonlinear encoding. This avoids changing existing sRGB rounding through an unnecessary transform.
- Validate source component shape, finiteness, and alpha before conversion and validate the resulting snapshot again afterward.
- The snapshot validates the color that reaches it. Core Graphics can sanitize invalid finite alpha during color construction; it cannot recover those original values.
