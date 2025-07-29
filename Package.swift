// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "HapticVision",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "HapticVision", targets: ["HapticVision"])
    ],
    targets: [
        .target(
            name: "HapticVision",
            dependencies: [],
            path: "Sources",
            sources: [
                "HapticManager.swift",
                "VisionProcessor.swift",
                "CameraManager.swift",
                "HapticVisionViewModel.swift",
                "ContentView.swift"
            ]
        )
    ]
)
