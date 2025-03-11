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
✅ **CMYK Color Support**  
✅ **LAB Color Support**  
✅ **Adaptive Colors (Light/Dark Mode)**  
✅ **WCAG Contrast Checking for Accessibility**  
✅ **SwiftUI Modifiers for Dynamic Colors**  

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

### **3️⃣ CMYK Conversion**  
```swift
// Convert from RGB to CMYK
let cmyk = Color.red.cmykComponents()
// (cyan: 0.0, magenta: 1.0, yellow: 1.0, key: 0.0)

// Create color from CMYK values
let printColor = Color(cyan: 0.2, magenta: 0.8, yellow: 0.1, key: 0.1)
```

### **4️⃣ LAB Conversion**  
```swift
// Convert from RGB to LAB
let lab = Color.red.labComponents()
// (L: 53.24, a: 80.09, b: 67.20)

// Create color from LAB values
let labColor = Color(L: 50.0, a: 25.0, b: -30.0)
```

### **5️⃣ Adaptive Colors (Light/Dark Mode)**  
```swift
Text("Adaptive Text")
    .adaptiveColor(light: .blue, dark: .orange)
```

### **6️⃣ Ensuring High Contrast**  
```swift
Text("Accessible Text")
    .highContrastColor(base: .gray, background: .white)
```

### **7️⃣ Detecting Theme Changes**  
```swift
Text("Theme Change")
    .onAdaptiveColorChange { newScheme in
        print("Color scheme changed to: \(newScheme)")
    }
```

---

## **🛠 Contributing**  
We welcome contributions! Feel free to submit issues or open pull requests.  

## **📜 License**  
MIT License. See `LICENSE` for details.  

---
