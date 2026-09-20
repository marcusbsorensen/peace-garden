#!/bin/sh
#
# Keep a copy of the Long Walk somewhere the Long Walk is not, and prove it
# comes back.
#
#   tools/backup.sh                 take a copy now, then pull everything down
#   tools/backup.sh --pull          pull what is already there, take nothing
#   tools/backup.sh --install-cron  set the server taking one a day
#   tools/backup.sh --restore-test  load the newest copy into an empty database
#                                   and replay the walk out of it
#   tools/backup.sh --rehearse      the same, on a walk made for the purpose,
#                                   so the test has teeth while the real walk
#                                   is still empty
#
# **Why the pull is half the job.** `Server/.api/backup.php` writes its copies
# into `~/backups` on the 20i account, which is the same disk, the same
# provider and the same billing relationship as the database. That copy is for
# the ordinary accident — a bad migration, a row deleted by hand. The copy that
# matters for the other kind lives here, on the Mac, where Time Machine and
# iCloud can reach it.
#
# **Why there is a restore test at all.** A backup nobody has restored is a
# belief about a file. The test is not that the file exists or that it is
# valid gzip; it is that the walk comes back *as the same walk* — every plant
# in the place the rule gave it, in the order arrivals came in. See
# `tools/reference/check_restore.php`.
set -eu

HOST=peacegarden
REMOTE=backups
HERE=$(cd "$(dirname "$0")/.." && pwd)
INTO=${PG_BACKUPS:-$HOME/Documents/Peace Garden backups}

# The database the copies came from, so the test restores into its own kind.
IMAGE=mariadb:10.11

# Loopback only, and a port nothing in this house is using.
PORT=33061

usage() {
    echo "usage: $0 [--pull|--install-cron|--restore-test [file]|--rehearse]" >&2
    exit 2
}

# MARK: Taking and pulling

take() {
    echo "Taking a copy on $HOST"
    ssh -o ConnectTimeout=20 "$HOST" "php ~/public_html/.api/backup.php"
}

pull() {
    mkdir -p "$INTO"
    echo "Pulling into $INTO"
    # No `--delete`: the server keeps the last thirty and this keeps all of
    # them. The history is the point — a row quietly wrong for a fortnight is
    # only recoverable from a copy older than the fortnight.
    rsync -a --stats \
        -e "ssh -o ConnectTimeout=20" \
        "$HOST:$REMOTE/" "$INTO/" | sed -n '/Number of files transferred/p'
    echo
    ls -lh "$INTO" | tail -5
}

install_cron() {
    # 03:17, because every service on a shared box runs on the hour and the
    # database is quietest between them.
    line='17 3 * * * /usr/bin/php $HOME/public_html/.api/backup.php >> $HOME/backups/backup.log 2>&1'
    ssh -o ConnectTimeout=20 "$HOST" "
        set -eu
        mkdir -p \$HOME/backups
        # The || true matters: with no crontab yet, crontab -l exits 1, and
        # under set -e that ends the group before the new line is echoed,
        # which installs an empty crontab and says it worked.
        # (No backticks in here. This whole script is inside double quotes on
        # the way to the far end, so a pair of them runs on the Mac instead.)
        if crontab -l 2>/dev/null | grep -q 'backup.php'; then
            echo 'Already there:'
        else
            { crontab -l 2>/dev/null || true; echo '$line'; } | crontab -
            echo 'Installed:'
        fi
        crontab -l | grep 'backup.php' || { echo 'but it is not there.' >&2; exit 1; }
    "
}

# MARK: The restore test

start_database() {
    name=peace-garden-restore-test
    docker rm -f "$name" >/dev/null 2>&1 || true

    # A throwaway database on a port nothing else wants, with no password and
    # nothing but this Mac's loopback able to reach it. It lives for the length
    # of this test and is removed however the test ends.
    docker run -d --name "$name" \
        -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=yes \
        -p 127.0.0.1:$PORT:3306 "$IMAGE" >/dev/null
    trap 'docker rm -f peace-garden-restore-test >/dev/null 2>&1 || true' EXIT

    # Asked over the socket inside the container, this answers yes while the
    # image is still setting itself up, because the server it is talking to is
    # the entrypoint's temporary one and has no network at all. So the question
    # is asked from here, over the port the test will actually use.
    printf '  waiting for the database'
    i=0
    while [ $i -lt 90 ]; do
        if php -r 'try { new PDO("mysql:host=127.0.0.1;port=" . $argv[1], "root", ""); }
                   catch (Throwable) { exit(1); }' "$PORT" 2>/dev/null; then
            echo
            return 0
        fi
        printf '.'
        sleep 1
        i=$((i + 1))
    done
    echo
    echo "  the database never came up" >&2
    exit 1
}

