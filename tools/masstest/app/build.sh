#!/bin/zsh
# Builds the app, its unit tests and the mass-test UI tests once, for any
# simulator, into the worktree's build/ (gitignored). Every run after this is
# `test-without-building`, so a matrix of hundreds of launches compiles nothing.
#
#   zsh tools/masstest/app/build.sh <log> <clock>
#
# The clock file ends `rc=<code>` and `DONE`, for whoever is waiting on it.
#
# `MT_OPT=1` builds the same Debug configuration with the optimiser on
# (`-O`), into build/DD-<scheme>O: the `-pg` launch arguments and the developer
# clock are Debug-only, and an unoptimised SeedCore makes every mesh about ten
# times slower than a phone ever sees. Run it with `MT_DD=build/DD-<scheme>O`.
set -u
cd "${0:A:h}/../../.."
LOG=${1:-build/masstest-build.log}
CLOCK=${2:-build/masstest-build.clock}
mkdir -p build
date > "$CLOCK"
xcodegen generate --spec tools/masstest/app/masstest.yml --project . > "$LOG" 2>&1
optimise=()
suffix=""
if [[ -n "${MT_OPT:-}" ]]; then optimise=(SWIFT_OPTIMIZATION_LEVEL=-O); suffix=O; fi
for scheme in MassTestUnit MassTestUI; do
  ${=MT_LOCK:-} xcodebuild build-for-testing -jobs 4 \
    -project PeaceGardenMassTest.xcodeproj \
    -scheme "$scheme" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "build/DD-$scheme$suffix" \
    CODE_SIGNING_ALLOWED=NO "${optimise[@]}" >> "$LOG" 2>&1
  rc=$?
  echo "$scheme rc=$rc" >> "$CLOCK"
  [[ $rc -ne 0 ]] && break
done
date >> "$CLOCK"
echo "rc=$rc" >> "$CLOCK"
echo DONE >> "$CLOCK"
