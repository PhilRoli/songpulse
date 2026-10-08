// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SongPulse",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "SongPulse",
            path: "Sources/SongPulse"
        ),
        .testTarget(
            name: "SongPulseTests",
            dependencies: ["SongPulse"],
            path: "Tests/SongPulseTests"
        )
    ]
)
