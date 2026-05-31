// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ASMR",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/Ink.git", from: "0.5.1")
    ],
    targets: [
        .executableTarget(
            name: "ASMR",
            dependencies: [
                .product(name: "Ink", package: "Ink")
            ],
            path: "Sources/ASMR",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
