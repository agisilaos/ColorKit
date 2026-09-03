# Classify dark colors at the equal-contrast luminance

`isDarkColor()` will compare relative luminance against the point where black and white contrast equally, approximately 0.1791, rather than the midpoint of the luminance range. The method exists to choose a contrasting endpoint, so the threshold that makes that choice correct is the one where the endpoints tie; the 0.5 midpoint has no contrast meaning under linear luminance and made the black-or-white fallback select the weaker endpoint for mid-tone backgrounds.
