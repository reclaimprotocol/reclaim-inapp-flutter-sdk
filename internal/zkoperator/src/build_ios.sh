#!/usr/bin/env sh

set -e
# Updated CGO_CFLAGS:
# Added -fno-exceptions to disable C++ exception handling.
# Added -fno-unwind-tables and -fno-asynchronous-unwind-tables to remove unwind information.
# Enhanced go build flags:
# Added -extldflags '-Wl,-s -Wl,-x' to the -ldflags to strip all symbols and debugging info from the final binary.
# Added -gcflags=all="-l -B" to disable function inlining and bounds checking.
# Added -asmflags=all="-trimpath=$PWD" to remove file system paths from the compiled binary.
export GOOS=ios
export CGO_ENABLED=1
export CGO_CFLAGS=""
# export MIN_VERSION=15

SDK_PATH=$(xcrun --sdk "$SDK" --show-sdk-path)

CARCH=$([ "$GOARCH" = "amd64" ] && echo "x86_64" || echo "arm64")

TARGET="$CARCH-apple-ios$MIN_VERSION$([ "$SDK" = "iphonesimulator" ] && echo "-simulator" || echo "")"

CLANG=$(xcrun --sdk "$SDK" --find clang)
export CC="$CLANG -target $TARGET -isysroot $SDK_PATH $@"

BUILD_OUTPUT_DIR="${BUILD_DIR}/${GOARCH}_${SDK}"
mkdir -p "$BUILD_OUTPUT_DIR"

go build -C "$GO_GNARKPROVER_DIR" -trimpath ${GOX_TAGS} -buildmode=c-archive \
  -ldflags="-s -w" \
  -o "${BUILD_OUTPUT_DIR}/${LIB_NAME}.a" "$GO_TARGET_LIB"