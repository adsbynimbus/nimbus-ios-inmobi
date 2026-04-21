// swift-tools-version: 6.1

import PackageDescription

var package = Package(
    name: "NimbusInMobiKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(
           name: "NimbusInMobiKit",
           targets: ["NimbusInMobiKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/adsbynimbus/swift-package-inmobi", from: "10.8.6"),
    ],
    targets: [
        .target(
            name: "NimbusInMobiKit",
            dependencies: [
                .product(name: "NimbusKit", package: "nimbus-ios-sdk"),
                .product(name: "InMobiSDK", package: "swift-package-inmobi")
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

package.dependencies.append(.package(url: "https://github.com/adsbynimbus/nimbus-ios-sdk", from: "3.0.0-rc.1"))
