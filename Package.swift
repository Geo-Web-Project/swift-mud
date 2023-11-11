// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMUD",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftMUD",
            targets: ["SwiftMUD"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Boilertalk/Web3.swift", .upToNextMajor(from: "0.8.4")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftMUD",
            dependencies: [
                .product(name: "Web3", package: "Web3.swift"),
                .product(name: "Web3ContractABI", package: "Web3.swift")
            ]),
        .testTarget(
            name: "SwiftMUDTests",
            dependencies: ["SwiftMUD"]),
    ]
)
