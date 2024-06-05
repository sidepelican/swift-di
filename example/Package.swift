// swift-tools-version: 5.10

import PackageDescription

func swiftSettings() -> [SwiftSetting] {
    return [
        .enableUpcomingFeature("ForwardTrailingClosures"),
        .enableUpcomingFeature("ConciseMagicFile"),
        .enableUpcomingFeature("BareSlashRegexLiterals"),
        .enableUpcomingFeature("ExistentialAny"),
        .enableExperimentalFeature("StrictConcurrency"),
    ]
}

let package = Package(
    name: "example",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .executable(name: "server", targets: ["ExampleServer"]),
        .executable(name: "client", targets: ["ExampleClient"]),
    ],
    dependencies: [
        .package(name: "swift-di", path: "../")
    ],
    targets: [
        .executableTarget(
            name: "ExampleServer",
            dependencies: [
                .product(name: "DI", package: "swift-di"),
            ],
            swiftSettings: swiftSettings()
        ),
        .executableTarget(
            name: "ExampleClient",
            dependencies: [
                .product(name: "DI", package: "swift-di"),
            ],
            swiftSettings: swiftSettings()
        ),
    ]
)
