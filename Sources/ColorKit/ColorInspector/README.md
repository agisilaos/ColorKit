# Color Inspector

The Color Inspector is a powerful tool for real-time color analysis in SwiftUI applications. It provides detailed information about colors, including HEX values, RGB components, HSL components, and WCAG contrast compliance.

## Features

- **Live Color Information**: See HEX, RGB, and HSL values in real-time
- **Contrast Analysis**: Check contrast ratios between foreground and background colors
- **WCAG Compliance**: View WCAG 2.1 compliance indicators for AA and AAA levels
- **Customizable Position**: Place the inspector in any corner of your view
- **Cross-Platform**: Works on iOS, macOS, and other Apple platforms

## Unavailable conversions

The inspector derives its presentation from the current inputs on every render,
including its first appearance and when contrast information is shown again.
It never retains values from an earlier color after a conversion fails.

An unavailable HEX conversion displays `#??????`. Unavailable RGB and HSL
conversions display `Unavailable`. If either color cannot supply the components
needed for contrast, the inspector displays `Ratio: Unavailable` without
compliance badges. A background conversion failure does not hide valid foreground
color information. Setting `showContrastInfo` to `false` hides the entire contrast
section; showing it again uses the latest foreground and background colors.

## Usage

### Basic Usage

```swift
import SwiftUI
import ColorKit

struct ContentView: View {
    @State private var color = Color.blue
    
    var body: some View {
        VStack {
            // Your content here
        }
        .colorInspector(color: color)
    }
}
```

### Advanced Usage

```swift
import SwiftUI
import ColorKit

struct ContentView: View {
    @State private var foregroundColor = Color.blue
    @State private var backgroundColor = Color.white
    
    var body: some View {
        VStack {
            // Your content here
        }
        .colorInspector(
            color: foregroundColor,
            backgroundColor: backgroundColor,
            position: .topTrailing,
            showContrastInfo: true
        )
    }
}
```

### Using the Demo View

```swift
import SwiftUI
import ColorKit

struct ContentView: View {
    var body: some View {
        ColorKit.ColorInspector.demoView()
    }
}
```

## API Reference

### ColorInspectorView

A view that displays detailed information about a color in real-time.

```swift
ColorInspectorView(
    color: Color,
    backgroundColor: Color = .white,
    showContrastInfo: Bool = true
)
```

### colorInspector() View Modifier

A modifier that adds a color inspector to any view.

```swift
view.colorInspector(
    color: Color,
    backgroundColor: Color = .white,
    position: ColorInspectorModifier.Position = .bottomTrailing,
    showContrastInfo: Bool = true
)
```

### Position Options

- `.topLeading`: Top left corner
- `.topTrailing`: Top right corner
- `.bottomLeading`: Bottom left corner
- `.bottomTrailing`: Bottom right corner

## Example

```swift
import SwiftUI
import ColorKit

struct ColorInspectorExample: View {
    @State private var color = Color.blue
    @State private var backgroundColor = Color.white
    
    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Color Inspector Example")
                    .font(.largeTitle)
                    .foregroundColor(color)
                
                ColorPicker("Select a color", selection: $color)
                ColorPicker("Select a background", selection: $backgroundColor)
            }
            .padding()
        }
        .colorInspector(
            color: color,
            backgroundColor: backgroundColor
        )
    }
}
```
