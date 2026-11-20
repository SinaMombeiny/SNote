// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SNote",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "SNoteCore",
            path: "Sources/SNoteCore",
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("include"),
                .unsafeFlags(["-std=c++23"])
            ],
            linkerSettings: [
                .linkedFramework("CoreFoundation")
            ]
        ),
        .executableTarget(
            name: "SNote",
            dependencies: ["SNoteCore"],
            path: "Sources/SNoteUI",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ]
)
