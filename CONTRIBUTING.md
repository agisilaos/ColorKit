# Contributing to ColorKit

Thank you for your interest in contributing to ColorKit! This document outlines our coding standards and guidelines to help maintain consistency across the codebase.

## Code Style Guidelines

### General Principles

- Write clear, self-documenting code
- Follow Swift's official style guide
- Keep functions focused and single-purpose
- Use meaningful variable and function names
- Add comments for complex logic or non-obvious decisions
- Keep the code DRY (Don't Repeat Yourself)

### Naming Conventions

- Use PascalCase for types (structs, classes, enums, protocols)
- Use camelCase for properties, methods, and variables
- Use lowerCamelCase for constants, following Swift naming conventions
- Prefix boolean properties with verbs (is, has, should, etc.)
- Use descriptive names that indicate purpose rather than type

```swift
// Good
struct ColorPalette {
    let primaryColor: Color
    let secondaryColors: [Color]
    var isEnabled: Bool
}

// Avoid
struct Colors {
    let color: Color
    let colors: [Color]
    var enabled: Bool
}
```

### Code Organization

- Group related properties and methods together
- Use MARK comments to organize code sections
- Keep files focused and under 500 lines when possible
- Use extensions to organize protocol conformance
- Place private properties and methods at the bottom of the type

```swift
struct ColorKit {
    // MARK: - Public Properties
    
    // MARK: - Private Properties
    
    // MARK: - Initialization
    
    // MARK: - Public Methods
    
    // MARK: - Private Methods
}
```

### SwiftLint Rules

We use SwiftLint to enforce code style. Here are some key rules and their rationale:

#### Enabled Rules
- `force_unwrapping`: Avoid force unwrapping (`!`) - use optional binding or nil coalescing
- `force_cast`: Avoid force casting (`as!`) - use optional casting (`as?`)
- `trailing_whitespace`: Keep files clean of trailing whitespace
- `sorted_imports`: Keep imports organized alphabetically
- `vertical_whitespace_closing_braces`: Maintain consistent spacing

#### Disabled Rules
- `line_length`: We allow longer lines (up to 120 characters) for better readability
- `type_body_length`: Complex types may need more than 400 lines
- `function_body_length`: Some functions may need more than 100 lines
- `cyclomatic_complexity`: We trust developers to keep complexity reasonable

### Documentation

- Document public APIs using Swift-style documentation comments
- Include parameter descriptions and return value information
- Add examples for complex functionality
- Keep documentation up to date with code changes

```swift
/// Creates a new color with the specified RGB components.
///
/// - Parameters:
///   - red: The red component (0-255)
///   - green: The green component (0-255)
///   - blue: The blue component (0-255)
///
/// - Returns: A new Color instance
///
/// - Example:
///   ```
///   let red = Color(r: 255, g: 0, b: 0)
///   ```
func color(r: UInt8, g: UInt8, b: UInt8) -> Color
```

### Testing

- Write unit tests for new functionality
- Follow the Arrange-Act-Assert pattern in tests
- Use descriptive test names that explain the scenario
- Keep tests focused and independent
- Use appropriate test doubles (mocks, stubs) when needed

```swift
func testColorInitialization() {
    // Arrange
    let red: UInt8 = 255
    let green: UInt8 = 0
    let blue: UInt8 = 0
    
    // Act
    let color = Color(r: red, g: green, b: blue)
    
    // Assert
    XCTAssertEqual(color.red, red)
    XCTAssertEqual(color.green, green)
    XCTAssertEqual(color.blue, blue)
}
```

### CI Validation

CI runs strict SwiftLint checks, builds the DocC catalog with warnings treated as
errors, compiles selected public examples as a macOS client, and tests on both
iOS and macOS. The jobs use the `macos-26` runner with
Xcode 26.5 and an iPhone 17 simulator running iOS 26.5.
When changing Xcode versions, also check the simulator runtime against the
[runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md).

To run the same platform checks locally with Xcode 26.5 selected:

```sh
swiftlint lint --strict
xcodebuild docbuild -scheme ColorKit -destination 'generic/platform=macOS' \
  -derivedDataPath /tmp/ColorKitDocumentation \
  -skipPackagePluginValidation -skipMacroValidation \
  'OTHER_DOCC_FLAGS=--warnings-as-errors'
scripts/run_tests.sh
python3 -m unittest discover -s scripts/tests
python3 scripts/check_documentation.py
```

The zero-argument runner is the canonical CI matrix: parallel iOS and macOS tests,
then serialized shared-state suites on each platform. Change the shared-suite list
and pinned destinations in `scripts/run_tests.sh`, not in the workflow. Set
`COLORKIT_IOS_DESTINATION` or `COLORKIT_MACOS_DESTINATION` for another local device.
Build storage defaults to this checkout's `.build/xcode`; override it with
`COLORKIT_DERIVED_DATA` when needed.

CI caches only SwiftPM checkouts, repositories, and downloaded artifacts. Xcode
build products and test results stay outside that dependency cache. The cache key
has its own scope version so older whole-`.build` archives are not restored.

Each matrix invocation retains raw stdout/stderr logs and result bundles in a unique directory
under `.build/test-results`; use `--results-dir TestResults` to choose another parent.
For a targeted run, pass a platform label, destination, and Xcode options. Only
these explicit single-destination runs use `xcpretty` when available; add
`--log-file path` to retain raw output (its parent directory must exist).

After a release PR is merged, run `scripts/check_release.sh <version>` from `main`
before tagging. The check fetches `origin/main` and tags, then verifies the working
tree, release metadata, synchronized commit, and tag availability.

`ColorCacheIntegrationTests` clears `ColorCache.shared` before and after each test.
Run it separately without parallel testing; direct cache tests use independent instances.
`ThemeManagerIntegrationTests` also runs in this serial invocation. It preserves the
private singleton initializer, registers unique names, uses baseline-relative
registry assertions, and restores the previous selected value. There is no theme
reset or removal API, so registered fixtures remain until the test process exits.

The `test-results` workflow artifact retains raw build logs and `.xcresult`
bundles for 14 days, including logs from failed test commands. Check the
"Show Xcode and Available Simulators" step if a destination cannot be found.

### Keeping contracts and documentation synchronized

For every public API or behavior change, review these together in the same PR:

- Source/API comments and the relevant DocC article.
- English and Spanish README examples and contract prose (or explain why neither is affected).
- An Unreleased changelog entry and migration guidance for changed results, fallbacks,
  enum cases, or deprecations—not only source-breaking signature changes.
- Regression tests and representative public examples exercising the changed contract.

`python3 scripts/check_documentation.py` compiles the actual Swift fences marked
with `<!-- swift-example: example-id -->`, using public imports and the package's
macOS 12 deployment target. Add each marker to the explicit inventory in that script.
The READMEs share the same required example IDs; deleting or renaming a required
marker fails the check. Keep marked examples self-contained. The checker also
executes the actual HSL, CMYK, and LAB README snippets in both languages and verifies
their result variables against the expected contract. Keep those variables aligned
with `README_CHECKS`; add behavior checks when an example promises a specific result.
Named HSL colors are checked for availability and normalized finite components, not
appearance-specific numeric values. Fixed sRGB examples use numeric postconditions.
It also executes the real theme-code generator and compiles its output for named
defaults, translucent sRGB, grayscale, and Display P3 inputs. Generated files live
in a temporary directory and are not committed.

A successful DocC build validates documentation structure and links, not fenced
Swift. The compilation and behavior checks cover selected examples, not every snippet
or the truth of prose, visual behavior, or performance claims. Review translations
for semantic parity and use measured, reproducible evidence for performance claims. When parallel
branches touch the same contracts, reconcile their release and migration notes
after integrating upstream changes and rerun all gates against the combined result.

### Git Workflow

- Write clear, descriptive commit messages
- Keep commits focused and atomic
- Use feature branches for new work
- Update documentation when making API changes
- Follow the existing PR review process

### Getting Started

1. Fork the repository
2. Create a feature branch
3. Make your changes following these guidelines
4. Run SwiftLint locally to check for style issues
5. Write or update tests as needed
6. Submit a pull request

## Questions?

If you have any questions about these guidelines or need clarification, please open an issue or reach out to the maintainers.
