// swift-tools-version: 5.10

import CompilerPluginSupport
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
    name: "swift-di",
    platforms: [.macOS(.v14), .iOS(.v16)],
    products: [
        .library(name: "DI", targets: ["DI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"999.0.0"),
    ],
    targets: [
        .target(
            name: "DI",
            dependencies: [
                "DIMacros",
            ],
            swiftSettings: swiftSettings()
        ),
        .macro(
            name: "DIMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings()
        ),
        .testTarget(
            name: "DITests",
            dependencies: [
                "DI",
            ],
            swiftSettings: swiftSettings()
        ),
        .testTarget(
            name: "DIMacrosTests",
            dependencies: [
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                "DIMacros",
            ],
            swiftSettings: swiftSettings()
        ),
    ]
)
