#!/usr/bin/env python3
"""Make every place table from its spec, and write it as Swift, PHP and JavaScript.

    python3 tools/layouts/generate.py           write every table
    python3 tools/layouts/generate.py --check   fail if any written table is not
                                                what its spec makes, byte for byte
    python3 tools/layouts/generate.py --list    say what each table holds

A spec is `tools/layouts/tables/<name>.py`. `tools/layouts/README.md` says how
to write one; `tables/example.py` is one. For each spec this writes

    Packages/SeedCore/Sources/SeedCore/WebGardens/Tables/<Name>.swift
    Server/.api/tables/<Name>Table.php
    Server/assets/js/tables/<name>.js          (only if the spec says JS = True)

and removes any generated file whose spec has gone. Standard library only, and
the same bytes on any machine and any Python 3.9 or later: the arithmetic is
`places.numbers`, which never asks the C library for a sine.

`--check` also runs `php -l` and `node --check` over what it reads, where they
are installed, so a table that would not parse is caught here rather than on
the server.
"""
import argparse
import importlib
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, HERE)

from places import Layout, Place  # noqa: E402
from places.layout import quantise  # noqa: E402
from places import emit  # noqa: E402

SPECS = os.path.join(HERE, 'tables')
OUT = {
    'swift': os.path.join(ROOT, 'Packages/SeedCore/Sources/SeedCore/WebGardens/Tables'),
    'php': os.path.join(ROOT, 'Server/.api/tables'),
    'js': os.path.join(ROOT, 'Server/assets/js/tables'),
}
NAME = re.compile(r'^[a-z][a-z0-9_]*$')
WORD = re.compile(r'^[a-z][A-Za-z0-9]*$')


class Table:
    """One spec, built: every feature variant's places in whole millimetres."""

    def __init__(self, stem, module):
        self.stem = stem
        self.doc = (module.__doc__ or '').strip()
        self.fields = tuple(getattr(module, 'FIELDS', ()))
        self.nudges = int(getattr(module, 'NUDGES', 1))
        self.js = bool(getattr(module, 'JS', False))
        self.bound = float(getattr(module, 'BOUND', 2.6))
        self.min_spacing = getattr(module, 'MIN_SPACING', None)
        self.same_count = bool(getattr(module, 'SAME_COUNT', True))
        self.variants = []
        self.curves = {}
        problems = []
        if not NAME.match(stem):
            problems.append(f'{stem}.py: a table is named in lower case and underscores')
        for f in self.fields:
            if not WORD.match(f):
                problems.append(f'{stem}: the field {f!r} is not a plain word')
        if not hasattr(module, 'build'):
            problems.append(f'{stem}: a spec needs build(nudge)')
        if self.nudges < 1:
            problems.append(f'{stem}: NUDGES is at least 1')
        if problems:
            raise SystemExit('\n'.join(problems))

        for nudge in range(self.nudges):
            layout = module.build(nudge)
            if not isinstance(layout, Layout):
                raise SystemExit(f'{stem}: build({nudge}) returns a places.Layout')
            self.variants.append(self._places(layout, nudge))
            for name, (points, closed) in layout.curves.items():
                if not WORD.match(name):
                    raise SystemExit(f'{stem}: the curve {name!r} is not a plain word')
                self.curves.setdefault(name, []).append(
                    (closed, [(quantise(x), quantise(z)) for x, z in points]))
        self._check()

    def _places(self, layout, nudge):
        out = []
        for p in layout.places:
            if set(p.tags) != set(self.fields):
                raise SystemExit(f'{self.stem} variant {nudge}: a place at ({p.x:.3f}, {p.z:.3f}) is tagged '
                                 f'{sorted(p.tags)}, and the table has fields {list(self.fields)}')
            tags = [p.tags[f] for f in self.fields]
            if not all(isinstance(t, int) and not isinstance(t, bool) for t in tags):
                raise SystemExit(f'{self.stem}: a tag is a whole number')
            out.append((quantise(p.x), quantise(p.z), tags))
        return out

    def _check(self):
        problems = []
        limit = round(self.bound * 1000)
        counts = [len(v) for v in self.variants]
        if self.same_count and len(set(counts)) > 1:
            problems.append(f'feature variants hold {counts} places; set SAME_COUNT = False if that is meant')
        for nudge, places in enumerate(self.variants):
            if not places:
                problems.append(f'variant {nudge} has no places')
            seen = set()
            for x, z, _ in places:
                if abs(x) > limit or abs(z) > limit:
                    problems.append(f'variant {nudge}: ({emit.num(x)}, {emit.num(z)}) is outside '
                                    f'±{self.bound} m (BOUND)')
                if (x, z) in seen:
                    problems.append(f'variant {nudge}: two places at ({emit.num(x)}, {emit.num(z)})')
                seen.add((x, z))
            if self.min_spacing is not None:
                least = round(self.min_spacing * 1000)
                for i, (ax, az, _) in enumerate(places):
                    for bx, bz, _ in places[i + 1:]:
                        if (ax - bx) ** 2 + (az - bz) ** 2 < least * least:
                            problems.append(f'variant {nudge}: ({emit.num(ax)}, {emit.num(az)}) and '
                                            f'({emit.num(bx)}, {emit.num(bz)}) are closer than '
                                            f'MIN_SPACING, {self.min_spacing} m')
        names = set(self.curves)
        for name, variants in self.curves.items():
            if len(variants) != self.nudges:
                problems.append(f'the curve {name} is in {len(variants)} of {self.nudges} variants')
        if problems:
            raise SystemExit(f'{self.stem}:\n  ' + '\n  '.join(problems[:12]))
        self.curve_names = names

    def files(self):
        out = {
            os.path.join(OUT['swift'], emit.pascal(self.stem) + '.swift'): emit.swift(self),
            os.path.join(OUT['php'], emit.pascal(self.stem) + 'Table.php'): emit.php(self),
        }
        if self.js:
            out[os.path.join(OUT['js'], self.stem + '.js')] = emit.js(self)
        return out


