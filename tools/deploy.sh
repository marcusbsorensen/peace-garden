#!/bin/sh
#
# Put the site on peacegarden.app, and then check that what is served is what
# was meant.
#
#   tools/deploy.sh              upload, then check
#   tools/deploy.sh --dry-run    say what would change, touch nothing
#   tools/deploy.sh --check      check what is live, upload nothing
#
# Needs the `peacegarden` host in ~/.ssh/config and its key registered in
# My20i -> peacegarden.app -> Security -> SSH Access. Until it is registered,
# ssh answers "Permission denied (publickey)". A connection *reset* instead
# means the IP allowlist on that same page, which gates SSH before auth.
#
# **The check is the point.** Every failure this site has had at the host has
# been a 200 with the wrong `Content-Type` on it: the request succeeds, the log
# is clean, and the browser saves a file instead of drawing a page. Nothing
# short of reading the header at the far end catches that, so this reads it
# every time rather than trusting the upload.
set -eu

HOST=peacegarden
ROOT=public_html
BASE=https://peacegarden.app
HERE=$(cd "$(dirname "$0")/.." && pwd)

upload=yes
check=yes
dry=""
case "${1:-}" in
    --dry-run) dry="--dry-run" ;;
    --check)   upload=no ;;
    "")        ;;
    *) echo "usage: $0 [--dry-run|--check]" >&2; exit 2 ;;
esac

if [ "$upload" = yes ]; then
    echo "Uploading $HERE/Server/ to $HOST:$ROOT/"

    # `--delete`, because the failure it prevents is invisible. A file left at
    # `/s` from an older upload wins at nginx's `try_files` and is served as a
    # download; `index.php` is never reached and nothing in any log says why.
    #
    # `.well-known/` is the one directory the host owns: certificate renewal
    # writes an ACME challenge into it and would find it deleted. The
    # association file moved out of there and into `.pages/` when `/s` did —
    # see Server/index.php for why none of the four can sit at its own path —
    # so there is nothing of ours left in it to sync.
    #
    # `README.md` is how to run this, addressed to whoever is deploying. It is
    # not addressed to a reader of the site and should not be on it. The rule
    # carries `s` — sender only — because a plain `--exclude` protects a file at
    # the far end from `--delete` as well as skipping it here, so an earlier
    # upload's copy would sit there being served for as long as the exclude
    # existed. It did, and this check caught it.
    rsync -a $dry --delete --stats \
        --exclude='.DS_Store' \
        --filter='-s /README.md' \
        --exclude='/.well-known/' \
        -e "ssh -o ConnectTimeout=20" \
        "$HERE/Server/" "$HOST:$ROOT/" | sed -n '/^deleting/p; /Number of files transferred/p'

    if [ -z "$dry" ]; then
        # One-off left over from the upload that predates `index.php`: a static
        # association file at its served path wins at `try_files` the same way
        # a static `/s` would, and would go on being served as
        # `application/octet-stream`.
        ssh -o ConnectTimeout=20 "$HOST" \
            "rm -f '$ROOT/.well-known/apple-app-site-association' '$ROOT/.well-known/.htaccess'"
    fi

    [ -n "$dry" ] && { echo; echo "Dry run. Nothing was uploaded."; exit 0; }
    echo
fi

[ "$check" = yes ] || exit 0

echo "Checking what is actually served"
fail=0

# path, wanted status, wanted content-type prefix
check_path() {
    path=$1
    want_status=$2
    want_type=$3

    headers=$(curl -sSI --max-time 25 "$BASE$path")
    status=$(printf '%s' "$headers" | awk 'NR==1 {print $2}')
    type=$(printf '%s' "$headers" | awk 'tolower($1) == "content-type:" {print tolower($2)}')

    if [ "$status" = "$want_status" ] && case "$type" in "$want_type"*) true ;; *) false ;; esac
    then
        printf '  ok    %-42s %s  %s\n' "$path" "$status" "$type"
    else
        printf '  BAD   %-42s %s  %s   (wanted %s %s)\n' \
            "$path" "$status" "$type" "$want_status" "$want_type"
        fail=1
    fi
}

# The four with no extension. `application/octet-stream` on any of them means
# a file is sitting at that path and nginx is serving it before index.php.
check_path /s                                      200 text/html
check_path /g                                      200 text/html
check_path /t                                      200 text/html
check_path /.well-known/apple-app-site-association 200 application/json

# A sample of the static half, which nginx types from its own mime.types.
check_path /assets/site.css     200 text/css
check_path /assets/js/page.js   200 application/javascript
check_path /assets/icon.svg     200 image/svg+xml
check_path /languages.json      200 application/json
check_path /strings/fr.json     200 application/json
check_path /passages/fr.json    200 application/json
check_path /favicon.ico         200 image/

# English is written into `strings.js` and has no file. `loadStrings` reads the
# status, so this 404 is the feature and a 200 here would be the bug.
check_path /strings/en.json     404 text/html

# Server/README.md is for whoever deploys, not for the site.
check_path /README.md           404 text/html

echo
echo "The association file iOS will actually read"
aasa=$(curl -sS --max-time 25 "$BASE/.well-known/apple-app-site-association")
if printf '%s' "$aasa" | python3 -m json.tool >/dev/null 2>&1; then
    appid=$(printf '%s' "$aasa" | python3 -c \
        'import json,sys; print(json.load(sys.stdin)["applinks"]["details"][0]["appIDs"][0])')
    printf '  appID         %s\n' "$appid"
    team=${appid%%.*}
    if ! grep -q "DEVELOPMENT_TEAM: $team" "$HERE/project.yml"; then
        echo "  ! The Team ID here does not match project.yml. iOS declines the"
        echo "    domain silently when they disagree."
        fail=1
    fi
else
    echo "  ! Not valid JSON at the far end."
    fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "Served correctly."
    echo "Apple's CDN caches the association file for up to a day, so a seed link"
    echo "on a device is a test for tomorrow rather than for now:"
    echo "  curl -sSI https://app-site-association.cdn-apple.com/a/v1/peacegarden.app"
else
    echo "Not right yet. Server/README.md has the rules and the ways round them."
    exit 1
fi
