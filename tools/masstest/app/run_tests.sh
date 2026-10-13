#!/bin/zsh
# Runs one kind of mass test on one simulator, from the build `build.sh` made.
#
#   zsh tools/masstest/app/run_tests.sh stress  <udid> <out> <clock> PG_MASSTEST_SIZES=14,100
#   zsh tools/masstest/app/run_tests.sh screens <udid> <out> <clock> PG_MT_CONFIGS='en/L/dark;fr/AX5/light' PG_MT_FIXTURES=<dir>
#   zsh tools/masstest/app/run_tests.sh perf    <udid> <out> <clock> PG_MT_SIZES=14,100,500 PG_MT_FIXTURES=<dir>
#
# Every KEY=VALUE after the clock reaches the tests as KEY (xcodebuild passes
# TEST_RUNNER_KEY through with the prefix stripped). The output folder is
# handed over as PG_MASSTEST (stress) or PG_MT_OUT (the UI tests). The clock
# file ends `rc=<code>` and `DONE`.
#
# Never point this at a simulator somebody uses: it installs the app over
# whatever is there and writes the garden it is testing into it.
set -u
cd "${0:A:h}/../../.."
KIND=$1; SIM=$2; OUT=${3:A}; CLOCK=${4:A}; shift 4
mkdir -p "$OUT" build/results
date > "$CLOCK"
xcrun simctl boot "$SIM" 2>/dev/null
xcrun simctl bootstatus "$SIM" > /dev/null 2>&1
# Two switches a launch argument cannot reach: both are read as `Bool`s off
# `object(forKey:)`, and `-key NO` on the command line arrives as the string
# "NO". The Testing section (English on purpose, and only in Debug and
# TestFlight copies) is folded, and the stage's plant held still so two
# photographs of one screen differ only in what is being tested.
xcrun simctl spawn "$SIM" defaults write app.peacegarden developer.showsSection -bool NO
xcrun simctl spawn "$SIM" defaults write app.peacegarden stage.turntable.v1 -bool NO

for kv in "$@"; do export "TEST_RUNNER_$kv"; done
export TEST_RUNNER_PG_MASSTEST="$OUT" TEST_RUNNER_PG_MT_OUT="$OUT"

run() {
  local scheme=$1 only=$2 tag=$3
  xcodebuild test-without-building \
    -project PeaceGardenMassTest.xcodeproj -scheme "$scheme" \
    -derivedDataPath "build/DD-$scheme" -destination "id=$SIM" \
    -only-testing:"$only" \
    -resultBundlePath "build/results/$tag-$SIM-$(date +%H%M%S).xcresult" \
    > "$OUT/xcodebuild-$tag.log" 2>&1
  local rc=$?
  echo "$tag rc=$rc $(date +%H:%M:%S)" >> "$CLOCK"
  return $rc
}

rc=0
case $KIND in
  stress)
    run MassTestUnit PeaceGardenTests/MassTestStressTests stress || rc=$? ;;
  screens)
    run MassTestUI PeaceGardenMassTestUI/MassTestScreensUITests screens || rc=$? ;;
  perf)
    for size in ${(s:,:)TEST_RUNNER_PG_MT_SIZES:-14,100,500,1000,2000}; do
      export TEST_RUNNER_PG_MT_SIZE=$size
      run MassTestUI PeaceGardenMassTestUI/MassTestPerformanceUITests "perf-$size" || rc=$?
    done ;;
  *) echo "unknown kind $KIND" >> "$CLOCK"; rc=2 ;;
esac

date >> "$CLOCK"
echo "rc=$rc" >> "$CLOCK"
echo DONE >> "$CLOCK"
