// swift-tools-version: 5.9

import PackageDescription

/// The native SDK, pinned to the version this plugin is released with. `BRUDCAST_IOS_SDK_PATH`
/// points it at a local checkout instead, for building against unreleased native changes.
let nativeSDK: Package.Dependency = {
    if let path = Context.environment["BRUDCAST_IOS_SDK_PATH"], !path.isEmpty {
        return .package(path: path)
    }
    return .package(url: "https://github.com/brudcast/brudcast-sdk-ios.git", exact: "0.2.0")
}()

let package = Package(
    name: "brudcast_flutter",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "brudcast-flutter", targets: ["brudcast_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        nativeSDK,
    ],
    targets: [
        .target(
            name: "brudcast_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "Brudcast", package: "brudcast-sdk-ios"),
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
