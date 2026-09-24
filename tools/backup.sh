#!/bin/sh
#
# Keep a copy of the Long Walk somewhere the Long Walk is not, and prove it
# comes back.
#
#   tools/backup.sh                 take a copy now, then pull everything down
#   tools/backup.sh --pull          pull what is already there, take nothing
#   tools/backup.sh --prune         drop the Mac's copies older than thirty
#                                   days, pull nothing
#   tools/backup.sh --install-launchd    have this Mac run --prune once a day
#   tools/backup.sh --uninstall-launchd  stop it
#   tools/backup.sh --install-cron  set the server taking one a day, and
#                                   sweeping every five minutes (sweep.php)
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
# **Thirty days, here as on the server** (24 September, Marcus's call). Every
# copy holds whatever the garden held that night — plants since taken back
# included — and the privacy page says the site's backups keep what they held
# for thirty days. So the copies here older than thirty days are deleted, by
# the date in their names: after every pull that succeeds, and once a day by
# launchd whether or not anybody pulls (`--install-launchd`). The newest is
# never deleted, however old: a Mac that has not pulled for two months keeps
# the last copy it has rather than none. Time Machine and iCloud keep their own
# history of this folder, which this cannot reach; see Server/README.md.
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
# In Application Support rather than Documents, since 24 September 2026:
# macOS keeps a background job out of ~/Documents, so the daily prune was
# refused there, and Documents is also what iCloud syncs, which kept a history
# of every copy that nothing here could prune.
INTO=${PG_BACKUPS:-$HOME/Library/Application Support/Peace Garden backups}

# How long a pulled copy is kept. `KEEP_DAYS` in Server/.api/backup.php is the
# server's, and the two are the same number on purpose.
KEEP_DAYS=30

# The database the copies came from, so the test restores into its own kind.
IMAGE=mariadb:10.11

# Loopback only, and a port nothing in this house is using.
PORT=33061

# The daily prune's launchd job: its label, its template, and where a user's
# agents live. `PG_LAUNCHCTL` stands a recorder in for launchctl, which is how
# the job is tested without loading anything into this Mac's own session.
LABEL=app.peacegarden.prune-backups
TEMPLATE="$HERE/tools/launchd/$LABEL.plist"
AGENTS="$HOME/Library/LaunchAgents"
LAUNCHCTL=${PG_LAUNCHCTL:-launchctl}

usage() {
    echo "usage: $0 [--pull|--prune|--install-launchd|--uninstall-launchd|--install-cron|--restore-test [file]|--rehearse]" >&2
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
    # No `--delete`, so a copy the server has just pruned is not taken from here
    # in the same breath; this folder's own thirty days are `prune`'s to keep.
    # Thirty days still reaches past a fortnight, which is the case the history
    # is for: a row quietly wrong for a fortnight is only recoverable from a copy
    # older than the fortnight.
    #
    # The status is rsync's, not the filter's: a pull that failed must not be
    # followed by a prune, or a Mac cut off from the server would delete its
    # copies one day at a time and fetch none.
    if ! stats=$(rsync -a --stats -e "ssh -o ConnectTimeout=20" "$HOST:$REMOTE/" "$INTO/"); then
        echo "The pull did not finish, so nothing here was pruned." >&2
        exit 1
    fi
    printf '%s\n' "$stats" | sed -n '/Number of files transferred/p'
    prune
    echo
    ls -lh "$INTO" | tail -5
}

# Drops the copies here older than KEEP_DAYS, by the stamp in their names —
# `walk-2026-09-24T031700Z.sql.gz`, which sorts as the date does — and never the
# newest. A file whose name carries no stamp is left alone: it is not a copy
# this script made, so it is not this script's to delete.
prune() {
    [ -d "$INTO" ] || return 0
    newest=$(ls -1 "$INTO" | grep -E '^walk-[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{6}Z\.sql\.gz$' | tail -1 || true)
    [ -n "$newest" ] || return 0
    cutoff=$(date -u -v-"$KEEP_DAYS"d +%Y-%m-%dT%H%M%SZ)
    dropped=0
    for copy in "$INTO"/walk-*.sql.gz; do
        name=$(basename "$copy")
        [ "$name" = "$newest" ] && continue
        case "$name" in
            walk-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z.sql.gz) ;;
            *) continue ;;
        esac
        stamp=${name#walk-}
        stamp=${stamp%.sql.gz}
        # `expr` compares two strings that are not numbers as strings, and
        # these stamps compare as strings exactly as they do as dates.
        if expr "$stamp" \< "$cutoff" > /dev/null; then
            rm -f -- "$copy"
            dropped=$((dropped + 1))
        fi
    done
    echo "Dropped $dropped cop$([ "$dropped" -eq 1 ] && echo y || echo ies) older than $KEEP_DAYS days; kept $newest and everything newer than $cutoff"
}

