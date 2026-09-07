// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ColorKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ColorKit",
            targets: ["ColorKit"]
        ),
    ],
    targets: [
        .target(
            name: "ColorKit",
            exclude: [
                "Utilities/DOCUMENTATION.md",
                "Utilities/README.md",
                "Utilities/PaletteExporter.md",
                "WCAG/README.md",
                "WCAG/AccessiblePaletteGenerator.md",
                "ColorInspector/README.md"
            ]
        ),
        .testTarget(
            name: "ColorKitTests",
            dependencies: ["ColorKit"]
        ),
    ]
)
