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
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .executable(name: "server", targets: ["ExampleServer"]),
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
    ]
)
