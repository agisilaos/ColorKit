---
status: accepted
---

# Use correct extended conversion math in new results

The new component-conversion API uses signed extended-sRGB decoding and exact CIE
LAB constants, while preserving every legacy calculation and its existing call paths.
This supports correct negative-channel conversion without changing shipped behavior;
document that new XYZ/LAB results can differ from legacy values for negative channels
and near the old rounded LAB breakpoint.
