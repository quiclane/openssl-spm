// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenSSL",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(name: "OpenSSL", targets: ["OpenSSL"]),
    ],
    targets: [
        .binaryTarget(
            name: "OpenSSL",
            url: "https://github.com/quiclane/openssl-spm/releases/download/3.5.7/OpenSSL.xcframework.zip",
            checksum: "f26e01e627ed5018743e5bd3c55a463e54d1c561355a763c17f505dd3d32e6e2"
        ),
    ]
)
