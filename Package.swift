// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUtils",

    platforms: [
        .macOS(.v10_15), .iOS(.v17),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftUtils",
            targets: ["SwiftUtils"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftUtils"),
        .target(
            name: "CCWrapper",
            dependencies: [],
            path: "Sources/CCWrapper",
            publicHeadersPath: "."),
        .testTarget(
            name: "SwiftUtilsTests",
            dependencies: ["SwiftUtils"]),
    ])
