# LAB resolution

Status: implemented.

## Agreed scope

- Change `Color.labComponents()` to derive LAB coordinates from `ResolvedSRGBA.resolve(_:)` instead of interpreting raw `CGColor` component positions as sRGB.
- Preserve the public optional signature and let `labString()` inherit the corrected result through its existing call to `labComponents()`.
- Leave `ColorSpaceConverter.getAllColorComponents()` and its nonoptional aggregate fallback behavior unchanged.
- Preserve deployment targets and the existing sRGB-to-XYZ-to-LAB formulas.

## Agreed gamut policy

- Derive LAB from the finite nonlinear sRGB channels supplied by the resolved sRGBA snapshot.
- Preserve extended-range sRGB channel values, including values below zero or above one. Do not clamp, reject, or otherwise gamut-map them before the sRGB-to-XYZ-to-LAB conversion.
- This deliberately differs from bounded representations such as Hex and CMYK. LAB can describe colors outside the sRGB gamut, while those consumers reject snapshots they cannot represent without clipping.
- Return no LAB value when a fixed color cannot be resolved or the resolved snapshot is invalid.

## Agreed alpha and cache policy

- Ignore alpha when calculating LAB coordinates. Opacity does not change the color's LAB coordinates.
- Require the resolved snapshot to contain valid alpha even though alpha is not an input to the LAB calculation.
- Preserve the existing cache lookup and insertion path. Cache identity remains based on the original color space and complete component values, including alpha, so colors with different alpha retain distinct entries even when their LAB coordinates match.

## Agreed appearance policy

- Resolve only colors that expose a fixed `Color.cgColor`.
- Dynamic and semantic colors without fixed components return no LAB value on both iOS and macOS.
- Do not infer or consult a light or dark appearance. Callers that need appearance-specific LAB coordinates must supply an already-resolved fixed color.

## Agreed source and failure policy

- Accept exactly the fixed RGB and grayscale inputs that `ResolvedSRGBA.resolve(_:)` can resolve. Do not add a LAB-specific source-space allowlist.
- Return no LAB value for patterns, CMYK sources, nonfinite components, malformed snapshots, failed conversions, and every other input for which resolution is unavailable.
- Do not substitute black, zero LAB coordinates, or another compatibility fallback.
- Keep resolution support independent of cache eligibility. A convertible source may produce LAB coordinates while bypassing the cache under the existing identity rules.

## Agreed result policy

- Require the calculated L*, a*, and b* coordinates to be finite before returning or caching them.
- Ordinary finite extended-range channels remain valid inputs and are not gamut-mapped.
- If finite input channels cause arithmetic overflow or another nonfinite LAB result, return no LAB value and do not cache the result.

## Validation plan

- Verify ordinary sRGB values retain their existing LAB coordinates and cache behavior.
- Compare equivalent colors represented in sRGB, grayscale, linear RGB, and Display P3, confirming that conversion uses resolved nonlinear sRGB rather than raw source component positions.
- Verify in-gamut and out-of-sRGB-gamut Display P3 inputs, plus finite extended-sRGB values below zero and above one, produce finite unclipped LAB coordinates when the arithmetic remains representable.
- Verify extreme finite extended-range input that overflows the conversion returns no LAB value and is not cached.
- Verify transparent, translucent, and opaque versions have equal LAB coordinates while retaining distinct original-color cache identities.
- Verify dynamic and semantic colors, patterns, CMYK sources, nonfinite components, malformed snapshots, and failed resolution return no LAB value.
- Where Core Graphics rejects or sanitizes an invalid color during construction, test snapshot validation directly and do not mischaracterize the sanitized `Color` as preserving the invalid input.
- Verify cold and warm cache results, distinct source-space identities for visually equivalent colors, cache bypass for convertible but ineligible spaces, and unchanged aggregate-converter cache independence.
- Run the test suite on macOS and an iOS Simulator without changing the package deployment targets.
