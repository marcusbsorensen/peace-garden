#!/bin/bash
#
# Merge the strings the compiler extracted into the String Catalog.
#
# Xcode does this on every build when the build is started from Xcode. A build
# started from `xcodebuild` does not: it writes the `.stringsdata` files and
# stops there, so on a machine that builds from the command line the catalogue
# quietly stops matching the source. This is that missing step, done by hand.
#
#   tools/strings/sync.sh [derived-data-path]
#
# Run it after a build. New literals arrive as untranslated entries; a literal
# that has gone is marked `stale` rather than deleted, so a translation is never
# lost to a refactor. Comments and translations already in the catalogue are
# kept.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
derived="${1:-${DERIVED_DATA:-$root/build}}"
catalogue="$root/App/PeaceGarden/Resources/Localizable.xcstrings"
tool="$(xcode-select -p)/usr/bin/xcstringstool"

args=()
while IFS= read -r file; do
    args+=(--stringsdata "$file")
done < <(find "$derived/Build/Intermediates.noindex/PeaceGarden.build" -name '*.stringsdata' | sort)

if [ ${#args[@]} -eq 0 ]; then
    echo "No .stringsdata under $derived — build the app target first." >&2
    exit 1
fi

"$tool" sync "$catalogue" "${args[@]}"
echo "Synced $((${#args[@]} / 2)) stringsdata files into $catalogue"
