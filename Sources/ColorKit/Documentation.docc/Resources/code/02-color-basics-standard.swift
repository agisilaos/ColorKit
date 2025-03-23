import SwiftUI
import ColorKit

struct ContentView: View {
    // Standard SwiftUI colors
    let redColor = Color.red
    let blueColor = Color.blue
    let greenColor = Color.green
    
    // Custom RGB colors
    let customRGB = Color(red: 0.7, green: 0.2, blue: 0.9)
    let customRGBwithOpacity = Color(red: 0.7, green: 0.2, blue: 0.9, opacity: 0.5)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Standard Colors")
                .font(.headline)
            
            HStack(spacing: 20) {
                ColorSwatch(color: redColor, name: "Red")
                ColorSwatch(color: blueColor, name: "Blue")
                ColorSwatch(color: greenColor, name: "Green")
            }
            
            Text("Custom RGB Colors")
                .font(.headline)
            
            HStack(spacing: 20) {
                ColorSwatch(color: customRGB, name: "RGB")
                ColorSwatch(color: customRGBwithOpacity, name: "RGB+Alpha")
            }
        }
        .padding()
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(color)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            Text(name)
                .font(.caption)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 