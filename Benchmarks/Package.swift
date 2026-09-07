// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ColorKitBenchmarks",
    platforms: [.macOS(.v12)],
    dependencies: [.package(path: "..")],
    targets: [
        .executableTarget(name: "ColorKitBenchmarks", dependencies: [.product(name: "ColorKit", package: "ColorKit")]),
        .testTarget(name: "ColorKitBenchmarksTests", dependencies: ["ColorKitBenchmarks"])
    ]
)
