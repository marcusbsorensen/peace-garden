#!/bin/sh
#
# SQLite file locking on this host, under many launches at once: the test
# `design/space-seeds-2026-10-16/DESIGN.md` §6.2 asks for before the aloft
# pools are relied on. Everything is in `locktest.php`; this picks the PHP.
#
#   tools/zonec/locktest.sh --serve                local trial: a local php -S, 5 minutes
#   tools/zonec/locktest.sh --serve --seconds 30   the same, shorter
#   tools/zonec/locktest.sh --url ADDRESS          on a host, with locktest.php served at ADDRESS
#
# Options pass through: --seconds N (300), --cli N (64), --web N (64),
# --scratch DIR (default: beside the directory you run it from, never inside
# public_html). It makes a scratch pool, reports, and deletes what it made.
#
# **Running it on the live host is Marcus's decision (gate G4).** Nothing here
# connects anywhere by itself.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)

# The host runs php83; a laptop runs php.
if [ -n "${PHP:-}" ]; then
    :
elif command -v php83 >/dev/null 2>&1; then
    PHP=php83
else
    PHP=php
fi

exec "$PHP" "$HERE/locktest.php" run "$@"
