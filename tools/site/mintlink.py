#!/usr/bin/env python3
"""
A seed link, so the seed page can be looked at.

    python3 tools/site/mintlink.py                       # an offer
    python3 tools/site/mintlink.py --kind r              # a reply
    python3 tools/site/mintlink.py --name Nadia --plant "Wynula latifolia"
    python3 tools/site/mintlink.py --base http://localhost:8801
    python3 tools/site/mintlink.py --review fr           # one language's six
    python3 tools/site/mintlink.py --packets out/review  # every language, sendable

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
import json
import os
import pathlib
import struct
import time

DOMAIN = b"peacegarden.link.v1"
SEED_BYTES = 32
NONCE_BYTES = 16

HERE = pathlib.Path(__file__).resolve().parents[2]
GUIDE = HERE / "docs" / "REVIEWING-A-LANGUAGE.md"
TESTERS = HERE / "Server" / "testers.json"


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


def review_rows(code, base, name, plant, born):
    """The six screens a reviewer needs, in the order §2 of the guide names
    them. Screens 2, 3 and 4 differ only in the fragment, and the fragment never
    reaches the server — so these are six URLs rather than six pages, and there
    is nothing on the site to keep in step with them."""
    return [
        ("What this is, for somebody with no seed",
         f"{base}/s?l={code}"),
        ("A seed that has arrived",
         f"{base}/s?l={code}#{mint('o', name, plant, born)}"),
        ("The same, from somebody who gave no name",
         f"{base}/s?l={code}#{mint('o', '', plant, born)}"),
        ("A seed that has come back",
         f"{base}/s?l={code}#{mint('r', name, plant, born)}"),
        ("A link that arrived broken",
         f"{base}/s?l={code}#1.o.notaseed"),
        ("The garden",
         f"{base}/g?l={code}"),
    ]


def packets(directory, base, name, plant, born):
    """One file per language: the guide, then that language's six links.

    **A reviewer should need one thing, not two.** The guide is the same for
    everybody and the links are not, and a message that says "read the attached
    and also here are six URLs" is a message somebody half-reads. So each file
    is the whole packet, ready to send as it stands.

    The links are fixtures and are minted fresh on every run, so these are
    written outside the repository — `out/` is ignored. Two reviewers holding
    different links is fine: nothing is derived from the bytes and no two of
    them mean anything to each other.
    """
    directory = pathlib.Path(directory)
    directory.mkdir(parents=True, exist_ok=True)
    guide = GUIDE.read_text()
    testers = json.loads(TESTERS.read_text())["testers"]

    written = []
    for tester in testers:
        code = tester["code"]
        rows = review_rows(code, base, name, plant, born)
        links = "\n".join(
            f"{index}. **{what}**\n   {url}\n"
            for index, (what, url) in enumerate(rows, 1)
        )
        # The heading names the language in its own script as well as in
        # English, because the first thing a reviewer checks is that they have
        # been sent the right one.
        packet = (
            f"# {tester['name']} — {tester['endonym']}\n\n"
            f"{guide.split('\n', 1)[1].lstrip()}\n"
            f"---\n\n## Your six links\n\n{links}"
        )
        path = directory / f"{code}-{tester['name'].replace(' ', '-')}.md"
        path.write_text(packet)
        written.append((code, tester["name"], path))

    index = "\n".join(
        f"| {code} | {language} | `{path.name}` |" for code, language, path in written
    )
    (directory / "INDEX.md").write_text(
        "# Review packets\n\n"
        f"Minted {time.strftime('%d %B %Y')} against `{base}`. One file per\n"
        "language, each the whole guide plus that language's six links, ready to\n"
        "send as it stands.\n\n"
        "Greenlandic (`kl`) ships English until a speaker reads it — see\n"
        "`Server/strings/kl.json`. Its packet is here so the speaker who reads it\n"
        "gets the same one as everybody else.\n\n"
        "| | Language | Packet |\n| --- | --- | --- |\n" + index + "\n"
    )
    print(f"{len(written)} packets in {directory}/")
    return written


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
    parser.add_argument("--packets", metavar="DIR",
                        help="write one sendable packet per language into DIR "
                             "— the guide and that language's six links")
    args = parser.parse_args()

    born = time.time() - args.days * 86_400

    if args.packets:
        packets(args.packets, args.base, args.name, args.plant, born)
        return

    if args.review:
        rows = review_rows(args.review, args.base, args.name, args.plant, born)
        for index, (what, url) in enumerate(rows, 1):
            print(f"{index}. {what}\n   {url}\n")
        return
    print(f"{args.base}/s#{mint(args.kind, args.name, args.plant, born)}")


if __name__ == "__main__":
    main()
