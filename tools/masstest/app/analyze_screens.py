"""Reads a screen sweep back and flags what can be flagged without eyes.

    python3 tools/masstest/app/analyze_screens.py build/mt/screens build/mt/analysis

For every device folder (`<config>/<screen>.json`, `-audit.json`):

- **off-screen**: a word or a control past the left or right edge of the
  window, or below the foot on a screen that does not scroll there.
- **overlap**: two words or controls whose frames overlap by more than a
  quarter of the smaller, neither inside the other.
- **not localised**: a label shown identically under `pseudo`
  (`-NSDoubleLocalizedStrings`, which doubles every string the bundle looks
  up) and in English — a string that never went through the catalogue.
- **untranslated**: a label in a translated language identical to the same
  screen's English, checked against the catalogue (translation missing, or
  present and not shown).
- **not mirrored**: under forced right-to-left, a label standing where it
  stood left to right rather than mirrored (the plot itself is exempt: it is
  a map and reads one way round by design).
- **Dynamic Type**: the same label's height at L and at the largest size.
- the accessibility audit, by type and by element.

Writes `<out>/<device>.json` and prints a summary.
"""
import glob, json, os, re, sys
from collections import Counter, defaultdict

ROOT, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
CATALOGUE = json.load(open(os.path.join(REPO, "App/PeaceGarden/Resources/Localizable.xcstrings")))["strings"]
LANGS = ["da", "es", "fr", "it", "nb", "nl", "sv"]
# What the fixture garden says, which is somebody's own words and not the app's.
FIXTURE = {"wren", "the long field", "with pia", "ada", "bo", "cai", "devi", "esme", "fen", "ines",
           "jo", "kit", "lin", "mo", "nell", "oz", "pia", "peace garden"}
BINOMIAL = re.compile(r"^[A-Z][a-z]+ [a-z]+$")
WORDS = re.compile(r"[A-Za-z]{3,}")


def key_pattern(key):
    """The catalogue key as a regex a rendered label can be matched against."""
    pattern = re.escape(key)
    pattern = re.sub(r"%(\\\d\\\$)?(lld|ld|d|@|f|\\\.\dlf|lf)", ".+", pattern)
    return re.compile("^" + pattern + "$", re.IGNORECASE | re.DOTALL)


PATTERNS = [(k, key_pattern(k)) for k in CATALOGUE if k.strip()]


def catalogue_entry(label):
    for key, pattern in PATTERNS:
        if pattern.match(label):
            return key
    return None


def visible(e):
    return e["w"] > 0.5 and e["h"] > 0.5 and e["type"] in ("text", "button", "switch", "toggle", "textField", "link", "slider")


def load(device_folder):
    data = {}
    for path in glob.glob(os.path.join(device_folder, "*", "*.json")):
        if path.endswith("-audit.json"):
            continue
        config = os.path.basename(os.path.dirname(path))
        screen = os.path.basename(path)[:-5]
        d = json.load(open(path))
        audit_path = path[:-5] + "-audit.json"
        d["audit"] = json.load(open(audit_path)) if os.path.exists(audit_path) else None
        data.setdefault(config, {})[screen] = d
    return data


def wordy(label):
    text = label.strip()
    if not WORDS.search(text) or text.lower() in FIXTURE:
        return False
    if BINOMIAL.match(text):
        return False
    return True


