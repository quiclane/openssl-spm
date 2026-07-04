#!/usr/bin/env bash
# Writes a url-based Package.swift for a given version + checksum.
# Usage: ci/write-package-swift.sh <version> <checksum>
set -euo pipefail
V="$1"; SUM="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cat > "$ROOT/Package.swift" <<EOF
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
            url: "https://github.com/quiclane/openssl-spm/releases/download/$V/OpenSSL.xcframework.zip",
            checksum: "$SUM"
        ),
    ]
)
EOF
echo "wrote Package.swift for $V ($SUM)"
