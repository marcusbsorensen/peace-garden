# Serving peacegarden.app

Two files, one job: convince iOS that this app owns this domain, so a seed link
opens the app instead of a web page.

## What goes where

```
peacegarden.app/
└── .well-known/
    └── apple-app-site-association     ← no file extension
```

## Before it will work

Replace `TEAMID` in `apple-app-site-association` with your Apple Developer Team
ID — ten characters, found in the Apple Developer portal under Membership, or in
Xcode under Signing & Capabilities next to the team name.

The result should read `ABCDE12345.com.peacegarden.app`. If the bundle
identifier in `project.yml` ever changes, it changes here too.

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

Upload to the document root of `peacegarden.app` — the directory serving the
site, usually `public_html`.

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