def specs():
    stems = sorted(f[:-3] for f in os.listdir(SPECS)
                   if f.endswith('.py') and not f.startswith('_'))
    tables = []
    for stem in stems:
        module = importlib.import_module(f'tables.{stem}')
        tables.append(Table(stem, module))
    return tables


def generated_on_disk():
    """Every file under the three output folders that this script wrote."""
    found = set()
    for folder in OUT.values():
        if not os.path.isdir(folder):
            continue
        for name in os.listdir(folder):
            path = os.path.join(folder, name)
            with open(path, encoding='utf-8') as f:
                if emit.MARK in f.read(600):
                    found.add(path)
    return found


def rel(path):
    return os.path.relpath(path, ROOT)


def lint(paths):
    """`php -l` and `node --check`, where they are installed."""
    problems = []
    php = shutil.which('php')
    node = shutil.which('node')
    for path in sorted(paths):
        tool = php and path.endswith('.php') and [php, '-l', path] \
            or node and path.endswith('.js') and [node, '--check', path]
        if not tool:
            continue
        done = subprocess.run(tool, capture_output=True, text=True)
        if done.returncode != 0:
            problems.append(f'{rel(path)} does not parse:\n{done.stdout}{done.stderr}')
    return problems


PALETTE = ['#c0533a', '#3f7fa0', '#7a9a3a', '#8a5bb0', '#c79a2b', '#3a8f7a', '#b0507a', '#6b6b6b']