install_cron() {
    # 03:17, because every service on a shared box runs on the hour and the
    # database is quietest between them.
    install_line 'backup.php' \
        '17 3 * * * /usr/bin/php $HOME/public_html/.api/backup.php >> $HOME/backups/backup.log 2>&1'
    # And the clean-up every five minutes: ended rate-limit windows and
    # thirty-day offers, for the hours nobody asks the service anything. Five
    # because a window is fifty-five minutes and the privacy page says an hour.
    # See Server/.api/sweep.php.
    install_line 'sweep.php' \
        '*/5 * * * * /usr/bin/php $HOME/public_html/.api/sweep.php >> $HOME/backups/sweep.log 2>&1'
}

# One line in the server's crontab, added once: a second run finds it there.
install_line() {
    name=$1
    line=$2
    ssh -o ConnectTimeout=20 "$HOST" "
        set -eu
        mkdir -p \$HOME/backups
        # The || true matters: with no crontab yet, crontab -l exits 1, and
        # under set -e that ends the group before the new line is echoed,
        # which installs an empty crontab and says it worked.
        # (No backticks in here. This whole script is inside double quotes on
        # the way to the far end, so a pair of them runs on the Mac instead.)
        if crontab -l 2>/dev/null | grep -q '$name'; then
            echo 'Already there:'
        else
            { crontab -l 2>/dev/null || true; echo '$line'; } | crontab -
            echo 'Installed:'
        fi
        crontab -l | grep '$name' || { echo 'but it is not there.' >&2; exit 1; }
    "
}

# MARK: The daily prune on this Mac

# Fills the template's two paths in, for a sed replacement: a backslash, the
# `|` delimiter and `&` would each mean something to sed, and `&` and `<`
# something to the plist, so all of them are escaped.
plist_path() {
    printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/[\\|&]/\\&/g'
}

# Puts the job in ~/Library/LaunchAgents and loads it into this user's session.
# Idempotent: the same job already loaded is left alone and said to be there; a
# changed one (the checkout moved, `$PG_BACKUPS` changed) is unloaded and loaded
# again. Run it from the checkout that will stay: the job runs *this*
# backup.sh, and a worktree that is later removed takes the job's script with it.
install_launchd() {
    target="$AGENTS/$LABEL.plist"
    domain="gui/$(id -u)"
    mkdir -p "$AGENTS" "$INTO"
    made=$(mktemp)
    sed -e "s|@BACKUP_SH@|$(plist_path "$HERE/tools/backup.sh")|g" \
        -e "s|@BACKUPS@|$(plist_path "$INTO")|g" "$TEMPLATE" > "$made"
    plutil -lint -s "$made" || { rm -f "$made"; echo "The job would not be a valid plist." >&2; exit 1; }

    if [ -f "$target" ] && cmp -s "$made" "$target" && "$LAUNCHCTL" print "$domain/$LABEL" > /dev/null 2>&1; then
        rm -f "$made"
        echo "Already there: $target, loaded as $LABEL"
        return 0
    fi
    # Unloaded first, because bootstrap refuses a label that is already loaded
    # and a job loaded from an older file would go on running the old one.
    "$LAUNCHCTL" bootout "$domain/$LABEL" > /dev/null 2>&1 || true
    mv "$made" "$target"
    chmod 644 "$target"
    "$LAUNCHCTL" bootstrap "$domain" "$target"
    echo "Installed: $target, loaded as $LABEL. It prunes $INTO daily at 09:41;"
    echo "its log is $INTO/prune.log."
}

# Unloads the job and removes its file. Nothing to remove is not a failure.
uninstall_launchd() {
    target="$AGENTS/$LABEL.plist"
    "$LAUNCHCTL" bootout "gui/$(id -u)/$LABEL" > /dev/null 2>&1 || true
    if [ -f "$target" ]; then
        rm -f "$target"
        echo "Removed: $target"
    else
        echo "Not installed: nothing at $target"
    fi
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
    --prune)        prune ;;
    --install-launchd)   install_launchd ;;
    --uninstall-launchd) uninstall_launchd ;;
    --install-cron) install_cron ;;
    --restore-test) restore_test "${2:-}" ;;
    --rehearse)     rehearse ;;
    *)              usage ;;
esac
