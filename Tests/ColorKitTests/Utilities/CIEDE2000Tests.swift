import Testing

@testable import ColorKit

struct CIEDE2000Tests {
    /// Sharma, Wu, and Dalal's implementation notes and supplementary data:
    /// https://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf
    /// https://hajim.rochester.edu/ece/sites/gsharma/ciede2000/dataNprograms/ciede2000testdata.txt
    @Test(
        "Matches the published CIEDE2000 reference pairs",
        arguments: kReferencePairs
    )
    func matchesPublishedReferencePair(pair: CIEDE2000ReferencePair) {
        let difference = CIEDE2000.difference(between: pair.first, and: pair.second)

        #expect(
            abs(difference - pair.expectedDifference) <= 0.0001,
            "Expected \(pair.expectedDifference), got \(difference)"
        )
    }

    @Test(
        "Produces the same difference when inputs are reversed",
        arguments: kReferencePairs
    )
    func isSymmetric(pair: CIEDE2000ReferencePair) {
        let forward = CIEDE2000.difference(between: pair.first, and: pair.second)
        let reverse = CIEDE2000.difference(between: pair.second, and: pair.first)

        #expect(abs(forward - reverse) <= 1e-12)
    }

    @Test(
        "Produces zero for identical LAB colors",
        arguments: [
            LABColor(lightness: 0, a: 0, b: 0),
            LABColor(lightness: 50, a: 2.5, b: -80),
            LABColor(lightness: 100, a: 0, b: 0)
        ]
    )
    func identicalColorsHaveNoDifference(color: LABColor) {
        #expect(CIEDE2000.difference(between: color, and: color) == 0)
    }
}

struct CIEDE2000ReferencePair: Sendable, CustomTestStringConvertible {
    let first: LABColor
    let second: LABColor
    let expectedDifference: Double

    var testDescription: String {
        "\(first) to \(second) = \(expectedDifference)"
    }

    init(
        _ first: (Double, Double, Double),
        _ second: (Double, Double, Double),
        _ expectedDifference: Double
    ) {
        self.first = LABColor(lightness: first.0, a: first.1, b: first.2)
        self.second = LABColor(lightness: second.0, a: second.1, b: second.2)
        self.expectedDifference = expectedDifference
    }
}

let kReferencePairs: [CIEDE2000ReferencePair] = [
    .init((50.0000, 2.6772, -79.7751), (50.0000, 0.0000, -82.7485), 2.0425),
    .init((50.0000, 3.1571, -77.2803), (50.0000, 0.0000, -82.7485), 2.8615),
    .init((50.0000, 2.8361, -74.0200), (50.0000, 0.0000, -82.7485), 3.4412),
    .init((50.0000, -1.3802, -84.2814), (50.0000, 0.0000, -82.7485), 1.0000),
    .init((50.0000, -1.1848, -84.8006), (50.0000, 0.0000, -82.7485), 1.0000),
    .init((50.0000, -0.9009, -85.5211), (50.0000, 0.0000, -82.7485), 1.0000),
    .init((50.0000, 0.0000, 0.0000), (50.0000, -1.0000, 2.0000), 2.3669),
    .init((50.0000, -1.0000, 2.0000), (50.0000, 0.0000, 0.0000), 2.3669),
    .init((50.0000, 2.4900, -0.0010), (50.0000, -2.4900, 0.0009), 7.1792),
    .init((50.0000, 2.4900, -0.0010), (50.0000, -2.4900, 0.0010), 7.1792),
    .init((50.0000, 2.4900, -0.0010), (50.0000, -2.4900, 0.0011), 7.2195),
    .init((50.0000, 2.4900, -0.0010), (50.0000, -2.4900, 0.0012), 7.2195),
    .init((50.0000, -0.0010, 2.4900), (50.0000, 0.0009, -2.4900), 4.8045),
    .init((50.0000, -0.0010, 2.4900), (50.0000, 0.0010, -2.4900), 4.8045),
    .init((50.0000, -0.0010, 2.4900), (50.0000, 0.0011, -2.4900), 4.7461),
    .init((50.0000, 2.5000, 0.0000), (50.0000, 0.0000, -2.5000), 4.3065),
    .init((50.0000, 2.5000, 0.0000), (73.0000, 25.0000, -18.0000), 27.1492),
    .init((50.0000, 2.5000, 0.0000), (61.0000, -5.0000, 29.0000), 22.8977),
    .init((50.0000, 2.5000, 0.0000), (56.0000, -27.0000, -3.0000), 31.9030),
    .init((50.0000, 2.5000, 0.0000), (58.0000, 24.0000, 15.0000), 19.4535),
    .init((50.0000, 2.5000, 0.0000), (50.0000, 3.1736, 0.5854), 1.0000),
    .init((50.0000, 2.5000, 0.0000), (50.0000, 3.2972, 0.0000), 1.0000),
    .init((50.0000, 2.5000, 0.0000), (50.0000, 1.8634, 0.5757), 1.0000),
    .init((50.0000, 2.5000, 0.0000), (50.0000, 3.2592, 0.3350), 1.0000),
    .init((60.2574, -34.0099, 36.2677), (60.4626, -34.1751, 39.4387), 1.2644),
    .init((63.0109, -31.0961, -5.8663), (62.8187, -29.7946, -4.0864), 1.2630),
    .init((61.2901, 3.7196, -5.3901), (61.4292, 2.2480, -4.9620), 1.8731),
    .init((35.0831, -44.1164, 3.7933), (35.0232, -40.0716, 1.5901), 1.8645),
    .init((22.7233, 20.0904, -46.6940), (23.0331, 14.9730, -42.5619), 2.0373),
    .init((36.4612, 47.8580, 18.3852), (36.2715, 50.5065, 21.2231), 1.4146),
    .init((90.8027, -2.0831, 1.4410), (91.1528, -1.6435, 0.0447), 1.4441),
    .init((90.9257, -0.5406, -0.9208), (88.6381, -0.8985, -0.7239), 1.5381),
    .init((6.7747, -0.2908, -2.4247), (5.8714, -0.0985, -2.2286), 0.6377),
    .init((2.0776, 0.0795, -1.1350), (0.9033, -0.0636, -0.5514), 0.9082)
]
