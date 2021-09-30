// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Meals",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13)],
    products: [
        .library(
            name: "Meals",
            targets: ["Meals"]),
    ],
    dependencies: [
        .package(name: "AutomatedFetcher", url: "https://github.com/helsingborg-stad/spm-automated-fetcher", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "Meals",
            dependencies: ["AutomatedFetcher"]),
        .testTarget(
            name: "MealsTests",
            dependencies: ["Meals"]),
    ]
)
