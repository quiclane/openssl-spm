#!/usr/bin/env bash
# Build OpenSSL as a STATIC, arm64-only XCFramework for Apple platforms.
#
# Slices:  ios-arm64 (device) · ios-arm64-simulator · macos-arm64
# Ships libcrypto.a + libssl.a ONLY (no `openssl` CLI app) → no `_main` symbol,
# so it embeds in an app with zero entrypoint collision.
#
# Source: $OPENSSL_SRC (a checked-out openssl tree). For CI, clone upstream first.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="${OPENSSL_SRC:-$REPO_DIR/build/openssl}"
OUT_DIR="$SCRIPT_DIR/output"
ROOT="$REPO_DIR"                         # xcframework + libs live at repo ROOT
DEPLOY_IOS="14.0"
DEPLOY_MAC="11.0"

# no-apps/no-tests → we never build the CLI, so no `_main`. Lean, static.
CONFIG_OPTS=(
  no-shared no-tests no-async no-engine no-dso no-docs
  no-deprecated no-legacy no-comp no-ssl3 no-weak-ssl-ciphers
)

rm -rf "$OUT_DIR"; mkdir -p "$OUT_DIR"

# args: <slice> <openssl-target> <sdk> <arch> <min-version-flag>
build_arch() {
  local slice="$1" target="$2" sdk="$3" arch="$4" minflag="$5"
  local prefix="$OUT_DIR/$slice"
  echo "==> Building $slice ($arch / $sdk)"
  pushd "$SRC_DIR" >/dev/null
  make distclean >/dev/null 2>&1 || true
  local sysroot cc
  sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
  cc="$(xcrun --sdk "$sdk" -f clang)"
  CC="$cc" CFLAGS="-arch $arch -isysroot $sysroot $minflag" \
    ./Configure "$target" "${CONFIG_OPTS[@]}" --prefix="$prefix"
  make -j"$(sysctl -n hw.ncpu)" build_libs
  make install_dev
  popd >/dev/null
  libtool -static -o "$prefix/lib/libOpenSSL.a" "$prefix/lib/libssl.a" "$prefix/lib/libcrypto.a"
}

build_arch "ios-arm64"           "ios64-cross"        iphoneos        arm64 "-miphoneos-version-min=$DEPLOY_IOS"
build_arch "ios-arm64-simulator" "iossimulator-xcrun" iphonesimulator arm64 "-mios-simulator-version-min=$DEPLOY_IOS"
build_arch "macos-arm64"         "darwin64-arm64-cc"  macosx          arm64 "-mmacosx-version-min=$DEPLOY_MAC"

# Swift module map (shim umbrella) so consumers can `import OpenSSL`.
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
  inc="$OUT_DIR/$slice/include"
  cat > "$inc/shim.h" <<'EOF'
#ifndef OPENSSL_SPM_SHIM_H
#define OPENSSL_SPM_SHIM_H
#include <openssl/opensslv.h>
#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <openssl/sha.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/err.h>
#include <openssl/rand.h>
#include <openssl/bio.h>
#include <openssl/bn.h>
#include <openssl/hmac.h>
#include <openssl/aes.h>
#include <openssl/ec.h>
#include <openssl/x509.h>
#include <openssl/x509v3.h>
#include <openssl/ssl.h>
#endif
EOF
  cat > "$inc/module.modulemap" <<'EOF'
module OpenSSL {
    header "shim.h"
    export *
}
EOF
done

echo "==> Assembling OpenSSL.xcframework"
XCF="$ROOT/OpenSSL.xcframework"; rm -rf "$XCF"
xcodebuild -create-xcframework \
  -library "$OUT_DIR/ios-arm64/lib/libOpenSSL.a"           -headers "$OUT_DIR/ios-arm64/include" \
  -library "$OUT_DIR/ios-arm64-simulator/lib/libOpenSSL.a" -headers "$OUT_DIR/ios-arm64-simulator/include" \
  -library "$OUT_DIR/macos-arm64/lib/libOpenSSL.a"         -headers "$OUT_DIR/macos-arm64/include" \
  -output "$XCF"

# Root-level static libs + headers (iOS device slice is canonical).
cp "$OUT_DIR/ios-arm64/lib/libssl.a"    "$ROOT/libssl.a"
cp "$OUT_DIR/ios-arm64/lib/libcrypto.a" "$ROOT/libcrypto.a"
rm -rf "$ROOT/include"; cp -R "$OUT_DIR/ios-arm64/include" "$ROOT/include"

# Zip + checksum for the SwiftPM release asset.
( cd "$ROOT" && rm -f OpenSSL.xcframework.zip && zip -qry OpenSSL.xcframework.zip OpenSSL.xcframework )
echo "==> checksum: $(swift package compute-checksum "$ROOT/OpenSSL.xcframework.zip" 2>/dev/null || echo '(swift not found)')"
echo "==> Done. Slices:"; plutil -p "$XCF/Info.plist" | grep LibraryIdentifier
