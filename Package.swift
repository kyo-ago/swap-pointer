// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SwapPointer",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "SwapPointer",
            path: "Sources/SwapPointer",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("Carbon"),
            ]
        ),
        .testTarget(
            name: "SwapPointerTests",
            dependencies: ["SwapPointer"],
            path: "Tests/SwapPointerTests"
        ),
    ]
)
