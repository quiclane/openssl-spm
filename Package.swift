// swift-tools-version: 5.9
import PackageDescription

// OpenSSL for Apple platforms — static, arm64-only XCFramework.
// Slices: ios-arm64, ios-arm64-simulator, ios-arm64-maccatalyst, macos-arm64.
// url-based binaryTarget: SwiftPM downloads the release zip and verifies the
// checksum. This tag's url + checksum are immutable.
//
//   Stable (frozen forever):  exact: "1.0.0"
//   Dev (rolling, ~14 days):  .upToNextMinor(from: "1.0.1")
let package = Package(
    name: "OpenSSL",
    platforms: [.iOS(.v14), .macCatalyst(.v14), .macOS(.v11)],
    products: [
        .library(name: "OpenSSL", targets: ["OpenSSL"]),
    ],
    targets: [
        .binaryTarget(
            name: "OpenSSL",
            url: "https://github.com/quiclane/openssl-spm/releases/download/1.0.5/OpenSSL.xcframework.zip",
            checksum: "a02de8c6f2d7fba94efc43816268c93c12e61f907b258e2527ec4c8a56f44fd8"
        ),
    ]
)
