# Contrast pair report

Standalone macOS example using public ColorKit APIs. Requires macOS 14+ and
Swift 6.2+. From the repository root:

```sh
swift run --package-path Examples/ContrastPairReport ContrastPairReport
# Control-C stops the process. Run the separate empty case with:
swift run --package-path Examples/ContrastPairReport ContrastPairReport --empty
swift test --package-path Examples/ContrastPairReport
```

Edit `Samples` in `Sources/ContrastPairReport/ContrastPairReportApp.swift` to supply
ordered foreground/background pairs with labels and explicit WCAG targets.
Samples cover passes, a shortfall, duplicate labels and identical pairs,
a translucent background, and independently unresolved inputs.

Callers own appearance capture. Supply fixed colors for the intended appearance;
`.primary` deliberately demonstrates unavailability. The report neither captures
ambient appearance nor evaluates both appearances. Classification uses unrounded
ratios; display uses two decimals and the current locale. Unavailable rows report
both input issue lists without inventing a ratio. This is not a whole-app
accessibility compliance assessment.

Validated on Apple Silicon macOS 26.6.2 with Swift 6.3.2: executable build,
six tests (including rounding boundaries for all four targets), strict lint,
and manual inspection of populated/empty windows and scrolling. No iOS host,
Intel build, minimum-OS runtime, or full VoiceOver interaction was tested.
All code stays outside the library target; no additional public API is needed.
