#!/bin/sh
# Builds SeedCore's plant module for the browser into Server/assets/PlantWasm.wasm.
#
# Needs the swift.org toolchain and its WebAssembly SDK, the same version as
# each other (Xcode's Swift cannot target wasm):
#   https://www.swift.org/documentation/articles/wasm-getting-started.html
set -eu
cd "$(dirname "$0")"

VERSION=${SWIFT_VERSION:-6.3.3}
TOOLCHAIN="$HOME/Library/Developer/Toolchains/swift-$VERSION-RELEASE.xctoolchain/usr/bin"
[ -x "$TOOLCHAIN/swift" ] || TOOLCHAIN="$(dirname "$(command -v swift)")"

"$TOOLCHAIN/swift" build -c release --swift-sdk "swift-$VERSION-RELEASE_wasm" -Xswiftc -Osize

# wasm-opt (Homebrew's binaryen) takes a further 18% off, and grows every
# pinned seed to the same bytes. Without it the module is simply larger.
if command -v wasm-opt > /dev/null; then
  wasm-opt -Oz --strip-debug --strip-producers \
    --enable-bulk-memory --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int \
    .build/release/PlantWasm.wasm -o ../../Server/assets/PlantWasm.wasm
else
  echo "wasm-opt not found (brew install binaryen): writing the unoptimised module" >&2
  "$TOOLCHAIN/llvm-objcopy" --strip-all .build/release/PlantWasm.wasm ../../Server/assets/PlantWasm.wasm
fi

bytes=$(wc -c < ../../Server/assets/PlantWasm.wasm)
gzipped=$(gzip -9 -c ../../Server/assets/PlantWasm.wasm | wc -c)
echo "Server/assets/PlantWasm.wasm: $bytes bytes, $gzipped gzipped"
if command -v brotli > /dev/null; then
  echo "  $(brotli -q 11 -c ../../Server/assets/PlantWasm.wasm | wc -c) brotli"
fi
