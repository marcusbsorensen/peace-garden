# Serving peacegarden.app

Two jobs. Convince iOS that this app owns this domain, so a seed link opens the
app instead of a web page — and answer everybody else, on `/s`, with the page a
seed lands on.

## What goes where

```
peacegarden.app/
├── index.php                          ← serves the four paths below
├── .pages/                            ← nginx refuses a dot-directory
│   ├── s                              ← the page a seed lands on
│   ├── g                              ← the garden, walked
│   ├── t                              ← the test roster
│   └── apple-app-site-association     ← no file extension, and none is added
├── .htaccess                          ← for a host that reads one. This is not.
├── languages.json                     ← generated: tools/site/export.py
├── testers.json                       ← generated: one gardener per language
├── passages/<code>.json               ← generated: one bank per language
├── strings/<code>.json                ← the site's own words, per language
└── assets/
    ├── site.css
    ├── mark.svg                       ← a copy of tools/icon/icon.svg
    └── js/
        ├── page.js                    ← the /s page
        ├── walk.js                    ← the /g page
        ├── door.js                    ← the /t page
        ├── link.js                    ← reads the fragment
        ├── languages.js               ← negotiation and the chooser
        ├── strings.js                 ← the catalogue, English written
        ├── testers.js                 ← standing in another language
        ├── garden.js, plots.js        ← the map, and what stands on it
        ├── keys.js                    ← the keyboard, and the sheet under ?
        └── passages.js                ← theme, subtheme, and the draw
```

Almost everything is a file. No build step, no framework, no npm, and one
twenty-line PHP script whose whole job is to put a `Content-Type` on four
paths. Deploy with:

    tools/deploy.sh

That uploads this directory and then reads the headers back, which is the half
that matters — see **Deploying** below.

**`s` has no file extension on purpose.** It is the path every seed link
already points at and the path the association file claims, so it cannot grow a
`.html`.

**peacegarden.app does not read `.htaccess`.** This was the design's one
assumption and it is wrong on this host. The 20i vhost is nginx talking
straight to PHP-FPM: there is no Apache in the chain, and no `.htaccess`
anywhere under the document root is ever consulted. Checked on 4 September 2026
by putting a `RewriteRule` to a known-good path and a `Header always set` in
one, at the document root and one directory down, and watching neither happen.

The symptom is the one this file already warned about in another form: `/s`,
`/g`, `/t` and the association file all arrived as `application/octet-stream`,
so a browser saved the page instead of drawing it. Every request was a 200 and
every log line was clean.

**So `index.php` serves those four**, because the same nginx vhost offers
exactly that and nothing else:

    location / { try_files $uri $uri/ @dispatch; }
    location @dispatch { if (-f $document_root/index.php) { rewrite ^ /index.php last; } }

A path with no file behind it reaches `index.php` with `REQUEST_URI` intact.
Which is why the four live in `.pages/` rather than at the paths they are
served at: a file at `/s` wins at `try_files` and is served as a download
again, and `index.php` never sees the request. The leading dot is not
decoration — nginx's own `location ~ /\.(?!well-known(?:/|$)) { deny all; }`
makes the directory unreachable from outside, so each page has one address
rather than two.

**Every page added here has to be added to `ROUTES` in `index.php`** — and to
`PAGES` in `tools/site/serve.py`, which is the same four rows in Python. `g`
was missing from the old list once and arrived as a download; nothing said so.
Serve the directory locally the way the host serves it before believing a page
works:

    python3 tools/site/serve.py

That is the reason it exists rather than `python3 -m http.server`, which types
a file by its extension and so cannot draw any of the three pages.

**The cost is that four paths now need PHP.** Static files did not. It is the
trade the host leaves available: `/s` is in every link already minted and
cannot grow an extension, so either something sets the header or the header is
wrong. If PHP is ever unavailable, the association file — and only that one —
can go back to `.well-known/` as a static file and be served with the wrong
type; Apple's CDN parsed it happily for the four days it was, reporting
`Apple-Origin-Format: json` while the origin said `application/octet-stream`.
That is Apple being lenient about a rule Apple documents, and it is a fallback
rather than a plan.

**Getting `.htaccess` honoured instead** would mean 20i moving this site off
its nginx-only config, which is a support request rather than anything in this
repository. It would make `.htaccess` here do the routing — it is written to
send the same four paths to `index.php` either way, so one mechanism would
still serve them and the two hosts could not disagree about what `/s` is.

**`/t` is the test roster** — forty-three gardeners, one per language, for
looking at the site from where a reader of it stands. There are no accounts
behind it: `assets/js/testers.js` opens with what a tester is and why a static
site has nobody to log in. It is `noindex, nofollow`, it guards nothing, and it
can ship or be left out of an upload without anything else noticing.

**`mark.svg` is a copy.** `tools/icon/make_icon.py` writes the canonical
drawing at `tools/icon/icon.svg`; this is that file, copied. Change the dials
and re-run the generator, then copy it here again. Do not hand-edit either one.
**SEAM:** a deploy script that re-copies it is what would keep the two from
drifting, and there is not one yet.

**This README is not uploaded.** `tools/deploy.sh` excludes it and deletes it
if an earlier upload left one there, which one had. It is addressed to whoever
is deploying rather than to a reader of the site.

**Two deploy steps that are settings rather than files:**

- **Request logging on `/s`.** docs/WEBSITE.md asks for none, or the shortest
  the host permits. That is a 20i control-panel setting. Nothing on the page
  claims more than what is actually switched off, and nothing should. Note that
  `/s` is now a PHP request rather than a static one, so it appears in whatever
  the host logs for PHP as well.
