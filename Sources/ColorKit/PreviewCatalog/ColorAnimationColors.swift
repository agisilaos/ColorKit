import SwiftUI

struct ColorAnimationColors {
    var start: Color = .blue
    var end: Color = .red
    var current: Color = .blue

    mutating func selectStart(_ color: Color, isAnimating: Bool) {
        start = color
        if !isAnimating { current = color }
    }
}
