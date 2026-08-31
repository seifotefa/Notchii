// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Notchi",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Notchi",
            path: "Sources/Notchi"
        )
    ]
)
