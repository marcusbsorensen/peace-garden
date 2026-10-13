#!/bin/sh
# A local copy of the plot service that resembles the live one, for the
# population test (design/mass-test-2026-10-13/population/README.md).
#
#   MariaDB 10.11 in Docker   127.0.0.1:3407   container pg-mt-pop-db, volume pg-mt-pop-data
#   nginx 1.27 in Docker      127.0.0.1:8811   container pg-mt-pop-web
#   PHP-FPM on this Mac       127.0.0.1:9811   a static pool of $PGMT_CHILDREN (16)
#
# It never talks to peacegarden.app. It writes Server/.api/config.php in this
# checkout (git ignores it) pointing at the container, and removes it on `down`.
#
#   stack.sh up        start all three, create pgmt_main
#   stack.sh db NAME   create (or empty) database pgmt_NAME [charset]
#   stack.sh sql "…"   run SQL as root in the container
#   stack.sh down      stop and remove the containers and the volume, stop FPM
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
SCRATCH=${PGMT_SCRATCH:-${TMPDIR:-/tmp}/pg-mt-pop}
DB_PORT=3407
WEB_PORT=8811
FPM_PORT=9811
CHILDREN=${PGMT_CHILDREN:-16}
DB=pg-mt-pop-db
WEB=pg-mt-pop-web
VOLUME=pg-mt-pop-data
CONFIG="$ROOT/Server/.api/config.php"

sql() { docker exec -i "$DB" mariadb -uroot -proot-local-only -N -e "$1"; }

fill() {
    sed -e "s#__SERVER_ROOT__#$ROOT/Server#g" -e "s#__FPM__#host.docker.internal:$FPM_PORT#g" \
        -e "s#__SCRATCH__#$SCRATCH#g" -e "s#__FPM_PORT__#$FPM_PORT#g" -e "s#__CHILDREN__#$CHILDREN#g" \
        -e "s#__DB_PORT__#$DB_PORT#g" "$1" > "$2"
}

database() {
    name=pgmt_$1
    charset=${2:-utf8mb4}
    sql "DROP DATABASE IF EXISTS $name; CREATE DATABASE $name CHARACTER SET $charset;
         GRANT ALL PRIVILEGES ON \`$name\`.* TO 'pgmt'@'%';"
    echo "database $name ($charset)"
}

up() {
    mkdir -p "$SCRATCH"
    docker rm -f "$DB" "$WEB" >/dev/null 2>&1 || true
    # The slow log catches anything over 20 ms; performance_schema keeps the
    # per-statement digests the report ranks.
    # PGMT_STORAGE=tmpfs keeps the data in memory, where fsync costs nothing;
    # the default is a Docker volume on the VM's disk, where fsync goes through
    # to macOS and costs far more than on a Linux host. The two bracket a host.
    if [ "${PGMT_STORAGE:-volume}" = tmpfs ]; then
        storage="--tmpfs /var/lib/mysql:rw,size=3g"
    else
        storage="-v $VOLUME:/var/lib/mysql"
    fi
    # shellcheck disable=SC2086
    docker run -d --name "$DB" -e MARIADB_ROOT_PASSWORD=root-local-only \
        $storage -p 127.0.0.1:$DB_PORT:3306 mariadb:10.11 \
        --slow-query-log=1 --long-query-time=0.02 --slow-query-log-file=/var/lib/mysql/slow.log \
        --log-slow-verbosity=query_plan,explain --performance-schema=ON \
        --max-connections=500 >/dev/null
    printf 'waiting for MariaDB'
    i=0
    until php -r 'try { new PDO("mysql:host=127.0.0.1;port=" . $argv[1], "root", "root-local-only"); } catch (Throwable) { exit(1); }' "$DB_PORT" 2>/dev/null; do
        i=$((i + 1)); [ $i -lt 120 ] || { echo ' never came up' >&2; exit 1; }
        printf '.'; sleep 1
    done
    echo
    sql "CREATE USER IF NOT EXISTS 'pgmt'@'%' IDENTIFIED BY 'pgmt-local-only';"
    database main

    fill "$HERE/conf/config.php" "$CONFIG"
    fill "$HERE/conf/php-fpm.conf" "$SCRATCH/php-fpm.conf"
    fill "$HERE/conf/nginx.conf" "$SCRATCH/nginx.conf"

    [ -f "$SCRATCH/php-fpm.pid" ] && kill "$(cat "$SCRATCH/php-fpm.pid")" 2>/dev/null || true
    sleep 1
    /opt/homebrew/sbin/php-fpm --fpm-config "$SCRATCH/php-fpm.conf"

    docker run -d --name "$WEB" -p 127.0.0.1:$WEB_PORT:80 \
        -v "$ROOT/Server:$ROOT/Server:ro" -v "$SCRATCH/nginx.conf:/etc/nginx/nginx.conf:ro" \
        nginx:1.27-alpine >/dev/null
    sleep 1
    echo "up: http://127.0.0.1:$WEB_PORT  (FPM children $CHILDREN, storage ${PGMT_STORAGE:-volume}, scratch $SCRATCH)"
}

down() {
    docker rm -f "$DB" "$WEB" >/dev/null 2>&1 || true
    docker volume rm "$VOLUME" >/dev/null 2>&1 || true
    [ -f "$SCRATCH/php-fpm.pid" ] && kill "$(cat "$SCRATCH/php-fpm.pid")" 2>/dev/null || true
    rm -f "$CONFIG"
    echo down
}

case "${1:-}" in
    up) up ;;
    db) database "$2" "${3:-utf8mb4}" ;;
    sql) sql "$2" ;;
    down) down ;;
    *) echo "usage: $0 up|db NAME [charset]|sql SQL|down" >&2; exit 2 ;;
esac
