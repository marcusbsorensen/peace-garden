# Water under a lotus in the Wild Fields, 2 October 2026

Renders to choose from. **Marcus chose b on 2 October 2026**; a and c were prototypes and are no longer in the code (docs/WEB-GARDENS.md §*Water under a lotus*).

- **now**: as it is today. A lotus lies on the grass, and on a slope its pads sink into it.
- **a, a pool where it stands**: each lotus has a seep the size of its pads, with its own water level, a wet margin and a lip of turf on the downhill side.
- **b, the hollow holds water**: the hollow that a lotus's water runs down into holds a shallow pond shaped by the land. A lotus in the pond floats; a lotus on a rise lies in a damp patch with water standing in its low spots. Most lotuses land on a rise: 26 of 27 in a field of 400.
- **c, the gardens' own pool**: the Cold Frame tank's water, dug under each lotus as a garden would dig it. It is round, has a silt lip, and its water lies five centimetres down.
- **b2, b as built for the live page**: the night sky in the ponds. The stars and haze the sky draws are mirrored in the water, and slow ripples make them waver and change the sheen; the fireflies' reflections sway with them. `b2-close.mp4` is seven seconds of the close view, to judge the ripples in motion.

Every view has the same plants and positions: 400 invented plants, plus three lotuses seeded round the field's deepest hollow at 46.7,55.4, 47.9,54.2 and 44.6,53.2. To draw b2 again:
`/dev/wild?plants=400&lotus=46.7,55.4;47.9,54.2;44.6,53.2&at=47.0,54.4` for the wide view, and `&at=48.85,54.85&zoom=2.1` for the close one. The first four were drawn by commit 704f93c with `&water=a|b|c`, a switch that is gone.
