import SwiftUI
import ColorKit

struct ContentView: View {
    // Colors from HEX strings
    let redColor = Color(hex: "#FF0000") ?? .red
    let blueColor = Color(hex: "#0000FF") ?? .blue
    let greenColor = Color(hex: "#00FF00") ?? .green
    
    // HEX colors with alpha channel
    let purpleWithAlpha = Color(hex: "#800080AA") ?? .purple // Alpha = AA (66%)
    let orangeWithAlpha = Color(hex: "#FFA50080") ?? .orange // Alpha = 80 (50%)
    
    // HEX string representations
    let redHex = "#FF0000FF"
    let blueHex = "#0000FFFF"
    let greenHex = "#00FF00FF"
    let purpleHexNoAlpha = "#800080"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Colors from HEX")
                .font(.headline)
            
            HStack(spacing: 20) {
                ColorSwatch(color: redColor, name: "#FF0000")
                ColorSwatch(color: blueColor, name: "#0000FF")
                ColorSwatch(color: greenColor, name: "#00FF00")
            }
            
            Text("HEX with Alpha")
                .font(.headline)
            
            HStack(spacing: 20) {
                ColorSwatch(color: purpleWithAlpha, name: "#800080AA")
                ColorSwatch(color: orangeWithAlpha, name: "#FFA50080")
            }
            
            Text("HEX Value Examples")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Red: \(redHex)")
                Text("Blue: \(blueHex)")
                Text("Green: \(greenHex)")
                Text("Purple (no alpha): \(purpleHexNoAlpha)")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
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