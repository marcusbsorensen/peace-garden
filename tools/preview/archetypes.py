"""One plant of each of the twelve archetypes, side by side, at full bloom.

The acceptance test for `docs/PLANT-FORMS.md`, and the reason it exists: before
the forms went in, three plants side by side were the same plant three times. If
two tiles on this sheet still share a silhouette, the forms are not carrying
enough.

    python3 archetypes.py --out sheet.png
    python3 archetypes.py --archetype umbel --stages --out umbel.png

`SeedCore` is authoritative and this is a port, so use the sheet to judge
silhouette and then confirm on a simulator. Shape is what it is good for.
"""

import argparse
import math

from PIL import Image, ImageDraw

import plant_model
from plant_model import ARCHETYPES, Genome, build_skeleton, growth_state
from preview import mint_seed, render


def find_seeds(archetypes, limit=4000):
    """The first seed that grows each archetype.

    Searched rather than chosen, because an archetype is drawn from the seed and
    there is no way to ask for one.
    """
    wanted = {name: None for name in archetypes}
    for index in range(limit):
        if all(seed is not None for seed in wanted.values()):
            break
        label = f"form-{index}"
        genome = Genome(mint_seed(label.encode()))
        if wanted.get(genome.archetype) is None:
            wanted[genome.archetype] = (label, genome)
    missing = [name for name, seed in wanted.items() if seed is None]
    if missing:
        raise SystemExit(f"no seed found for {', '.join(missing)} in {limit} tries")
    return wanted


def caption(tile, text, sub):
    draw = ImageDraw.Draw(tile)
    draw.text((10, 8), text.upper(), fill=(232, 228, 216))
    draw.text((10, 22), sub, fill=(150, 146, 136))
    return tile


def sheet(archetypes, columns=4, cell=(300, 430), age=None):
    found = find_seeds(archetypes)
    rows = math.ceil(len(archetypes) / columns)
    out = Image.new("RGB", (columns * cell[0], rows * cell[1]), (0, 0, 0))
    for index, name in enumerate(archetypes):
        label, genome = found[name]
        days = age if age is not None else genome.daysToBloom + genome.bloomDays * 0.45
        state = growth_state(genome, days * 86400)
        tile = caption(
            render(genome, state, size=cell),
            name,
            f"{genome.inflorescence}  h={genome.height:.2f}",
        )
        out.paste(tile, ((index % columns) * cell[0], (index // columns) * cell[1]))
        branches = len(build_skeleton(genome, state["heightScale"])["branches"])
        print(
            f"{name:<10} {genome.inflorescence:<9} seed={label:<9} "
            f"height={genome.height:.3f}  branches={branches}  "
            f"petal={genome.petalLength:.3f}"
        )
    return out


def stages(name, cell=(300, 430), steps=6):
    """One archetype over its life — the check that a head divides gradually."""
    found = find_seeds([name])
    label, genome = found[name]
    full = genome.daysToBloom + genome.bloomDays * 0.45
    out = Image.new("RGB", (steps * cell[0], cell[1]), (0, 0, 0))
    for index in range(steps):
        days = full * (index / (steps - 1)) if steps > 1 else full
        state = growth_state(genome, days * 86400)
        skeleton = build_skeleton(genome, state["heightScale"])
        tile = caption(
            render(genome, state, size=cell),
            f"day {days:.1f}",
            f"{len(skeleton['branches'])} stalks  h={state['heightScale']:.2f}",
        )
        out.paste(tile, (index * cell[0], 0))
        print(f"day {days:>6.2f}  heightScale={state['heightScale']:.3f}  "
              f"stalks={len(skeleton['branches'])}")
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--archetype", type=str)
    parser.add_argument("--stages", action="store_true")
    parser.add_argument("--age-days", type=float)
    parser.add_argument("--out", type=str, default="archetypes.png")
    args = parser.parse_args()

    if args.stages:
        name = args.archetype or "umbel"
        image = stages(name)
    elif args.archetype:
        image = sheet([args.archetype], columns=1, age=args.age_days)
    else:
        image = sheet(ARCHETYPES, age=args.age_days)

    image.save(args.out)
    print(f"\nwrote {args.out}")


if __name__ == "__main__":
    main()
