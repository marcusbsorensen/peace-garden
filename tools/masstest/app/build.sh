#!/bin/zsh
# Builds the app, its unit tests and the mass-test UI tests once, for any
# simulator, into the worktree's build/ (gitignored). Every run after this is
# `test-without-building`, so a matrix of hundreds of launches compiles nothing.
#
#   zsh tools/masstest/app/build.sh <log> <clock>
#
# The clock file ends `rc=<code>` and `DONE`, for whoever is waiting on it.
set -u
cd "${0:A:h}/../../.."
LOG=${1:-build/masstest-build.log}
CLOCK=${2:-build/masstest-build.clock}
mkdir -p build
date > "$CLOCK"
xcodegen generate --spec tools/masstest/app/masstest.yml --project . > "$LOG" 2>&1
for scheme in MassTestUnit MassTestUI; do
  xcodebuild build-for-testing \
    -project PeaceGardenMassTest.xcodeproj \
    -scheme "$scheme" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "build/DD-$scheme" \
    CODE_SIGNING_ALLOWED=NO >> "$LOG" 2>&1
  rc=$?
  echo "$scheme rc=$rc" >> "$CLOCK"
  [[ $rc -ne 0 ]] && break
done
date >> "$CLOCK"
echo "rc=$rc" >> "$CLOCK"
echo DONE >> "$CLOCK"
