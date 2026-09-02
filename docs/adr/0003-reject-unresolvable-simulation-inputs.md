# Reject unresolvable simulation inputs

Fixed-color simulation will return no result unless the input resolves to finite, in-gamut sRGB. Valid input is decoded to linear light, transformed by the selected Machado matrix, clipped to the sRGB gamut, encoded back to nonlinear sRGB, and returned with its original alpha; this strict boundary keeps fixtures deterministic and avoids presenting guesses for dynamic, semantic, pattern, unsupported, or out-of-gamut colors.
