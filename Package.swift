// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Logsene",
    products: [
        .library(
            name: "Logsene",
            targets: ["Logsene"]),
    ],
    targets: [
        .target(
            name: "Logsene",
            dependencies: [],
            path: "Logsene/Classes"),
        .testTarget(
            name: "Example",
            dependencies: ["Logsene"],
            path: "Example/Logsene"),
    ]
)