def draw(table, folder):
    """An SVG of each feature variant, to look at a table before using it:
    the plot's rim, the curves, and every place as a dot coloured by its
    first tag and numbered in fill order. North (z-) up. Nothing drawn here
    is a straight line: the rim and every curve are paths through points
    finer than a stroke."""
    from places import shapes
    corners = [(2.5, 0.0), (2.3, 2.3), (0.0, 2.5), (-2.3, 2.3), (-2.5, 0.0), (-2.3, -2.3), (0.0, -2.5), (2.3, -2.3)]
    rim = shapes.wander(shapes.spline(corners, per=20), 0.05, ('rim', table.stem))
    px = 100.0

    def xy(x, z):
        return f'{(x + 2.8) * px:.1f},{(z + 2.8) * px:.1f}'

    def path(points, closed):
        return 'M' + ' L'.join(xy(x, z) for x, z in points) + (' Z' if closed else '')

    written = []
    for nudge, places in enumerate(table.variants):
        out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {5.6 * px:.0f} {5.6 * px:.0f}" '
               f'font-family="sans-serif">',
               f'<rect width="100%" height="100%" fill="#f4efe4"/>',
               f'<path d="{path(rim, True)}" fill="#e4dcc8" stroke="#a89c80" stroke-width="2"/>']
        for name, variants in table.curves.items():
            closed, points = variants[nudge]
            out.append(f'<path d="{path([(x / 1000, z / 1000) for x, z in points], closed)}" '
                       f'fill="{"#d5e3d2" if closed else "none"}" fill-opacity="0.6" stroke="#5f7f5a" '
                       f'stroke-width="2"><title>{name}</title></path>')
        for i, (x, z, tags) in enumerate(places):
            colour = PALETTE[(tags[0] if tags else 0) % len(PALETTE)]
            cx, cz = xy(x / 1000, z / 1000).split(',')
            out.append(f'<circle cx="{cx}" cy="{cz}" r="11" fill="{colour}"/>'
                       f'<text x="{cx}" y="{float(cz) + 4:.1f}" font-size="11" text-anchor="middle" '
                       f'fill="#fff">{i}</text>')
        out.append(f'<text x="12" y="22" font-size="15" fill="#4a4030">{table.stem}, variant {nudge}: '
                   f'{len(places)} places, numbered in fill order</text></svg>')
        target = os.path.join(folder, f'{table.stem}-{nudge}.svg')
        with open(target, 'w', encoding='utf-8') as f:
            f.write('\n'.join(out) + '\n')
        written.append(target)
    return written


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n\n')[0])
    ap.add_argument('--check', action='store_true', help='fail if any written table differs from its spec')
    ap.add_argument('--list', action='store_true', help='say what each table holds')
    ap.add_argument('--draw', metavar='DIR', help='also draw each table as SVGs in DIR, to look at')
    args = ap.parse_args()

    tables = specs()
    want = {}
    for t in tables:
        want.update(t.files())

    if args.draw:
        os.makedirs(args.draw, exist_ok=True)
        for t in tables:
            for path in draw(t, args.draw):
                print(f'drew {rel(path) if path.startswith(ROOT) else path}')

    if args.list:
        for t in tables:
            counts = '/'.join(str(len(v)) for v in t.variants)
            curves = ', '.join(sorted(t.curve_names)) or 'no curves'
            print(f'{t.stem}: {counts} places in {t.nudges} variant{"s" if t.nudges != 1 else ""}, '
                  f'fields {list(t.fields)}, {curves}{", and JavaScript" if t.js else ""}')
        return 0

    on_disk = generated_on_disk()
    stale = sorted(on_disk - set(want))

    if args.check:
        problems = []
        for path, text in sorted(want.items()):
            try:
                with open(path, encoding='utf-8') as f:
                    have = f.read()
            except FileNotFoundError:
                problems.append(f'{rel(path)} is missing')
                continue
            if have != text:
                a, b = have.splitlines(), text.splitlines()
                at = next((i for i, (x, y) in enumerate(zip(a, b)) if x != y), min(len(a), len(b)))
                problems.append(f'{rel(path)} is not what its spec makes, from line {at + 1}:\n'
                                f'    written:   {a[at] if at < len(a) else "(nothing)"}\n'
                                f'    generated: {b[at] if at < len(b) else "(nothing)"}')
        for path in stale:
            problems.append(f'{rel(path)} was generated from a spec that is no longer there')
        problems += lint(want)
        if problems:
            print('The place tables are not what their specs make:\n', file=sys.stderr)
            for p in problems:
                print('  ' + p, file=sys.stderr)
            print('\nRun python3 tools/layouts/generate.py and commit what it writes.', file=sys.stderr)
            return 1
        places = sum(len(v) for t in tables for v in t.variants)
        print(f'{len(tables)} place table{"s" if len(tables) != 1 else ""}, {places} places, '
              f'{len(want)} files: each is what its spec makes.')
        return 0

    for folder in OUT.values():
        os.makedirs(folder, exist_ok=True)
    wrote = 0
    for path, text in sorted(want.items()):
        try:
            with open(path, encoding='utf-8') as f:
                if f.read() == text:
                    continue
        except FileNotFoundError:
            pass
        with open(path, 'w', encoding='utf-8') as f:
            f.write(text)
        print(f'wrote {rel(path)}')
        wrote += 1
    for path in stale:
        os.remove(path)
        print(f'removed {rel(path)}, whose spec has gone')
    print(f'{len(tables)} table{"s" if len(tables) != 1 else ""}; {wrote} file{"s" if wrote != 1 else ""} written.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
