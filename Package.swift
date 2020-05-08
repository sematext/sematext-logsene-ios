// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Logsene",
    products: [
        .library(
            name: "Logsene",
            targets: ["Logsene"]),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.12.2"),
    ],
    targets: [
        .target(
            name: "Logsene",
            dependencies: ["SQLite"],
            path: "Logsene/Classes"),
        .testTarget(
            name: "Example",
            dependencies: ["Logsene"],
            path: "Example/Logsene"),
    ]
)