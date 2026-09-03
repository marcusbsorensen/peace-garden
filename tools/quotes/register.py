"""Put an assembled bank into the app.

`assemble.py` writes `Quotes+Language.swift` and checks it. That file is inert
until `QuoteBank` knows about it, which is two lines in `QuoteBanks.swift` — a
case on the enum and a case in `passages` — and forgetting the second is a
compile error, which is the good outcome. Forgetting both is a bank that exists
and is never read by anybody, which is not.

    python3 tools/quotes/register.py Slovak sk
    python3 tools/quotes/register.py Slovak sk --check

Textual, and deliberately so: `QuoteBanks.swift` is source, not data, and it
carries doc comments that no round trip through a parser would keep. The same
reason `Localizable.xcstrings` is edited textually — see the note in
docs/HANDOVER.md about what `json.dumps` does to it.

Idempotent. Registering a bank twice is a no-op, so this can be run over a whole
wave without checking which of them landed already.
"""

import argparse
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BANKS = ROOT / "App/PeaceGarden/Views/QuoteBanks.swift"
VIEWS = ROOT / "App/PeaceGarden/Views"


def property_name(language):
    """`Slovak` -> `slovak`. The property `assemble.py` writes."""
    return language[0].lower() + language[1:]


def register(language, code, check=False):
    name = property_name(language)
    text = BANKS.read_text()

    bank_file = VIEWS / f"Quotes+{language}.swift"
    if not bank_file.exists():
        return f"no {bank_file.relative_to(ROOT)} — run assemble.py first", False
    if f"static let {name}" not in bank_file.read_text():
        return f"{bank_file.name} has no `static let {name}`", False

    already_case = re.search(rf"^\s*case {name} = \"(\w{{2}})\"", text, re.M)
    already_switch = re.search(rf"^\s*case \.{name}: return Quotes\.{name}$", text, re.M)
    if already_case and already_switch:
        # Idempotent by name, so a wave can be run over twice — but a name that
        # is registered under a *different* code is a typo in the invocation,
        # and saying "already registered" to that would swallow it.
        if already_case.group(1) != code:
            return f"{language} is registered as \"{already_case.group(1)}\", not \"{code}\"", False
        return f"{language} ({code}) is already registered", True
    if already_case or already_switch:
        return f"{language} is half-registered — fix {BANKS.name} by hand", False

    if re.search(rf"= \"{code}\"", text):
        return f"another bank already claims \"{code}\"", False

    # The enum's cases are in commission order rather than alphabetical, so a
    # new one goes at the end of the run — after the last `case x = "y"`.
    cases = list(re.finditer(r"^(\s*)case (\w+) = \"(\w{2})\"$", text, re.M))
    if not cases:
        return "could not find the enum cases", False
    last = cases[-1]
    text = text[: last.end()] + f'\n{last.group(1)}case {name} = "{code}"' + text[last.end():]

    # And the switch keeps the same order as the enum, which is the property
    # that makes a missing line show up as a non-exhaustive switch.
    arms = list(re.finditer(r"^(\s*)case \.(\w+): return Quotes\.(\w+)$", text, re.M))
    if not arms:
        return "could not find the `passages` switch", False
    last = arms[-1]
    text = text[: last.end()] + f"\n{last.group(1)}case .{name}: return Quotes.{name}" + text[last.end():]

    if not check:
        BANKS.write_text(text)
    return f"{language} ({code}) registered", True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("language", help="Slovak, Welsh, … — as `assemble.py` was given it")
    parser.add_argument("code", help="the two-letter language code")
    parser.add_argument("--check", action="store_true", help="say what would happen, change nothing")
    args = parser.parse_args()

    message, ok = register(args.language, args.code, check=args.check)
    print(message)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
