// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ComponentConsumer",
    platforms: [.macOS(.v12)],
    dependencies: [.package(name: "ColorKit", path: "../..")],
    targets: [.executableTarget(
        name: "ComponentConsumer",
        dependencies: [.product(name: "ColorKit", package: "ColorKit")]
    )]
)
