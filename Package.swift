// swift-tools-version: 6.1
import PackageDescription

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
            name: "Extensions",
            targets: ["Extensions"]
        ),
        .executable(
            name: "swiftsheetgen",
            targets: ["SwiftSheetGenCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        // MARK: - Extension Module
        .target(
            name: "Extensions",
            dependencies: [],
            path: "Sources/Extensions"
        ),
        
        // MARK: - Core Library
        .target(
            name: "SheetLocalizer",
            dependencies: ["Extensions"],
            path: "Sources/SheetLocalizer"
        ),
        
        // MARK: - CLI Executable
        .executableTarget(
            name: "SwiftSheetGenCLI",
            dependencies: [
                "SheetLocalizer",
                "Extensions",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/SwiftSheetGenCLI"
        ),
        
        // MARK: - Tests
        .testTarget(
            name: "SheetLocalizerTests",
            dependencies: [
                "SheetLocalizer",
                "Extensions"
            ],
            path: "Tests/SheetLocalizer"
        )
    ]
)
