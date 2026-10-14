#!/bin/sh
#
# Put the site on peacegarden.app, and then check that what is served is what
# was meant.
#
#   tools/deploy.sh              upload, then check
#   tools/deploy.sh --dry-run    say what would change, touch nothing
#   tools/deploy.sh --check      check what is live, upload nothing
#
# `PG_BASE=http://127.0.0.1:8822 tools/deploy.sh --check` runs the same check
# against a local copy (tools/masstest/site/README.md says how to serve one),
# which is how a change to the rows is tried before it is trusted.
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
BASE=${PG_BASE:-https://peacegarden.app}
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
    #
    # `.api/config.php` is the plot service's database credentials, written on
    # the server and never in git, so it is the reverse case: a plain exclude,
    # to skip it here and keep `--delete` from removing the server's copy.
    # The plant renderer is built rather than committed — see .gitignore — so
    # a clone that has never run tools/wasm/build.sh has no copy of it, and
    # `--delete` would take the server's. The walk is then a night with no
    # plants in it, which looks like an empty garden rather than a failed
    # upload.
    if [ ! -f "$HERE/Server/.pages/PlantWasm.wasm.gz" ]; then
        echo "Server/.pages/PlantWasm.wasm.gz is missing. Run tools/wasm/build.sh first." >&2
        exit 1
    fi
    # A module built before `pg_name` grows every plant and names none, and the
    # plant panel on every area page then opens on nothing. Asked of the module
    # itself, because a file that exists says nothing about when it was built.
    if ! node -e 'const fs = require("fs"); const m = new WebAssembly.Module(fs.readFileSync(process.argv[1]));
        process.exit(WebAssembly.Module.exports(m).some((e) => e.name === "pg_name") ? 0 : 1)' \
        "$HERE/Server/.pages/PlantWasm.wasm"; then
        echo "Server/.pages/PlantWasm.wasm has no pg_name. Run tools/wasm/build.sh again." >&2
        exit 1
    fi

    # `-i`, because rsync names nothing it deletes without it (or `-v`), and the
    # sed then shows a clean run over a deletion: a dry run said nothing about
    # a `.api/config.php.bak` it was about to remove. Each deletion is a
    # `*deleting` line; the line `-i` also prints per changed file is dropped.
    rsync -a -i $dry --delete --stats \
        --exclude='.DS_Store' \
        --filter='-s /README.md' \
        --exclude='/.well-known/' \
        --exclude='/.api/config.php' \
        -e "ssh -o ConnectTimeout=20" \
        "$HERE/Server/" "$HOST:$ROOT/" | sed -n '/^\*deleting/p; /Number of .*files transferred/p'

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

# The response headers for a path: a HEAD, except under `/api/`, which is
# asked with a GET and its body thrown away. The plot service answers GET and
# nothing else (`route` in Server/.api/router.php), so a HEAD that reaches PHP
# as a HEAD is a 404 there, and whether one does depends on what stands in
# front of the host (a CDN may fetch a HEAD from the origin as a GET; a local
# copy does not). Asked as a browser asks, it means the same everywhere.
headers_of() {
    path=$1
    shift
    case "$path" in
        /api/*) curl -sS -D - -o /dev/null --max-time 25 "$@" "$BASE$path" ;;
        *)      curl -sSI --max-time 25 "$@" "$BASE$path" ;;
    esac
}

# path, wanted status, wanted content-type prefix
check_path() {
    path=$1
    want_status=$2
    want_type=$3

    headers=$(headers_of "$path")
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
check_path /                                       200 text/html
check_path /s                                      200 text/html
check_path /g                                      200 text/html
check_path /garden                                 200 text/html
check_path /download                               200 text/html
check_path /wild                                   200 text/html
check_path /walk                                   200 text/html
check_path /t                                      200 text/html
check_path /meanings                               200 text/html
# Every area page. A page absent from `Server/index.php`'s table answers 404
# here. The list stopped at the eighth, ninth and tenth until 14 October 2026,
# when the site's mass test found it read three of the ten
# (design/mass-test-2026-10-13/site/README.md, finding 8).
check_path /quiet                                  200 text/html
check_path /cross                                  200 text/html
check_path /orchard                                200 text/html
check_path /knot                                   200 text/html
check_path /seedbed                                200 text/html
check_path /frame                                  200 text/html
check_path /glasshouse                             200 text/html
check_path /coppice                                200 text/html
check_path /ground                                 200 text/html
# A mandatory App Store listing field (Server/index.php's table says so).
check_path /privacy                                200 text/html
check_path /.well-known/apple-app-site-association 200 application/json

# A sample of the static half, which nginx types from its own mime.types.
check_path /assets/site.css     200 text/css
check_path /assets/js/page.js   200 application/javascript
check_path /assets/js/frontpage.js 200 application/javascript
# The Long Walk's three modules and the two files the sky reads. `.wasm` and
# `.bin` are the ones worth naming: a host that does not know `application/wasm`
# serves the module as `application/octet-stream`, which
# `WebAssembly.instantiateStreaming` refuses, and the page is then a night with
# no plants in it and no error anybody sees.
check_path /assets/js/longwalk.js 200 application/javascript
check_path /assets/js/sky.js      200 application/javascript
check_path /assets/js/plant.js    200 application/javascript
check_path /plant.wasm            200 application/wasm
# The Glasshouse's two modules, and its plot service. The route answering
# JSON is the sign the service knows the area; the pages' routes are above.
check_path /assets/js/glasshouse.js     200 application/javascript
check_path /assets/js/glasshousepage.js 200 application/javascript
check_path /api/glasshouse              200 application/json
# And the Coppice's, the same three.
check_path /assets/js/coppice.js        200 application/javascript
check_path /assets/js/coppicepage.js    200 application/javascript
check_path /api/coppice                 200 application/json
# And the Home Ground's.
check_path /assets/js/ground.js         200 application/javascript
check_path /assets/js/groundpage.js     200 application/javascript
check_path /api/ground                  200 application/json
# The other seven areas' plot services and the Wild Fields', read the same
# way: JSON from the route is the sign the service knows the area.
check_path /api/walk                    200 application/json
check_path /api/quiet                   200 application/json
check_path /api/cross                   200 application/json
check_path /api/orchard                 200 application/json
check_path /api/knot                    200 application/json
check_path /api/seedbed                 200 application/json
check_path /api/frame                   200 application/json
check_path /api/wild                    200 application/json
# A plant's panel, which all ten area pages import: a page that cannot load
# it cannot load at all.
check_path /assets/js/plantpanel.js     200 application/javascript
# The shadows under every plant and beside every hedge, which the stage
# imports: a page that cannot load it cannot load at all.
check_path /assets/js/shadow.js         200 application/javascript
# The slab every plot hangs, which the stage and every area's ground import:
# the same again.
check_path /assets/js/slab.js           200 application/javascript
check_path /assets/places.json    200 application/json
check_path /assets/stars.bin      200 application/octet-stream
check_path /assets/icon.svg     200 image/svg+xml
check_path /assets/favicon.svg  200 image/svg+xml
check_path /assets/mark-dark.svg  200 image/svg+xml
check_path /assets/mark-light.svg 200 image/svg+xml
check_path /languages.json      200 application/json
check_path /strings/fr.json     200 application/json
check_path /passages/fr.json    200 application/json
check_path /favicon.ico         200 image/

# English is written into `strings.js` and has no file. `loadStrings` reads the
# status, so this 404 is the feature and a 200 here would be the bug.
check_path /strings/en.json     404 text/html

# Server/README.md is for whoever deploys, not for the site.
check_path /README.md           404 text/html

# The curator's tool is run over ssh and never as a page. nginx's dot rule
# refuses the whole of `.api/`; a 404 here would be PHP answering instead,
# which means the rule has gone and only the tool's own guard is left.
check_path /.api/curate.php     403 text/html

# path, header (lower case), what its value must contain ('-' for absent),
# then any extra arguments for the request
check_header() {
    path=$1
    name=$2
    want=$3
    shift 3
    value=$(headers_of "$path" "$@" \
        | awk -v n="$name:" 'tolower($1) == n { $1 = ""; sub(/^ /, ""); sub(/\r$/, ""); print; exit }')
    if { [ "$want" = - ] && [ -z "$value" ]; } \
        || { [ "$want" != - ] && case "$value" in *"$want"*) true ;; *) false ;; esac; }
    then
        printf '  ok    %-42s %s: %s\n' "$path" "$name" "${value:-(absent)}"
    else
        [ "$want" = - ] && wanted=absent || wanted=$want
        printf '  BAD   %-42s %s: %s   (wanted %s)\n' "$path" "$name" "${value:-(absent)}" "$wanted"
        fail=1
    fi
}

# **The headers PHP sends, since 14 October 2026** (the head of
# Server/index.php, and Server/README.md §Headers). The pages, the renderer
# and the plot service carry them; the static files are nginx's and carry
# none of these.
echo
echo "Headers"
check_header /          strict-transport-security max-age=
check_header /          content-security-policy   "default-src 'self'"
check_header /          referrer-policy           strict-origin-when-cross-origin
check_header /          x-content-type-options    nosniff
check_header /          x-powered-by              -
check_header /api/walk  x-powered-by              -

# The renderer at the address the pages ask for it by is kept for a year
# (finding L1 of the mass test: before this, every visit downloaded it again).
# The stamp is read from the front page, as a browser reads it.
module=$(curl -sS --max-time 25 "$BASE/" | sed -n 's/.*data-module="\([^"]*\)".*/\1/p' | head -n 1)
if [ -n "$module" ]; then
    check_header "$module"   cache-control immutable -H 'Accept-Encoding: gzip'
    check_header /plant.wasm cache-control no-cache  -H 'Accept-Encoding: gzip'
    # A revalidation of the bare address ought to be a 304. On 13 October it
    # came back 200 because the If-None-Match was lost in front of the host;
    # with the stamped address immutable that no longer costs a reader a
    # download, so this is said rather than failed.
    head=$(curl -sSI --max-time 25 -H 'Accept-Encoding: gzip' "$BASE/plant.wasm")
    tag=$(printf '%s' "$head" | awk 'tolower($1) == "etag:" { print $2; exit }' | tr -d '\r')
    since=$(printf '%s' "$head" | awk 'tolower($1) == "last-modified:" { $1 = ""; sub(/^ /, ""); print; exit }' | tr -d '\r')
    by_tag=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 25 -H 'Accept-Encoding: gzip' \
        -H "If-None-Match: $tag" "$BASE/plant.wasm")
    by_date=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 25 -H 'Accept-Encoding: gzip' \
        -H "If-Modified-Since: $since" "$BASE/plant.wasm")
    printf '  note  %-42s revalidated by tag %s, by date %s (304 is the hope)\n' /plant.wasm "$by_tag" "$by_date"
