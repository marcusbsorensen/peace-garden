#!/bin/sh
# The schema version on MariaDB (14 October 2026): a fresh database, and two
# that the code before the version built and the new code then upgraded on
# its first request, as a deploy would.
#
#   ./migrations.sh [OUT_DIR] [OLD_COMMIT]
#
# Needs the stack up (stack.sh up) and popgen built. OLD_COMMIT is the code
# before the fixes (default 97fd259, what the population report measured);
# its Server/ is unpacked into out/old/ and served for the first half.
#
#   pgmt_upgrade   utf8mb4 (MariaDB's default collation): a small population
#                  lives under the old code, then rows the code before 24
#                  September left are written in, then the new code opens it
#   pgmt_uplatin   created latin1: the old code makes its tables latin1 and
#                  refuses an emoji; the new code converts them
#   pgmt_fresh     created by the new code from nothing
#
# Then the upgraded schema is compared with the fresh one table by table, the
# rows before and after the upgrade are compared, and check.php and popgen
# verify run over the upgraded population.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
OUT=${1:-$HERE/out/migrations}
OLD_COMMIT=${2:-97fd259}
OLD=$HERE/out/old
mkdir -p "$OUT" "$OLD"
cd "$HERE"

rm -rf "$OLD/Server"
git -C "$ROOT" archive "$OLD_COMMIT" Server | tar -x -C "$OLD"

echo "== the old code ($OLD_COMMIT) builds two databases"
./stack.sh db upgrade
./stack.sh db uplatin latin1
PGMT_SERVER_DIR="$OLD/Server" ./stack.sh web
.build/release/popgen plan 800 30 60 31415 "$OUT/plan.jsonl"
# The driver's own commands (sweep.php, curate.php) from the old copy too, or
# the new code's sweep would migrate the database on day 0.
PGMT_SERVER_DIR="$OLD/Server" node driver.mjs "$OUT/plan.jsonl" "$OUT/run" --db upgrade --width 32 > "$OUT/driver.log" 2>&1
tail -n 1 "$OUT/driver.log"
php migrations.php latin1-setup uplatin
php migrations.php legacy upgrade
php migrations.php snapshot upgrade "$OUT/upgrade-before.json"
php migrations.php snapshot uplatin "$OUT/latin1-before.json"

echo "== the new code opens them"
./stack.sh web
./stack.sh db fresh
php migrations.php first fresh "$OUT/first-fresh.json"
php migrations.php first upgrade "$OUT/first-upgrade.json"
php migrations.php first uplatin "$OUT/first-latin1.json"
php migrations.php snapshot fresh "$OUT/fresh.json"
php migrations.php snapshot upgrade "$OUT/upgrade-after.json"
php migrations.php snapshot uplatin "$OUT/latin1-after.json"

echo "== compared"
status=0
php migrations.php compare "$OUT/upgrade-before.json" "$OUT/upgrade-after.json" "$OUT/fresh.json" "$OUT/compare-upgrade.json" || status=1
php migrations.php compare "$OUT/latin1-before.json" "$OUT/latin1-after.json" "$OUT/fresh.json" "$OUT/compare-latin1.json" || status=1
php migrations.php latin1-verify uplatin "$OUT/latin1-verify.json"
php check.php "$OUT/run" upgrade > "$OUT/check.log" 2>&1 || status=1
tail -n 2 "$OUT/check.log"
.build/release/popgen verify "$OUT/plan.jsonl" "$OUT/run/dump.json" > "$OUT/verify.log" 2>&1 || status=1
tail -n 2 "$OUT/verify.log"

echo "== a rollback to the old code and back"
PGMT_SERVER_DIR="$OLD/Server" ./stack.sh web
php migrations.php rollback-setup uplatin
./stack.sh web
php migrations.php rollback-verify uplatin "$OUT/rollback.json" || status=1
exit $status
