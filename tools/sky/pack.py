"""The real sky, packed small enough to carry.

    python3 tools/sky/pack.py

Writes four things, all generated — edit this script, never its outputs:

  App/PeaceGarden/Resources/stars.bin     the catalogue, 6 bytes a star
  Packages/SeedCore/Sources/SeedCore/Sky/Places.swift   where a time zone is
  tools/wasm/web/stars.bin                the same catalogue, for the browser
  tools/wasm/web/places.json              the same zones, for the browser

The two for the browser are copies rather than a second source: the web walk
draws the same sky as the app, and two catalogues that could drift apart would
be two skies.

**The catalogue** is the Yale Bright Star Catalogue (BSC5, Hoffleit & Warren),
every star to magnitude 6.5 — which is what an eye sees on a dark night. It is
fetched once by hand from tdc-www.harvard.edu/catalogs/bsc5.dat.gz and kept in
`tools/sky/bsc5.dat`; it has not changed since 1991 and is not going to.

**Where somebody is comes from their time zone**, and from nothing else. The
tz database ships a file called `zone.tab` giving a representative latitude and
longitude for every zone it knows — Europe/London is London, America/Sao_Paulo
is São Paulo — and every phone already has it at /usr/share/zoneinfo. So a sky
that is right for where you are costs no permission, no request and no setting:
the phone already knows, because it is already keeping your clock by it.

What that buys, and what it does not: a zone's coordinate is its principal city,
so somebody in Aberdeen gets London's sky. Aberdeen is 6 degrees north of
London, which tilts the whole sky by six degrees — about the width of three
fingers held at arm's length, and invisible unless you are checking. A
coordinate would fix it, and the reason not to take one is in `docs/PLACE.md`.
"""

import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent

CATALOGUE = HERE / "bsc5.dat"
ZONE_TAB = Path("/usr/share/zoneinfo/zone.tab")

STARS_OUT = ROOT / "App/PeaceGarden/Resources/stars.bin"
PLACES_OUT = ROOT / "Packages/SeedCore/Sources/SeedCore/Sky/Places.swift"
WEB_STARS_OUT = ROOT / "tools/wasm/web/stars.bin"
WEB_PLACES_OUT = ROOT / "tools/wasm/web/places.json"

#: Everything an eye can see, and nothing it cannot. The renderer picks its own
#: limit from within this; the data does not decide how dark the sky looks.
FAINTEST = 6.5

MAGIC = b"PGSKY1"


# MARK: The catalogue


def stars():
    """Every star to `FAINTEST`, as (right ascension, declination, magnitude, colour)."""
    if not CATALOGUE.is_file():
        sys.exit(
            f"{CATALOGUE} is missing.\n"
            "Fetch it once:\n"
            "  curl -sSL http://tdc-www.harvard.edu/catalogs/bsc5.dat.gz "
            f"| gunzip > {CATALOGUE}"
        )

    out = []
    for line in CATALOGUE.read_text(encoding="latin-1").splitlines():
        try:
            # J2000, in the fixed columns ADC V/50 documents. A row with a
            # blank position is a catalogue entry for a star that turned out
            # not to be one, and there are fourteen of them.
            hours, minutes, seconds = int(line[75:77]), int(line[77:79]), float(line[79:83])
            sign = -1 if line[83] == "-" else 1
            degrees, arcmin, arcsec = int(line[84:86]), int(line[86:88]), int(line[88:90])
            magnitude = float(line[102:107])
        except ValueError:
            continue
        if magnitude > FAINTEST:
            continue
        try:
            colour = float(line[109:114])
        except ValueError:
            # No B−V measured. Nought is a white star, which is the safest
            # thing to call one nobody has measured.
            colour = 0.0
        out.append((
            (hours + minutes / 60 + seconds / 3600) * 15,
            sign * (degrees + arcmin / 60 + arcsec / 3600),
            magnitude,
            colour,
        ))
    # Brightest first, so a renderer that wants the first N gets the N that
    # matter and can stop reading.
    out.sort(key=lambda s: s[2])
    return out


