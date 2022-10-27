// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NewIcon",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "NewIcon", targets: ["NewIcon"]),
        .executable(name: "new-icon", targets: ["NewIconCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.1.2"),
    ],
    targets: [
        .target(
            name: "NewIcon",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            resources: [
                .copy("PluginTemplate"),
            ]
        ),
        .executableTarget(
            name: "NewIconCLI",
            dependencies: [
                "NewIcon"
            ]
        ),
    ]
)
