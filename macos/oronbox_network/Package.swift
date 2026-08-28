// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "oronbox_network",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(
            name: "oronbox-network",
            type: .dynamic,
            targets: ["oronbox_network"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "oronbox_network",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                "OronBoxNetworkBinary"
            ],
            path: "Sources/oronbox_network",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include")
            ]
        ),
        .binaryTarget(
            name: "OronBoxNetworkBinary",
            url: "https://github.com/zxor-org/OronBox-Package-Network/releases/download/v0.1.3/oronbox-network-macos-universal.xcframework.zip",
            checksum: "da5b3261a3b12a0c5a4dfef182a4a5f9c77d13782326a049dbc0972e56b1ee53"
        )
    ]
)
