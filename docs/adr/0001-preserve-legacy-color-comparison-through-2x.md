---
status: accepted
---

# Preserve legacy color comparison through 2.x

ColorKit will make a new result-bearing color-comparison API authoritative and use it in its own UI and documentation. The existing `compare(with:)` API will remain as a deprecated source-compatibility adapter through the 2.x release line, including its documented legacy behavior for inputs that cannot produce an honest comparison, and will be removed in ColorKit 3.0; this isolates the accurate contract without introducing an unannounced breaking change. Every `ColorDifference` identifies whether its numeric value is CIEDE2000 or the legacy RGB distance, and public API comments and guides must describe that distinction rather than presenting the fallback as perceptual.
