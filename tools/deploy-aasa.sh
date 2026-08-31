#!/bin/sh
#
# Put the association file on peacegarden.app, and then check that the thing
# iOS actually reads is the thing we meant to serve.
#
#   tools/deploy-aasa.sh
#
# Needs the `peacegarden` host in ~/.ssh/config and its key registered in
# My20i -> peacegarden.app -> Security -> SSH Access. Until it is registered,
# ssh answers "Permission denied (publickey)". A connection *reset* instead
# means the IP allowlist on that same page, which gates SSH before auth.
set -eu

HOST=peacegarden
ROOT=public_html
HERE=$(cd "$(dirname "$0")/.." && pwd)
URL=https://peacegarden.app/.well-known/apple-app-site-association

echo "Uploading to $HOST:$ROOT/.well-known/"
ssh "$HOST" "mkdir -p '$ROOT/.well-known'"
scp -q "$HERE/Server/.well-known/apple-app-site-association" "$HOST:$ROOT/.well-known/"
scp -q "$HERE/Server/.well-known/.htaccess" "$HOST:$ROOT/.well-known/"

echo
echo "Checking what is actually served"

# Apple's CDN caches this for up to a day, so this check is of the origin and
# of nothing else. Devices may keep seeing the old answer well after it passes.
headers=$(curl -sSI "$URL")
status=$(printf '%s' "$headers" | awk 'NR==1 {print $2}')
type=$(printf '%s' "$headers" | awk 'tolower($1) == "content-type:" {print $2}')

printf '  status        %s\n' "$status"
printf '  content-type  %s\n' "$type"

fail=0
case "$status" in
    200) ;;
    30*) echo "  ! A redirect. iOS follows none of them, not even http to https."; fail=1 ;;
    *)   echo "  ! Wanted 200."; fail=1 ;;
esac

case "$type" in
    application/json*) ;;
    *) echo "  ! Wanted application/json. The .htaccess beside the file forces it;"
       echo "    if it is still wrong, the host is ignoring .htaccess overrides."
       fail=1 ;;
esac

if curl -sS "$URL" | python3 -m json.tool >/dev/null 2>&1; then
    appid=$(curl -sS "$URL" | python3 -c 'import json,sys; print(json.load(sys.stdin)["applinks"]["details"][0]["appIDs"][0])')
    printf '  appID         %s\n' "$appid"
    grep -q "$appid" "$HERE/project.yml" 2>/dev/null || {
        team=${appid%%.*}
        grep -q "DEVELOPMENT_TEAM: $team" "$HERE/project.yml" || {
            echo "  ! The Team ID here does not match project.yml. iOS declines the"
            echo "    domain silently when they disagree."
            fail=1
        }
    }
else
    echo "  ! Not valid JSON at the far end."
    fail=1
fi

echo
if [ "$fail" -eq 0 ]; then
    echo "Served correctly. Apple's CDN may take up to a day to catch up,"
    echo "so test seed links tomorrow rather than now."
else
    echo "Not right yet. Server/README.md has the rules and the ways round them."
    exit 1
fi
