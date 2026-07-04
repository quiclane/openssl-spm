# openssl-spm — hands-off OpenSSL XCFramework pipeline (arm64, static).
# `make build` produces OpenSSL.xcframework + libssl.a/libcrypto.a at repo root.

OPENSSL_SRC ?= build/openssl
.DEFAULT_GOAL := help

## help: list targets
.PHONY: help
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'

## build: build the arm64 static OpenSSL.xcframework at repo root
.PHONY: build
build:
	OPENSSL_SRC=$(OPENSSL_SRC) bash ci/build-openssl-apple.sh

## verify: print xcframework slices + checksum
.PHONY: verify
verify:
	@plutil -p OpenSSL.xcframework/Info.plist | grep LibraryIdentifier
	@swift package compute-checksum OpenSSL.xcframework.zip

## clean: remove build output + artifacts
.PHONY: clean
clean:
	rm -rf ci/output OpenSSL.xcframework OpenSSL.xcframework.zip libssl.a libcrypto.a include
