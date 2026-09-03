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
errors, and tests on both iOS and macOS. The jobs use the `macos-26` runner with
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
scripts/run_tests.sh iOS 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -skip-testing:ColorKitTests/ColorCacheIntegrationTests \
  -skip-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
scripts/run_tests.sh macOS 'platform=macOS' \
  -skip-testing:ColorKitTests/ColorCacheIntegrationTests \
  -skip-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
scripts/run_tests.sh iOS 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -parallel-testing-enabled NO \
  -only-testing:ColorKitTests/ColorCacheIntegrationTests \
  -only-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
scripts/run_tests.sh macOS 'platform=macOS' \
  -parallel-testing-enabled NO \
  -only-testing:ColorKitTests/ColorCacheIntegrationTests \
  -only-testing:ColorKitTests/ThemeManagerIntegrationTests \
  -skipPackagePluginValidation -skipMacroValidation
```

`scripts/run_tests.sh` formats output with `xcpretty` when it is installed and
otherwise prints raw `xcodebuild` output. Pass `--log-file path` before the platform
to retain the raw log with `tee`; create the log's parent directory first.

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
