# Contributing to ColorKit

Thank you for your interest in contributing to ColorKit! This document provides guidelines and instructions for contributing to this project.

## Development Prerequisites

- Xcode 14.0 or later
- Swift 6.0 or later
- iOS 14.0 or later (for iOS development)
- macOS 11.0 or later (for macOS development)

## Platform Compatibility Requirements

ColorKit supports:
- iOS 14.0 and later
- macOS 11.0 and later

### API Availability Guidelines

1. **Package.swift Requirements**
   - Minimum deployment targets are set in Package.swift
   - All code must be compatible with these minimum versions

2. **API Availability**
   - Always check API availability when using platform-specific features
   - Use `@available` annotations when required
   - Example:
     ```swift
     if #available(macOS 11.0, *) {
         // Use macOS 11.0+ APIs here
     }
     ```

3. **SF Symbols Usage**
   - Always wrap SF Symbols usage in availability checks
   - Example:
     ```swift
     if #available(macOS 11.0, iOS 14.0, *) {
         Image(systemName: "star.fill")
     }
     ```

## Version Management

We follow [Semantic Versioning](https://semver.org/):

- MAJOR version (x.0.0) - Incompatible API changes
- MINOR version (0.x.0) - Added functionality in a backward-compatible manner
- PATCH version (0.0.x) - Backward-compatible bug fixes

### Version Update Process

1. Update version number in:
   - `ColorKit.swift` (`version` property)
   - Documentation references

2. Update CHANGELOG.md:
   - Add new version section at the top
   - Document all changes under appropriate categories
   - Include date of release

## Pull Request Process

1. Create a new branch:
   - Features: `feature/description`
   - Fixes: `fix/description`
   - Documentation: `docs/description`

2. Follow the PR template checklist

3. Ensure all tests pass on supported platforms

4. Update documentation as needed

## Code Style Guidelines

1. **SwiftUI Views**
   - Use proper view modifiers
   - Follow SwiftUI best practices
   - Document custom view modifiers

2. **Documentation**
   - Use Swift-style documentation comments
   - Include parameter descriptions
   - Provide usage examples for public APIs

3. **Testing**
   - Write unit tests for new features
   - Include UI tests for view components
   - Test edge cases and error conditions

## Commit Message Format

Format: `type: subject`

Types:
- feat: New feature
- fix: Bug fix
- docs: Documentation changes
- style: Formatting, missing semicolons, etc
- refactor: Code restructuring
- perf: Performance improvements
- test: Adding tests
- chore: Maintenance tasks

Example:
```
fix: add availability check for SF Symbols on macOS
```

## Questions or Problems?

Feel free to open an issue for:
- Bug reports
- Feature requests
- Documentation improvements
- General questions

## License

By contributing to ColorKit, you agree that your contributions will be licensed under its MIT License. 