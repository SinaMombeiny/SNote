// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "HelloCppSwift",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "CppHello",
            path: "Sources/CppHello",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "HelloApp",
            dependencies: ["CppHello"],
            path: "Sources/HelloApp"
        )
    ]
)
