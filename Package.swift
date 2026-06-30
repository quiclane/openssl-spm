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
            url: "https://github.com/quiclane/openssl-spm/releases/download/3.5.8/OpenSSL.xcframework.zip",
            checksum: "7092ae79484d17745ac9eb1e078c31b9b9577749cb76dcc792dfe60be872e0c7"
        ),
    ]
)
