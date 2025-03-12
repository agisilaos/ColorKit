# WCAG Compliance Checker

The WCAG (Web Content Accessibility Guidelines) Compliance Checker is a powerful tool in ColorKit that helps developers ensure their SwiftUI applications meet accessibility standards for color contrast.

## Features

- **Real-time Contrast Ratio Calculation**: Calculate the contrast ratio between text and background colors according to WCAG 2.1 standards.
- **Compliance Level Checking**: Check if your color combinations meet WCAG AA and AAA compliance levels for both normal and large text.
- **Live Previews**: See how your text looks with different color combinations in real-time.
- **Color Blindness Simulation**: Preview how your content appears to users with different types of color blindness.
- **Suggestions**: Get suggestions for colors that would meet WCAG compliance levels.

## Usage

### Basic Usage

```swift
import SwiftUI
import ColorKit

struct MyView: View {
    let textColor = Color.blue
    let backgroundColor = Color.white
    
    var body: some View {
        Text("Hello, World!")
            .wcagCompliance(foreground: textColor, background: backgroundColor)
    }
}
```

### Color Blindness Simulation

```swift
import SwiftUI
import ColorKit

struct MyView: View {
    var body: some View {
        Text("Hello, World!")
            .colorBlindnessPreview(type: .protanopia)
    }
}
```

### Checking Compliance Programmatically

```swift
import SwiftUI
import ColorKit

struct MyView: View {
    let textColor = Color.blue
    let backgroundColor = Color.white
    
    var body: some View {
        let compliance = textColor.wcagCompliance(with: backgroundColor)
        
        VStack {
            Text("Contrast Ratio: \(String(format: "%.2f", compliance.contrastRatio)):1")
            
            if compliance.passesAA {
                Text("Passes WCAG AA")
            }
            
            if compliance.passesAAA {
                Text("Passes WCAG AAA")
            }
        }
    }
}
```

### Demo View

ColorKit includes a comprehensive demo view that showcases all the WCAG compliance features:

```swift
import SwiftUI
import ColorKit

struct ContentView: View {
    @State private var showWCAGDemo = false
    
    var body: some View {
        Button("Open WCAG Compliance Checker") {
            showWCAGDemo = true
        }
        .sheet(isPresented: $showWCAGDemo) {
            ColorKit.WCAG.demoView()
        }
    }
}
```

## WCAG Compliance Levels

The WCAG defines several levels of compliance for contrast ratios:

- **AA Large**: Requires a contrast ratio of at least 3:1 for large text (18pt or 14pt bold).
- **AA**: Requires a contrast ratio of at least 4.5:1 for normal text.
- **AAA Large**: Requires a contrast ratio of at least 4.5:1 for large text.
- **AAA**: Requires a contrast ratio of at least 7:1 for normal text.

## Color Blindness Types

The color blindness simulation supports the following types:

- **Protanopia**: Red-blindness
- **Deuteranopia**: Green-blindness
- **Tritanopia**: Blue-blindness
- **Achromatopsia**: Complete color blindness (grayscale vision)

## References

- [WCAG 2.1 Contrast Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [Color Blindness Simulation](https://www.color-blindness.com/types-of-color-blindness/) 