- **The root.** `peacegarden.app/` still answers 403, and `index.php` returns
  that 403 deliberately: with an index in place the root would otherwise become
  whatever the script did next. `/s` with no seed in it is the page that says
  what Peace Garden is, so what the root should do is the open question in
  docs/WEBSITE.md about whether there is a marketing page at all — left alone
  rather than answered with a redirect.

## What the next page reuses

`/p/…`, the shared plant page, is phase 2 and is not here. What is here is the
half of it that has nothing to do with a service, and it is deliberately in
modules of its own rather than inside the `/s` page:

| | |
| --- | --- |
| `languages.js` | negotiation, the chooser, the written-case list |
| `strings.js` | the catalogue and the silent English fallback |
| `passages.js` | theme and subtheme off a name, and the draw |

A plant page reads the same manifest and picks its passage the same way. What
it adds is a plot service — **same-origin on 20i, decided 2 September**, so a
plant page fetches `/api/…` on this host rather than reaching another domain.
That is worth writing down where somebody will look for it: it means the page
has no cross-origin story to design, and it means a request to the service is a
request to the same log as everything else. The fragment property that `/s`
depends on is a property of `/s` alone, because `/p` publishes its payload on
purpose.

## Checking the page

```sh
tools/deploy.sh --check
```

That reads the headers on every path that has ever been served with the wrong
one, and on a sample of the ones nginx types from its own `mime.types`. Wanted
on `/s`: `HTTP/2 200` and `content-type: text/html`. `application/octet-stream`
means a file is sitting at that path and nginx is serving it before
`index.php`, so the page will download rather than draw.

Two of the rows are 404s on purpose, and a 200 on either is the failure:
`/strings/en.json`, because English is written into `strings.js` and
`loadStrings` reads the status; and `/README.md`, because this file belongs to
whoever deploys.

The fragment is the payload and never reaches the server, so a seed can only be
tested in a browser. Any link the app mints will do; `assets/js/link.js` also
carries `PINNED`, the same fragment `PollenLinkTests` and `tools/reference/`
both agree on, which is a valid offer from *Marcus* of *Aurelia nocturna*.

## Already filled in

The Team ID (`R94VDZ56RY`) and bundle identifier (`app.peacegarden`) are in the
file. If either changes in `project.yml`, it changes here too — they have to
agree or iOS silently declines to associate the domain.

The `appclips` entry names the clip's bundle ID, which by convention is the
app's with `.Clip` appended. It is harmless to serve before the App Clip target
exists — iOS simply finds nothing to invoke.

## The rules iOS actually enforces

These are the ones that quietly break associated domains:

- **No file extension.** `apple-app-site-association`, not `.json`.
- **Served as `application/json`.** Some hosts guess `text/plain` for an
  extensionless file and iOS rejects it.
- **HTTPS, valid certificate, no redirects.** Not even http → https. The file
  must be at the final URL directly.
- **No authentication.** Not behind a login, a maintenance page, or a
  "coming soon" splash.
- **Apple's CDN caches it.** A change can take up to 24 hours to reach devices,
  so get it right before testing rather than iterating against it.

## Deploying

```sh
tools/deploy.sh              # upload, then check
tools/deploy.sh --dry-run    # say what would change, touch nothing
tools/deploy.sh --check      # check what is live, upload nothing
```

That uploads this directory and then reads back the status and content type of
every path, plus whether the Team ID in the association file still matches
`project.yml`.

It uploads with `--delete`, because the failure that prevents is invisible: a
file left at `/s` by an older upload wins at nginx's `try_files` and is served
as a download, and `index.php` is never reached. `.well-known/` is the one
directory left alone — certificate renewal writes an ACME challenge there, and
nothing of ours lives in it any more.

It needs the `peacegarden` host in `~/.ssh/config`, which is written, and its
key registered in **My20i → peacegarden.app → Security → SSH Access**. Paste
the contents of `~/.ssh/peacegarden_app.pub` there under a handle such as
`peacegarden-deploy`.

The two failure modes read very differently, and it is worth knowing which is
which before diagnosing the wrong one:

| What ssh says | What it means |
| --- | --- |
| `Permission denied (publickey)` | The key is not registered yet. The host and the SSH user are fine. |
| Connection reset at the handshake | The **IP allowlist** on that same page. It gates SSH before authentication, so it reads like a network fault rather than a permissions one. |

Failing all of that, upload by hand to the document root of `peacegarden.app` —
the directory serving the site, usually `public_html`. `.pages` starts with a
dot, so 20i's file manager may hide it. Turn on "show hidden files", or use
SFTP.

## Checking it

```sh
curl -sSI https://peacegarden.app/.well-known/apple-app-site-association
```

Wanted: `HTTP/2 200` and `content-type: application/json`. A `301`, a `404`, or
`text/html` all mean it will not work.

```sh
curl -sS https://peacegarden.app/.well-known/apple-app-site-association | python3 -m json.tool
```

Should print the JSON with your real Team ID in it.

Apple's own validator — replace the domain:

```
https://app-site-association.cdn-apple.com/a/v1/peacegarden.app
```

That is what devices actually fetch. If it returns nothing, no amount of
correctness on your server matters yet; wait for the cache and try again.

## Testing on a device

With the app installed and the entitlement in place, send yourself a seed link
and tap it. It should open the app. If it opens Safari instead:

1. Check the validator URL above returns your file.
2. Check the Team ID matches the one the app was signed with.
3. Delete and reinstall — associated domains are fetched at install time.
4. On a development build, `applinks:peacegarden.app?mode=developer` in the
   entitlement makes iOS bypass its CDN and fetch from your server directly.
