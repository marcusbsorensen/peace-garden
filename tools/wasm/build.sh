#!/bin/sh
# Builds SeedCore's plant module for the browser into web/PlantWasm.wasm.
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
"$TOOLCHAIN/llvm-objcopy" --strip-all .build/release/PlantWasm.wasm web/PlantWasm.wasm

bytes=$(wc -c < web/PlantWasm.wasm)
gzipped=$(gzip -9 -c web/PlantWasm.wasm | wc -c)
echo "web/PlantWasm.wasm: $bytes bytes, $gzipped gzipped"
