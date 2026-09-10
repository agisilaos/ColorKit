// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ContrastPairReport",
    platforms: [.macOS(.v14)],
    dependencies: [.package(name: "ColorKit", path: "../..")],
    targets: [
        .executableTarget(
            name: "ContrastPairReport",
            dependencies: [.product(name: "ColorKit", package: "ColorKit")]
        ),
        .testTarget(name: "ContrastPairReportTests", dependencies: ["ContrastPairReport"])
    ]
)
