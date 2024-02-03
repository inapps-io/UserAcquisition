// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UserAcquisition",
    platforms: [
        .iOS("9.0")
    ],
    products: [
        .library(name: "UserAcquisition", targets: ["UserAcquisition"])
    ],
    dependencies: [
        .package(url: "https://github.com/bizz84/SwiftyStoreKit.git", from: "0.16.4")
    ],
    targets: [
        .target(
            name: "UserAcquisition",
            dependencies: [
                .product(name: "SwiftyStoreKit", package: "SwiftyStoreKit")
            ],
            path: "Sources"),
    ]
)
