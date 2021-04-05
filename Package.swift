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
        .library(
            name: "SchemasParser",
            targets: ["SchemasParser"]),
    ],
    dependencies: [
        //.package(name: "JSONSchema", url: "https://github.com/kylef/JSONSchema.swift", .branch("master")),
        //.package(name: "JSONSchema", url: "https://github.com/kylef/JSONSchema.swift", .exact("0.5.0")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0"),
    ],
    targets: [
        .target(
            name: "KrogerSwiftPoet",
            dependencies: []),
        .testTarget(
            name: "KrogerSwiftPoetTests",
            dependencies: ["KrogerSwiftPoet"],
            resources: [.process("test_resources")]),
        .target(
            name: "SchemasParser",
            dependencies: ["KrogerSwiftPoet", .product(name: "ArgumentParser", package: "swift-argument-parser")]),
    ]
)