def pack(rows):
    """Six bytes a star, and the resolution each field is given is the
    resolution the sky is drawn at.

    Right ascension in a `UInt16` is 20 arcseconds; declination in an `Int16`
    is 10. A star is drawn at about a point across on a screen four hundred
    points wide covering a hundred and eighty degrees, so a point is a
    thousand arcseconds — fifty times coarser than the coarsest of these.
    """
    body = bytearray()
    for ra, dec, magnitude, colour in rows:
        body += struct.pack(
            "<HhBb",
            round(ra / 360 * 65536) % 65536,
            max(-32767, min(32767, round(dec / 90 * 32767))),
            # −2.0 to +13.9 in sixteenths, which covers Sirius at −1.46 and
            # everything this catalogue holds.
            max(0, min(255, round((magnitude + 2) * 16))),
            # B−V from −2.5 to +2.5 in fiftieths. Real stars run about −0.4
            # (Rigel) to +2.0 (a carbon star).
            max(-127, min(127, round(colour * 50))),
        )
    return MAGIC + struct.pack("<I", len(rows)) + bytes(body)


# MARK: Where a time zone is


def places():
    """Every zone the tz database knows, with the coordinate it gives for it."""
    if not ZONE_TAB.is_file():
        sys.exit(f"{ZONE_TAB} is missing — this wants a machine with the tz database on it.")

    # ISO 6709: ±DDMM±DDDMM, or ±DDMMSS±DDDMMSS.
    shape = re.compile(r"([+-])(\d{2})(\d{2})(\d{2})?([+-])(\d{3})(\d{2})(\d{2})?")
    found = {}
    for line in ZONE_TAB.read_text().splitlines():
        if line.startswith("#") or not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 3:
            continue
        match = shape.fullmatch(parts[1])
        if not match:
            continue
        ns, latd, latm, lats, ew, lond, lonm, lons = match.groups()
        latitude = (int(latd) + int(latm) / 60 + int(lats or 0) / 3600) * (-1 if ns == "-" else 1)
        longitude = (int(lond) + int(lonm) / 60 + int(lons or 0) / 3600) * (-1 if ew == "-" else 1)
        found[parts[2]] = (round(latitude, 2), round(longitude, 2))
    return dict(sorted(found.items()))


def swift(found):
    rows = "\n".join(f"{name},{lat},{lon}" for name, (lat, lon) in found.items())
    return f'''//
//  Generated by tools/sky/pack.py from the tz database's own zone.tab.
//  Edit the script, never this file.
//
//  zone.tab is in the public domain, so clarified in 2009 by Arthur David
//  Olson, and every machine that keeps time has a copy of it.
//

/// Where each of the world's time zones is, near enough for a sky.
///
/// **This is the whole of how the app knows where you are**, and it asks for
/// nothing: a phone keeping London time is a phone in London's sky, and it was
/// already keeping London time before this app existed. A zone's coordinate is
/// its principal city, so somebody in Aberdeen is given London's sky — six
/// degrees of tilt, about three fingers held at arm's length, and invisible
/// unless you are checking. `docs/PLACE.md` says why the app does not take a
/// coordinate to do better.
///
/// One string rather than {len(found)} dictionary entries, because a literal that
/// size is a minute of the type checker's time on every clean build. It is
/// parsed once, on first use.
enum Places {{
    static let count = {len(found)}

    /// `identifier,latitude,longitude`, one zone a line, sorted.
    static let table = """
{rows}
"""
}}
'''


def main():
    rows = stars()
    blob = pack(rows)
    STARS_OUT.parent.mkdir(parents=True, exist_ok=True)
    STARS_OUT.write_bytes(blob)

    found = places()
    PLACES_OUT.parent.mkdir(parents=True, exist_ok=True)
    PLACES_OUT.write_text(swift(found))

    # The browser's two, byte for byte the same data. `sky.js` reads the
    # catalogue with the same six-byte layout SeedCore's `StarCatalogue` does,
    # and `tools/reference/check_sky.mjs` holds its arithmetic to the Swift's.
    WEB_STARS_OUT.parent.mkdir(parents=True, exist_ok=True)
    WEB_STARS_OUT.write_bytes(blob)
    WEB_PLACES_OUT.write_text(json.dumps(
        {name: [lat, lon] for name, (lat, lon) in found.items()},
        separators=(",", ":"), sort_keys=True,
    ) + "\n")

    brightest = rows[0]
    print(f"{len(rows)} stars to magnitude {FAINTEST}, {len(blob) / 1024:.1f} KB")
    print(f"  brightest: magnitude {brightest[2]} at RA {brightest[0]:.3f}, dec {brightest[1]:.3f}")
    print(f"{len(found)} time zones -> {PLACES_OUT.relative_to(ROOT)}")
    print(f"  and the browser's copies -> {WEB_STARS_OUT.relative_to(ROOT)}, "
          f"{WEB_PLACES_OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
