// swift-tools-version: 5.9
import PackageDescription

// OpenSSL for Apple platforms — static, arm64-only XCFramework.
// Slices: ios-arm64, ios-arm64-simulator, ios-arm64-maccatalyst, macos-arm64.
// url-based binaryTarget → the repo stays tiny; SwiftPM downloads the release
// zip and verifies the checksum. Each version's Package.swift pins its own
// immutable url + checksum, so a tag never changes what it resolves to.
//
//   Stable (frozen forever):  exact: "1.0.0"
//   Dev (rolling, ~14 days):  .upToNextMinor(from: "1.0.1")   // immutable 1.0.N tags
let package = Package(
    name: "OpenSSL",
    platforms: [.iOS(.v14), .macCatalyst(.v14), .macOS(.v11)],
    products: [
        .library(name: "OpenSSL", targets: ["OpenSSL"]),
    ],
    targets: [
        .binaryTarget(
            name: "OpenSSL",
            url: "https://github.com/quiclane/openssl-spm/releases/download/1.0.0/OpenSSL.xcframework.zip",
            checksum: "86ca6717407b06e36115df18cfb13c2296e7817bc8cae9eaad467d041f572bfc"
        ),
    ]
)
