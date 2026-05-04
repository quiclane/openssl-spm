#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/openssl"
OUT_DIR="$SCRIPT_DIR/output"
ARTIFACTS_DIR="$SCRIPT_DIR/../artifacts"
DEPLOY_IOS="13.0"
DEPLOY_MAC="11.0"

CONFIG_OPTS=(
  no-shared no-tests no-async no-engine no-dso
  no-deprecated no-legacy no-comp no-ssl3 no-weak-ssl-ciphers
)

rm -rf "$OUT_DIR" "$ARTIFACTS_DIR"
mkdir -p "$OUT_DIR" "$ARTIFACTS_DIR"

# ---- Build function ----
# args: <slice-name> <openssl-target> <sdk> <arch> <min-version-flag>
build_arch() {
  local slice="$1" target="$2" sdk="$3" arch="$4" minflag="$5"
  local prefix="$OUT_DIR/$slice/$arch"

  echo "==> Building $slice / $arch"
  pushd "$SRC_DIR" >/dev/null
  make distclean >/dev/null 2>&1 || true

  local sysroot
  sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
  local cc
  cc="$(xcrun --sdk "$sdk" -f clang)"

  CC="$cc" \
  CFLAGS="-arch $arch -isysroot $sysroot $minflag -fembed-bitcode" \
  ./Configure "$target" "${CONFIG_OPTS[@]}" --prefix="$prefix"

  make -j"$(sysctl -n hw.ncpu)"
  make install_sw
  popd >/dev/null
}

# ---- iOS device (arm64) ----
build_arch "ios"        "ios64-cross"          iphoneos        arm64  "-mios-version-min=$DEPLOY_IOS"

# ---- iOS simulator (arm64 + x86_64) ----
build_arch "ios-sim"    "iossimulator-xcrun"   iphonesimulator arm64  "-mios-simulator-version-min=$DEPLOY_IOS"
build_arch "ios-sim"    "iossimulator-xcrun"   iphonesimulator x86_64 "-mios-simulator-version-min=$DEPLOY_IOS"

# ---- macOS (arm64 + x86_64) ----
build_arch "macos"      "darwin64-arm64-cc"    macosx          arm64  "-mmacosx-version-min=$DEPLOY_MAC"
build_arch "macos"      "darwin64-x86_64-cc"   macosx          x86_64 "-mmacosx-version-min=$DEPLOY_MAC"

# ---- Lipo multi-arch slices and merge libssl+libcrypto into a single libOpenSSL.a ----
merge_slice() {
  local slice="$1"; shift
  local archs=("$@")
  local merged="$OUT_DIR/$slice/merged"
  mkdir -p "$merged/lib" "$merged/include"

  # Copy headers from the first arch (they're identical across archs)
  cp -R "$OUT_DIR/$slice/${archs[0]}/include/." "$merged/include/"

  # Lipo each lib across archs
  for lib in libssl.a libcrypto.a; do
    local inputs=()
    for a in "${archs[@]}"; do inputs+=("$OUT_DIR/$slice/$a/lib/$lib"); done
    if [ "${#inputs[@]}" -eq 1 ]; then
      cp "${inputs[0]}" "$merged/lib/$lib"
    else
      lipo -create "${inputs[@]}" -output "$merged/lib/$lib"
    fi
  done

  # Combine libssl+libcrypto into a single libOpenSSL.a per slice
  pushd "$merged/lib" >/dev/null
  libtool -static -o libOpenSSL.a libssl.a libcrypto.a
  popd >/dev/null
}

merge_slice "ios"     arm64
merge_slice "ios-sim" arm64 x86_64
merge_slice "macos"   arm64 x86_64

# ---- Build the xcframework ----
XCF="$ARTIFACTS_DIR/OpenSSL.xcframework"
xcodebuild -create-xcframework \
  -library "$OUT_DIR/ios/merged/lib/libOpenSSL.a"     -headers "$OUT_DIR/ios/merged/include" \
  -library "$OUT_DIR/ios-sim/merged/lib/libOpenSSL.a" -headers "$OUT_DIR/ios-sim/merged/include" \
  -library "$OUT_DIR/macos/merged/lib/libOpenSSL.a"   -headers "$OUT_DIR/macos/merged/include" \
  -output "$XCF"

# ---- Stage root-level .a files (iOS device slice as the canonical default) ----
cp "$OUT_DIR/ios/merged/lib/libssl.a"    "$ARTIFACTS_DIR/libssl.a"
cp "$OUT_DIR/ios/merged/lib/libcrypto.a" "$ARTIFACTS_DIR/libcrypto.a"
cp -R "$OUT_DIR/ios/merged/include"      "$ARTIFACTS_DIR/include"

echo "==> Done. Artifacts in: $ARTIFACTS_DIR"
