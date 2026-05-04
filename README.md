# openssl-spm

Swift Package Manager distribution of OpenSSL 3.5.7 for Apple platforms.

## Install (Xcode)

**File → Add Package Dependencies → `https://github.com/quiclane/openssl-spm`**

Or in `Package.swift`:

```swift
.package(url: "https://github.com/quiclane/openssl-spm", from: "3.5.7")
```

Then import:

```swift
import OpenSSL
```

## Contents

- `OpenSSL.xcframework` — Combined xcframework (iOS device, iOS simulator, macOS)
- `libssl.a` / `libcrypto.a` — Raw iOS-arm64 static libraries for direct linking
- `include/` — OpenSSL headers

## Platforms

- iOS 13+ (arm64)
- iOS Simulator (arm64 + x86_64)
- macOS 11+ (arm64 + x86_64)

## Build from source

See `build/build-openssl.sh` for the build process.
