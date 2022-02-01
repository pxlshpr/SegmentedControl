// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SegmentedControl",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SegmentedControl",
            targets: ["SegmentedControl"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pxlshpr/SwiftUISugar", from: "0.0.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SegmentedControl",
            dependencies: [
                .product(name: "SwiftUISugar", package: "swiftuisugar")
            ]),
        .testTarget(
            name: "SegmentedControlTests",
            dependencies: ["SegmentedControl"]),
    ]
)
