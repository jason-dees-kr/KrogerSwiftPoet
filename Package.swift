// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KrogerSwiftPoet",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "KrogerSwiftPoet",
            targets: ["KrogerSwiftPoet"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "KrogerSwiftPoet",
            dependencies: []),
        .testTarget(
            name: "KrogerSwiftPoetTests",
            dependencies: ["KrogerSwiftPoet"],
            resources: [.process("test_resources")]),
    ]
)