restore_test() {
    copy=${1:-}
    if [ -z "$copy" ]; then
        copy=$(ls -1 "$INTO"/walk-*.sql.gz 2>/dev/null | tail -1 || true)
    fi
    [ -n "$copy" ] || { echo "No copy to test. Run $0 first." >&2; exit 1; }
    [ -f "$copy" ] || { echo "No such copy: $copy" >&2; exit 1; }

    needs_docker
    echo "Testing $(basename "$copy")"
    start_database
    load_and_check "$copy"
}

# **Why rehearse at all.** A restore test can only test what is in the copy, and
# the real walk is empty until two people have met, agreed and planted. A test
# that passes because there was nothing to get wrong is a test that will go on
# passing after it stops working. So this sows a walk of its own — enough
# arrivals to fill a plot and start another, some of them taken back — takes a
# copy of it with the same script cron runs, and puts that copy through the same
# check.
rehearse() {
    needs_docker
    echo "Rehearsing on a walk made for it"
    start_database

    docker exec peace-garden-restore-test mariadb -uroot -e 'CREATE DATABASE sown;'
    sown="mysql:host=127.0.0.1;port=$PORT;dbname=sown;charset=utf8mb4"
    php "$HERE/tools/reference/check_restore.php" --sow "$sown" root '' 24

    # The copy is taken with the database's own dumper, inside the container,
    # because there is no MySQL client on this Mac. The table list and the
    # preamble come from backup.php all the same, so there is one idea of what
    # a copy holds rather than two that can drift apart.
    made=$(mktemp -d)
    copy="$made/walk-rehearsal.sql.gz"
    tables=$(PG_WALK_DSN="$sown" PG_WALK_USER=root php "$HERE/Server/.api/backup.php" --tables)
    {
        PG_WALK_DSN="$sown" PG_WALK_USER=root php "$HERE/Server/.api/backup.php" --preamble
        # shellcheck disable=SC2086
        docker exec peace-garden-restore-test mariadb-dump -uroot \
            --single-transaction --skip-lock-tables --no-tablespaces --no-create-db \
            --hex-blob --default-character-set=utf8mb4 sown $tables
    } | gzip -9 > "$copy"

    load_and_check "$copy"

    # **And that the check can fail.** A restore test nobody has seen fail is
    # the same belief as a backup nobody has restored. So the restored walk is
    # damaged the way a bad restore damages one — an arrival missing out of the
    # middle, which leaves every row after it individually plausible and the
    # walk wrong — and the check has to say so.
    echo
    echo "  and again with an arrival taken out of the middle"
    docker exec peace-garden-restore-test mariadb -uroot \
        -e 'DROP DATABASE IF EXISTS replayed; CREATE DATABASE replayed;
            DELETE FROM restored.long_walk WHERE arrival =
              (SELECT a FROM (SELECT arrival a FROM restored.long_walk
                              ORDER BY arrival LIMIT 1 OFFSET 8) middle);'
    if php "$HERE/tools/reference/check_restore.php" "$copy" \
        "mysql:host=127.0.0.1;port=$PORT;dbname=restored;charset=utf8mb4" \
        "mysql:host=127.0.0.1;port=$PORT;dbname=replayed;charset=utf8mb4" \
        root '' > /dev/null 2>&1
    then
        echo "  The check passed a walk with a plant missing. It is not a check." >&2
        exit 1
    fi
    echo "  caught it."
}

load_and_check() {
    copy=$1
    docker exec peace-garden-restore-test mariadb -uroot \
        -e 'DROP DATABASE IF EXISTS restored; DROP DATABASE IF EXISTS replayed;
            CREATE DATABASE restored; CREATE DATABASE replayed;'

    echo "  loading the copy"
    gunzip -c "$copy" | docker exec -i peace-garden-restore-test mariadb -uroot restored

    php "$HERE/tools/reference/check_restore.php" \
        "$copy" \
        "mysql:host=127.0.0.1;port=$PORT;dbname=restored;charset=utf8mb4" \
        "mysql:host=127.0.0.1;port=$PORT;dbname=replayed;charset=utf8mb4" \
        root ''
}

needs_docker() {
    docker info >/dev/null 2>&1 && return 0
    echo "The restore test needs Docker running, because the database it"
    echo "restores into has to be the kind the copy came from and there is"
    echo "no MariaDB on this Mac. Start it, then run this again:"
    echo
    echo "  open -a OrbStack"
    exit 1
}

case "${1:-}" in
    "")             take; echo; pull ;;
    --pull)         pull ;;
    --install-cron) install_cron ;;
    --restore-test) restore_test "${2:-}" ;;
    --rehearse)     rehearse ;;
    *)              usage ;;
esac
