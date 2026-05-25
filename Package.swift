// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PodMonsters",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PodMonsters",
            targets: ["PodMonsters"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PodMonsters",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "PodMonstersTests",
            dependencies: ["PodMonsters"],
            path: "Tests/PodMonstersTests"
        )
    ]
)
