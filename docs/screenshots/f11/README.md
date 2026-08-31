# F11 export actions validation

Validated with Xcode 26.5, macOS, and an iPhone 17 simulator running iOS 26.5.
The screenshots show `PaletteExportView` in a temporary host, not the separate
accessible-palette demo. No host or fault-injection code is included in the library.

## Screenshots

- [iOS: Copy and Share](ios-actions.png)
- [macOS: Copy and Export](macos-actions.png)
- [macOS: file-write error](macos-save-error.png)

## Runtime checks

- macOS exposes Copy and Export, with no Share button. iOS exposes Copy and
  Share, with no Export button.
- macOS Copy produces JSON on the clipboard and shows its existing success alert.
- Cancel a JSON save, select CSS, and save again: cancellation is silent; the
  second panel uses the CSS extension and writes CSS data with a success alert.
- Attempt to overwrite a read-only SVG fixture in a writable temporary folder:
  the existing file-write error alert appears and the fixture remains unchanged.
- On iOS, present JSON sharing and close it. Select CSS and share again, completing
  Save to Files. Inspect the saved bytes to confirm CSS, not the earlier JSON.
  After that activity completes, select SVG, share again, and confirm SVG bytes
  in the next saved file.
- In an isolated host copy of the view, substitute an exporter that returns nil
  for export preparation and false for copying. macOS preparation failure shows
  the existing error alert without opening Save; copy failure shows its existing
  alert. iOS preparation failure shows the existing error alert without a sheet;
  copying with the same failure returns the existing copy-error alert.
  This exercises UI failure handling without changing the serializers.
- In the isolated iOS host, observe the optional payload when presenting JSON
  and after closing the sheet: it contains prepared JSON during presentation and
  returns to nil on dismissal. The production payload stores immutable data and
  creates a UUID for each successful preparation.

## Automated checks

Strict SwiftLint passed with zero violations. The documented platform commands
passed all 153 tests per platform: 140 in the parallel suite and 13 shared-state
tests in the separate serial run. The existing six exporter tests also passed
in focused runs on both platforms. No new automated UI test target was added.

```sh
swiftlint lint --strict
scripts/run_tests.sh macOS 'platform=macOS' \
  -skip-testing:ColorKitTests/ColorCacheIntegrationTests \
  -skip-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
scripts/run_tests.sh iOS 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -skip-testing:ColorKitTests/ColorCacheIntegrationTests \
  -skip-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
scripts/run_tests.sh macOS 'platform=macOS' \
  -parallel-testing-enabled NO \
  -only-testing:ColorKitTests/ColorCacheIntegrationTests \
  -only-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
scripts/run_tests.sh iOS 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -parallel-testing-enabled NO \
  -only-testing:ColorKitTests/ColorCacheIntegrationTests \
  -only-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
```

## Existing serializer limitation

An exploratory non-finite-alpha JSON fixture raises `NSInvalidArgumentException`
in `JSONSerialization`, rather than returning nil. That is outside F11's UI scope;
serializers remain unchanged. Failure-alert checks above use explicit nil/false
results instead of treating that exception as an ordinary export failure.
