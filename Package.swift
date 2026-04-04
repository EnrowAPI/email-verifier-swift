// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EmailVerifier",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(name: "EmailVerifier", targets: ["EmailVerifier"]),
    ],
    targets: [
        .target(name: "EmailVerifier"),
    ]
)
