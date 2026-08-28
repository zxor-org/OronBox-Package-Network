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
            url: "https://github.com/zxor-org/OronBox-Package-Network/releases/download/v0.1.2/oronbox-network-macos-universal.xcframework.zip",
            checksum: "2bc68b89f0870f8138fbe9cba397cd6c54877beece1f5da4f482e28f3dc73753"
        )
    ]
)
