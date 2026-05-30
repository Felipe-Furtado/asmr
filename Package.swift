// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ASMR",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "ASMR",
            path: "Sources/ASMR",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
