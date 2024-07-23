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
    dependencies: [
        // 添加一个依赖
        .package(url: "https://github.com/Alamofire/Alamofire", exact: "5.9.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftUtils",
            dependencies: ["Alamofire"]),
        .target(
            name: "CCWrapper",
            dependencies: [],
            path: "Sources/CCWrapper",
            publicHeadersPath: "."),
        .testTarget(
            name: "SwiftUtilsTests",
            dependencies: ["SwiftUtils"]),
    ])
