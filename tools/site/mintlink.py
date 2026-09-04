#!/usr/bin/env python3
"""
A seed link, so the seed page can be looked at.

    python3 tools/site/mintlink.py                       # an offer
    python3 tools/site/mintlink.py --kind r              # a reply
    python3 tools/site/mintlink.py --name Nadia --plant "Wynula latifolia"
    python3 tools/site/mintlink.py --base http://localhost:8801

**Two of the site's six prose strings only exist on a page that has a seed in
it**, and the about block hides the moment one parses — so `growBody` and
`appNote` cannot be seen at all without a link, and nobody reviewing the
commission can reach a third of it. Minting one by hand means reading `link.js`,
which is where the afternoon goes.

This mints one the site accepts. **It is a fixture, not a seed**: the bytes are
random and belong to nobody, and nothing here derives a plant. The app mints the
real ones — `PollenLink` on the Swift side — and this exists so the page can be
read in a language, which is the one thing a checker cannot do.

The format is `link.js`'s, and the two have to agree. Ten dot-separated fields,
the checksum over the first nine.
"""

import argparse
import base64
import hashlib
import os
import struct
import time

DOMAIN = b"peacegarden.link.v1"
SEED_BYTES = 32
NONCE_BYTES = 16


def b64(raw):
    """base64url, unpadded, the way `decode` in link.js expects it."""
    return base64.urlsafe_b64encode(raw).decode().rstrip("=")


def checksum(body):
    """Six bytes of a domain-separated digest. Enough to catch a link a
    messaging app has wrapped or truncated, which is all it is for. It is not a
    signature and proves nothing about who sent anything."""
    part = body.encode()
    buffer = DOMAIN + b"\x00" + struct.pack(">I", len(part)) + part
    return b64(hashlib.sha256(buffer).digest()[:6])


def mint(kind="o", name="Nadia", plant="Wynula latifolia", born=None):
    fields = [
        "1",
        kind,
        b64(os.urandom(SEED_BYTES)),
        b64(os.urandom(NONCE_BYTES)),
        str(int(born if born is not None else time.time() - 21 * 86_400)),
        b64(name.encode()),
        b64(plant.encode()),
        # A reply carries the nonce it answers and the plant both sides should
        # reach. An offer carries neither, and the fields are still there:
        # a fixed field count is what makes a truncated link fail to parse
        # rather than parse as something else.
        b64(os.urandom(NONCE_BYTES)) if kind == "r" else "",
        b64(os.urandom(32)) if kind == "r" else "",
    ]
    return ".".join(fields + [checksum(".".join(fields))])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--kind", choices=("o", "r"), default="o",
                        help="o is an offer, r is a reply that has come back")
    parser.add_argument("--name", default="Nadia")
    parser.add_argument("--plant", default="Wynula latifolia")
    parser.add_argument("--base", default="http://localhost:8801")
    parser.add_argument("--days", type=int, default=21,
                        help="how long ago the sender's plant was born")
    parser.add_argument("--review", metavar="CODE",
                        help="print the whole set of links a reviewer of that "
                             "language needs, ready to paste into a message")
    args = parser.parse_args()

    if args.review:
        code = args.review
        born = time.time() - args.days * 86_400
        rows = [
            ("What this is, for somebody with no seed",
             f"{args.base}/s?l={code}"),
            ("A seed that has arrived",
             f"{args.base}/s?l={code}#{mint('o', args.name, args.plant, born)}"),
            ("The same, from somebody who gave no name",
             f"{args.base}/s?l={code}#{mint('o', '', args.plant, born)}"),
            ("A seed that has come back",
             f"{args.base}/s?l={code}#{mint('r', args.name, args.plant, born)}"),
            ("A link that arrived broken",
             f"{args.base}/s?l={code}#1.o.notaseed"),
            ("The garden",
             f"{args.base}/g?l={code}"),
        ]
        for index, (what, url) in enumerate(rows, 1):
            print(f"{index}. {what}\n   {url}\n")
        return
    fragment = mint(args.kind, args.name, args.plant,
                    born=time.time() - args.days * 86_400)
    print(f"{args.base}/s#{fragment}")


if __name__ == "__main__":
    main()
