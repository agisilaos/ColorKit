# ColorKit macOS Release baseline

Times include input barriers, clock reads, dispatch, and result consumption. The control substitutes a precomputed result and is an overhead estimate; it is reported without subtraction. Cache preparation is outside timing.

| Scenario | Cache preparation | Median ns/request | Sample range | Median control ns/request |
| --- | --- | ---: | ---: | ---: |
| component-results-red | unused | 1,682.5 | 1,589.2–1,810.9 | 27.1 |
| hsl-red | empty | 3,441.1 | 3,196.2–3,763.3 | 15.4 |
| hsl-red | primed | 1,166.0 | 1,108.3–1,271.1 | 20.2 |
| lab-red | empty | 2,091.9 | 1,932.5–2,488.8 | 15.8 |
| lab-red | primed | 1,212.5 | 1,094.2–1,321.7 | 15.8 |
| comparison-black-white | unused | 667.7 | 582.5–754.2 | 25.8 |
| enhancement-compliant | unused | 1,024.4 | 934.2–1,168.8 | 24.0 |
| enhancement-adjusted | empty | 31,828.7 | 30,243.3–32,879.6 | 21.5 |
| enhancement-adjusted | primed | 24,991.1 | 23,282.9–27,046.3 | 29.9 |
| enhancement-best-effort | empty | 25,308.7 | 22,294.2–26,872.1 | 24.6 |
| enhancement-best-effort | primed | 19,641.9 | 18,664.6–20,805.7 | 30.0 |
| palette-red-five | empty | 68,759.4 | 63,308.8–74,265.0 | 18.1 |
| palette-red-five | primed | 60,556.7 | 54,805.4–65,955.9 | 26.5 |

Each sample is the mean of individually timed complete requests. The table's median and range describe those sample means across runs, not individual-request latency percentiles.

Read raw.json for every sample, fixture description, run identity, and environment. Large ranges or a control close to the request time limit useful comparisons. These are reference measurements, not speedup claims, CI thresholds, or iOS results.
