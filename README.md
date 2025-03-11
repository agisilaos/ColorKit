# **ColorKit 🎨**  
![Swift Package Manager](https://img.shields.io/badge/SPM-Supported-green)  
![Swift Version](https://img.shields.io/badge/Swift-5.5%2B-blue)  

A lightweight **Swift package** for **color manipulation, adaptive themes, and accessibility compliance** in SwiftUI.  

---

## **📦 Installation**  

ColorKit supports **Swift Package Manager (SPM)**.  

1. Open your Xcode project.  
2. Go to **File > Add Packages**.  
3. Enter the URL:  
   ```
   https://github.com/agisilaos/ColorKit.git
   ```
4. Click **Add Package**.  

---

## **🚀 Features**  

✅ **HEX <-> RGB Conversion**  
✅ **HSL Color Support**  
✅ **Adaptive Colors (Light/Dark Mode)**  
✅ **WCAG Contrast Checking for Accessibility**  
✅ **SwiftUI Modifiers for Dynamic Colors**  
✅ **Gradient Generation Utilities**  
✅ **Color Blending Modes (Overlay, Multiply, Screen, etc.)**  

---

## **🎨 Usage**  

### **1️⃣ HEX <-> RGB Conversion**  
```swift
let color = Color(hex: "#FF5733")
print(color.hexValue()) // "#FF5733FF"
```

### **2️⃣ HSL Conversion**  
```swift
let hsl = Color.red.hslComponents()
let customColor = Color(hue: 0.5, saturation: 1.0, lightness: 0.5)
```

### **3️⃣ Adaptive Colors (Light/Dark Mode)**  
```swift
Text("Adaptive Text")
    .adaptiveColor(light: .blue, dark: .orange)
```

### **4️⃣ Ensuring High Contrast**  
```swift
Text("Accessible Text")
    .highContrastColor(base: .gray, background: .white)
```

### **5️⃣ Detecting Theme Changes**  
```swift
Text("Theme Change")
    .onAdaptiveColorChange { newScheme in
        print("Color scheme changed to: \(newScheme)")
    }
```

### **6️⃣ Gradient Generation Utilities**  
```swift
let gradient = Gradient(colors: [.red, .blue])
let linearGradient = LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
```

### **7️⃣ Color Blending Modes**  
```swift
let baseColor = Color.red
let blendColor = Color.blue
let blendedColor = baseColor.blended(with: blendColor, mode: .overlay)
```

---

## **🛠 Contributing**  
We welcome contributions! Feel free to submit issues or open pull requests.  

## **📜 License**  
MIT License. See `LICENSE` for details.  

---
