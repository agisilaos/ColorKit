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
- Use UPPER_SNAKE_CASE for constants
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