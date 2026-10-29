// swift-tools-version: 6.1

import PackageDescription

var package = Package(
    name: "NimbusInMobiKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(
           name: "NimbusInMobiKit",
           targets: ["NimbusInMobiKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/InMobi/InMobiSDK-Swift-Package", from: "11.3.0"),
    ],
    targets: [
        .target(
            name: "NimbusInMobiKit",
            dependencies: [
                .product(name: "NimbusKit", package: "nimbus-ios-sdk"),
                .product(name: "InMobiSDK", package: "InMobiSDK-Swift-Package")
            ]
        ),
        .testTarget(
            name: "NimbusInMobiKitTests",
            dependencies: ["NimbusInMobiKit"],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)

package.dependencies.append(.package(url: "https://github.com/adsbynimbus/nimbus-ios-sdk", from: "3.0.0"))
