---
status: accepted
---

# Enforce distance budgets in enhancement results

ColorKit will enforce `maxPerceptualDistance` as an inclusive CIEDE2000 Delta E 00 hard budget in result-bearing enhancement APIs, while retaining the existing budget-ignoring behavior of legacy color-returning APIs. The budget takes precedence over WCAG success, with explicit best-effort, unavailable, and invalid-configuration outcomes and public measurement evidence; this makes the previously inert setting meaningful without changing legacy callers' color selection or hiding configuration errors through clamping. Result-bearing variants also use CIEDE2000 for distinctness, while legacy variants retain their CIE76 rule.

The detailed contract and validation cases are recorded in [Enhancement distance budget](../design/enhancement-distance-budget.md).
