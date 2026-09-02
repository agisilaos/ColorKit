# ColorKit

ColorKit describes, compares, blends, and interpolates colors across color spaces, and provides contrast adjustments for SwiftUI interfaces.

## Language

**Resolved sRGBA snapshot**:
A fixed representation of a color in nonlinear sRGB with separate, unpremultiplied alpha in 0–1. All components are finite; RGB values may extend outside 0–1 to preserve colors beyond the sRGB gamut, and an unavailable conversion has no snapshot.
_Avoid_: Clamped RGB, color identity

**Unavailable inspector conversion**:
A color representation or contrast ratio that cannot be obtained from the current color inputs. It is neither a zero value nor a failed contrast threshold, and says nothing about earlier inputs.

**Color identity**:
The original color space and complete component values, including opacity, that distinguish a color input. Equal component values in different color spaces do not establish the same color identity.
_Avoid_: Visual equivalence

**Identifiable color**:
A fixed color whose original color space is an explicitly recognized RGB or grayscale space and whose complete, finite component values are available. Unresolved or dynamic colors, patterns, and colors in custom or unknown spaces fall outside this category.

**Interpolation amount**:
The position between an ordered pair of colors, with zero representing the starting color and one representing the destination. Nearby amounts such as 0.5001 and 0.5004 are distinct positions.
_Avoid_: Rounded amount

**Already-compliant input**:
A foreground color whose existing contrast against the specified background meets or exceeds the requested minimum under ColorKit's legacy contrast calculation. It needs no adjustment; this term does not independently certify WCAG compliance.

**Exhausted adjustment**:
A contrast adjustment attempt that ends without finding a color that meets the requested minimum. It does not establish that no suitable color exists.

**Directional endpoint attempt**:
A contrast adjustment candidate at the lightness endpoint selected by the existing direction: zero when darkening and one when lightening. Failure preserves that direction and does not cause the opposite endpoint to be considered.

**Successful directional endpoint attempt**:
A directional endpoint attempt whose contrast meets the requested level. It is distinct from an already-compliant input, which succeeds before any adjustment is attempted.

**Contrast fallback**:
The black or white color selected when contrast adjustment is unsuccessful. It is not guaranteed to meet every requested minimum.
_Avoid_: Guaranteed compliant color

**Best available contrasting endpoint**:
Whichever of black or white has the greater WCAG contrast ratio against a given color. This choice may still fall short of the requested contrast level, including AAA.
_Avoid_: Guaranteed compliant color

**Accessible variant request**:
A request for up to a specified number of perceptually distinct adjusted colors. A nonpositive count requests no suggestions; a positive request may return fewer when no additional distinct suggestions are available.
_Avoid_: Required variant count

**Accessibility result**:
The assessment of one foreground candidate against one explicit background and requested WCAG contrast level. It distinguishes a measured pass, a measurable best-effort result below the target, and an unavailable measurement.

**Best-effort accessibility result**:
A color candidate with a measurable contrast ratio below the requested level. It records a shortfall rather than claiming success or conversion failure.

**Unavailable accessibility result**:
An assessment for which ColorKit cannot establish a contrast ratio from the supplied inputs. This includes unresolved colors, out-of-gamut snapshots, and translucent backgrounds without a supplied backing color.

**LAB**:
CIE L*a*b* coordinates relative to a reference white: L* describes lightness, a* the green–red axis, and b* the blue–yellow axis. ColorKit uses D65 as the reference white.
_Avoid_: RGB brightness when referring to L*.

**XYZ**:
CIE XYZ tristimulus coordinates. ColorKit's public XYZ values use a relative scale on which the reference white has Y = 100; this is not an upper bound on every coordinate.
_Avoid_: XYZ percentages, XYZ in the range 0–1 without specifying a different scale.

**Normalized XYZ**:
CIE XYZ coordinates on a relative scale where the reference white has Y = 1. Multiplying each coordinate by 100 expresses the same color on ColorKit's public XYZ scale.
_Avoid_: XYZ percentages.

**D65 reference white**:
The reference white used for ColorKit's LAB coordinates, with XYZ values (95.047, 100, 108.883) on the Y = 100 scale.
_Avoid_: White RGB color when referring to the reference white itself.

**Theme registry**:
The collection of themes available for selection, with each registered name appearing at most once. Registration alone does not select a theme.

**Registered theme**:
The canonical theme value associated with a unique name in the theme registry. A same-name theme supplied for selection identifies this value and does not replace it.

**Current theme**:
The theme selected by the theme manager. A view subtree may use a different theme through a local override.

**Theme override**:
A theme applied to a view subtree in place of an inherited theme. It does not change the manager's current theme.

**Palette share payload**:
A snapshot of a palette in the export format selected for one sharing session. A later sharing session has its own snapshot, even when the palette and format are unchanged.

**Palette export snapshot**:
The palette or theme entries, export name, and format selected for one export action. Later generation or format changes do not change that selection.

**Palette export artifact**:
The prepared output of one palette export snapshot, ready to share or save in the selected format.

**Animation monitoring session**:
One continuous visit to the animation preview, with fresh performance metrics for each visit. Pausing animation or hiding metrics does not begin or end the session.
