import ColorKit
import Testing

struct PublicGradientOptionsTests {
    @Test
    func colorSpacesFollowDocumentedOrder() {
        #expect(GradientColorSpace.allCases == [.rgb, .hsl, .lab])
    }

    @Test
    func directionsFollowDocumentedOrder() {
        #expect(GradientDirection.allCases == [
            .topLeadingToBottomTrailing,
            .topTrailingToBottomLeading,
            .bottomLeadingToTopTrailing,
            .bottomTrailingToTopLeading,
            .topToBottom,
            .bottomToTop,
            .leadingToTrailing,
            .trailingToLeading
        ])
    }
}
