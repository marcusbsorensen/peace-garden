#!/bin/sh
# Checks the guards in make_key.sh. Run from anywhere:
#
#   sh tools/zonec/check_make_key.sh
#
# Writes only into a temporary folder, plus two paths inside the repository that
# are removed again. It never prints a key, and the real
# ZoneCProductionKey.swift is never touched: a case that should be refused uses
# another name, so a guard that failed would leave a stray file here and not a
# second K beside the real one.
#
# Exits 0 when every case behaves, 1 otherwise.
set -u

here=$(cd "$(dirname "$0")" && pwd -P)
root=$(cd "$here/../.." && pwd -P)
script="$here/make_key.sh"
work=$(mktemp -d)

unignored="$root/tools/zonec/zz-check-key.swift"
ignored="$root/App/PeaceGarden/ZoneC/ZoneCProductionKey.swift.check-$$"
cleanup() {
  rm -rf "$work"
  rm -f "$unignored" "$unignored".tmp.* "$ignored" "$ignored".tmp.*
}
trap cleanup EXIT INT TERM

# A git that cannot answer, as a missing binary (127) or an unreadable
# checkout (128) would.
for code in 127 128; do
  mkdir -p "$work/git$code"
  printf '#!/bin/sh\nexit %s\n' "$code" > "$work/git$code/git"
  chmod +x "$work/git$code/git"
done

failures=0
pass() { echo "ok   $1"; }
fail() { echo "FAIL $1"; failures=$((failures + 1)); }

# expect <name> <want-exit> <want-file: yes|no> <file> <command...>
expect() {
  name=$1; want=$2; file_wanted=$3; file=$4; shift 4
  "$@" > "$work/out.txt" 2> "$work/err.txt"
  got=$?
  if [ "$got" -ne "$want" ]; then fail "$name (exit $got, wanted $want)"; return; fi
  if [ "$file_wanted" = yes ] && [ ! -f "$file" ]; then fail "$name (no file written)"; return; fi
  if [ "$file_wanted" = no ] && [ -e "$file" ]; then fail "$name (a file was written)"; return; fi
  if grep -q '0x[0-9a-f][0-9a-f], ' "$work/out.txt" "$work/err.txt"; then fail "$name (a key was printed)"; return; fi
  pass "$name"
}

# 1. Outside the repository, with git working: written, owner-only.
outside="$work/outside/K.swift"
mkdir -p "$work/outside"
expect "outside the repository, git working" 0 yes "$outside" sh "$script" "$outside"
if [ -f "$outside" ]; then
  mode=$(stat -c '%a' "$outside" 2>/dev/null || stat -f '%Lp' "$outside")
  [ "$mode" = 600 ] && pass "the key file is owner-only" || fail "the key file mode is $mode"
fi

# 2. An existing file is never replaced.
before=$(cksum < "$outside")
expect "an existing key is not replaced" 1 yes "$outside" sh "$script" "$outside"
[ "$(cksum < "$outside")" = "$before" ] && pass "and is unchanged" || fail "the existing key changed"

# 3. Outside the repository git is not needed, so a broken git does not matter.
outside2="$work/outside/K2.swift"
expect "outside the repository, git broken" 0 yes "$outside2" \
  env PATH="$work/git128:$PATH" sh "$script" "$outside2"

# 4. Inside the repository and not ignored: refused.
expect "inside, not ignored" 1 no "$unignored" sh "$script" "$unignored"

# 5. Inside and git cannot answer: refused, however the path is spelled.
for code in 127 128; do
  expect "inside, git exits $code" 1 no "$unignored" \
    env PATH="$work/git$code:$PATH" sh "$script" "$unignored"
done
expect "inside by way of .., git exits 128" 1 no "$unignored" \
  env PATH="$work/git128:$PATH" sh "$script" "$root/tools/zonec/../zonec/zz-check-key.swift"

# 6. Inside and ignored, with git working: written.
expect "inside, ignored" 0 yes "$ignored" sh "$script" "$ignored"

[ "$failures" -eq 0 ] && echo "all cases behave" || echo "$failures case(s) failed"
[ "$failures" -eq 0 ]
