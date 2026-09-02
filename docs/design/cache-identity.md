# F03 · S04 — Optional, exact cache identity

Status: implemented.

## Agreed scope

- Preserve NSCache and existing public methods.
- Failure to establish a supported color identity means a cache miss on lookup and no insertion on write. No shared fallback identity is permitted.
- Support identities only for explicitly recognized RGB and grayscale spaces. Unresolved or dynamic colors, patterns, and custom or unknown spaces bypass caching.
- Preserve the original color space and every component, including alpha. Do not convert colors merely to construct keys.
- Giving grayscale a distinct identity does not change algorithms that currently reject grayscale component layouts or return a fallback.
- Preserve exact interpolation amounts: 0.5001 and 0.5004 must not share an entry.
- Preserve exact finite floating-point bit patterns for color components and interpolation amounts, including distinct negative and positive zero. Do not round, clamp, or normalize values when constructing keys; extended-range finite components remain eligible.
- If any component or interpolation amount supplied to the cache is NaN or infinite, lookup misses and insertion is skipped. This does not change the higher-level interpolation method's existing clamping behavior.
- Contrast remains symmetric; blending and interpolation retain operand order.
- Apply the existing per-store count limit to the blend and interpolation stores as well.

## Recognized color spaces

The initial list is explicit. Each listed space has a distinct identity:

- RGB: `sRGB`, `linearSRGB`, `extendedSRGB`, `extendedLinearSRGB`, and `displayP3`.
- Grayscale: `genericGrayGamma2_2`, `linearGray`, `extendedGray`, and `extendedLinearGray`.

All other spaces, including device-dependent spaces, bypass caching. Recognition must establish the actual supported space rather than equating spaces solely because their component counts or color models match.

## Existing behavior to preserve

`Color.interpolated` clamps the amount before passing the same value to both the cache and computation. Removing rounding inside the cache must preserve this behavior without introducing additional normalization in the cache's public methods.

## Required validation

Cover all six stores directly: LAB, HSL, luminance, contrast, blending, and interpolation.

- Verify that unsupported colors cannot insert entries or retrieve another color's entry, including either operand of pair operations.
- Verify the recognized RGB and grayscale spaces with fixtures whose actual color space and component layout are checked. Equal components in different supported spaces must remain distinct; alpha must participate in identity.
- Verify exact numeric identity, signed zero, finite extended-range components, and nonfinite-input bypass. Fixtures must establish which values survive platform color construction before asserting their cache behavior.
- Verify contrast symmetry, ordered blending and interpolation, and separation by blend mode and interpolation space.
- Verify each store-specific clear operation leaves other stores intact and that global clearing empties all stores.
- Compare cold and warm scalar or color-component results across the cached operations. For interpolation, exercise 0.5001 and 0.5004 in both call orders in RGB, HSL, and LAB, comparing each result with its own cold baseline. Assertions must expose the original collision rather than hide it behind a broad numerical tolerance.
- Retain the existing numerical suites and validate both platform storage paths on macOS and iOS Simulator where available.

## Test isolation

Keep `ColorCache.init()` internal so direct tests can construct a fresh instance per test through `@testable import`. The public API and shared production instance remain unchanged.

Tests of high-level operations still use `ColorCache.shared`. Run those integration tests in a separate invocation with parallel testing disabled, exclude them from the parallel invocation, and clear the shared cache before and after each test. This preserves parallel execution for the remaining suite without relying on a lock that unrelated cache users do not observe.