else
    printf '  BAD   %-42s no data-module on the front page\n' /
    fail=1
fi

# **Paths that visitors wear are on at the live site**, and the docs say so
# (Marcus, 14 October 2026: 18A). The switch is `'wear' => true` in the
# server's own `.api/config.php`, which this script never uploads, so only the
# far end can say whether it is on; `/api/wild` carries `wear` exactly when it
# is. If wear is ever turned off on purpose, change this row and the docs that
# say it is on (Server/README.md, docs/WEB-GARDENS.md) in the same commit.
echo
echo "Paths that visitors wear, and the app's iOS"
if curl -sS --max-time 25 "$BASE/api/wild" | grep -q '"wear":{'; then
    printf '  ok    %-42s wear is on, as the docs say\n' /api/wild
else
    printf '  BAD   %-42s wear is off, and the docs say it is on\n' /api/wild
    fail=1
fi

# The download page names the iOS the app needs, which is project.yml's
# deploymentTarget. It named a build number until 14 October 2026, and that
# went stale without anybody touching the page.
ios=$(awk '/deploymentTarget:/ { getline; gsub(/[^0-9.]/, ""); print; exit }' "$HERE/project.yml")
major=${ios%%.*}
if curl -sS --max-time 25 "$BASE/download" | grep -q "iOS $major and later"; then
    printf '  ok    %-42s says iOS %s and later\n' /download "$major"
else
    printf '  BAD   %-42s does not say iOS %s and later (project.yml: %s)\n' /download "$major" "$ios"
    fail=1
fi

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
