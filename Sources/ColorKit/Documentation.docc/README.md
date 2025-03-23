# ColorKit Documentation

This directory contains the DocC documentation for ColorKit.

## Building the Documentation

### Using Xcode

1. Open the ColorKit package in Xcode.
2. Select Product > Build Documentation.
3. The documentation will be built and automatically opened in Xcode's documentation viewer.

### Using Scripts (Recommended)

We've included convenient scripts to build and serve the documentation:

```bash
# Build the documentation
./scripts/build_docc.sh

# Build and serve the documentation locally
./scripts/serve_docc.sh
```

### Using Command Line Manually

```bash
# Build documentation
xcodebuild docbuild \
  -scheme ColorKit \
  -derivedDataPath ./DerivedData \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'

# Locate the .doccarchive
open ./DerivedData/Build/Products/Debug-iphonesimulator/ColorKit.doccarchive
```

## Documentation Structure

The documentation is organized as follows:

```
Documentation.docc/
├── ColorKit.md                # Main landing page
├── GettingStarted.md          # Getting started guide
├── Articles/                  # In-depth articles
│   ├── color-spaces.md        # Color spaces guide
│   ├── accessibility.md       # Accessibility guide
│   └── theming.md             # Theming guide
├── Tutorials/                 # Step-by-step tutorials
│   ├── ColorBasics.tutorial   # Basic color operations tutorial
│   ├── AccessibilityGuide.tutorial  # Accessibility tutorial
│   └── ThemingSystem.tutorial # Theming system tutorial
└── Resources/                 # Supporting resources
    ├── code/                  # Code snippets for tutorials
    └── images/                # Images for documentation
```

## Adding New Content

### Adding a New Article

1. Create a new markdown file in the `Articles/` directory.
2. Add a reference to it in `ColorKit.md` under the appropriate section:
   ```markdown
   - <doc:your-article-name>
   ```

### Adding a New Tutorial

1. Create a new tutorial file in the `Tutorials/` directory with the `.tutorial` extension.
2. Follow the DocC tutorial format.
3. Add a reference to it in `ColorKit.md` under the Tutorials section:
   ```markdown
   - <doc:YourTutorialName>
   ```

## Code Snippet Format

Code snippets for tutorials should be placed in the `Resources/code/` directory with the filename referenced in the tutorial's `@Code` directive.

## Images

Place images in the `Resources/images/` directory and reference them using the `@Image` directive.

## Validating Documentation

The documentation is automatically validated by GitHub Actions when changes are pushed to the repository. You can also validate it locally by building it as described above. 