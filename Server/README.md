# Serving peacegarden.app

Two jobs. Convince iOS that this app owns this domain, so a seed link opens the
app instead of a web page — and answer everybody else, on `/s`, with the page a
seed lands on.

## What goes where

```
peacegarden.app/
├── .well-known/
│   └── apple-app-site-association     ← no file extension
├── .htaccess                          ← serves `s` as text/html
├── s                                  ← the page, no file extension either
├── languages.json                     ← generated: tools/site/export.py
├── passages/<code>.json               ← generated: one bank per language
├── strings/<code>.json                ← the site's own words, per language
└── assets/
    ├── site.css
    ├── mark.svg                       ← a copy of tools/icon/icon.svg
    └── js/
        ├── page.js                    ← the /s page
        ├── link.js                    ← reads the fragment
        ├── languages.js               ← negotiation and the chooser
        ├── strings.js                 ← the catalogue, English written
        └── passages.js                ← theme, subtheme, and the draw
```

Everything is a file. No build step, no framework, no npm, and nothing to run
on the host: `git` is not needed on the server and neither is anything else.
Upload the contents of this directory to the document root.

**`s` has no file extension on purpose.** It is the path every seed link
already points at and the path the association file claims, so it cannot grow a
`.html`. `.htaccess` serves it as `text/html`, the same way `.well-known` forces
`application/json` — see that file for what it can and cannot promise.

**`mark.svg` is a copy.** `tools/icon/make_icon.py` writes the canonical
drawing at `tools/icon/icon.svg`; this is that file, copied. Change the dials
and re-run the generator, then copy it here again. Do not hand-edit either one.
**SEAM:** a deploy script that re-copies it is what would keep the two from
drifting, and there is not one yet.

**Two deploy steps that are settings rather than files:**

- **Request logging on `/s`.** docs/WEBSITE.md asks for none, or the shortest
  the host permits. That is a 20i control-panel setting. Nothing on the page
  claims more than what is actually switched off, and nothing should.
- **The root.** `peacegarden.app/` still answers 403. `/s` with no seed in it is
  the page that says what Peace Garden is, so what the root should do is the
  open question in docs/WEBSITE.md about whether there is a marketing page at
  all — deliberately left alone rather than answered with a redirect.

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
curl -sSI https://peacegarden.app/s
```

Wanted: `HTTP/2 200` and `content-type: text/html`. `text/plain` means
`.htaccess` is not being read, and the page will show as source.

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

## On 20i

```sh
tools/deploy-aasa.sh
```

That uploads both files and then checks what is actually served — status,
content type, and whether the Team ID in the file still matches `project.yml`.

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
the directory serving the site, usually `public_html`.

`.well-known` starts with a dot, so 20i's file manager may hide it. Turn on
"show hidden files", or create it over SFTP. If the folder cannot be created
through the UI at all, an `.htaccess` alias works:

```apache
RewriteEngine On
RewriteRule ^\.well-known/apple-app-site-association$ /aasa.json [L]
<Files "aasa.json">
    ForceType application/json
</Files>
```

If the extensionless file is served as the wrong type, force it directly:

```apache
<Files "apple-app-site-association">
    ForceType application/json
</Files>
```

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
