#!/bin/sh
# An experiment, not a fix: a copy of Server/ whose requests skip the schema
# migrations, to measure what running them on every request costs.
#
#   experiment-once.sh            writes out/server-once/ (gitignored)
#   PGMT_SERVER_DIR=…/out/server-once stack.sh web   serves it
#
# In the copy, every store's run() skips CREATE TABLE / CREATE INDEX / ALTER
# TABLE and the INSERT that seeds each lock row, Keyed::key skips its CREATE,
# and the two erasure migrations (Offers::migrate's SELECT and
# TakenBack::sweep) return at once. The schema must already exist — it does
# in a database the real copy has served — and nothing else changes.
# Server/ itself is untouched.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
COPY="$HERE/out/server-once"
rm -rf "$COPY"
mkdir -p "$HERE/out"
cp -R "$ROOT/Server" "$COPY"
cd "$COPY/.api"
for f in *.php; do
    perl -0pi -e 's/(private function run\(string \$sql\): void\n    \{\n)(        \$this->db->prepare\(\$sql\)->execute\(\);)/$1        if (preg_match(\x27\/\\A\\s*(CREATE|ALTER)\\b|\\A\\s*INSERT INTO \\w+_lock \\(id, arrivals\\) SELECT\/\x27, \$sql)) return;\n$2/' "$f"
done
perl -0pi -e 's/(public static function key\(PDO \$db\): string\n    \{\n)        \$db->prepare\(\x27CREATE TABLE IF NOT EXISTS offer_key[^\n]*\n[^\n]*\n/$1/' Keyed.php
perl -0pi -e 's/(public static function sweep\(PDO \$db, string \$table, array \$blank\): void\n    \{\n)/$1        return;\n/' TakenBack.php
perl -0pi -e 's/(\$plain = \$this->db->prepare\(\x27SELECT \* FROM walk_offers WHERE state IN)/return;\n        $1/' Offers.php
grep -c 'CREATE|ALTER' ./*.php | grep -v ':0' | wc -l | tr -d ' ' | sed 's/$/ run() helpers patched/'
grep -n -A1 'function sweep(PDO' TakenBack.php | head -n 3
grep -n -B1 'SELECT \* FROM walk_offers WHERE state IN' Offers.php | head -n 3
php -l Offers.php >/dev/null && php -l TakenBack.php >/dev/null && php -l Keyed.php >/dev/null && echo "lint ok: $COPY"
