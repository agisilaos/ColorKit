# Correct WCAG relative luminance in place

`relativeLuminance()` will linearize sRGB components before weighting them, changing the values it and every API built on it return, rather than preserving the previous numbers behind a deprecated adapter. The previous calculation weighted gamma-encoded components and was documented as WCAG 2.1, so callers already relied on it to mean WCAG contrast; keeping a compatibility path would preserve an understated ratio that silently fails accessibility decisions, and no caller can reasonably depend on a value that never matched the specification it named.
