// swift-tools-version: 6.0
import PackageDescription
import Foundation

let versionString = ProcessInfo.processInfo.environment["SWIFTSHEETGEN_VERSION"] ?? "0.0.0-development"

let package = Package(
    name: "SwiftSheetGen",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "SheetLocalizer",
            targets: ["SheetLocalizer"]
        ),
        .library(
            name: "CoreExtensions",
            targets: ["CoreExtensions"]
        ),
        .library(
            name: "XcodeIntegration",
            targets: ["XcodeIntegration"]
        ),
        .executable(
            name: "swiftsheetgen",
            targets: ["SwiftSheetGenCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        // MARK: - Extension Module
        .target(
            name: "CoreExtensions",
            dependencies: [],
            path: "Sources/CoreExtensions"
        ),
        
        // MARK: - Xcode Project Generator
        .target(
            name: "XcodeIntegration",
            dependencies: ["CoreExtensions"],
            path: "Sources/XcodeIntegration"
        ),
        
        // MARK: - CoreExtension Library
        .target(
            name: "SheetLocalizer",
            dependencies: [
                "CoreExtensions",
                "XcodeIntegration"
            ],
            path: "Sources/Sheet"
        ),
        
        // MARK: - CLI Executable
        .executableTarget(
            name: "SwiftSheetGenCLI",
            dependencies: [
                "SheetLocalizer",
                "CoreExtensions",
                "XcodeIntegration",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/SwiftSheetGenCLI",
            swiftSettings: [
                .unsafeFlags(["-DSWIFTSHEETGEN_VERSION=\\\"\(versionString)\\\""])
            ]
        ),
        
        // MARK: - Tests
        .testTarget(
            name: "SheetLocalizerTests",
            dependencies: [
                "SheetLocalizer",
                "CoreExtensions",
                "XcodeIntegration"
            ]
        )
    ]
)
