#!/bin/zsh
# A hundred thousand random crosses through SeedCore, on the Mac (no
# simulator), twice: the second run's fingerprint must equal the first's.
# Then the sampled crosses are re-derived in Python, a second implementation of
# the same hashing (`check_crosses.py`).
#
#   zsh tools/masstest/app/fuzz.sh <out folder> <clock>
set -u
cd "${0:A:h}/../../.."
OUT=${1:?out folder}
CLOCK=${2:-$OUT/fuzz.clock}
mkdir -p "$OUT/run1" "$OUT/run2"
date > "$CLOCK"
cd Packages/SeedCore
PG_MASSTEST=1 PG_MASSTEST_FUZZ_OUT="$OUT/run1" swift test --filter MassTestFuzzTests > "$OUT/run1.log" 2>&1
echo "run1 rc=$?" >> "$CLOCK"
PG_MASSTEST=1 PG_MASSTEST_FUZZ_OUT="$OUT/run2" swift test --filter MassTestFuzzTests > "$OUT/run2.log" 2>&1
echo "run2 rc=$?" >> "$CLOCK"
cd ../..
python3 tools/masstest/app/check_crosses.py "$OUT/run1/fuzz-crosses.json" > "$OUT/check.log" 2>&1
echo "check rc=$?" >> "$CLOCK"
date >> "$CLOCK"
echo "rc=0" >> "$CLOCK"
echo DONE >> "$CLOCK"
