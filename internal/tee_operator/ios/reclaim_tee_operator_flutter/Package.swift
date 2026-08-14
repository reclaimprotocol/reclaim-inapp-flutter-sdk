// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    // TODO: Update your plugin name.
    name: "reclaim_tee_operator_flutter",
    platforms: [
        // TODO: Update the platforms your plugin supports.
        // If your plugin only supports iOS, remove `.macOS(...)`.
        // If your plugin only supports macOS, remove `.iOS(...)`.
        .iOS("13.0")
    ],
    products: [
        // TODO: Update your library and target names.
        // If the plugin name contains "_", replace with "-" for the library name.
        // Go code is no longer linked through SPM at all: hook/build.dart
        // bundles libreclaim.dylib directly via Dart's native assets
        // (DynamicLoadingBundled), so this product only carries the Swift
        // plugin glue (method channel handlers) and has no native binary of
        // its own to worry about static vs. dynamic linkage for.
        .library(name: "reclaim-tee-operator-flutter", targets: ["reclaim_tee_operator_flutter"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            // TODO: Update your target name.
            name: "reclaim_tee_operator_flutter",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // TODO: If your plugin requires a privacy manifest
                // (e.g. if it uses any required reason APIs), update the PrivacyInfo.xcprivacy file
                // to describe your plugin's privacy impact, and then uncomment this line.
                // For more information, visit:
                // https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
                .process("PrivacyInfo.xcprivacy"),

                // TODO: If you have other resources that need to be bundled with your plugin, refer to
                // the following instructions to add them:
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)
