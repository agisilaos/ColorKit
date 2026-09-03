import Foundation

struct LABColor: Sendable {
    let lightness: Double
    let a: Double
    let b: Double
}

/// Calculates CIEDE2000 color difference with `kL`, `kC`, and `kH` set to one.
///
/// This implementation follows Sharma, Wu, and Dalal's implementation notes:
/// https://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf
/// and is validated against their 34 published supplementary color pairs:
/// https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt
enum CIEDE2000 {
    private static let chromaThreshold = pow(25.0, 7.0)

    static func difference(between first: LABColor, and second: LABColor) -> Double {
        let firstChroma = hypot(first.a, first.b)
        let secondChroma = hypot(second.a, second.b)
        let meanChroma = (firstChroma + secondChroma) / 2
        let meanChromaPower = pow(meanChroma, 7)
        let compensation = 0.5 * (1 - sqrt(meanChromaPower / (meanChromaPower + chromaThreshold)))

        let adjustedFirstA = (1 + compensation) * first.a
        let adjustedSecondA = (1 + compensation) * second.a
        let adjustedFirstChroma = hypot(adjustedFirstA, first.b)
        let adjustedSecondChroma = hypot(adjustedSecondA, second.b)
        let firstHue = hueDegrees(a: adjustedFirstA, b: first.b)
        let secondHue = hueDegrees(a: adjustedSecondA, b: second.b)

        let lightnessDifference = second.lightness - first.lightness
        let chromaDifference = adjustedSecondChroma - adjustedFirstChroma
        let hueAngleDifference = adjustedHueAngleDifference(
            firstHue: firstHue,
            secondHue: secondHue,
            firstChroma: adjustedFirstChroma,
            secondChroma: adjustedSecondChroma
        )
        let hueDifference = 2
            * sqrt(adjustedFirstChroma * adjustedSecondChroma)
            * sin(degreesToRadians(hueAngleDifference / 2))

        let meanLightness = (first.lightness + second.lightness) / 2
        let meanAdjustedChroma = (adjustedFirstChroma + adjustedSecondChroma) / 2
        let meanHue = adjustedMeanHue(
            firstHue: firstHue,
            secondHue: secondHue,
            firstChroma: adjustedFirstChroma,
            secondChroma: adjustedSecondChroma
        )

        let hueWeight = 1
            - 0.17 * cos(degreesToRadians(meanHue - 30))
            + 0.24 * cos(degreesToRadians(2 * meanHue))
            + 0.32 * cos(degreesToRadians(3 * meanHue + 6))
            - 0.20 * cos(degreesToRadians(4 * meanHue - 63))
        let rotationAngle = 30 * exp(-pow((meanHue - 275) / 25, 2))
        let meanAdjustedChromaPower = pow(meanAdjustedChroma, 7)
        let rotationMagnitude = 2 * sqrt(
            meanAdjustedChromaPower / (meanAdjustedChromaPower + chromaThreshold)
        )
        let lightnessOffset = meanLightness - 50
        let lightnessWeight = 1 + (0.015 * pow(lightnessOffset, 2))
            / sqrt(20 + pow(lightnessOffset, 2))
        let chromaWeight = 1 + 0.045 * meanAdjustedChroma
        let adjustedHueWeight = 1 + 0.015 * meanAdjustedChroma * hueWeight
        let rotation = -sin(degreesToRadians(2 * rotationAngle)) * rotationMagnitude

        let lightnessTerm = lightnessDifference / lightnessWeight
        let chromaTerm = chromaDifference / chromaWeight
        let hueTerm = hueDifference / adjustedHueWeight

        return sqrt(
            pow(lightnessTerm, 2)
                + pow(chromaTerm, 2)
                + pow(hueTerm, 2)
                + rotation * chromaTerm * hueTerm
        )
    }

    private static func hueDegrees(a: Double, b: Double) -> Double {
        guard a != 0 || b != 0 else { return 0 }
        let degrees = radiansToDegrees(atan2(b, a))
        return degrees >= 0 ? degrees : degrees + 360
    }

    private static func adjustedHueAngleDifference(
        firstHue: Double,
        secondHue: Double,
        firstChroma: Double,
        secondChroma: Double
    ) -> Double {
        guard firstChroma * secondChroma != 0 else { return 0 }

        let difference = secondHue - firstHue
        if abs(difference) <= 180 {
            return difference
        } else if difference > 180 {
            return difference - 360
        } else {
            return difference + 360
        }
    }

    private static func adjustedMeanHue(
        firstHue: Double,
        secondHue: Double,
        firstChroma: Double,
        secondChroma: Double
    ) -> Double {
        guard firstChroma * secondChroma != 0 else { return firstHue + secondHue }

        let sum = firstHue + secondHue
        if abs(firstHue - secondHue) <= 180 {
            return sum / 2
        } else if sum < 360 {
            return (sum + 360) / 2
        } else {
            return (sum - 360) / 2
        }
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
}
