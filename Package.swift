// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AudioTier",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AudioTier",
            linkerSettings: [
                .linkedFramework("CoreAudio"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AppKit")
            ]
        )
    ]
)
