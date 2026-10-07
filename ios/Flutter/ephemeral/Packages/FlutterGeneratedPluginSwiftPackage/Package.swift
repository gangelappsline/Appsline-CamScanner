// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "camera_avfoundation", path: "../.packages/camera_avfoundation-0.9.23+2"),
        .package(name: "image_picker_ios", path: "../.packages/image_picker_ios-0.8.13+9"),
        .package(name: "share_plus", path: "../.packages/share_plus-10.1.4"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "camera-avfoundation", package: "camera_avfoundation"),
                .product(name: "image-picker-ios", package: "image_picker_ios"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
