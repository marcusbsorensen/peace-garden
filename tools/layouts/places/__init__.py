"""Place tables for the ten areas, made offline and written out as literal numbers.

`tools/layouts/README.md` says how to use it. The pieces:

- `numbers`: arithmetic that is the same on every machine (no libm trig);
- `shapes`: outlines, arcs and splines, and what can be asked of them;
- `sample`: blue noise in an outline, a sunflower, points along a curve;
- `order`: fill orders, farthest-first and centre-first;
- `Layout`, `Place`: what a table's `build(nudge)` returns.
"""
from .layout import Layout, Place, MM
from . import numbers, shapes, sample, order

__all__ = ['Layout', 'Place', 'MM', 'numbers', 'shapes', 'sample', 'order']
