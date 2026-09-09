import ColorKit
import SwiftUI
import Testing

/// Independent caller checks: deliberately no access to internal construction or resolver helpers.
struct PublicComponentConversionTests {
    @Test(arguments: [0.0, 0.5, 1.0])
    func transparentGreenRetainsCoordinates(alpha: Double) throws {
        let result = Color(.sRGB, red: 0, green: 1, blue: 0, opacity: alpha).componentConversionResults()
        let rgb = try result.srgba.get()
        #expect(rgb.red == 0 && rgb.green == 1 && rgb.blue == 0 && rgb.alpha == alpha)
        let hsl = try result.hsl.get()
        #expect(hsl.hue == 1.0 / 3 && hsl.saturation == 1 && hsl.lightness == 0.5)
        let hsb = try result.hsb.get()
        #expect(hsb.hue == hsl.hue && hsb.saturation == 1 && hsb.brightness == 1)
        let cmyk = try result.cmyk.get()
        #expect(cmyk.cyan == 1 && cmyk.magenta == 0 && cmyk.yellow == 1 && cmyk.key == 0)
        let xyz = try result.xyz.get()
        // Independently pinned green column of the agreed sRGB/D65 matrix, Y = 100 scale.
        #expect(abs(xyz.x - 35.75761) < 1e-9)
        #expect(abs(xyz.y - 71.51522) < 1e-9)
        #expect(abs(xyz.z - 11.91920) < 1e-9)
        let lab = try result.lab.get()
        #expect(abs(lab.lightness - 87.7347223528) < 1e-9)
        #expect(abs(lab.a + 86.1827164205) < 1e-9)
        #expect(abs(lab.b - 83.1793205027) < 1e-9)
        #expect(try result.hex.get() == "#00FF00" + (alpha == 0 ? "00" : alpha == 0.5 ? "80" : "FF"))
    }

    @Test
    func partialAvailabilityAndRetainedSnapshot() throws {
        let color = Color(.displayP3, red: 1, green: 0, blue: 0, opacity: 0.5)
        let result = color.componentConversionResults()
        let rgb = try result.srgba.get()
        #expect(rgb.red > 1 && rgb.green < 0 && rgb.alpha == 0.5)
        #expect(result.hsl == .failure(.outOfSRGBGamut))
        #expect(result.hsb == .failure(.outOfSRGBGamut))
        #expect(result.cmyk == .failure(.outOfSRGBGamut))
        #expect(result.hex == .failure(.outOfSRGBGamut))
        #expect(try result.xyz.get().x.isFinite)
        #expect(try result.lab.get().lightness.isFinite)
        // Reconstruct only the published snapshot; all representations must agree.
        let space = try #require(CGColorSpace(name: CGColorSpace.extendedSRGB))
        let cgColor = try #require(CGColor(colorSpace: space, components: [rgb.red, rgb.green, rgb.blue, rgb.alpha]))
        let replay = Color(cgColor).componentConversionResults()
        #expect(result.srgba == replay.srgba)
        #expect(result.xyz == replay.xyz)
        #expect(result.lab == replay.lab)
        #expect(result.hex == replay.hex)
    }

    @Test
    func completeUnavailabilityIsNotSuccessfulZero() throws {
        let result = Color.primary.componentConversionResults()
        #expect(result.srgba == .failure(.unresolvedInput))
        #expect(result.hsl == .failure(.unresolvedInput))
        #expect(result.hsb == .failure(.unresolvedInput))
        #expect(result.cmyk == .failure(.unresolvedInput))
        #expect(result.xyz == .failure(.unresolvedInput))
        #expect(result.lab == .failure(.unresolvedInput))
        #expect(result.hex == .failure(.unresolvedInput))
        let black = Color(.sRGB, red: 0, green: 0, blue: 0).componentConversionResults()
        #expect(try black.lab.get().lightness == 0)
        #expect(try black.hex.get() == "#000000FF")
    }
}
