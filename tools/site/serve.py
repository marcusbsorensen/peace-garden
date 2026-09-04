"""Serve `Server/` the way a host serves it.

    python3 tools/site/serve.py            # http://localhost:8801
    python3 tools/site/serve.py --port N

**Why this exists rather than `python3 -m http.server --directory Server`.**
The site's three pages are `/s`, `/g` and `/t`, with no extension on any of
them, because that is what they are: a seed link minted by the app points at
`/s` and will point at it for as long as any link already sent is worth
following. `http.server` types a file by its extension and falls back to
`application/octet-stream`, so all three arrive as downloads and none of them
renders. The bare command looks like it works — 200, no error in the log — and
then the browser saves a file.

So this serves the four extensionless paths with the types they are, out of
`Server/.pages/`, which is where they live and is not where they are served
from. `Server/index.php` says why: peacegarden.app runs nginx with no Apache
behind it, `.htaccess` is never read there, and a file sitting at `/s` would be
served as a download before PHP ever saw the request. This is the same table of
four, in Python, so that what is looked at locally is what is served.

Two smaller things a real host does that the plain module does not:

- **A new port each run is unnecessary.** Modules are served `no-store`, so a
  changed one is fetched rather than remembered. `.claude/HANDOVER.md` records
  moving the port to be sure a module had really changed; that was the right
  move against a caching server and this removes the reason for it.
- **`/` serves `/g`.** The garden is the page worth landing on while the site is
  being worked on, and the root is otherwise a directory listing that publishes
  the whole tree.
"""

import argparse
import functools
import http.server
import pathlib
import socketserver

ROOT = pathlib.Path(__file__).resolve().parents[2] / "Server"

# Path served -> file under `.pages/`, and the type it is. The same four rows as
# `ROUTES` in Server/index.php, and they have to stay the same four: this is the
# thing that shows a page has stopped being a page before a host does.
#
# Named one by one rather than inferred from "has no dot", so a stray file
# cannot start being served as a page by accident.
PAGES = {
    "/s": ("s", "text/html"),
    "/g": ("g", "text/html"),
    "/t": ("t", "text/html"),
    "/.well-known/apple-app-site-association": (
        "apple-app-site-association", "application/json",
    ),
}


class Handler(http.server.SimpleHTTPRequestHandler):
    def send_head(self):
        # A directory listing publishes the whole tree, which is not what any
        # host would do and not what should be looked at while working.
        if self.path in ("/", ""):
            self.path = "/g"
        # nginx refuses dot-directories, so `.pages/s` is not a second address
        # for the seed page on the live host. It should not be one here either.
        if self.path.startswith("/.pages"):
            self.send_error(403)
            return None
        route = PAGES.get(self.path.split("?", 1)[0])
        if route is not None:
            self.path = "/.pages/" + route[0]
        return super().send_head()

    def guess_type(self, path):
        name = pathlib.Path(path).name
        for file, type_ in PAGES.values():
            if name == file:
                return type_
        return super().guess_type(path)

    def end_headers(self):
        # A browser caches ES modules by URL, and a cached module that has
        # changed on disk looks like a module that has stopped working.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def log_message(self, format, *args):
        # One line per request is noise while walking a garden; a failure is
        # not. 404s and 500s still print.
        if not str(args[1] if len(args) > 1 else "").startswith("2"):
            super().log_message(format, *args)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8801)
    args = parser.parse_args()

    handler = functools.partial(Handler, directory=str(ROOT))
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", args.port), handler) as server:
        print(f"http://localhost:{args.port}/g   — the garden")
        print(f"http://localhost:{args.port}/t   — the testers")
        print(f"http://localhost:{args.port}/s   — a seed link, with one in the fragment")
        server.serve_forever()


if __name__ == "__main__":
    main()
