// swift-tools-version: 5.10

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-di",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "DI", targets: ["DI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.2"),
    ],
    targets: [
        .target(
            name: "DI",
            dependencies: [
                "DIMacros",
            ]
        ),
        .macro(
            name: "DIMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "DIMacrosTests",
            dependencies: [
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                "DIMacros",
            ]
        ),
    ]
)
