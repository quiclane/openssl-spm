# openssl-spm

Static, **arm64-only** OpenSSL as an Apple **XCFramework**, packaged for Swift
Package Manager. Add it by URL and `import OpenSSL`. Each version is an
**immutable semver tag** whose `Package.swift` pins its own release-zip **url +
checksum** — a tag never changes what it resolves to, and the repo stays tiny
(the binary ships as a release asset, not committed).

## Two channels

| Channel | Add as | Updates | For |
|---|---|---|---|
| **Stable** | `exact: "1.0.0"` | **Never** — frozen forever | reproducible / shipping builds |
| **Dev (rolling)** | `.upToNextMinor(from: "1.0.1")` → newest immutable **`1.0.N`** tag | Automatic, at most **every 14 days** | latest OpenSSL |

### Xcode
- **Stable:** File → Add Package Dependencies → `https://github.com/quiclane/openssl-spm` → **Exact Version** `1.0.0`.
- **Dev:** same URL → **Up to Next Minor Version** → `1.0.1` (auto-tracks the newest `1.0.N`).

### Package.swift
```swift
.package(url: "https://github.com/quiclane/openssl-spm", exact: "1.0.0")                 // stable, frozen
.package(url: "https://github.com/quiclane/openssl-spm", .upToNextMinor(from: "1.0.1"))  // rolling dev
```
Then: `import OpenSSL`.

## What's inside

- **Slices:** `ios-arm64` (device), `ios-arm64-simulator`, `macos-arm64`. **arm64 only.**
- **Static:** `libssl` + `libcrypto` merged into one `libOpenSSL.a` per slice.
- **No `openssl` CLI** is built (`build_libs` only) → **no `_main` symbol**, so it
  embeds in an app with zero entrypoint collision.
- A Swift **module map** (`import OpenSSL`, via a shim umbrella header).
- Root-level `libssl.a`, `libcrypto.a`, `include/` for manual / non-SPM linking.

Built with: `no-shared no-tests no-async no-engine no-dso no-docs no-deprecated
no-legacy no-comp no-ssl3 no-weak-ssl-ciphers`.

## Advantages

- **Reproducible** — path-based binary at a pinned tag is byte-identical forever
  (stable never moves); no checksum drift, no release-download step at resolve.
- **Lean** — arm64-only, trimmed config, static; embeds cleanly.
- **Safe to embed** — no `_main`, no dynamic libraries to sign/bundle.
- **Hands-off** — the dev channel rebuilds itself from upstream on a schedule.

## Pipeline (fully hands-off)

- **`make build`** → `ci/build-openssl-apple.sh`: builds all three arm64 slices,
  merges libs, adds the module map, assembles `OpenSSL.xcframework`, and stages
  root `libssl.a`/`libcrypto.a`/`include/`.
- **`.github/workflows/openssl-dev-rolling.yml`** — cron on the 1st & 15th
  (≈ every 14 days): gates on an upstream change **and** a ≥14-day interval,
  rebuilds, and force-updates the `dev` branch to a single fresh commit (no
  history bloat).
- **`.github/workflows/openssl-stable-once.yml`** — manual dispatch to cut a new
  locked stable tag (rare; a cut tag is frozen forever).
- Tracked upstream lives in **`ci/openssl-upstream.txt`** (repo + branch).

## Build locally

```sh
make build     # → OpenSSL.xcframework + root libs
make verify    # prints slices + checksum
```
