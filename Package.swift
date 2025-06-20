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
        .executable(
            name: "swiftsheetgen",
            targets: ["SwiftSheetGenCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "SheetLocalizer",
            dependencies: []
        ),
        .executableTarget(
            name: "SwiftSheetGenCLI",  //
            dependencies: [
                "SheetLocalizer",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "SheetLocalizerTests",
            dependencies: ["SheetLocalizer"]
        )
    ]
)
