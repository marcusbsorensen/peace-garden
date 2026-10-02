"""Arithmetic that comes out the same on every machine that runs the generator.

The tables are generated offline, so a `sin` here would never reach a phone or
the plot service. But `generate.py --check` regenerates them in continuous
integration, on Linux, and has to get the same bytes this Mac got: and
`math.sin`, `math.cos`, `math.atan2`, `math.exp`, `math.hypot` and `**` with a
float exponent are the C library's, which is the libm divergence of
22 September 2026 all over again (`VectorFile.swift` in SeedCore's tests).

So nothing here calls them. Turning is a polynomial, as `Organic.quarter` is;
an angle is found from a square root and a series; the only library function
used is `math.sqrt`, which IEEE 754 requires to be correctly rounded and so is
the same everywhere. Random numbers are SplitMix64 in Python's integers, not
the `random` module, so a seed means the same stream in every Python. And
floats are added left to right, never with `sum()`, whose rounding Python 3.12
changed.
"""
import math

PI = 3.141592653589793

# The golden angle as a fraction of a turn, (3 - sqrt 5) / 2: Vogel's sunflower.
GOLDEN = (3.0 - math.sqrt(5.0)) / 2.0

_MASK = 0xFFFFFFFFFFFFFFFF


def quarter(t):
    """cos and sin of t radians, for t in 0...pi/2, as `Organic.quarter` has them."""
    t2 = t * t
    c = 1 - t2 / 2 + t2 * t2 / 24 - t2 * t2 * t2 / 720 + t2 * t2 * t2 * t2 / 40320 \
        - t2 * t2 * t2 * t2 * t2 / 3628800
    s = t * (1 - t2 / 6 + t2 * t2 / 120 - t2 * t2 * t2 / 5040 + t2 * t2 * t2 * t2 / 362880
             - t2 * t2 * t2 * t2 * t2 / 39916800)
    return c, s


def cos_sin(turn):
    """cos and sin of a fraction of a turn. Turn 0 is x+, a quarter is z+: the
    way `PlotVariant` turns a plot and `Organic.outline` runs round one."""
    wrapped = turn - math.floor(turn)
    q = wrapped * 4
    leg = min(3, int(q))
    c, s = quarter((q - leg) * PI / 2)
    if leg == 0:
        return c, s
    if leg == 1:
        return -s, c
    if leg == 2:
        return -c, -s
    return s, -c


def _atan_unit(t):
    """atan of t in 0...1, by halving the angle twice and a series."""
    for _ in range(2):
        t = t / (1 + math.sqrt(1 + t * t))
    t2 = t * t
    total, term = 0.0, t
    for k in range(12):
        total += term / (2 * k + 1) if k % 2 == 0 else -term / (2 * k + 1)
        term *= t2
    return 4 * total


def turn_of(x, z):
    """Which way a point lies from the origin, as a fraction of a turn in
    0...1: 0 toward x+, a quarter toward z+. The inverse of `cos_sin`."""
    if x == 0 and z == 0:
        return 0.0
    ax, az = abs(x), abs(z)
    a = _atan_unit(az / ax) if az <= ax else PI / 2 - _atan_unit(ax / az)
    if x < 0:
        a = PI - a
    if z < 0:
        a = 2 * PI - a
    turn = a / (2 * PI)
    return turn - math.floor(turn)


def smooth(t):
    """Smoothstep on 0...1."""
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


def bump(d, width):
    """A soft bump, 1 at d = 0 and 0 from |d| = width out: (1 - (d/w)^2)^2.
    In place of a Gaussian, whose `exp` is the library's."""
    u = d / width
    return 0.0 if abs(u) >= 1 else (1 - u * u) * (1 - u * u)


def mix64(x):
    """SplitMix64's finaliser, as SeedCore's `mix64`."""
    x &= _MASK
    x ^= x >> 30
    x = (x * 0xBF58476D1CE4E5B9) & _MASK
    x ^= x >> 27
    x = (x * 0x94D049BB133111EB) & _MASK
    x ^= x >> 31
    return x


def key(*parts):
    """A 64-bit seed from any strings and integers, by FNV-1a over their text.
    Floats are refused: their text is not something to seed from."""
    h = 0xCBF29CE484222325
    for part in parts:
        if isinstance(part, float):
            raise TypeError('seed from strings and integers, not floats')
        if isinstance(part, (tuple, list)):
            part = key(*part)
        for byte in (str(part) + '\x1f').encode():
            h ^= byte
            h = (h * 0x100000001B3) & _MASK
    return h


class Rng:
    """SplitMix64, seeded from `key(*parts)`."""

    def __init__(self, *parts):
        self.state = key(*parts)

    def next(self):
        self.state = (self.state + 0x9E3779B97F4A7C15) & _MASK
        return mix64(self.state)

    def unit(self):
        """Uniform in 0...1, from the top 53 bits."""
        return (self.next() >> 11) * (1.0 / 9007199254740992.0)

    def uniform(self, a, b):
        return a + (b - a) * self.unit()

    def below(self, n):
        return self.next() % n


def _lattice(i, seed):
    return (mix64(seed ^ ((i * 0xD6E8FEB86659FD93) & _MASK)) >> 11) * (2.0 / 9007199254740992.0) - 1


def noise(t, seed, period=None):
    """Smooth value noise along a line, in -1...1, `t` in lattice cells. With a
    `period` in whole cells it repeats, so a closed outline has no seam."""
    cell = math.floor(t)
    f = t - cell
    a, b = cell, cell + 1
    if period:
        a, b = a % period, b % period
    va, vb = _lattice(a, seed), _lattice(b, seed)
    return va + (vb - va) * smooth(f)


def wobble(t, wavelength, seed, period=None):
    """Three octaves of `noise`, as `Organic.wobble` has them: an edge that
    wanders at a walking scale and is rough close to. In -1...1. `period`,
    if given, is a length in the units of `t` that the wander repeats over,
    rounded to whole cells of each octave."""
    total = 0.0
    weight = 0.0
    for octave, (scale, amount) in enumerate(((1.0, 1.0), (2.0, 0.5), (4.0, 0.25))):
        cells = t / wavelength * scale
        p = None
        if period:
            p = max(3, round(period / wavelength * scale))
            cells = t / period * p
        total += amount * noise(cells, mix64(seed + octave), p)
        weight += amount
    return total / weight
