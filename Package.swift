// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWHashtag",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "WWHashtag", targets: ["WWHashtag"]),
    ],
    targets: [
        .target(name: "WWHashtag", resources: [.copy("Privacy")])
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
