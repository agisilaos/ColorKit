# ColorKit

ColorKit describes, compares, blends, and interpolates colors across color spaces.

## Language

**Color identity**:
The original color space and complete component values, including opacity, that distinguish a color input. Equal component values in different color spaces do not establish the same color identity.
_Avoid_: Visual equivalence

**Identifiable color**:
A fixed color whose original color space is an explicitly recognized RGB or grayscale space and whose complete, finite component values are available. Unresolved or dynamic colors, patterns, and colors in custom or unknown spaces fall outside this category.

**Interpolation amount**:
The position between an ordered pair of colors, with zero representing the starting color and one representing the destination. Nearby amounts such as 0.5001 and 0.5004 are distinct positions.
_Avoid_: Rounded amount
