// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenAI",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v8)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "OpenAI",
            targets: ["OpenAI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rchatham/LangTools.swift.git", branch: "main"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "OpenAI",
            dependencies: [.product(name: "LangTools", package: "LangTools.swift")]),
        .testTarget(
            name: "OpenAITests",
            dependencies: ["OpenAI", "SwiftyJSON"],
            resources: [
                .process("Resources/"),
            ])
    ]
)
