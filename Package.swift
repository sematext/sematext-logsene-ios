// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Logsene",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_12),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "Logsene",
            targets: ["Logsene"]),
    ],
    targets: [
        .target(
            name: "Logsene",
            dependencies: [],
            path: "Logsene/Classes")
    ]
)
