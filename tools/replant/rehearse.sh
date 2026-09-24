#!/bin/sh
#
# Rehearse the replant end to end, on a garden made for it, before it is run
# on the live one.
#
#   tools/replant/rehearse.sh [live-ref]            on SQLite
#   tools/replant/rehearse.sh --mariadb [live-ref]  on MariaDB, in Docker, as live
#   tools/replant/rehearse.sh --copy <walk-*.sql.gz> on a real copy, in Docker
#
# `live-ref` is the commit the live service is running, `main` by default: the
# rehearsal garden is sown by that code — its rules, its cuts, its SeedCore's
# heights — exactly as the live one was, and then replanted by this checkout.
# Once the replant has been merged, `main` is no longer the live code; pass the
# commit that is deployed instead.
#
# What it proves, in order:
#   1. a copy taken by the live backup.php is read (SQLite copy or mysqldump);
#   2. the plan is made, and replant.php --dry-run agrees with it and writes
#      nothing;
#   3. --verify says the garden is not yet what the plan leaves;
#   4. the replant runs, and --verify says the garden is what it leaves;
#   5. running the same plan again is refused;
#   6. the plan is refused on a garden it was not made from;
#   7. the replanted garden is what this checkout's stores grow from scratch
#      with the new traits (Rehearsal/replay.php);
#   8. a new arrival after the replant plants as usual.
#
# Nothing here touches the live service, or anything outside a temporary
# directory and, for the MariaDB rehearsals, a throwaway container.
set -eu

HERE=$(cd "$(dirname "$0")/../.." && pwd)
MODE=sqlite
COPY=
case "${1:-}" in
    --mariadb) MODE=mariadb; shift ;;
    --copy) MODE=copy; COPY=${2:?a copy to rehearse on}; shift 2 ;;
esac
LIVE=${1:-main}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/replant-rehearsal.XXXXXX")
PORT=33062
CONTAINER=peace-garden-replant-rehearsal
REPLANT="$HERE/Server/.api/replant.php"

say() { printf '\n== %s\n' "$*"; }
fail() { echo "REHEARSAL FAILED: $*" >&2; exit 1; }

echo "Rehearsing in $WORK ($MODE), with $LIVE as the live service"

swift build -c release --package-path "$HERE/tools/replant" >/dev/null
PLANNER="$HERE/tools/replant/.build/release/replant"

start_mariadb() {
    docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
    docker run -d --name "$CONTAINER" -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=yes \
        -p 127.0.0.1:$PORT:3306 mariadb:10.11 >/dev/null
    trap 'docker rm -f '"$CONTAINER"' >/dev/null 2>&1 || true' EXIT
    i=0
    until php -r 'try { new PDO("mysql:host=127.0.0.1;port=" . $argv[1], "root", ""); } catch (Throwable) { exit(1); }' "$PORT" 2>/dev/null; do
        i=$((i + 1)); [ $i -lt 90 ] || fail "MariaDB never came up"; sleep 1
    done
    for db in garden other fresh; do
        docker exec "$CONTAINER" mariadb -uroot -e "DROP DATABASE IF EXISTS $db; CREATE DATABASE $db;"
    done
}

if [ "$MODE" = copy ]; then
    # A real copy: loaded as it is into a throwaway MariaDB, planned from the
    # file itself, replanted in the container. The copy is only read.
    start_mariadb
    DSN="mysql:host=127.0.0.1;port=$PORT;dbname=garden;charset=utf8mb4"
    OTHER="mysql:host=127.0.0.1;port=$PORT;dbname=other;charset=utf8mb4"
    FRESH="mysql:host=127.0.0.1;port=$PORT;dbname=fresh;charset=utf8mb4"
    export PG_WALK_USER=root
    say "loading $(basename "$COPY")"
    gunzip -c "$COPY" | docker exec -i "$CONTAINER" mariadb -uroot garden
    PLAN_FROM=$COPY
else
    say "the live code ($LIVE), and arrivals grown by its SeedCore"
    mkdir -p "$WORK/live" "$WORK/sow/Sources/sow" "$WORK/copies"
    git -C "$HERE" archive "$LIVE" Packages/SeedCore Server/.api | tar -x -C "$WORK/live"
    cp "$HERE/tools/replant/Rehearsal/sow.swift" "$WORK/sow/Sources/sow/main.swift"
    cat > "$WORK/sow/Package.swift" <<EOF
// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Sow", platforms: [.macOS(.v14)],
    dependencies: [.package(path: "$WORK/live/Packages/SeedCore")],
    targets: [.executableTarget(name: "sow", dependencies: [.product(name: "SeedCore", package: "SeedCore")],
                                path: "Sources/sow", swiftSettings: [.swiftLanguageMode(.v6)])]
)
EOF
    swift build -c release --package-path "$WORK/sow" >/dev/null
    "$WORK/sow/.build/release/sow" 40 3 > "$WORK/arrivals.jsonl"

    if [ "$MODE" = mariadb ]; then
        start_mariadb
        DSN="mysql:host=127.0.0.1;port=$PORT;dbname=garden;charset=utf8mb4"
        OTHER="mysql:host=127.0.0.1;port=$PORT;dbname=other;charset=utf8mb4"
        FRESH="mysql:host=127.0.0.1;port=$PORT;dbname=fresh;charset=utf8mb4"
        export PG_WALK_USER=root
    else
        DSN="sqlite:$WORK/garden.sqlite"
        OTHER="sqlite:$WORK/other.sqlite"
        FRESH="sqlite:$WORK/fresh.sqlite"
    fi

    say "sowing the garden with the live code"
    php "$HERE/tools/replant/Rehearsal/sow.php" "$WORK/live/Server/.api" "$DSN" "$WORK/arrivals.jsonl" \
        ${PG_WALK_USER:+root} ${PG_WALK_USER:+""}

    say "taking a copy with the live backup.php"
    if [ "$MODE" = mariadb ]; then
        # As tools/backup.sh --rehearse takes one: the container's own dumper,
        # behind backup.php's preamble.
        tables=$(PG_WALK_DSN="$DSN" php "$WORK/live/Server/.api/backup.php" --tables)
        {
            PG_WALK_DSN="$DSN" php "$WORK/live/Server/.api/backup.php" --preamble
            # shellcheck disable=SC2086
            docker exec "$CONTAINER" mariadb-dump -uroot --single-transaction --skip-lock-tables \
                --no-tablespaces --no-create-db --hex-blob --default-character-set=utf8mb4 garden $tables
        } | gzip -9 > "$WORK/copies/walk-rehearsal.sql.gz"
    else
        PG_WALK_DSN="$DSN" php "$WORK/live/Server/.api/backup.php" "$WORK/copies"
    fi
    PLAN_FROM=$(ls -1 "$WORK/copies"/walk-*.sql.gz | tail -1)
fi

say "the plan"
"$PLANNER" plan "$PLAN_FROM" --out "$WORK/plan.json"

export PG_WALK_DSN="$DSN"

say "a dry run"
php "$REPLANT" "$WORK/plan.json" --dry-run

say "verify before: should say no"
if php "$REPLANT" "$WORK/plan.json" --verify > "$WORK/verify-before.txt"; then
    if grep -q ' 0 plantings' "$WORK/verify-before.txt"; then
        echo "  (a garden with nothing planted is already what any plan leaves)"
    else
        fail "--verify passed before the replant ran"
    fi
else
    tail -1 "$WORK/verify-before.txt"
fi

say "the replant"
php "$REPLANT" "$WORK/plan.json"

say "verify after"
php "$REPLANT" "$WORK/plan.json" --verify

say "the same plan again: should be refused"
if php "$REPLANT" "$WORK/plan.json" 2> "$WORK/again.txt"; then fail "the plan ran twice"; fi
cat "$WORK/again.txt"

say "the plan on a garden it was not made from: should be refused"
# The same arrivals where there are any, and then one the copy never held: the
# plan is for the plants the copy saw, and a garden with one more is another.
if [ "$MODE" != copy ]; then
    php "$HERE/tools/replant/Rehearsal/sow.php" "$HERE/Server/.api" "$OTHER" "$WORK/arrivals.jsonl" \
        ${PG_WALK_USER:+root} ${PG_WALK_USER:+""} > /dev/null
fi
php -r 'require $argv[1]; $s = WalkStore::open($argv[2], $argv[3] ?: null, "");
        $s->plant(hash("sha256", "one more"), hash("sha256", "a"), hash("sha256", "b"), hash("sha256", "e"), 1.0, 1);' \
    "$HERE/Server/.api/WalkStore.php" "$OTHER" "${PG_WALK_USER:-}"
if PG_WALK_DSN="$OTHER" php "$REPLANT" "$WORK/plan.json" --dry-run 2> "$WORK/other.txt"; then
    fail "the plan ran on a garden it was not made from"
fi
cat "$WORK/other.txt"

say "grown fresh through the stores"
php "$HERE/tools/replant/Rehearsal/replay.php" "$DSN" "$FRESH" ${PG_WALK_USER:+root} ${PG_WALK_USER:+""}

say "a new arrival after the replant"
php -r 'require $argv[1]; $s = WalkStore::open($argv[2], $argv[3] ?: null, "");
        [$p, $new] = $s->plantInto("travel", hash("sha256","after"), hash("sha256","pa"), hash("sha256","pb"), hash("sha256","en"), 0.8, 2);
        echo "  planted in plot {$p["plot"]}, new: " . ($new ? "yes" : "no") . "\n";' \
    "$HERE/Server/.api/WalkStore.php" "$DSN" "${PG_WALK_USER:-}"

say "rehearsed: every step did what it should"
echo "  plan and logs in $WORK"