def analyse(device, data):
    findings = defaultdict(list)
    configs = sorted(data)

    def baseline(config, screen):
        locale, size, appearance = config.split("-")
        for candidate in (f"en-{size}-{appearance}", *[c for c in configs if c.startswith("en-")]):
            if candidate in data and screen in data[candidate]:
                return candidate
        return None

    for config in configs:
        locale, size, appearance = config.split("-")
        for screen, d in data[config].items():
            W, H = d["window"]["w"], d["window"]["h"]
            elements = [e for e in d["elements"] if visible(e)]
            scrolls = [e for e in d["elements"] if e["type"] == "scrollView"]

            def in_scroll(e):
                return any(s["y"] - 1 <= e["y"] and e["y"] + e["h"] <= s["y"] + s["h"] + 1 for s in scrolls)

            for e in elements:
                if (e["x"] < -0.5 or e["x"] + e["w"] > W + 0.5) and not in_scroll(e):
                    findings["offscreen"].append({"config": config, "screen": screen, "label": e["label"],
                                                  "frame": [round(e["x"]), round(e["y"]), round(e["w"]), round(e["h"])],
                                                  "edge": "left" if e["x"] < 0 else "right"})
                elif e["y"] + e["h"] > H + 0.5 and screen not in ("settings", "settings-end") and not in_scroll(e):
                    findings["offscreen"].append({"config": config, "screen": screen, "label": e["label"],
                                                  "frame": [round(e["x"]), round(e["y"]), round(e["w"]), round(e["h"])],
                                                  "edge": "bottom"})
            texts = [e for e in elements if e["type"] in ("text", "button") and e["label"].strip()]
            for i, a in enumerate(texts):
                for b in texts[i + 1:]:
                    ix = min(a["x"] + a["w"], b["x"] + b["w"]) - max(a["x"], b["x"])
                    iy = min(a["y"] + a["h"], b["y"] + b["h"]) - max(a["y"], b["y"])
                    if ix <= 1 or iy <= 1:
                        continue
                    smaller = min(a["w"] * a["h"], b["w"] * b["h"])
                    contains = lambda p, q: p["x"] <= q["x"] + 1 and p["y"] <= q["y"] + 1 and \
                        p["x"] + p["w"] >= q["x"] + q["w"] - 1 and p["y"] + p["h"] >= q["y"] + q["h"] - 1
                    if ix * iy > 0.25 * smaller and not contains(a, b) and not contains(b, a):
                        findings["overlap"].append({"config": config, "screen": screen,
                                                    "a": a["label"][:60], "b": b["label"][:60],
                                                    "share": round(ix * iy / smaller, 2)})

            base = baseline(config, screen)
            if base is None or base == config:
                continue
            en = data[base][screen]
            en_labels = {e["label"].strip() for e in en["elements"] if visible(e) and e["label"].strip()}
            labels = [e for e in elements if e["label"].strip()]
            if locale == "pseudo":
                for e in labels:
                    text = e["label"].strip()
                    if text in en_labels and wordy(text):
                        findings["notLocalised"].append({"config": config, "screen": screen, "label": text[:90],
                                                         "inCatalogue": catalogue_entry(text) is not None})
            elif locale in LANGS:
                for e in labels:
                    text = e["label"].strip()
                    if text in en_labels and wordy(text):
                        key = catalogue_entry(text)
                        entry = CATALOGUE.get(key, {}) if key else {}
                        unit = entry.get("localizations", {}).get(locale, {}).get("stringUnit", {})
                        if key is None:
                            why = "not in the catalogue"
                        elif entry.get("shouldTranslate") is False:
                            continue
                        elif not unit:
                            why = "no translation in the catalogue"
                        elif unit.get("value", "").strip().lower() == text.lower():
                            continue  # the translation is the same word
                        else:
                            why = "translated in the catalogue, English on screen"
                        findings["untranslated"].append({"config": config, "screen": screen, "label": text[:90], "why": why})
            elif locale == "rtl":
                en_by_label = defaultdict(list)
                for e in en["elements"]:
                    if visible(e) and e["label"].strip():
                        en_by_label[e["label"].strip()].append(e)
                for e in labels:
                    text = e["label"].strip()
                    if text not in en_by_label or len(en_by_label[text]) != 1:
                        continue
                    o = en_by_label[text][0]
                    cx_en, cx = o["x"] + o["w"] / 2, e["x"] + e["w"] / 2
                    if abs(cx_en - W / 2) < 16:
                        continue  # centred either way
                    mirrored = abs(cx - (W - cx_en)) < 14
                    unmoved = abs(cx - cx_en) < 6
                    if unmoved and not mirrored:
                        findings["notMirrored"].append({"config": config, "screen": screen, "label": text[:60],
                                                        "x": round(e["x"]), "w": round(e["w"])})

            if size in ("AX5", "AX3", "XXXL"):
                en_heights = {}
                small = f"{locale}-L-{appearance}" if f"{locale}-L-{appearance}" in data else \
                    next((c for c in configs if c.startswith(locale + "-L-")), None)
                if small and screen in data[small]:
                    for e in data[small][screen]["elements"]:
                        if e["type"] == "text" and e["label"].strip():
                            en_heights.setdefault(e["label"].strip(), e["h"])
                    same = grown = 0
                    for e in elements:
                        if e["type"] == "text" and e["label"].strip() in en_heights:
                            if e["h"] > en_heights[e["label"].strip()] + 1:
                                grown += 1
                            else:
                                same += 1
                    findings["dynamicType"].append({"config": config, "screen": screen, "against": small,
                                                    "textsThatGrew": grown, "textsThatDidNot": same})

            if d.get("audit"):
                for issue in d["audit"]:
                    findings["audit"].append({"config": config, "screen": screen, "type": issue.get("type"),
                                              "description": issue.get("description", ""),
                                              "label": (issue.get("label") or "")[:80],
                                              "frame": issue.get("frame")})
    return findings


def main():
    summary = {}
    for device_folder in sorted(glob.glob(os.path.join(ROOT, "*"))):
        if not os.path.isdir(device_folder):
            continue
        device = os.path.basename(device_folder)
        data = load(device_folder)
        findings = analyse(device, data)
        json.dump(findings, open(os.path.join(OUT, f"{device}.json"), "w"), indent=1)
        summary[device] = findings
        print(f"\n=== {device}: {len(data)} configurations, {sum(len(s) for s in data.values())} screens")
        for kind in ("offscreen", "overlap", "notLocalised", "untranslated", "notMirrored"):
            rows = findings.get(kind, [])
            unique = Counter((r["screen"], r.get("label") or f"{r.get('a')} / {r.get('b')}") for r in rows)
            print(f"  {kind}: {len(rows)} ({len(unique)} distinct)")
            for (screen, label), n in unique.most_common(12):
                print(f"     {n:3}x {screen:13} {label[:80]!r}")
        dt = findings.get("dynamicType", [])
        if dt:
            print(f"  dynamicType: texts that grew {sum(r['textsThatGrew'] for r in dt)}, did not {sum(r['textsThatDidNot'] for r in dt)}")
        audit = findings.get("audit", [])
        print(f"  audit: {len(audit)} issues; by type {dict(Counter(r['type'] for r in audit))}")
        for t in ("textClipped", "contrast", "hitRegion", "elementDetection", "trait", "sufficientElementDescription"):
            rows = [r for r in audit if r["type"] == t]
            if not rows:
                continue
            unique = Counter((r["screen"], r["label"]) for r in rows)
            print(f"   {t}:")
            for (screen, label), n in unique.most_common(10):
                print(f"     {n:3}x {screen:13} {label!r}")


if __name__ == "__main__":
    main()
