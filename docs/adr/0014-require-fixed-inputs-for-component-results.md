---
status: accepted
---

# Require fixed inputs for component-conversion results

ColorKit 3.1's new result-bearing component-conversion entry point requires fixed
color components and does not consult ambient appearance; callers must explicitly
resolve named or dynamic colors that lack fixed components, including `.blue` when
applicable. This makes the input context explicit without introducing a ColorKit
appearance framework, at the cost of caller-side resolution for these colors.
Existing appearance-based APIs retain their shipped behavior.
