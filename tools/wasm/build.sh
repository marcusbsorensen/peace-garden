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
    .build/release/PlantWasm.wasm -o ../../Server/.pages/PlantWasm.wasm
else
  echo "wasm-opt not found (brew install binaryen): writing the unoptimised module" >&2
  "$TOOLCHAIN/llvm-objcopy" --strip-all .build/release/PlantWasm.wasm ../../Server/.pages/PlantWasm.wasm
fi

# **Compressed here rather than by the host.** nginx on 20i gzips JavaScript,
# CSS and JSON and does not gzip `application/wasm`, and its vhost is not ours
# to add a type to — so `Server/index.php` serves `/plant.wasm` from whichever
# of these three the browser will take. They live in `.pages/`, which nginx
# refuses outright because it is a dot-directory, so there is no second address
# handing the module over whole.
raw=../../Server/.pages/PlantWasm.wasm
gzip -9 -c "$raw" > "$raw.gz"
if command -v brotli > /dev/null; then
  brotli -q 11 -f -c "$raw" > "$raw.br"
else
  # A stale copy from a machine that had brotli would be served for ever after
  # to every browser that asks for it, which is all of them.
  rm -f "$raw.br"
  echo "brotli not found (brew install brotli): gzip only, 700 KB larger on the wire" >&2
fi

report() { echo "  $1: $(wc -c < "$2" | tr -d ' ') bytes"; }
echo "Server/.pages/PlantWasm.wasm, and what is served from it:"
report "whole  " "$raw"
report "gzip   " "$raw.gz"
[ -f "$raw.br" ] && report "brotli " "$raw.br" 
