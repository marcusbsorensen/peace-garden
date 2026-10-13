#!/bin/sh
# A local copy of the plot service that resembles the live one, for the
# population test (design/mass-test-2026-10-13/population/README.md).
#
#   MariaDB 10.11 in Docker   127.0.0.1:3407   container pg-mt-pop-db
#   PHP-FPM 8.3 in Docker     (network only)   container pg-mt-pop-php, a static pool of $PGMT_CHILDREN (16)
#   nginx 1.27 in Docker      127.0.0.1:8811   container pg-mt-pop-web
#
# All three on one Docker network, pg-mt-pop-net, so the service's database
# round trips cross a Docker network as they would cross a host's LAN.
# PGMT_FPM=host runs PHP-FPM on this Mac instead (Homebrew PHP, 127.0.0.1:9811),
# which is how the first runs were made; every round trip then goes through
# Docker Desktop's port forwarding.
#
# PGMT_STORAGE=tmpfs keeps the database in memory, where fsync costs nothing;
# the default is a Docker volume on the VM's disk, where fsync goes through to
# macOS and costs far more than on a Linux host. The two bracket a host.
#
# It never talks to peacegarden.app. It writes Server/.api/config.php in this
# checkout (git ignores it) pointing at the container, and removes it on `down`.
#
#   stack.sh up        start all three, create pgmt_main
#   stack.sh web       (re)start PHP and nginx only, keeping the database
#   stack.sh db NAME   create (or empty) database pgmt_NAME [charset]
#   stack.sh sql "…"   run SQL as root in the database container
#   stack.sh down      stop and remove the containers, the network and the volume
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
SCRATCH=${PGMT_SCRATCH:-$HERE/out/stack}
DB_PORT=3407
WEB_PORT=8811
FPM_PORT=9811
CHILDREN=${PGMT_CHILDREN:-16}
FPM_MODE=${PGMT_FPM:-docker}
NET=pg-mt-pop-net
DB=pg-mt-pop-db
PHP=pg-mt-pop-php
WEB=pg-mt-pop-web
VOLUME=pg-mt-pop-data
# PGMT_SERVER_DIR serves another copy of the tree (experiment-once.sh's).
SERVER=${PGMT_SERVER_DIR:-$ROOT/Server}
CONFIG="$SERVER/.api/config.php"

sql() { docker exec -i "$DB" mariadb -uroot -proot-local-only -N -e "$1"; }

fill() {
    if [ "$FPM_MODE" = host ]; then fpm="host.docker.internal:$FPM_PORT"; fpmdb="127.0.0.1;port=$DB_PORT"
    else fpm="$PHP:9000"; fpmdb="$DB;port=3306"; fi
    sed -e "s#__SERVER_ROOT__#$SERVER#g" -e "s#__FPM__#$fpm#g" -e "s#__FPM_DB__#$fpmdb#g" \
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

db_up() {
    mkdir -p "$SCRATCH"
    docker network create "$NET" >/dev/null 2>&1 || true
    docker rm -f "$DB" >/dev/null 2>&1 || true
    if [ "${PGMT_STORAGE:-volume}" = tmpfs ]; then
        storage="--tmpfs /var/lib/mysql:rw,size=3g"
    else
        storage="-v $VOLUME:/var/lib/mysql"
    fi
    # The slow log catches anything over 20 ms; performance_schema keeps the
    # per-statement digests the report ranks.
    # shellcheck disable=SC2086
    docker run -d --name "$DB" --network "$NET" -e MARIADB_ROOT_PASSWORD=root-local-only \
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
}

web_up() {
    mkdir -p "$SCRATCH/phplog"
    chmod 777 "$SCRATCH/phplog"
    docker network create "$NET" >/dev/null 2>&1 || true
    docker network connect "$NET" "$DB" >/dev/null 2>&1 || true
    docker rm -f "$PHP" "$WEB" >/dev/null 2>&1 || true
    [ -f "$SCRATCH/php-fpm.pid" ] && kill "$(cat "$SCRATCH/php-fpm.pid")" 2>/dev/null || true
    fill "$HERE/conf/config.php" "$CONFIG"
    fill "$HERE/conf/nginx.conf" "$SCRATCH/nginx.conf"
    if [ "$FPM_MODE" = host ]; then
        fill "$HERE/conf/php-fpm.conf" "$SCRATCH/php-fpm.conf"
        sleep 1
        /opt/homebrew/sbin/php-fpm --fpm-config "$SCRATCH/php-fpm.conf"
    else
        # A new database connection per request, as the service makes, runs a
        # container out of ephemeral ports past ~470 a second (TIME_WAIT); the
        # wider range and reuse keep the measurement about the service.
        docker run -d --name "$PHP" --network "$NET" -e PGMT_CHILDREN="$CHILDREN" \
            --sysctl net.ipv4.ip_local_port_range="1024 65535" --sysctl net.ipv4.tcp_tw_reuse=1 \
            -v "$SERVER:$SERVER:ro" -v "$SCRATCH/phplog:/var/log/pop" pg-mt-pop-php:8.3 >/dev/null
    fi
    docker run -d --name "$WEB" --network "$NET" -p 127.0.0.1:$WEB_PORT:80 \
        -v "$SERVER:$SERVER:ro" -v "$SCRATCH/nginx.conf:/etc/nginx/nginx.conf:ro" \
        nginx:1.27-alpine >/dev/null
    sleep 1
    echo "up: http://127.0.0.1:$WEB_PORT  (PHP-FPM $FPM_MODE, $CHILDREN children, storage ${PGMT_STORAGE:-volume})"
}

down() {
    docker rm -f "$DB" "$PHP" "$WEB" >/dev/null 2>&1 || true
    docker network rm "$NET" >/dev/null 2>&1 || true
    docker volume rm "$VOLUME" >/dev/null 2>&1 || true
    [ -f "$SCRATCH/php-fpm.pid" ] && kill "$(cat "$SCRATCH/php-fpm.pid")" 2>/dev/null || true
    rm -f "$CONFIG"
    echo down
}

case "${1:-}" in
    up) db_up; web_up ;;
    web) web_up ;;
    db) database "$2" "${3:-utf8mb4}" ;;
    sql) sql "$2" ;;
    down) down ;;
    *) echo "usage: $0 up|web|db NAME [charset]|sql SQL|down" >&2; exit 2 ;;
esac
