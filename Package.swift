// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AirText",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AirText", targets: ["AirText"])
    ],
    targets: [
        .executableTarget(
            name: "AirText"
        )
    ]
)
