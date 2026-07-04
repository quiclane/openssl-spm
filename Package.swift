// swift-tools-version: 5.9
import PackageDescription

// OpenSSL for Apple platforms — static, arm64-only XCFramework.
// Slices: ios-arm64 (device), ios-arm64-simulator, macos-arm64.
// The binary is committed at repo root and referenced by path, so a given
// tag/branch is fully self-contained and reproducible (SwiftPM checks it out
// and the .xcframework is right there — no checksum drift).
//
//   Stable (locked forever):  exact: "1.0.0"
//   Dev (rolling, ~14 days):  branch: "dev"
let package = Package(
    name: "OpenSSL",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "OpenSSL", targets: ["OpenSSL"]),
    ],
    targets: [
        .binaryTarget(name: "OpenSSL", path: "OpenSSL.xcframework"),
    ]
)
