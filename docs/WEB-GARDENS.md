# The web gardens and the Wild Fields

Asked for 18 September 2026, after the app's Garden screen became a place: a
floating isometric plot, a chosen ground, the sun and moon going round it, lights
to put out, and glow-in-the-dark figures (`ARRANGING.md`). This is the same
direction for the shared garden on the website, which **we curate**, and for the
Wild Fields, which nobody does.

Nothing here is built. The website cannot yet draw a plant (§*What has to exist
first*), and until it can, every decision below is a design and not a garden.

## The Wild Fields joined: the ponds, the worn paths and the ground, 2 October 2026

Three things built apart on 2 October are one field now, on
`worktree-agent-a16338ad17866618c`: the ponds Marcus chose (option B, the
hollows holding water near a lotus, with the night sky in them;
`wildwater.js`), the paths visitors wear with their paragraph on the privacy
page in 41 languages (`wear.js`, `WildWear.php`, `privacy9`), and the ground
close to (`wildground.js`). **Marcus chose the pasture on 2 October 2026**, so
it is the only sward and the meadow is gone from the code. **Wear is still off
unless `config.php` says `'wear' => true`**, which only a copy's own
`config.php` can say (the server's is written on the server and left alone by
the deploy), and `privacy9` shows only where it is on.

**How they meet** — the two plans in §*The Wild Fields' ground, close to*,
carried out:

- **The worn paths are the ground's `wear`.** `wornGround()` answers `glsl`
  (`WEAR_GLSL`, then `wearAt(p)` as `wornAt` at that point) with its one
  uniform, its texture on unit 2 and `set`, and nothing else: its shader
  rewrite (`withWear`, `trodden`, `flattened`) is gone. Worn ground is drawn
  by the ground's detail: the tufts thin, shorten and are pressed flat, and
  give way to bare earth, trodden paler, its crumb pressed together. The
  field still tells it what the middle of the window crosses (`looked`,
  `groundUnder`), and `/wild` still loads `wear.js` only where the service
  has wear on.
- **The ponds are the ground's `wet`.** The water answers `wetness(x, z)` —
  1 where its level is over the floor, else the larger of its margin's wet
  and mud — and `floorAt(x, z)`, and no longer paints the margin into the
  ground's colours (a tussock's top in a pond keeps its rush green). The
  stage makes the water first, stands the tufts and stones on its floor, and
  samples the wet into a texture (`fieldInput`, unit 3). Whenever what has
  arrived changes the water, the wet is sampled again and the tufts and
  stones grown again — where it changed.
- **Texture units:** the plants 0 and 1, the worn paths 2, the wet 3, and the
  sky the water mirrors 4 (it was 2, which the worn paths also bind).

**Where the joining went further than the plans, and why**, each judged on
renders or measured:

- **The margin's wet on the ground's own scale.** The ground reads wet as
  sedge from a third, mud from a half, and nothing growing past nine tenths,
  which is the water's. The ponds' wet and mud ran to 1, and taken whole a
  lotus's damp patch — wet across most of it — drew as a pale disc of
  glistening mud with no grass in it, nothing like the dark, rushy flush with
  water in its low spots of the renders Marcus chose. So each is answered on
  the ground's scale, at most (`ON_GROUND` in `wildwater.js`): a pond's bank
  at the water 0.75, sedge going over to mud; the mud at its edge 0.9; a
  damp patch 0.45, rushy grass with a little sedge; the silt in its low spots
  0.55.
- **The wet an eighth of a metre to a texel**, not a quarter. A pond's margin
  needs no finer, but a damp patch's puddles are a hand or two across, and at
  a quarter each spread a ring of bare mud round itself.
- **Grown again only where the water changed.** The water says where it has
  changed since it was last asked (`changes`, the bounds of every pond, damp
  patch or tussock that came or went); only those texels are sampled again,
  and only the squares they reach are grown again and laid where they lie.
  Growing everything in sight again for each lotus that arrived was most of
  what walking cost: about a second of growing over a nine-metre walk on the
  slowed phone, now about a tenth of that.
- **The water's features are kept by the 4 m squares they reach**, because the
  floor is now asked for at every square in sight every frame and for every
  tuft grown, and a field of a thousand plants has some sixty ponds and damp
  patches.
- **Nothing stands through a water lily's pads.** Out of the water its pads
  lie flat on the ground, and sedge and stones came up through them; under a
  lily's pads (`flat`, how far they reach) the tufts and stones give way, as
  they already did at a stem.
- **A frame drawn because the window moved counts as a frame of the
  ripples**, so walking past a pond draws the field once a frame and not now
  and then twice. With the ground's detail in every frame that doubling cost
  three to five milliseconds on the desktop.
- **The workbench** (`/dev/wild`): `?try=` and `?sward=` are gone; `?wear=demo`
  invents the paths, `?lotus=` places lilies, and `wear.js` is loaded only for
  `?wear=demo` or a local service with wear on, as the page does.
  `wild.stage.wetness(x, z)` and `wild.stage.counts()` are for render scripts.

**Checked**, with a local `config.php` turning wear on and with none:

- Every reference check CI runs passes, `check_curate.php`,
  `check_wild_fields.php`, `check_wild_wear.php` and `check_backup.php`
  among them; `tools/strings/check.py` has 41 catalogues with the paragraph
  on paths that visitors wear.
- `/wild`, `/dev/wild`, `/dev/wild?wear=demo` and `/dev/wild?source=service`,
  headless in Chrome, have clean consoles either way. With wear off `/wild`
  fetches no `wear.js`, nothing touches `/api/wild/wear`, which answers 404,
  and `/privacy` has eight paragraphs; with it on `/wild` loads `wear.js`,
  reads the field's wear, sends what a drag crosses when the page is put
  away, and `/privacy` has nine. The ten areas' pages, the front page and
  the privacy page have clean consoles too.

**What it costs**, on `/dev/wild?plants=1000`, measured as the ground's own
figures were (above) but with a harness of this joining's own, so the three
are compared on it: the stage's work for a frame while the window moves every
frame, a one-pixel read making it wait for the GPU, median and 95th centile in
milliseconds, two runs each; *slow* is frames more than 25 ms apart in the 300
of a walk. Headless Chrome on the M4 Max through Metal; desktop 1440 × 900 at
2×, the phone 390 × 844 at 3× with the CPU slowed four times (CDP).

| | still | walk | slow |
|---|---|---|---|
| desktop, the ground alone (7ef2b4a) | 10.4–14.0 (p95 12.5–15.9) | 10.1–12.2 (p95 13.5–16.3) | 24–26 |
| desktop, the ponds alone (1171d50) | 10.8–12.1 (p95 12.2–17.4) | 9.2–12.8 (p95 14.8–18.1) | 32–33 |
| desktop, joined | 11.2–11.6 (p95 12.2–15.4) | 10.7–11.5 (p95 14.0–14.3) | 27–32 |
| phone, the ground alone | 11.8–14.5 (p95 16.2–17.5) | 12.9–14.0 (p95 22.2–22.5) | 57–62 |
| phone, the ponds alone | 10.5–11.4 (p95 16.9–18.5) | 12.1–12.9 (p95 21.3–21.5) | 56–62 |
| phone, joined | 12.6–14.0 (p95 15.6–19.6) | 13.2–13.3 (p95 23.0–26.0) | 63–64 |

The frame held at sixty in every case. Joined costs what the ground alone
does, within the noise between runs, which is several milliseconds; the
ground's own figures above, from its own harness, are of the same size
(desktop still 10.6–13.7, phone still 13.7–13.9), though its *slow* counted
something else. What makes a walk's slow frames on the slowed phone is the
ponds' own: building the ground again near water takes 60 to 210 ms there,
as it did before the joining. It wants trying on a real phone before it goes
live, as the ground does.

**Renders**, night, in `design/wild-together-2026-10-02/` (1000 × 640 from
2×, reduced to 256 colours), every one over the same 400 invented plants and
drawn with motion reduced, so the fireflies and the ripples hold still:

- `pond-wide.png`: the field's deepest hollow holding its pond, lilies on it
  and at its edge, and a damp patch round a lily on the rise above, in pasture
  (`/dev/wild?plants=400&lotus=46.7,55.4;47.9,54.2;44.6,53.2&at=47.0,54.4`).
- `pond-margin.png`: its margin close to — mud at the edge, sedge on the
  bank, the stars in the water, and nothing through the pads of the lily on
  the bank (the same, `&at=48.85,54.85&zoom=2.1`).
- `worn-path.png`: the invented summer's desire lines through pasture, worn
  to bare earth, with wear on (`/dev/wild?plants=400&wear=demo&zoom=1.7`).

## The Wild Fields' ground, close to, 2 October 2026

Marcus, 2 October: *The textures of the earth have to be more realistic in the
Wild Fields. So as appropriate, have more realistic tufts of grass, pebbles,
grainy earth and so forth. Otherwise the difference between the landscape
itself and the incredible detail of the plants is too jarring.* A released
plant is grown from its seed with veined leaves and ribbed stems; the field it
stood on was one smooth shaded sheet, so every plant read as laid on a cloth.
Built in `wildground.js`, on `/wild` and `/dev/wild`; not merged or deployed.
Renders, before and after, are in `design/wild-ground-2026-10-02/`.

- **Tufts of grass are geometry**: one clump of blades drawn once and stood
  wherever the field has one (instancing), each its own height, turned, combed
  over by the wind so neighbours lean together, and coloured by the field's
  own green where it stands — lusher where the grass is thick, each tuft a
  little towards yellow or blue, some blades died back to straw. A few have
  gone to seed: a stalk over the blades and a head the colour of ripe grass.
  **Close to, the short grass between them is geometry too**, many times
  denser and a few centimetres high, growing in as the reader comes closer
  than about two millimetres to a pixel.
- **Pebbles are geometry**: a lumpy ball, flattened and sunk a quarter to a
  half into the turf, in the gardens' stones' colours (the slab's bedrock
  darkened to flint, the Knot's gravel, the Crossing's paving, and the
  gardens' earth for ironstone); a few anywhere, more on stony ground, now and
  then a little scatter together, and kept mostly where the earth shows,
  since under thick grass nobody would see them.
- **The earth and the mat are the ground's own shader.** Where the tufts are
  thick, the mat under them: the short grass's dark depths, mottled by the
  clumps, with blades lying across it, combed the same way. Where they are
  thin, earth, in gaps a hand or two across between tussocks rather than bald
  patches: the Home Ground's soil (`SOIL`, greyed for the field), its crumb —
  a jittered lattice, a tone to a crumb, wider where the soil is loose and
  narrower where feet have pressed it — pushed about so the crumbs are lumps
  and not a paving, clods, a grain of four millimetres, the odd pale grit, and
  each crumb a little dome so the galaxy finds it. Moss in the damp hollows.
- **Near and far go by zoom.** The view is true isometric, so nothing is
  further off than anything else; what changes is how close the reader has
  come. The tufts are drawn with 22, 15 or 10 blades by how much of the field
  a pixel covers, and never thinner than a pixel; stones with 320 or 80
  facets; and every grain of the earth fades to its own average once it is
  smaller than a pixel, rather than shimmering. At the widest look the field
  still reads as pasture, because the tufts are still there.
- **Placed by where it is.** Every tuft and stone comes from the square metre
  it stands in, by a hash of that square's number on the field, wrapped: the
  same for everyone, and the field meets itself where it comes round (checked
  on renders across the seam and the corner). How thick the grass is, and
  where the earth shows, is one sum the page and the shader both work out
  from integer hashes, so they agree and no tuft stands on bare earth. Every
  noise lies on a lattice turned off the field's axes by a whole step, which
  keeps it at an angle to everything and still lets it come round: no ruled
  lines, no tile.
- **Lit as the plants are**: the same sum (the galaxy, the night sky, the
  bounce) with the fireflies added by the field, and under a plant the same
  darkening its foot gives the ground. Beside a stem the tufts are shorter, so
  a plant's lowest leaves are not drowned, and none stand at the stem itself.
- **Pasture, chosen by Marcus on 2 October 2026** from renders of two
  (`design/wild-ground-2026-10-02/`): grazed short, 4 to 15 cm, earth showing
  between tussocks, rank patches left long to about 25 cm, a tenth of the
  tufts gone to seed, most of those in the rank grass. It is the only sward
  (`PASTURE` in `wildground.js`). The other was a meadow — uncut, 8 to 28 cm
  and rank to a third of a metre, thick, a quarter of it seeding, hardly any
  earth — and it and `?sward=` went when the three were joined (§*The Wild
  Fields joined*).
- **Not built: sway.** The stage draws when the window moves and not
  otherwise; grass that swayed would have the whole field, a thousand plants
  with it, drawn thirty times a second to move blades a few millimetres. The
  wind's combing is what stands for it, and costs nothing.

**Two inputs, for the field's other layers, that default to nothing.** Each
is GLSL defining `float wearAt(vec2 p)` or `float wetAt(vec2 p)` over the
field's unwrapped metres, with the uniforms it needs and a `bind(gl, at)` that
sets them; `makeWildStage` takes them as `wear` and `wet` and the detail binds
them on the ground, the tufts and the stones. `fieldInput(name, at)` makes
one from a function of the field sampled into a texture that repeats as the
field does (`set(at)` samples it again). `/dev/wild?try=wear`, `?try=wet` and
`?try=both` invented a path across the middle and a pond's margin beside it,
until the worn paths and the ponds were joined to it and gave it the real
ones (§*The Wild Fields joined*).

- `wear`, 0 to 1: tufts thin out (each at its own place in the order of
  giving way, so a path's edge is ragged), shorten and are pressed flat; the
  ground goes to bare earth, the Home Ground's path colour, its crumb pressed
  together; seed heads go first.
- `wet`, 0 to 1: the grass grows taller, stiffer, broader and darker, like
  sedge, from about a third; the earth darkens to the gardens' silt and
  glistens from about a half; nothing grows past nine tenths, which is where
  the water is.

The two plans below are as they were written before the joining; both were
carried out on 2 October 2026, and §*The Wild Fields joined* says where it
went further than they did.

**How the worn paths meet it** (`worktree-agent-ae92f34eae33f3ae0`). Its
`wornGround()` answers `{ shader, uniforms: ['wear'], bind, set }`, and
`shader` rewrites the ground's old fragment shader at three anchors this one
no longer has, so as it stands it would warn and draw no wear.

1. `wear.js`: `wornGround()` answers `glsl` in place of `shader` —
   `WEAR_GLSL` (its texture, its noise and `wornAt`) followed by
   `float wearAt(vec2 p) { return wornAt(vec3(p.x, 0.0, p.y)); }`. `trodden`,
   `flattened`, `withWear` and its anchors go: the detail does what they did,
   and thins and flattens the tufts as well, which a rewrite of the ground's
   colour could not.
2. `wildfields.js`: keep this branch's `groundDetail` and `ground` lines and
   drop theirs (`wear ? wear.shader(GROUND_FRAGMENT) : …`, `...(wear ?
   wear.uniforms : [])`, `wear?.bind(gl, ground.at)`); keep their `looked`
   option, `groundUnder` and the calls to `looked`.
3. `wildpage.js` and `wild.html` pass `wear: worn` as they do now. It binds
   texture unit 2; `fieldInput` defaults to 3; the plants use 0 and 1.
   `?wear=demo` is theirs and `?try=wear` this branch's; theirs can replace it.

**How the ponds meet it** (`worktree-agent-afbb63685ec62a87c`, Marcus's option
B, drawn on `/wild` for every visitor). The stage there makes the water itself
(`makeWildWater(e, { side, height })`), and the water's `sample` works out
`wet` and `mud` at a point and paints them into the ground's vertex colours
(`RUSH`, `SILT`).

1. `wildwater.js`: `sample` answers `wet` and `mud` along with `floor`,
   `level` and `colour`; and the water answers `wetness(x, z)` — 1 where its
   level is over the floor, else the larger of `wet` and `mud` — and
   `floorAt(x, z)`, `sample(x, z, height(x, z), [0, 0, 0]).floor`. The
   `wet → RUSH` and `mud → SILT` mixes leave `sample` (the tussock tops'
   `grass → RUSH` stays): the detail darkens to mud and grows sedge from
   `wetAt`, and with both the margin is darkened twice.
2. `wildfields.js`, in `makeWildStage`: make the water before the detail;
   give the detail `height: (x, z) => water.floorAt(x, z)` in place of
   `groundHeight`, so tufts and stones stand on a dug floor rather than over
   it, and `wet: fieldInput('wet', water.wetness)` (256 to a side, a quarter
   of a metre to a texel, which a margin a metre or two wide needs no finer
   than). Where `refresh()` finds `water.version` changed, call the input's
   `set(water.wetness)` and `detail.changed({ regrow: true })`. If sampling
   the whole field again on every lotus that changes the water shows in a
   profile, sample only that pond's box.
3. Their `refine` draws the fine ground near the water with the same `ground`
   program, so it has the detail as it is; the water's own program is not
   touched.

**What it costs**, measured headless in Chrome on the Mac's GPU (an M4 Max)
on `/dev/wild`, before (24c45e5) and after, twice each. *Cost* is the
stage's own work for a frame while the window moves every frame — drawing,
and waiting for the GPU to finish — in milliseconds, median and 95th
centile; *still* sways inside a metre, *walk* walks nine metres. Desktop is
1440 × 900 at 2×; the phone is 390 × 844 at 3× with the CPU slowed four
times (CDP). The frame rate held at sixty in every case (the median frame
was 16.7 ms everywhere); *slow* is frames over 25 ms in the 300 of a walk.

| | still, before | still, after | walk, before | walk, after | slow, before → after |
|---|---|---|---|---|---|
| desktop, 400 plants | 6.0–7.4 (p95 7.8–7.9) | 5.6–10.3 (p95 5.9–10.9) | 3.9–5.6 | 5.3–6.1 | 0 → 1–2 |
| desktop, 1000 | 10.4 (p95 11.5–11.6) | 10.6–13.7 (p95 12.2–15.5) | 8.6–9.9 | 10.5–11.0 | 1 → 1 |
| phone, 400 | 6.9–7.2 (p95 7.8–8.6) | 9.8–10.3 (p95 11.2–12.2) | 7.0–7.2 | 6.9–9.2 | 3 → 3 |
| phone, 1000 | 13.2–13.5 (p95 15.2–15.8) | 13.7–13.9 (p95 15.5–16.1) | 10.8–12.9 | 13.3–13.7 | 4 → 5–6 |
| phone, 1000, as close as it goes | 12.8 (p95 14.2) | 11.6 (p95 16.3) | 12.5 | 11.8 | 0 → 0 |
| phone, 1000, meadow | — | 10.7 (p95 13.8) | — | 11.1 | 4 |

Two runs of the same build differ by up to five milliseconds here, so read
the ranges rather than the digits: the detail adds about one to three
milliseconds to a frame's work, and at a thousand plants the plants are
still most of it.

- **At the opening look a phone draws about 14,000 tufts and 430 stones,**
  a desktop 12,000 and 360 (the pasture; the meadow about 18,000), and as
  close as the field goes 3,500 tufts and 6,800 of the short grass's.
- **What is in sight is laid a metre past the screen, and each square keeps
  its own run of the buffer while it is held.** A square coming into sight
  is laid into a free run, one going out is blanked where it lies, and the
  rest are not touched; it is laid again only when a square that is seen is
  not there, a plant comes or goes in one, or the look comes closer or goes
  further. Walking, that is about once every thirty frames, at about 2 ms on
  the slowed phone, and about 5 ms more the first time those squares are
  grown. Gathering everything again at every square's edge, as it first did,
  was most of what walking cost.
- **The GPU cannot be measured for a phone here.** On this Mac the ground's
  shader costs about 0.17 ms a frame on a phone-sized canvas and the tufts
  and stones about 0.14 ms (each drawn ten times over, blended, to make it
  measurable); a phone's GPU is perhaps ten times slower, so about 3 ms of a
  16.7 ms frame. It wants trying on a real phone before it goes live.

## The plot's side as a solid slab, 2 October 2026

The night the app's plot became a solid floating slab (`ARRANGING.md` §*A keel
that tapers to nothing*), Marcus approved it and asked on 2 October 2026 for the
website's plots to match it, so that a plot on the phone and a plot in the
browser read as the same object. Every plot on the site hangs it now: the ten
areas' own and the neighbours seen past them through the gateways. The Wild
Fields have no slab and did not change.

**One function, as in the app.** `hangSide` in `Server/assets/js/slab.js` hangs
the side from the plot's outline, which is still SeedCore's (`Organic.outline`,
through the module), so both start from the same rim. Every ground builder
hands it back as `side` and the stage draws it with a program of its own. The
upright bank had been written out eleven times — the walk's, the neighbours',
and one in each of the other nine areas — and is now one line in each.

What is the app's, number for number:

- **1.05 m deep, leaning in 0.20 m**, a little under the rim and more toward the
  foot, so it meets its lower edge at an angle and the near side still shows
  0.95 m from the front.
- **One lower edge**, undulating by about a tenth of the depth over a pace and a
  half and meeting itself round the loop; the old floor had a seam where the
  outline starts. The sag under a dip in the rim is there too and does nothing
  yet, because every plot on the website is level at its rim.
- **Lit as planes**: the facing smoothed over 18 cm either side, turned down by
  the lean, and lit by the whole of the light. The old bank took a normal per
  8 cm of rim and was lit in stripes.
- **Strata as bands**: humus a hand deep, earth, then rock (bedrock with some
  stone in it), each boundary wandering on its own, each band graded as the app
  grades it with faint layers in it, and a few angular stones in the rock with
  nine corners each, close to it in tone, drawn as the shadow each sits in, a
  body and an upper face.

What is different here, and why:

- **Drawn in along the way the rim faces, not toward the middle.** The app's
  plot is square, and so are nine of these, but the Long Walk is three plots
  end to end: drawn toward the middle, its long sides would have leant in
  barely 7 cm near its ends. Along the facing every side leans the whole
  20 cm; on a square plot that is within 5 cm of the app's anywhere and the
  same at the middle of each side and at each corner.
- **The website's light, and a lift measured against it.** The side is lit by
  `LIGHT`, the fixed noon sun, gamma-correct, and drawn 1.2 times lighter than
  its materials (`LIFT`) rather than the app's 1.45. Leaning in costs a face
  under a sun 62° up a fifth of its light; at 1.2 the face in the sun is as
  bright as the upright bank was (51 against 52 of 255, averaged down the face)
  and the face in shade a little brighter (33 against 27).
- **A stone's upper face is turned to the sky by 0.08, not 0.22.** At 0.22 it
  turned into the noon sun and came out two fifths brighter than the rock
  round it, and the stones on the face in the light read as the row of rivets
  the app's note warns about.
- **The bands are worked out per pixel.** The mesh is eight rows down and a
  column per point of the rim, a few thousand triangles; the shader works out
  the bands, their edges (softened over a pixel and a half) and the layers from
  where on the side each pixel is, so they stay sharp at the closest zoom.
- **Hung once a plot.** The side is the same from every quarter, so a turn,
  which builds the ground again, finds it already hung.
- `COLOUR`'s humus, earth and bedrock are read from `slab.js`, and `RIM_DEPTH`
  lives there, exported by `longwalk.js` as before. `BESIDE.deepest` did not
  move: the new lower edge comes less far down the screen than the old floor
  did, so the neighbours stand where Marcus last saw them.

**Measured** in headless Chrome on an M4 Max (ANGLE on Metal): one frame's
drawing and the wait for the GPU, median of three runs, before and after. At
1440×900 on a 2× screen the Knot Garden 3.0 → 3.1 ms, the same zoomed 2.5× onto
a side 3.0 → 3.8, the Orchard with its three neighbours 1.5 → 1.7, the Long Walk
7.8 → 9.0. At 390×844 on a 3× screen with the processor slowed four times, the
Knot Garden 3.5 → 3.0, the Orchard 1.5 → 1.7, the Long Walk 7.7 → 7.8. Every
view held sixty frames a second before and after, and a turn costs what it did.
The renders are in `design/web-slab-2026-10-02/`.

### Decided, 2 October 2026

Marcus's two answers, from the renders:

- **Deploy it now**, as built, with the one change below.
- **Stones only when zoomed in, on the website and in the app alike.** On the
  whole plot they were a sprinkle of pale flecks along the side; a stone is
  for a close look. So the whole plot has none, and close up none is drawn
  under eight points across as it is seen (CSS pixels on the website).
  - **Website:** none until the look is 1.3 times closer than the whole plot,
    which one press of the pad passes (`STONES` in `slab.js`, set by the stage
    as `stonesFrom`). Eight pixels alone would not have done it: a desktop
    window shows the whole plot at 100 to 140 pixels a metre, where the largest
    stones are 13 to 18 across, and only a phone's whole plot is small enough
    to lose them all.
  - **App:** none on the whole plot, only in the close drawing that is made
    once the plot is zoomed past 1.3, and there none under eight points at the
    zoom it is drawn for (`GardenGround.smallestStone`). It had been three
    points at whatever size the plot was drawn, so the larger stones showed on
    the whole plot. `PlotTests.testStonesOnlyWhenZoomedIn` holds it on a phone
    and an iPad.

`design/web-slab-2026-10-02/` has the website's whole Knot Garden with none and
the close view with them, and the app's 17:00 wide and close views
(`app-after-stones-…`).

## The Wild Fields built, 1 October 2026

Release sends a plant somewhere now. Marcus had released one believing it
went to the Wild Fields, and it had gone nowhere, so he asked for the place to
be built that day. §*The Wild Fields*, *Built*, has what was decided. The one
thing that could not be — whether the field may publish a released plant's
parents without the other gardener's say — Marcus settled the same day: the
plant goes as built, and release becomes a moment of contact, each gardener
choosing what of theirs stands beside it (§*Who stands beside it*).

On 2 October Marcus chose, from renders, how a water lily released there lies
in water: the field's own hollows hold it, near a lotus (§*Water under a
lotus*).

## The plants' shapes changed, 24 September 2026

Every plant was narrow and tall, and Marcus chose to change their shape
everywhere (`docs/PLANT-FORMS.md` §*Habit*, §*What holds a flower from
beneath*, §*A petal's outline*). The garden came down and out: over three
thousand crossings the median height is 0.87 m and the median spread 0.62 m
(measured over six thousand plants before, 1.00 and 0.45), and three plants in
ten are wider than they are tall. A lotus is a water lily 0.34 m tall, a succulent a rosette of 0.28. **Every measured number below was measured again the way it
was first measured, and changed where it changed**, so the cuts, fills and
margins in this document are the new shapes'. Names, areas, hues, colour
families, kinds and habits did not move; only heights did.

- **The cuts:** Long Walk 0.93/1.28 → 0.77/1.20, Quiet Garden 1.13 → 1.09,
  Crossing 0.97/1.43 → 0.91/1.30, Orchard 0.75/1.30 → 0.58/1.20 (the Knot
  Garden's with it), Cold Frame 0.85 → 0.38 → 0.50, Coppice 1.10 → 1.00, and the
  Glasshouse border its own again at 1.14 rather than the Orchard's.
- **The four cuts over all crossings were measured on one sample of three
  hundred** where each area had drawn its own, so the Orchard's crown and the
  walk's back cut, both the tallest quarter, are now one number.
- **The live garden is replanted** when the shapes go live: every stored seed
  grown again, every area's arrivals placed again in order (`tools/replant`).
- Where a design section below records what a simulation found before the
  shapes changed and nothing re-ran it, it says so.

## Every cut measured again, 29 September 2026

The re-roll of 28 September (the reed and the cushion as families, the spire
flowering from below) moved the population the cuts were measured on: the Knot
Garden's own five hundred ranked **164/234/102** against about 1:2:1, and the
Coppice's tests' stars stood at a median of 0.96 m under a cut described as
their median, 1.00. Marcus asked for every cut that is a median or a centile of
a population to be measured again, the way its own comment says it was measured.

**The garden-wide cuts are measured on three thousand crossings of three
thousand pairs now, not three hundred.** Three hundred of the same put the 25th
centile at 0.51 m against three thousand's 0.48, and the Knot Garden's own five
hundred at 0.42 — too loose to say a number to the centimetre. The heights run
**0.12 to 2.47 m, thirds at 0.62 and 1.07 m** (the Long Walk's synthetic
arrivals follow them).

| Area | What the cut is | Old | Measured | New |
|---|---|---|---|---|
| Long Walk | 42nd / 75th centile, three thousand crossings | 0.77 / 1.20 | 0.746 / 1.183 | **0.75 / 1.18** |
| Quiet Garden | 67th centile, the same | 1.09 | 1.076 | **1.08** |
| Crossing | 50th / 83rd centile, the same | 0.91 / 1.30 | 0.852 / 1.336 | **0.85 / 1.34** |
| Orchard | 25th / 75th centile, the same | 0.58 / 1.20 | 0.476 / 1.183 | **0.48 / 1.18** |
| Knot Garden | the Orchard's, named as the Orchard's | 0.58 / 1.20 | — | **0.48 / 1.18** |
| Glasshouse border | 75th centile of five hundred `light` plants, a label the tests do not use | 1.14 | 1.160 (1.157 on two thousand) | **1.16** |
| Cold Frame | median of its own five hundred's dry plants | 0.50 | 0.486 | **0.49** |
| Coppice | median of the design sample's stars (`tools/coppice/sample.json`, grown again) | 1.00 | 0.991 | **0.99** |
| Home Ground spire | median of 2,000 Home Ground spires (`tools/homeground`) | 1.346 | 1.261 | **1.261** |
| Home Ground umbel | the same, umbels; kept off the median | 0.930 | 0.932 | **0.930** |
| Home Ground rosette | the same, rosettes | 0.275 | 0.266 | **0.266** |

- **The Knot Garden ranks 142/250/108** at the new cuts, against 164/234/102;
  its own five hundred run shorter than the garden (their 25th centile is
  0.42), so it is nearer 1:2:1 without reaching it. Seventeen plots where it
  was eighteen, 93% of claimed places held.
- **Every cut stays clear of every recorded height** by more than the 0.01 mm
  two hosts may disagree by: every area's `placementCannotTurn` passes on the
  re-recorded vectors, and none needed nudging. The Cold Frame's is now asked
  of the plants under glass only: the tank reads no height, and at thirty-nine
  to a tank two lilies stood 4.8 µm apart.
- **The Coppice's samples were grown again** with `simulate.py`'s commands, and
  `simulate.py` leaves out the ambassador (a fern on a stool since the re-roll,
  whose young heights the sample does not record) from its cut-year measure.
  At 0.99 the fresh sample's stars go 49.4% to the back; the nearest of 2,118
  stands 0.21 mm from it.
- **The Home Ground's cache was cleared** before it was measured: it is stamped
  with the ground ambassador's height, and that plant did not change in the
  re-roll, so the tool would have answered with the old heights.
- The Long Walk's drift test was lowered from a half to 0.45: the share of
  plants in a drift sits at a half (146 of 300, 52% over larger samples) and
  a bar at exactly a half was failing on which three hundred were drawn.

## What was settled

Settled by Marcus, 18 September:

1. **Curating means designing the rules, not placing the plants.** For each of
   the ten areas we design a layout from the real practice of that kind of
   garden, and an arriving plant takes its place by the rule. We place by hand
   only what we choose to show off. This still works at ten thousand plants.
   Placing every plant would not: a queue of arrivals never ends.
2. **An area is many plots**, each the app's own floating square, each one bed
   laid out by the area's rule. One growing plot per area would be unreadable at
   any zoom once it held a thousand plants.
3. **The Wild Fields are uncurated, on purpose.** The gardens are what we look
   after; the wild is what nobody arranges.

## What this reverses

`WEBSITE.md` §*Walking it* settled on 3 September that **a plant's place comes
from its seed and never moves**: each area a 256 × 256 grid, a plant's cell two
slices of its seed hex, collisions allowed. Curating by rule replaces the first
half of that and keeps the second.

- **Kept: a plant never moves.** That was the point of deriving a place: a place
  somebody visited yesterday is still theirs today. It holds here too, and for
  the same reason.
- **Replaced: where it goes comes from the bed, not from the hash.** The seed
  cannot know which bed has room, or whether a tall plant belongs at the back
  of it. So a plant's place is **assigned once, on arrival, and stored**, and
  from then on it is as fixed as a derived one.

What made sorting wrong was that inserting one plant reshuffled everything after
it. Assigning a slot on arrival appends and never reshuffles, so the objection
does not apply. The cost is that a place can no longer be worked out in a
browser from the seed alone: the plot service has to say where a plant stands.
It already has to say which plants exist, so this is one more column, not a new
dependency.

## An area is a map of plots

Each area is a map of floating plots on the app's own projection: 5.2 m squares,
isometric, floating over the same sky. You walk the map, and come down onto a
plot. A plot is what the app's Garden screen is, so everything the app settled
carries over: the ground, the orbit, the shadows, the lights, the zoom.

- **A plot is a bed.** It has a template: slots, each with a role (back of the
  border, a specimen, a row in a drill), a spacing, and fixed structures (a
  hedge line, a frame, a bench, a path).
- **A plot fills, then the next one opens.** An arriving plant takes the first
  open slot whose role fits it (§*Slots and roles*). When no slot in the
  area's newest plot fits, it goes to the next plot, which is opened on the
  map in the area's own order: along the walk, round the crossing, out from
  the orchard's first tree.
- **A plot is never re-laid.** Changing an area's template changes the plots
  opened after the change, never the ones already planted. A curator who wants
  an old bed to look different is asking to move plants, and plants do not move.
  **Twice Marcus has chosen to re-lay the whole garden on purpose**, once for
  the plants' new shapes (24 September 2026) and once for the new layouts (2
  October 2026, §*The layouts of 2 October 2026*), each with one replant
  (`tools/replant`) that places every arrival again in order. Neither is a plot
  re-laid by a later arrival.
- **The map is fixed as each plot opens.** The map of an area grows at its edge;
  what is already there stays where it is.

### Slots and roles

A template says what goes where in terms a plant can answer from its genome,
without anybody looking at it:

| Role | Answered from |
| --- | --- |
| **Height class** — edge, middle, back | Mature height, from `PlantSceneBuilder.matureBounds`. The same number `GardenSprites` frames a plant by. |
| **Habit** — the plant's form | `Genome`'s archetype, and its spread against its height. |
| **Colour** — the flower's hue family | The palette, the way the app's *Colours* arrangement already reads it. |

There is no season to lay out by. A plant's bloom follows the day
(`diurnalFactor`), not the year, so the border books' rule of a succession of
flowering through the summer has nothing to act on.

**Best practice is mostly a rule about height and repetition.** Tall at the back,
low at the edge, and the same colour repeated so the eye travels: every border
book says it and every template below is a version of it. A plant that fits no
open slot in the newest plot takes the nearest slot that fits in the next one,
not a wrong slot in this one. A gap in a bed is a gap a later plant will fill;
a tall plant at the front is there for good.

## The layouts of 2 October 2026

**Decided by Marcus on 2 October 2026**, from the layout research
(`design/garden-layouts-2026-10-02/RESEARCH.md`): *lovely research, please
implement*. He took every recommendation:

- **every area takes option A**, its own kind of garden laid out again with
  curves, a focal point and the fill in mind;
- **every count looks finished**: places are offered focal place first, then
  farthest-first, so a plot of ten and a plot of a thousand both look composed;
- **plots vary by their number**, everywhere but the Knot Garden and the
  Glasshouse;
- **the live garden is replanted to match later**, in one step.

Each area's section below says what its new layout is, dated, after what it
replaced. The built notes, with the renders before and after, are in
`design/garden-layouts-2026-10-02/built/`.

**Marcus's answers on the built layouts, the same day**, each recorded again in
its area's section:

1. **Cold Frame**: a lotus takes **one** place in the new pond. For this area
   that replaces the rule of two places (25 September, kept with the bigger
   tank on 29 September). The Seedbed's two places are untouched.
2. **Crossing**: the narrower paths are kept, 0.9 m where a path comes onto the
   plot, narrowing to 0.7 m at the paving.
3. **Cold Frame**: five reed clumps of three are kept.
4. **Knot Garden**: the small rings stay on the diagonals.
5. **Glasshouse**: the dome is kept (eaves 2.2 m, crown 3.5 m), and a painted
   band is added along the staging.
6. **Quiet Garden**: the cut between back and arm is **1.04 m**.
7. **Home Ground**: the paths are **0.40 m** and the beds sway **about 0.15 m**.

### One foundation: `tools/layouts/`

Built first, so ten areas could be laid out on one set of parts.
`tools/layouts/README.md` says how to use it; this is what it is.

- **Place tables, made offline.** An area's places are written by a spec in
  Python (`tools/layouts/tables/<name>.py`) rather than worked out by the rule
  as it runs: outlines (`shapes`: wandering blobs, splines, offsets), places
  in them (`sample`: blue noise, a sunflower spiral, places along a curve), and
  the order they are offered in (`order`). `generate.py` writes each as a
  Swift `PlaceTable` (`WebGardens/Tables/`), a PHP class
  (`Server/.api/tables/`) and, where the page draws from it, a JavaScript
  module (`Server/assets/js/tables/`). A table also carries the curves its
  drawing follows, a pond's outline or a path's line, so the page cannot
  disagree with the rule about where the water is.
- **Exact on every host.** Places are written to the millimetre, and a spec
  uses the foundation's own arithmetic (`places.numbers`), never the C
  library's `sin` or `atan2`, so Linux and a Mac write the same bytes. A spot
  from a table is exact everywhere, so every area's vector file compares it
  with no tolerance. **A generated file is never edited by hand**:
  `generate.py --check`, in CI, fails on any byte its spec would not make.
- **Plot variants.** A plot is turned, mirrored and given a feature variant by
  its number (`PlotVariant` in Swift, `PlotVariant.php`, `variant.js`), so a
  thousand plots are not one plot a thousand times. Plot 0 is always the plan
  as drawn, no plot is laid as the plot before it, and every block of plots
  holds every variant. Each area declares its own space:

  | Space | Areas |
  | --- | --- |
  | fixed | Knot Garden, Glasshouse: a knot and a colour wheel have one way round |
  | four turns and a mirror, eight ways | Quiet Garden, Crossing |
  | four turns, a mirror and three feature variants, 24 ways | Orchard, Coppice |
  | a half turn and a mirror, four ways, so the path stays where it runs | Long Walk |
  | mirrored only, so plots alternate | Seedbed, Cold Frame, Home Ground |

- **A slot is stored, a spot is worked out.** The service stores a planting's
  slot and its nudge, never where it stands, and works the spot out each time
  it serves it: the table's place plus the nudge, turned for the plot. The
  nudge is added in the table's frame and then turned, so a nudge narrower one
  way turns with its row. That is why most areas' existing plots are re-laid
  by a deploy alone.
- **Fill order is the table's.** *Every count looks finished* is an order, not
  a rule: a rule takes the first free place in table order that it may stand
  in, and a table lists its places focal first and then farthest-first
  (`order.focal_first`), or centre first for a spiral. Where a rule picks a
  group first (a guild, a coupe, a lens), the order runs within the group.
- **The fill harness**, `tools/layouts/harness/`, grows each area's own
  thousand arrivals from SeedCore and places them with the rule as it is in
  the checkout, counting plots, places held and how full the settled plots are
  at 10, 100 and 1,000, against `baseline.json`: the rules of 1 October
  (`tools/layouts/BASELINE.md`). **At 1,000, no worse than the baseline** was
  every area's bar.

### What the ten hold, measured with all ten merged

The harness at 1,000 arrivals, on each area's own plants, with Marcus's
answers above applied. A figure that moved is shown as new (baseline).

| Area | Plots | Places held | Held in settled plots | Empty in settled plots |
| --- | --- | --- | --- | --- |
| Long Walk | **22** (24) | **94.8%** (86.9%) | **98.9%** (92.2%) | **11** (82) |
| Quiet Garden | 101 | 99.1% | **100.0%** (99.7%) | **0** (3) |
| Crossing | 46 | 90.7% | 92.6% | 78 |
| Orchard | 51 | 98.1% | 99.9% | 1 |
| Knot Garden | 33 | 94.8% | 99.1% | 9 |
| Seedbed | 36 | 73.8% | 77.3% | 370 |
| Cold Frame | 18 | 88.3% | 94.4% | 56 |
| Glasshouse | 33 | 94.8% | 98.7% | 13 |
| Coppice | 31 | 97.8% | 100.0% | 0 |
| Home Ground | 16 | 96.3% | 100.0% | 0 |

Two areas fill better and none worse. The Long Walk's rule and the Quiet
Garden's groups changed, and with them which plot a plant goes to. The
Glasshouse's pale pots take a different pot, which moves a few plants to
another plot, and the Seedbed and the Cold Frame offer a plot's places in a new
order. In the Orchard, the Coppice, the Crossing, the Knot Garden and the Home
Ground the same plants land in the same slots, and only where a slot stands
moved.

**What the replant needs**, area by area:

- **A deploy re-lays these by itself, with no row changed**: the Orchard, the
  Coppice, the Crossing, the Knot Garden and the Home Ground. Capacities and
  plot assignment are unchanged.
- **The Glasshouse** is re-laid by a deploy too; only its pale pots would sit
  where the old rule put them until a replant.
- **The Quiet Garden and the Cold Frame** are re-laid by a deploy onto their
  old slot numbers, which now mean other places: a group of three standing in
  three of the five's places, reeds in the open water and lilies in the reed
  clumps. The replant puts them right.
- **The Seedbed** is re-laid by a deploy onto its curved drills, each plant at
  its old place along its drill; its old plots keep their old claims and their
  sowing from the label until the replant gives them the new order.
- **The Long Walk must be deployed and replanted together**: a stored
  `slot_index` now means a place in the table, and an old row served after a
  deploy would stand in another tier.

`tools/replant` needs nothing new for any of them: no column changed.

## The ten areas, and what each is laid out as

Each area already has a name and a theme (`WEBSITE.md`, `strings.js`), and each
name is a real kind of garden with a real way of being laid out. The layout is
the one that kind of garden has always had, which is the whole of what
"best practice" means here: a knot garden laid out like a knot garden, not like
a border with a knot garden's name.

| Area | Theme | How it is laid out | Ground | Structures |
| --- | --- | --- | --- | --- |
| **The Cold Frame** | waiting | Two low glazed frames at the back, two ranks of six young plants in each, hardening off, and in front of them a pond planted as a pond: reeds in clumps on its margin, lilies in its open water (since 2 October 2026; four frames until 29 September, then a tank). **Every plant drawn young** — the young stages of what grows elsewhere — and nobody turned away. **Sixty-three a plot, 24 under glass and 39 in the water; what wants water goes in the pond, colour claims a frame and the height a plant will grow to orders its ranks**, tallest-to-be at the back under the high side of the glass. | Flat, gravel round the pond, soil inside the frames | Frames of boards, their lights propped open by day; the pond and its shelf |
| **The Home Ground** | ground | The kitchen garden: three beds 1.2 m wide, so no soil is ever stood on, swaying together in a lazy S (since 2 October 2026), paths of 0.40 m between, crops in rows square to each bed. | Dark soil, mounded into beds, no boards | None: the beds are the ground's relief. A stone trough at the foot of a path |
| **The Seedbed** | beginnings | Six drills of eight laid on the contour, each a gentle arc (straight until 2 October 2026), a label at the head of each, sown from its middle out. One kind repeated along a drill, not mixed; a drill of water lilies is flooded, and the water lies at the foot of the bed. | Fine tilth | Row labels |
| **The Coppice** | renewal | Three coupes of unequal size round a small sunny glade, divided by three bending rides (three bands until 2 October 2026), each coupe cut in its year of the rotation, so every stage stands at once. Stools scattered as a stand; woodland flowers in clumps along the ride edges, where the light is. | Woodland floor, gentle relief, a glade | Stools, the cut and the uncut |
| **The Long Walk** | travel | A double border either side of a path: interlocking drifts of five and three, each a lens slanting from the hedge to the path and holding one colour, tall at the back, graded cool–hot–cool along each plot (since 2 October 2026; rows in three tiers until then). The walk goes on; plots open end to end. | Level, a mown path, a bed of loam along each hedge | The path, a hedge behind each border |
| **The Quiet Garden** | peace | An enclosure: hedged, one bench, and more lawn than planting. A specimen by the bench, across a still pool a group of five, a group of three to one side, and one plant alone echoing the five (since 2 October 2026; groups of three in the corners until then). **The fewest plants per plot of any area, by rule.** Room is what it is for. | Lawn, a pool off the middle | A hedge round, a bench, stepping stones |
| **The Orchard** | kinship | Five trees on a quincunx, meadow beneath, and a guild of four under each: under an outer tree a crescent at its drip line turned toward the middle tree, under the middle tree a ring (since 2 October 2026). **Twenty a plot, and an arrival goes under the earliest tree with a place left**, so trees are dressed one at a time rather than five at once. The first area whose tallest thing is not something anybody grew. | Meadow, mown into a crescent under each outer tree, a disc under the middle one, and one way through | The five trees, a dipping pond |
| **The Knot Garden** | pattern | Low clipped hedging laid as interlaced rings, a ring round the middle and four small rings woven over and under through it on the diagonals, inside a softened square edging (since 2 October 2026; two bands each way until then), and eight compartments — four lenses and four crescents — each filled with one colour. **Thirty-two a plot, and a plant's colour decides which pair of opposite compartments it stands in**, its height where in the block. The first area whose rule reads anything but a height. | Flat, gravel | The woven hedging and its edging |
| **The Glasshouse** | light | A round house of glass (a span house until 2 October 2026): a ring of staging round its inside, its pots going round it as a colour wheel and a band of the hues painted along it, and a round bed in the middle under the dome for the tallest. Tender plants, set close to the glass for the light. | Floor tiles | The round house, the ring of staging, its pots |
| **The Crossing** | meeting | Four paths meeting at a centre, four quarters, one feature where they meet: the quadripartite garden, one of the oldest plans there is for a meeting place. Since 2 October 2026 each path turns in as it comes, all four the same way, so they meet the round rather than crossing it and each quarter wraps round the centre. Plants face the centre. **Twenty-four a plot, and an arrival goes wherever there is least**, so the four quarters grow together. | Grass, with four paths mown through it | The paths, a round of paving where they meet |

Three things follow from the table:

- **Two areas are neighbours because the two themes are** (`WEBSITE.md`), and
  now the layouts neighbour too. The Cold Frame stands above the Quiet Garden:
  a frame of plants waiting and an enclosure for sitting still, the same
  stillness at two scales. That was never designed; it came out of the themes.
- **The Quiet Garden is the one area where the rule is fewer.** Every other
  template asks how to fit plants in well; this one asks how few a plot can
  hold and still be a garden. It opens more plots than any other area for the
  same number of plants, and that is right: measured at five hundred, fifty-one
  plots against the Long Walk's eleven. **Built 21 September** — §*The Quiet
  Garden, built*.
- **Ten ambassadors, one per area** (`WEBSITE.md` §*The ambassador plants*),
  stand in each area's first plot. **The ten seeds exist, 20 September**
  (`SeedCore/WebGardens/Ambassadors.swift`), and **the Long Walk's is standing
  in it**, the same day — see §*The ambassador, standing*, which also answers
  what a specimen slot is for an area whose plots never reach an end. The other
  nine wait on their areas' rules.

### Structures need drawing properly

A hedge, a glazed frame, a bench, staging, a path edge. **Seven of them exist
now** — the row label for the Seedbed and the glazed frame for the Cold Frame
since this paragraph was first written. The first two were built for the Long Walk and are in the app and the
browser: a hedge (`GardenStructures.swift` — `HedgeLine`, `HedgePiece`,
`HedgeShadow`) and a mown path (`MownPath`), ported to `longwalk.js`. Then
`Organic.bench` for the Quiet Garden, `Organic.roundel` for the Crossing's
paving and `Organic.tree` for the Orchard. **The Knot Garden needed none**: its
woven bands and its edging are `Organic.hedge` at ankle height, which is the
first area built without a structure of its own and the point at which the
hedge stopped being the Long Walk's. It did need the hedge to bend — `bow`,
added on 23 September, stands a run's middle off the straight line between its
ends and leaves both ends flat, which is a sixth thing `Organic` knows how to
draw and the point at which a `Structures/` split is worth doing. The frame, the staging, the bed edging and
the row labels are still to come, and each belongs to an area that is not built
yet. They
carry the look of each area, and **they meet the same test the figures did**: a
hedge drawn as a green rectangle is clip art beside plants grown from a genome.
So they are modelled and lit the way the figures are, by the garden's own light
at its hour, and drawn once per turn of the plot. They are also **unnamed**, as
the worlds and the lights are: a named structure is forty-two translations.

## The Long Walk, built

The rule is in `SeedCore` (`WebGardens/LongWalk.swift`), where the plot service,
the website and the app can all read it. Built 18 September, with
`LongWalkTests`.

- **The plot:** a 1.2 m mown path down the middle, a border each side, a hedge
  from 2.3 m out, and 48 plants a plot. **Since 2 October 2026 each border is
  six interlocking drifts** (§*Interlocking drifts, 2 October 2026*, below).
  Until then each side had three tiers, each in two staggered rows of five
  front slots, four middle and three back, the tiers at different spacings so
  they staggered against each other too.
- **Tiers from measurement.** Across 300 crossings of 300 different pairs of
  parents, grown heights run 0.15 to 2.31 m, with thirds at 0.70 and 1.09 m. The
  cuts are at 0.77 m and 1.20 m instead, to match the number of slots in each
  tier (0.93 m and 1.28 m before 24 September 2026; **0.75 m and 1.18 m since
  29 September**, measured on three thousand after the re-roll, when the
  heights ran 0.12 to 2.47 m with thirds at 0.62 and 1.07). Crossings of one person with forty others ran taller and were half
  bells, so a sample from one gardener is the wrong sample.
- **The rule is that nothing stands in front of something shorter**, not
  "tall ones in the back row". A plant goes to its own tier in the oldest plot
  with room, or else the tier beside it where the heights around it still
  order, or else a new plot. **The test found why.** Filling by row alone, a
  few more tall plants than back slots left eleven of fifteen plots holding
  six to nine plants. Now every plot but the newest four is full.
- **Drifts of colour, capped at five**, then the same colour starts again
  further down the walk. Every plant is unique, so a border here cannot repeat
  a plant; it repeats a colour. **Since 2 October 2026 a drift is a lens of the
  table and the cap is the lens**: five places or three, one colour. Until
  then the cap was kept by refusing a slot that would join drifts past five,
  not by scoring it low: at two rows a tier, scoring let a plant between two
  short drifts make one of six.
- **A developer preview**: `-pgPlotSide 5.2` fixes the app's plot at a web
  plot's size, so a Long Walk plot can be looked at in the app's own renderer
  before the website can draw one.

**What looking found:** without the path and the hedges, a Long Walk plot is a
scatter of plants on grass. The rule is right and invisible. The structures are
not dressing; they are how a visitor can see the rule.

**The structures, built the same day** (`GardenStructures.swift`, shown by
`-pgArea longWalk`):

- **The hedges: tall yew behind the far border and low in front of the near
  one**, decided by the view, so they swap as the plot turns. Settled by Marcus.
  Looking down from one side, a 2 m hedge on the near side hid the whole border
  behind it. It isn't how a real garden is built; it is how this one is best
  seen.
- **No straight line anywhere in the garden** (Marcus, 18 September). Ruled
  edges round delicate flowers are jarring, so the ground's outline and sides,
  the path's verges and ends, and the hedges all wander. The shapes are
  SeedCore's `Organic` (`Morphology/Organic.swift`), so the app and the website
  draw the same ones, pinned in `OrganicTests`. The wander only goes inward
  from the plot's square, up to 0.16 m, so placement tests a point against the
  outline, not the square. Chrome outside the scene is not covered.
- **A hedge is grown, not built**: a loaf section, soft-shouldered, bulging and
  dipping along its length, its top undulating and its ends domed to the
  ground, with a leaf-grain texture. **Replaced 18 September**: it was a clipped
  box, square-ended. It is still drawn in pieces, each sorted by its own depth,
  because one picture cannot be in front of some plants and behind others; the
  pieces are cut from one continuous mesh and share their boundary rings, which
  is what the square ends were for (rounded pieces drew a seam at every joint).
- **A hedge's shadow is one shape on the ground**: its footprint, moved away
  from the light by its height over the light's slope. Sheared per piece like a
  plant's shadow, near noon each piece cast a hairline across the garden.
- **The path is mown in stripes along its length**, as a mower goes. Striped
  across, it read as paving slabs.
- **A hedge's top wanders** by up to 8% of its height over about 0.7 m, one
  line along the whole hedge. **Replaced 18 September**: it was cut level.
  Standing each piece at the hedge's height from its own ground still steps
  the top at every joint, so the top follows the one hedge's line.
- **Yew is picked brighter than yew**, the rule the bank of earth under the plot
  already follows: a vertical face gets the sky and little of the sun, and at
  yew's own darkness the face towards the path was black at midday. Brighter
  alone made it toy-green in the sun, so it is also greyed towards blue.

### Interlocking drifts, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026, with each plot graded
cool–hot–cool (his yes to the research's question 5). **The rule changed**: the
tiers' two staggered rows are gone, and three parts of the old rule became
rules about lenses. Notes and renders: `design/garden-layouts-2026-10-02/built/walk.md`.

- **The table**, `tools/layouts/tables/long_walk_drifts.py`
  (`PlaceTable.longWalkDrifts`, `LongWalkDriftsTable`,
  `tables/long_walk_drifts.js`): 48 places in twelve lenses, six to a border,
  5, 3, 5, 3, 5, 3 on the `x−` border and 3, 5, 3, 5, 3, 5 on the `x+`, so a
  lens of five faces a lens of three. Each lens slants from its back at the
  hedge, up the walk, to its tip at the path's edge, down the walk; it is
  1.3 m long along the walk, overlaps the next like slates, and its spine is
  bowed about 5 cm.
- **Tiers by depth along a lens.** A lens of five is back, middle, middle,
  front, front; a lens of three back, middle, front. A plot has 18 front, 18
  middle and 12 back places (the rows had 20, 16 and 12): front 0.90–1.22 m
  from the path's middle, middle 1.33–1.69 m, back 1.78–1.94 m. **The cuts are
  unchanged**, 0.75 m and 1.18 m.
- **The rule** (`LongWalk.Walk.place`, `LongWalk::place`), plot by plot from
  the oldest: a lens its colour has claimed, in its own tier; else a lens
  nobody has claimed, in its own tier; else a lens its colour has claimed, in
  the tier beside its own; only then a new plot. In a lens a plant takes the
  first free place of its tier in table order, the lens's middle first.
  - **A lens is a drift**, claimed by the colour family of its first plant and
    read off the plants. It holds only that colour.
  - **Cool–hot–cool**: a warm colour (families 0, 1 and 5) claims free lenses
    from the plot's middle out, a cool one the same groups of four ends first.
  - **Repetition**: a colour never claims a lens beside one it already holds,
    in its border or across the join with the plot before or after.
  - **Nothing stands in front of something shorter**, as before: by tier,
    within 1.3 m along the walk on one side.
- **Plots vary by number**, a half turn, a mirror or both (`LongWalk.variants`),
  so the path stays where it runs and the drifts slant one way and then the
  other.
- **The nudge is ±0.05 m** both ways, where it was ±0.10 m and ±0.14 m: the
  places no longer sit on a grid that needs hiding. The nearest two places are
  0.365 m apart, 0.22 m at the worst nudge; in the rows two plants could stand
  on one spot.
- **The page** (`longwalk.js`) lays each border as a bed of loam along the
  hedge, each lens running out from it to the grass verge, so the bed's front
  is scalloped by the drifts' tips, darker down each lens's middle so a
  part-sown drift's slant shows. The path, the rill and the hedges are as they
  were. The workbench takes `?plot=`.
- **The stored shape is the same**: `side`, `tier` and `slot_index`, the last
  now a place in the table (0–47) where it was a place in a tier's rows (0–9).

**The fill, at 1,000 of the area's own: 22 plots where the baseline took 24,
94.8% of places held (86.9%), 98.9% in settled plots (92.2%), and 11 settled
places empty where there were 82.** Every figure is better. On the area's own
thousand, no colour stands in two lenses side by side or runs across a join;
70% of the plants in the four lenses nearest a plot's middle are warm and 59%
in the four at its ends are cool.

**Deploy and replant together.** A stored `slot_index` served after a deploy
would stand at whichever table place has its number, often in another tier.
`tools/replant` writes the same columns, with no schema change. Capacity is
unchanged; plot assignment is not, and the live walk will take fewer plots.

**Decided, 2 October 2026: the drifts stay as built.** Marcus kept them,
knowing what they cost. **11.5% of settled plants stand one height tier from
their own band** (2.5% in the rows), never with anything taller in front of
them, in exchange for **22 plots and 98.9% of places held in settled plots**.
The rule tries the tier beside in an old plot before it opens a new one, and
that is what fills the plots. He declined the purer-tier variant, a plant
trying its own tier in every plot first, which measured 24 plots and 91.9%
held in settled plots.

**Left open:**
- **The near border's bed is mostly hidden** behind the low hedge from the
  page's eye, as its plants always were.
- **The path is unchanged**; bending it was option B.

## The ambassador, standing

**Built 20 September.** *Halula crassicaulis* stands at the head of the Long
Walk's first plot: `LongWalk.ambassador` in SeedCore, `Ambassadors.php` in the
plot service, held to each other by `tools/reference/check_ambassador.php`.

- **There is no specimen slot, and that is the answer rather than a gap.** This
  document asked which slot of a template an ambassador stands in. For a double
  border the honest answer is none: a walk's feature belongs at the end of its
  vista, and this walk has no end — its plots open end to end for as long as
  people go on meeting. What it has is a head. So the ambassador is simply the
  first plant the rule ever placed, and the slot it took is the first slot of
  its own tier at the start of plot 0.
- **It could not have been the tall one at the back.** *Halula* is 1.04 m, the
  middle of a border. Measured across the ten, only *Cyninora contorta* is a
  back-tier plant at all, so a specimen fixed at the back of a border would have
  stood a short plant behind taller ones in nine areas out of ten, which is the
  one rule the Long Walk is built on. **A specimen slot has to be a slot the
  area's own ambassador can actually stand in**, and that is a constraint on
  every template still to be written.
- **It is not a row.** A slot and a nudge are both pure functions of the pinned
  seed, so the placement is derived on each side rather than stored on either:
  the Swift records it, the PHP re-derives it, and the check holds the two
  together. That also makes *nobody put it there and nobody can take it away*
  structural rather than a promise — there is no row for a withdrawal, a report
  or a backup to reach, and `WalkStore` refuses to plant an ambassador's seed at
  all.
- **The rule sees it.** The service hands it to the placement rule ahead of the
  stored arrivals, so every plant shared since has been graded against a border
  with its oldest plant in it. Handing it over afterwards would have drawn a
  plant nothing was placed around.
- **The walk is never empty.** `GET /api/walk` has said one plot since the day
  the garden opened, and `/walk` has had something in it to look at before
  anybody shared anything — which is what an ambassador was for.
- **A planting with no parents grows from its seed.** An ambassador was minted,
  not crossed, so the service sends it with an empty `parents` and no meeting,
  and `longwalk.js` grows it with `pg_grow` rather than `pg_grow_hybrid`. The
  empty list is how the wire says *this plant has no lineage* without a new
  field.

**Flipped while the walk was empty**, the same argument as the area flip the day
before: the walk is append-only, so the ambassador could be its first planting
only until somebody else's plant arrived. It had none.

**Since 2 October 2026 the walk's ambassador** (*Zephea pallida* since the
re-roll of 28 September, red, front tier) **stands at the tip of the first warm
lens, in the middle of plot 0**, rather than at the plot's head: the drifts are
graded hot in the middle. It is still derived rather than stored, so it moved
by itself; `ambassador_vectors.json` was re-recorded for its one line.

## The Quiet Garden, built

The rule is in `SeedCore` (`WebGardens/QuietGarden.swift`), where the plot
service, the website and the app can all read it. Built 21 September, with
`QuietGardenTests`, `QuietGardenVectorTests` and
`tools/reference/check_quiet_garden.php`. Live at `/quiet`.

- **The plot:** a 5.2 m square with a hedge round all four sides, its inner face
  2.3 m out, so the room is 4.6 m across. A bench lies across one corner and
  one plant stands beside it. **Ten plants a plot**, against the walk's
  forty-eight in the same square. **Since 2 October 2026** the other nine are a
  group of five across the water from the bench, a group of three along one
  side and one plant alone echoing the five (§*An asymmetric room, 2 October
  2026*, below). Until then each of the other three corners held a group of
  three at the foot of the hedge, and the middles of all four sides stayed
  grass.
- **A still pool in the middle, from 27 September, and two lilies in it.** The
  garden had no water anywhere, though `Archetype.lotus` has been modelled as a
  water lily since the shapes changed on the 24th — pads lying one against
  another, a flower smaller than the pads — and was being sown in a drill.
  Marcus asked where the water was and the answer was nowhere.
  - **Every area needs one, not the ones it suits.** An area comes from the
    seed's theme and not from the plant's shape, so a lotus lands in whichever
    of the ten its own seed names. One pond would catch a tenth of them.
  - The Quiet Garden is at the foot of the garden's slope (`COLUMN_RISE`), so
    this is where the water gathers. It was 2.2 m across in the middle of the
    lawn; **since 2 October 2026 it lies off the middle toward the bench, 2.1 m
    long and 1.2 m wide**, longer across the bench's line of sight than along
    it, and the nearest dry place is 0.87 m from the water (0.73 m after the
    largest nudge in five hundred), so nothing dry can drift in.
  - **Two lilies, and the number is the lilies' not the room's**: grown here a
    lotus's pads reach a median 0.51 m from the stem, so two side by side lie
    against each other, which is what a lily's pads do. A third would be a lily
    under a lily. They lie along the pool's length, so somebody sitting on the
    bench looks across the water at them.
  - **A lily takes no nudge.** The nudge makes a group of three read as a clump
    rather than a planting plan; two lilies in a small pool are neither.
  - **The room is two larger, not two rearranged.** The pool went in the middle
    of the lawn, which held nothing, so it took no planting place to pay for
    itself. The ten dry places are untouched and still a quarter of the walk's
    forty-eight — `testItHoldsAQuarterOfWhatTheWalkDoesInTheSameSquare` counts
    them dry now, because a pool is not planting.
  - **Full means its ground is full.** A pool fills only when a lily arrives,
    and lilies are one arrival in twelve, so a plot counted with its water in
    would almost never be full and the fill check would be measuring the draw
    rather than the rule.
  - `Corner.pool` is raw value 4, appended, so every planting already filed
    decodes as it did. `quiet_garden` gains a `habit` column by the same
    idempotent ALTER the Seedbed and the Cold Frame use.
- **No tree.** WEB-GARDENS said an enclosure has one. Nothing grown here is a
  tree: heights run 0.15 m to 2.31 m, which is a shrub at best, and a drawn tree
  among plants grown from a genome is the clip art this document warns about.
  Marcus dropped it on 21 September, and **the specimen is the plant by the
  bench** instead.
- **The specimen is the plot's first plant.** Not a reserved slot: a new plot is
  opened by taking its bench slot, so the plant beside the seat is always the
  oldest thing in the room. The same answer the Long Walk reached by a different
  route, and the reason this template can take a 0.55 m ambassador — a plant
  standing alone in grass beside a seat has no height to live up to.
- **A group is one colour, or a tone of it.** A group's colour is set by its
  first plant. An arriving plant takes a group of its own colour, else opens an
  unplanted group, else joins a group of a colour near its own — the two arcs
  either side, or pale. (Since 2 October 2026 the groups are the five, the
  three and the echo, tried in that order; the echo is never opened on its
  own, it waits for the five's colour.) **The near-colour fallback is not a
  nicety.** The seven
  families are nothing like evenly drawn: measured over three hundred crossings,
  two of them take 43% of plants between them and pale takes 3.7%, so own-colour
  alone would leave pale groups that never filled and plots that opened for want
  of a match.
- **Nothing stands in front of something shorter**, as on the walk, at the scale
  of a group: every back of a group is at least as tall as every arm. The cut
  between back and arm was 1.09 m (1.08 from 29 September 2026), the 67th
  centile of the measured spread, because a group was one back and two arms.
  **1.04 since 2 October 2026, Marcus's decision**: the group of five has two
  backs where a group of three had one, and 1.04 is the 67th centile of this
  area's own plants, as the Cold Frame measures its cut on its own. It is not
  the walk's 1.20 m and should not be — that one divides three tiers in the
  proportion 5:4:3.
- **How it fills, at five hundred:** 51 plots, 49 of them full, the two at the
  growing end holding seven and four. Of the plants that joined an existing
  group, 188 matched its colour exactly and 109 were a tone of it. (Measured on
  any crossings, before the rooms of 2 October; below is the fill now, on the
  area's own plants.)
- **The hedge's ends are cut square, not domed.** A free-standing run ends in a
  long shoulder falling to the ground over half its height — a metre on the tall
  ones — which leaves a notch at every corner you can see the sky through. Round
  an enclosure each run carries on into the next, so `Organic.hedge` gained a
  `domed` flag and the four runs overlap by a hedge's thickness.
- **Tall on the two far sides, low on the two near**, the rule Marcus settled for
  the walk on 18 September, now applied four times. Where a tall run meets a low
  one at a corner there is a step, which is what a hedge cut down to keep a view
  actually looks like.
- **The bench is sawn, not grown** (`Organic.bench`): a plank across two plank
  ends, its wander a twentieth of a hedge's and all of it in the softness of the
  edges. A hedge undulates because it grew; a bench was made, and one that
  undulated the same way would read as melted.
- **It has a back, decided 21 September.** Backless it read end-on as a single
  upright panel four tenths of a metre across and nearly square — a slab — and
  two of the four quarter turns put it that way, so half of all views of the
  room had it. A post over each end carries two rails, which puts a shoulder in
  the silhouette; the daylight between the rails is the point of there being two
  of them, since a back in one piece is the same panel the ends already are. The
  back stands on the bench's `+x`, which the room turns to point into the
  corner, so a sitter faces the lawn with the hedges behind them.

**What looking found:** the template was right first time, which the walk's was
not — because it borrowed the walk's shape (a first choice, a near-enough
second, a new plot only when neither fits) rather than inventing one. What
looking *did* change was the drawing: the corner notches, the bench lying along
its corner's diagonal instead of across it, and a room framed so tight that the
page's own prose landed on the lawn.

### An asymmetric room, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026. Notes and renders:
`design/garden-layouts-2026-10-02/built/quiet.md`, and
`quiet-after2-full.jpg` for a full room at the new cut.

- **The ten became one, five, three and one**, from a table
  (`tools/layouts/tables/quiet_room.py`, `PlaceTable.quietRoom`,
  `QuietRoomTable`), twelve places in fill order:
  - **the specimen** by the bench, where it has stood since 21 September;
  - **a group of five** in the far corner, across the water: what the bench
    looks at. Two backs toward the corner and three arms;
  - **a group of three** along the side to the bench's left, a third of the
    way down it: one back and two arms, a scalene triangle;
  - **the echo**, one plant alone across the lawn from the five, showing the
    five's colour;
  - **the pool's two places**, along its length.

  Each group's places are blue noise in a blob at the hedge's foot, nearest
  the corner first, then farthest-first. The groups ride in the old corners'
  numbers (`five` is what `second` was, `three` what `third` was, `echo` what
  `fourth` was), so a slot is still `corner` and `index` in the store, on the
  wire and in the replant.
- **The rule** (`QuietGarden.Room.place`, `QuietGarden::place`): own colour
  (the five, the three, then the echo); a group nobody has planted (the five,
  then the three); a colour near its own (a group whose colour is a tone of
  it, and the echo if it is a tone of the five's); else a new room, opened by
  the specimen. *Nothing stands in front of something shorter* is asked by
  stand rather than by index: every back of a group is at least as tall as
  every arm. A lily still goes to the pool and nowhere else; the live garden
  never sends this area one.
- **Three stepping stones** run from the seat to the pool's bay on the bench's
  side: low flat ovals drawn on the page only, with no structure in the app.
- **Every room is turned and mirrored by its number**, eight ways. The bench is
  always in a corner looking across the water at the five; the three falls on
  either hand. The service sends the turned spot (`QuietGarden::spotOn`).
- **The page rebuilds the ground for each room**: the pool from the table's
  outline, turned, with a bank; the lawn walked round it; a mown stripe
  stopping at the water's own edge in 6 cm pieces. The workbench draws only
  the area's own plants (`pg_room_arrive`), plumes and poppies.
- Nearest two of the five 0.61 m apart, of the three 0.60 m (0.85 m in the
  old groups of three); a plant's nudge 0.13 m, unchanged.

**The cut, decided by Marcus on 2 October 2026: 1.04 m.** Built at 1.08, the
settled rooms held 99.5% at a thousand arrivals against the baseline's 99.7%,
and all five empty places were backs of the five, which needs two tall plants
of its colour where a group of three needed one. At 1.04, re-recorded in the
Swift and the port, **the settled rooms hold 100% at 100 and at 1,000 with none
empty**, and plots and places held are the baseline's: 101 rooms, 99.1% held at
1,000. At ten arrivals room 0 holds six plants and room 1 five, both composed: a
room has two groups a colour can open where it had three, so a third colour
opens the next room sooner.

**The replant is needed.** Capacities are unchanged (ten on the ground, two in
the pool), but plot assignment is not. Served from slots chosen for groups of
three, a deploy alone would stand corner 1's three in three of the five's
places and corner 3's three all on the echo's one place. `tools/replant` needs
nothing new.

**Left open:** the echo is the five's own colour in 22 of 43 rooms at 500 (20
of 43 at 1.08) and a tone of it in the rest, because a tone can reach the echo
before a plant of the five's own colour does, and keeping it longer for its
own colour would cost fill; in some turns the bench is in the near corner with its
back to the reader, behind the low hedge, which is the eight ways working.

## The Orchard, built

21 September, the same day as the other three. `SeedCore/WebGardens/Orchard.swift`,
`Server/.api/Orchard.php`, `OrchardStore.php`, `Server/assets/js/orchard.js`,
`/orchard`, `/dev/orchard`, `tools/reference/check_orchard.php`, and
`Organic.tree`.

- **Twenty a plot: five guilds of four.** Between the crossing's twenty-four and
  the room's ten. Four is one place nearest the middle of the plot, two beside
  the trunk and one furthest out, so a guild faces the middle exactly as a
  crossing's quarter does. **Since 2 October 2026 an outer guild is a crescent
  at its tree's drip line**, turned toward the middle tree, and the ranks
  still read outward (§*A meadow orchard, 2 October 2026*, below); until then
  it was a square of four about its trunk.
- **The rule is *finish one guild, then start the next*** — the Crossing's rule
  turned inside out, and the reason to build a fourth area at all. What it
  guarantees is that **no guild is started while an earlier one stands empty**,
  and that **a free place in an earlier guild is one nobody in a later guild
  could have stood in**. It does *not* guarantee that the counts fall from guild
  to guild: 4 4 4 3 4 is correct, because a guild's last place holds the
  tightest constraint in the plot and may wait a long time for a plant tall
  enough. Both `check_orchard.php` and `OrchardTests` asserted the falsehood
  first, both passed on their own five hundred, and the workbench at
  `/dev/orchard` — which draws a different five hundred — is what showed it. The Crossing
  looks for a plant's own rank across every quarter before it will accept a
  neighbouring rank, because its business is keeping four beds level. This looks
  through every rank of the earliest unfinished guild before it will move to the
  next guild. **The two loops nested the other way round is the whole
  difference**, and it is what the port has to get right: a port with them
  swapped agrees about the first four plants of every plot, about every plot's
  total, and about most placements after that.
- **The five trees are structures, not plantings.** `Organic.tree`, standing in
  every plot from the day it opens, a row in no table — the roundel's move
  again. The alternative, the tallest arrivals becoming the trees, leaves a new
  plot with five empty tree slots and guild places that mean nothing until a tall
  plant happens along. What it costs is that this is the first area where a
  gardener's plant cannot be the tallest thing in the plot; the Quiet Garden's
  bench is the precedent that says an area may hold something nobody planted.
- **The middle guild has no ranks at all**, and it is not a special case bolted
  on. Every rule here orders plants outward from the middle of the plot, and the
  four places under the middle tree are all the same distance from that middle —
  there is no in-front-of among them, because the middle tree is the one you can
  walk all the way round. It is the Crossing's *three sharing an arc* applied to
  a whole guild. It is also what makes the rule work: the first four arrivals go
  under the middle tree whatever they are, so a plot never opens by turning
  somebody away, and the 1.34 m ambassador — the tallest of the ten — has
  somewhere to stand that is not the back of a guild.
- **Cuts at 0.58 m and 1.20 m**, measured at the 25th and 75th centiles of three
  hundred crossings for a guild of 1:2:1 (0.75 m and 1.30 m before 24 September
  2026; **0.48 m and 1.18 m since 29 September**, on three thousand). The fourth division of one population by a fourth template, and its
  crown is the walk's back cut: both are the tallest quarter.
- **At 500 arrivals: 26 plots, 24 exactly full**, the twenty-fifth holding
  nineteen and the twenty-sixth two. An older plot goes on receiving after a
  newer one opens, because `place` scans plots oldest first every time.
- **Four plants in five get their own rank, where the Crossing gets 95.4%.**
  Preferring the guild over the rank means a guild of four takes whoever arrives
  next rather than waiting for the right height. 321 of 399 in their own rank, 44
  one step out, 34 one step in, none further. **It is not a visual fault**:
  `inOrder` is what guarantees the picture and it holds for every plant. A rank
  is the height a place was meant for; `inOrder` is what a visitor sees.
- **The rule held first time**, as the room's and the crossing's did, and the
  port agreed with the Swift on all five hundred at the first run.
- **What looking found was all in the tree.** `Organic.tree` is the second
  structure that is neither hedge nor bench, and it took four passes, which is
  the roundel's number:
  - **Too big and too low.** A 1.7 m spread on a 1.55 m crown covered the
    planting from every angle — and an orchard where you cannot see the guild is
    five trees. Lifted and narrowed.
  - **A green balloon on a stick.** The lumpiness was set at 0.20 of the radius
    from `wobble`'s -1...1 range, but value noise only touches its ends: a
    typical reading is about a third of the range, so the canopy came out a
    twelfth out of true instead of a fifth. 0.55, and one octave nearly as broad
    as the tree, is what made a canopy lopsided rather than merely bumpy.
  - **Faceted.** Flat shading was tried first, on the roundel's precedent, and
    it made a polyhedron. The roundel is flat because paving *is* faces; a
    canopy is a grown thing and belongs with the hedges, which are smooth. Once
    the lumpiness was strong enough, smooth normals read as foliage.
  - **A star at every treetop**, twice over. The canopy's two poles are one
    point held by twenty-five vertices, and `computeNormals` gave each only its
    own faces; and the per-face colour hash gave tiny touching triangles wildly
    different greens. One averaged normal for the pole ring, and a tone read
    smoothly off each vertex's own height, and it is gone. Both are the same
    fault the roundel had in its third pass: **the mesh showing through its own
    shading.**
- **The mown ground under each tree is the guild made visible.** Grass left
  long between the trees and cut back round each trunk is what an orchard is,
  and it is also the only thing on the page that says which four plants belong
  to which tree — without a line being drawn anywhere. A disc under every tree
  until 2 October 2026; since then a mown crescent along each outer guild's
  arc and a disc under the middle tree, with one mown way through.
- **The discs and the meadow stay on the slab** (25 September 2026). Marcus
  saw the grass under the four outer trees overflowing the plot's edge. The
  outer trunks stand 1.70 m out and the wandering edge is 0.74–0.78 m beyond
  them, so a disc of 1.07 m radius hung a third of a metre into the sky — and
  had since the Orchard opened; the shadows of 24 September did not cause it.
  The meadow under it was a square grid 2.54 m either way on an outline that
  comes in to 2.42 m, so it overhung too, as a ruled edge with four corners
  poking out. Now the meadow is rings drawn in from the outline itself, and
  each disc's rim is the lesser of its wandering circle and the distance to
  the edge, rounded where one turns into the other: where a tree is near the
  edge the cut runs to the lip and stops on it. **On the edge, not short of
  it**, because a guild's outer plant can stand within a centimetre of the
  edge (6 mm in the workbench's five hundred), and a strip of meadow left
  there would put a plant out of its own disc. Checked on the geometry: no
  rim or meadow point off the plot, and every one of 501 spots inside its disc.
- **The same square was under five more areas**, found the same day by
  measuring every ground builder against its own outline. The Crossing's rough
  grass (now rings from the outline, as here) and its two mown paths, which
  ended in a ruled cut and now run to the edge and stop on it; the Knot's
  gravel, the Cold Frame's gravel, the Glasshouse's tiles and the Seedbed's
  tilth, all laid inside a 2.54 m square and overhanging by up to a third of a
  metre; and the Quiet Garden's stripes. `keepToPlot` in `longwalk.js` is the
  one move for all of them — a sheet laid a little wider than the plot, each
  point past the edge pulled straight in onto it, 4 mm inside — and
  `rimReach` beside it is what the discs here use. The Coppice and the Home
  Ground already kept theirs to the rim.
- **The hedges are pulled inside too** (Marcus's choice, 25 September 2026).
  The Long Walk's stood 0.27 m over the long sides and the Quiet Garden's
  crossed 0.49 m out at its corners, where the plot's corners are rounded.
  Where the places are is the rule's (`hedgeFrom` 2.3 m in both), and none
  of it moved: only where the hedges are drawn did. `hedgeToPlot` in
  `longwalk.js` leaves the inner face where the rule has it and presses what
  lies beyond onto the band between it and the plot's edge — straight across
  along a side, fanned from the inner corner at a corner, as a tanh so the
  hedge keeps its own shape near the inner face — and `pressNormal` turns the
  pressed outer side to face out. So each hedge's outer side is now flush
  with the slab's side and follows its wander, and the walk's hedges are
  0.11–0.25 m through at the foot where they were 0.33–0.40. Their shadows are
  worked from the pressed hedge. Measured on the workbench's five hundred in
  each area, at every turn: every hedge point on the plot, no plant inside a
  hedge, and the nearest plant exactly as far from a hedge as before (0.11 m
  on the walk, 0.20 m in the room).

### A meadow orchard, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026. Notes and renders:
`design/garden-layouts-2026-10-02/built/orchard.md`.

**The rule did not change**: five guilds of four, one finished before the next
is begun, a guild's places graded outward from the middle of the plot, the
middle tree's four rankless. Re-recorded, the 500 vector rows keep every plot,
slot and nudge they had and gain only their plot's variant and spot. What
changed is where a slot stands.

- **The table**, `tools/layouts/tables/orchard_meadow.py`
  (`PlaceTable.orchardMeadow`, `OrchardMeadowTable`): three feature variants,
  20 places each, in fill order.
- **The trees stay on the quincunx**, each outer one nudged by up to 0.08 m a
  way, differently in each feature variant: the outer trunks stand 1.74 m out
  (1.70 before). The middle tree is never nudged.
- **An outer guild is a crescent at its tree's drip line**, turned toward the
  middle tree, its four places 0.90 m from the trunk: the understorey on the
  line to the middle tree, the two flanks 36° either side of it, the crown at
  the far horn, 72° round. So the ranks still read outward: understorey 1.56 m
  from the plot's middle, flanks 1.81 m, crown 2.34 m. The crowns horn toward
  the two pockets on the `z` axis, framing each with two tall crowns, and the
  two `x` pockets stay low and open for the way.
- **The middle tree keeps its ring of four**, on the diagonals, each facing a
  crescent, 0.75 m from the trunk; the canopy's underside comes down to 2.23 m
  there, and `OrganicTests` checks the clearance at the nearer radius.
- **Every count looks finished**: the ring fills facing the first crescent,
  then opposite, then the other two; the guilds fill far corner, near corner,
  then the two sides. At ten plants that is the ring and the far crescent, and
  two of the near one.
- **Plots vary by number**: four turns, a mirror and three feature variants,
  24 ways (`Orchard.variants`). The service sends the turned spot
  (`Orchard::spot`).
- **The page** (`orchard.js`, from `pg_orchard_layout(plot)`) draws the five
  trunks, a mown crescent along each outer guild's arc, the middle tree's
  disc, **one mown way** in at one edge, through the middle disc and out at the
  other, and the dipping pond (0.64 m now, 0.70 before) in a pocket between two
  crowns, 0.81 m or more from every place.
- A crescent's neighbours are 0.556 m apart (0.90 m in the old squares, about
  the Crossing's 0.53); guilds come no nearer than 0.80 m; the nudge stays
  0.13 m, and at its worst a place stays 6 cm inside the plot, where a crown in
  a corner could stand 12 cm past the worst rim.

**The fill is the baseline's, every figure**: 51 plots at 1,000, 98.1% held,
99.9% in settled plots, one settled place empty. **A deploy re-lays every
existing plot at once with no row changed**; the replant would write the rows
it reads.

**Left open:** the near tree still hides part of the middle tree's ring before
a turn, as it did; the pond falls in the `z+` pocket in all three feature
variants, though turns and mirrors put it in every pocket across plots; the
mown way always crosses on the table's `x` axis, which turns put on either.

## The Knot Garden, built

22 September, and curved on 23 September.
`SeedCore/WebGardens/KnotGarden.swift`, `Server/.api/KnotGarden.php`,
`KnotStore.php`, `Server/assets/js/knot.js`, `/knot`, `/dev/knot`,
`tools/reference/check_knot.php`. No new structure: the knot is drawn in
`Organic.hedge`, which is the first time an area has been built without one —
though `Organic.hedge` learned to bend for it.

- **Thirty-two a plot: eight compartments of four.** Between the walk's
  forty-eight in the same square and the crossing's twenty-four. Four to a
  compartment because a block of three does not read as a block, and the
  compartments are blocks — that is what a knot garden's planting is.
- **The first rule that reads a plant's colour.** `PlantTraits` has carried
  `family` since the Long Walk and four areas have graded by height alone. This
  one asks the colour first and the height second: **colour picks the pair of
  opposite compartments, height picks the place within one.** Both fields used
  at last, and the height grammar every other area shares kept rather than
  thrown away.
- **The eight are four mirror pairs, and a pair holds one colour.** Opposite
  compartments across the middle of the plot — north against south, east against
  west, and the two diagonals — so the knot is symmetric in colour, which is
  what a knot garden looks like from above. A plot therefore carries four of the
  seven colour families, eight places each.
- **Nothing is reserved, and that settled what *a slot has a mirror* means.**
  The literal reading — taking a place holds the opposite place open for a
  matching plant — was rejected against a rule already written into four areas'
  comments: nothing in this garden reserves a slot, not even for an ambassador.
  The Orchard had also shown that a merely *constrained* place can wait hundreds
  of arrivals, and a reserved one would wait on a plant nobody has grown. A pair
  is claimed by the first plant to stand in it and filled by whoever of that
  colour arrives next.
- **The worry the brief raised was unfounded, and the number says so.** Seven
  families and four pairs a plot: a rule that claimed pairs greedily would open
  a plot for every colour that turned up and leave the garden half empty. This
  one claims a pair only when a plant needs one, so **at five hundred it is 17
  plots, 66 pairs claimed, 56 of them exactly full, and 92% of every place in
  the garden holding a plant** — the best fill of the five areas. The rarest
  colour is pale, nineteen plants of five hundred and one, and it claimed three
  pairs in the whole garden rather than one in every plot.
- **Four plants in five get the rank their height asks for**: 410 of 501 in their
  own rank, 67 one step out, 24 one step in, none further. Between the
  Crossing's 95.4% and the Orchard's 80%, for a nameable reason — preferring the
  pair over the rank displaces plants as the Orchard's guild-first rule does,
  but a pair holds eight places against a guild's four, so there is twice as
  much room to find the right one.
- **The cuts are the Orchard's 0.58 and 1.20, and are named as the Orchard's.**
  (0.48 and 1.18 since 29 September 2026, and ranking 142/250/108 here.)
  A compartment of four graded outward is the same 1:2:1 a guild is, so it
  divides the same population the same way. This is the first area to share cuts
  with another; re-measuring would have produced the same two numbers and
  presented them as an independent finding, which is a way of making one fact
  look like two.
- **The two compartments of a pair fill together**, which is the Crossing's
  *wherever there is least* asked of two instead of four — and *not* "they never
  differ by more than one", which is false and was this suite's first failure.
  A compartment whose remaining places are the wrong rank is passed over however
  empty it is. The test replays the five hundred arrival by arrival, because
  *which of the two was emptier* is a fact about the moment and the finished
  plot cannot say. At five hundred none of the sixty-six ends more than one
  apart (one did before 24 September 2026).
- **The pattern is a weave.** **Since 2 October 2026 it is interlaced rings**: a
  ring round the middle and four small rings woven through it on the
  diagonals, inside a softened square edging, the four sides now four lenses
  and the four corners four crescents (§*Interlaced rings, 2 October 2026*,
  below). Until then it was two bands each way, crossing four times, inside a
  square edging: four compartments at the sides, four at the corners, and the
  weave closing round a middle that holds no plant. That was a real knot-garden
  plan and it gave eight compartments of one size, which is what a mirror pair
  needs to read as a mirror — the alternative considered, an octagram of a
  square and a diamond, puts the compartments in the star's points, and a
  regular octagram's points are 0.45 m² each, which will not hold four plants at
  any scale that fits a 5.2 m plot.
- **The bands curved, and that is what stopped it reading as a grid** (the
  bands' layout until 2 October 2026) — added on 23 September, one day after
  the area opened, because straight interlaced runs
  are a weave the eye has nothing to follow through. `KnotGarden.weave` cuts
  each run into three: an arm, the stretch between its two crossings, and the
  other arm. The inner stretch bows 0.30 m in toward the empty middle, so the
  four of them close round it as a ring of four arcs; the arms bow 0.05 m the
  other way, so a run leaves a crossing turning back and reads as a ribbon
  rather than as a line with a curve let into it.
  - **No plant moved for it.** `Organic.hedge`'s bow is zero at both ends of a
    stretch, so every crossing is where it was, every compartment keeps its four
    corners, and `knot_garden_vectors.json` is untouched.
  - **The inner bow is free and the arm's is paid for.** Nothing is planted in
    the middle, so the inner stretch may bow as far as it likes; an arm has a
    compartment on each side. The nearest place to an arm stood 0.18 m from the
    band's face, of which the nudge already spends 0.09; at 0.05 m of bow a
    nudged plant still stands 0.048 m clear. `KnotGarden.clearance(x:z:)`
    measures it and `KnotGardenTests` holds it.
- **The weave is drawn rather than implied**, and it is drawn the way a real
  knot garden is made: living hedge cannot be woven, so the under-band stops
  square against the over-band's face and starts again beyond it, while the
  over-band carries on through and swells where the two have grown into each
  other. Which does which alternates round the knot, so every run is over at one
  of its two crossings and under at the other. The rings of 2 October keep all
  of this: going round the middle ring it is over, under, over, under.
- **What looking found was all in the band and the ground**, and took three
  passes:
  - **The bands were walls.** 0.22 m through and 0.32 m tall drew nine boxes
    with walls between them, and no crossing read as a crossing because the
    junctions were blobs. Thinner was not enough on its own: what reads as a
    wall is a run **taller than it is broad**. Young clipped box in a knot is a
    ribbon laid on the ground, so it is 0.18 m through and 0.17 m tall, and at
    that the weave reads from every turn.
  - **The gravel was a tiled floor.** A square grid of cells each split on the
    same diagonal and flat-toned draws a checkerboard however small the cells
    are and however hard the tones vary: the eye finds the grid first, because
    the grid is the only thing in the picture that repeats exactly. Jittering
    the lattice by a third of a cell and turning each cell's diagonal with the
    same noise put it right. **It was the grid's regularity that had to go, not
    its size** — the cell is what it was.
  - **Per-face tone, not per-corner.** Grass is a surface and carries its tone
    on the corners of a grid, interpolated, so no cell edge shows. Gravel is a
    heap of stones, and the same smooth interpolation drew wet sand. It is the
    roundel's finding — paving is faces — at a twentieth of the size.
- **The ambassador wanted no accommodation.** *Quina caerulea*, 1.085 m, family
  4, placed by the rule into an empty Knot Garden: it claims the first pair for
  its colour and stands in the north compartment, at one of the two places
  beside the middle of it, because 1.085 m reads as a side rather than a heart.
  Nothing had to be arranged for it — an empty compartment refuses nobody —
  which is worth having confirmed rather than assumed, given what the Orchard's
  1.34 m ambassador cost.

### Interlaced rings, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026, laid one way in every
plot, as decided. Notes and renders:
`design/garden-layouts-2026-10-02/built/knot.md`.

**The rule did not change**: colour picks the pair, height picks the place, a
pair's two compartments fill together, nothing reserved. The eight
compartments keep their numbers, the four sides now the four lenses and the
four corners the four crescents, and a pair is still the opposite two.
Re-recorded, the 500 vector rows keep every plot, compartment, index and nudge
they had and gain only their variant (always plain) and their spot.

- **The knot**: a ring round the middle, radius 1.48 m, and four small rings of
  0.94 m woven through it, each crossing it twice, inside a squircle edging of
  half side 2.25 m. Every line strays off its true curve by up to a
  centimetre: formal, but hand-laid, with nothing straight.
- **The small rings stand on the diagonals, not on the axes as the research's
  sketch drew them.** Measured: on the axes a small ring can be no bigger than
  0.74 m before it meets its neighbour or the edging, and a lens then holds its
  four plants 0.22 m apart; on the diagonals the rings reach into the square's
  corners and a lens holds them 0.42 m apart, with the 9 cm nudge kept.
  **Marcus kept the rings on the diagonals, 2 October 2026.**
- **The table**, `tools/layouts/tables/knot_garden_rings.py`
  (`PlaceTable.knotGardenRings`, `KnotGardenRingsTable`,
  `tables/knot_garden_rings.js`): 32 places compartment by compartment, the
  north-east lens and crescent turned by whole quarters, so a pair's places are
  exactly opposite; its curves are the five rings, the edging, and the eight
  crossings in order round the middle ring.
- **Each compartment is still graded outward**, heart nearest the basin, point
  farthest out: in a lens the heart 0.805 m from the plot's middle, the sides
  1.17 m, the point 1.22 m; in a crescent 1.74 m, 1.78 m and 2.155 m.
- **The weave**: an under-band stops 4 cm inside the over-band's face, and the
  over-band swells there, 2.75 cm thicker each side and 5.5 cm taller, easing
  out over 0.29 m.
- **Every count looks finished**: the lenses are claimed first and close round
  the basin, so a plot's first two colours are four ribbons round its heart;
  the crescents come after.
- **The page** (`knot.js`) sweeps a run of box along each line with
  `Organic.hedge`'s section, cut where it dives under and swollen where it
  rides over (`knotRuns`). The basin is as it was.
- Closest two places 0.42 m (0.56 before); a plant pushed as hard as its seed
  can push it stands at least 3 cm clear of the box; the edging's outer face
  comes to 2.34 m at most, inside the 2.38 m any slab's edge comes to.

**The fill is the baseline's, every figure**: 33 plots at 1,000, 94.8% held,
99.1% in settled plots. **A deploy re-lays every existing plot by itself**;
the replant would put every plant back in the slot it holds.

**The map's glyph** (`gates.js`, `LOOK.pattern`) is the knot's now: the middle
ring and the four small rings, broken where a band goes under. A square and a
diamond until 2 October 2026.

## The Seedbed, built

The sixth area, `beginnings`, and **the first rule in the garden that groups by
sameness**. The five before it all sort by difference: a border graded by
height, a group of three read by rank, a quarter ranked, a crown standing over
its flanks, a pair claimed by colour and then graded. Every one asks *how does
this plant differ from that one*. A nursery row asks the other question, and a
drill sown with one kind is the plainest possible answer to it.

Marcus answered the three questions on 23 September before any code existed:
**six drills of eight**, forty-eight a plot; **a drill is claimed by the kind of
the first plant sown in it**, and only that kind may join it; **a place is taken
in the order of arrival**, filling from the labelled end. The third answer was
changed on purpose on 2 October 2026, by his yes to *every count looks
finished*: **a drill is sown from its middle** (§*Drills on the contour, 2
October 2026*, below).

### A kind is the epithet, and that was measured rather than chosen

The obvious reading of *kind* is the plant's name, and it does not work. Over
five hundred crossings **490 binomials are unique**; the genus is nearly as
rare, the commonest standing five times. A drill claimed by either would hold
one plant and wait forever, and the area would be a bed of singletons.

The **epithet** repeats: 46 of them over those five hundred, *rubra* thirty
times, *aurea* twenty-nine. It is also the truer reading. A genus is inherited —
`PlantName` gives a hybrid one parent's genus — where an epithet is chosen by
`Epithet.describing` to say the one thing that is most so about the plant it
names. **A drill of *contorta* is a drill of plants that are actually alike**,
which is what a nursery row means.

So `PlantTraits` carries a third fact. It had held two since the Long Walk —
height and colour family — on the argument that only two can be read without
looking; the kind is a third of exactly that sort, read off the grown plant and
stored with the planting. Nothing but the Seedbed reads it, and the service
never derives it: the phone sends it, the store keeps it in a column, and the
PHP rule compares it as a string. **The port needs to know nothing about
botany.**

### What the rule does

Three steps, oldest plot first: a drill already sown with this kind and not yet
full; failing that the first drill nobody has claimed; failing that a new plot,
first drill. A drill filled from index 0 outward until 2 October 2026, so
reading a drill from its label was reading it in the order it was sown; since
then it fills from its middle, and the first drill nobody has claimed is the
highest for a dry kind and the lowest for a water one.

- **A drill is claimed, never reserved**, as the Knot Garden's pairs are, and
  read off the plants rather than stored in a column — a claim that cannot go
  stale, be restored wrong, or disagree with what is standing in it. Were a
  drill held open for each of the 46 kinds, one plot would owe more drills than
  a bed has.
- **Nothing here reads a height, and nothing reads a colour.** This is the only
  area whose placement neither can move, which is why its vector file needs no
  `placementCannotTurn` check: it has no cuts for a plant to stand near. See
  `.claude/HANDOVER.md` §*The libm divergence* for why that matters everywhere
  else. `SeedbedTests` proves it by replaying every arrival with its height
  thrown away and again with one colour for all of them.
- **The nudge is the only one in the garden that differs by direction**: 0.035 m
  across a drill, 0.06 m along it. A drill has to read as a line, and a line
  survives being uneven along its length but not across it.

### The fill, and why it is the loosest in the garden

Five hundred arrivals: **16 plots, 91 drills claimed, 47 of them full, 65% of
places held** — against the Knot Garden's 92%. The waste is inherent and it is
the right waste: a kind that arrives once claims a drill and stands in it alone,
which is what a part-sown seedbed looks like. A bed shows what has been sown,
not what would look tidiest. Those five hundred were any crossings; since 25
September they are the area's own plants and a lotus takes two places, and the
numbers are the ones under *A lotus takes two places*, below.

### The label

`Organic.rowLabel` — the sixth structure the file knows how to draw, and the
first of the four that the five remaining areas need. A tongue on a short stake,
leaning back 22°, because **seen from the garden's fixed isometric eye a plate
standing upright is a line two pixels wide**. Nothing is written on it: at this
scale a word would be four pixels tall and would fight the plants. The drill's
kind is named in the page's text, where it can be read and translated.

### A lotus takes two places, 25 September 2026

**Decided.** *A lotus takes two places, standing centred across two
neighbouring places, in the Cold Frame and the Seedbed only.* Marcus, from four
options simulated on 24 September. Since the shapes changed that day a lotus is
a water lily, low and wide: grown here its pads reach a median **0.51 m** from
the stem (0.69 m at the ninetieth percentile), and places along a drill are
0.52 m apart, so **one plant in twelve stood with its stem inside a lotus's
pads**. Simulated beforehand on five hundred of the area's own plants, the rule
took that to none, at the cost of **fifteen plots becoming nineteen**. The
other options — six places a drill at 0.70 m, or pads drawn smaller — were
set aside. The Cold Frame's section says the same for that area.

**As built.** `Seedbed.span(of:)`, `Planting.span`, `slot_span` and `habit` in
`SeedbedStore`, `Seedbed::span` in the port.

- **The habit is read, and only whether it is `lotus`.** It is picked from the
  seed's bytes, exact on every host like the kind, so this is still the one
  area no height can move and its vector file still needs no margin. A plant
  whose phone never sent a habit takes one place.
- **A lotus takes the next two places its drill would fill**, and stands at
  their middle — half a place further from the label than its first, plus its
  usual nudge, which leaves **0.78 m to the next stem along the drill**. The
  second place is held, and a drill counts as sown to the end of it, so the
  plant after a lotus stands after both.
- **A drill's last single place is no place for a lotus.** It goes on as a
  plant finding its drill full does — an unclaimed drill, then a new plot —
  and the place waits for a plant of one place of that kind. So a common kind
  can now claim a second drill in a plot whose first still has a place in it.
- **Taking back keeps both places.** `slot_span` is part of the place and
  stays with the placeholder; the habit goes with the rest of the plant, since
  the rule reads it only of a plant arriving.
- **A planting stored before this holds one place**, whatever it is: the
  column is added with a default of 1 (an `ALTER` that may already have run, as
  `Offers` adds its columns), and `Planting` decodes a missing span as 1. Until
  the replant places everything again, an old lotus stands where it stood, in
  one place, and the next arrival along its drill takes the place after it.
  The replant writes `slot_span` and `habit` for every planting.
- **The wire carries the span** beside the drill and the kind, for the page's
  marks of how far each drill is sown: a drill of four lotuses is full. Where a
  plant stands needs only its spot, which is already the middle of its places.
- **`SeedbedTests` now draws the area's own plants**, as the Cold Frame's
  always has, and so does `/dev/seedbed`: a third of them are lotuses, where
  one crossing in twelve is, and a sample of any crossing would measure a rule
  that hardly runs.

At five hundred of the area's own plants, 173 of them lotuses: **19 plots, 112
drills claimed, 66 of them full, 73% of places held**, and one stem inside a
lotus's pads — two lotuses side by side in neighbouring drills, 0.69 m apart,
where the rule does not reach and the drills stay 0.74 m apart.

### The drills are flooded, 27 September 2026

**Decided.** *A drill sown with water lilies is a flooded drill.* Marcus, from
three offers, having been told the thing that ruled the other two out: **grown
here a lily's pads reach 0.51 m, so it needs a metre of water round it**, and
a metre-spaced pool does not fit a 5.2 m plot alongside six drills of eight.
A pool would have meant shortening the drills. Flooding them costs no geometry
at all — the two places a lotus has taken since 25 September are 1.04 m, which
is exactly the room its pads want — and it is what a nursery does: the
aquatics stand in their own rows in water, beside the rows of fine tilth.

**The rule gains one clause.** A drill is claimed **by kind and by element**.
An epithet says what is most so about a plant rather than what it is —
*rubra* is red and a water lily can be red — so one kind can arrive as a lily
and as a fern, and they take a drill each. A half-flooded drill is not a thing
a nursery has.

**As built.** `Seedbed.Ways.isWater(_:in:)` and the second half of the match in
`place(for:)`; `Seedbed::isWater` and `::wantsWater` in the port; the element
invariants in `check_seedbed.php`. **No new column and no change to a slot** —
the element is read off the first plant's habit, the way the kind is read off
its epithet.

- **`SeedbedStore` now keeps the habit when a planting is taken back**, for the
  same reason it already kept the kind: a blanked habit would tell the rule a
  flooded drill was dry, and the next lily of that kind would claim a fresh
  drill instead of joining the water. A row taken back before 27 September has
  a blank habit, so its drill reads as dry until the replant sows it again.
- **A flooded drill divides exactly**: eight places, two to a lily, four
  lilies, nothing over. The odd last place a lotus cannot use only exists in
  rows written before 25 September.
- **This is still an area no height can move.** The element comes from the
  habit, picked from the seed's bytes with no `sin` or `pow` in it, so it is
  exact on every host like the kind.

At five hundred: **21 plots, 124 drills claimed, 60 of them flooded, 57 full,
66% of places held.** **The two plots are what the water costs and they are
the price of the whole feature** — an epithet arriving as both takes two
drills where it took one, so 124 are claimed where 112 were and 57 fill where
66 did. Nothing else moved: a lotus holds the same two places, and they are now
two places of water. Water is 48% of the claimed drills, against the 35% of
arrivals that are lilies, because a flooded drill fills more slowly.

### Drills on the contour, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026. Notes and renders:
`design/garden-layouts-2026-10-02/built/seedbed.md`.

**These stand as they were**: six drills of eight, 0.74 m between drills and
0.52 m between places along one; a drill claimed by kind and by element, read
off its first plant; **a lotus taking two places and standing centred across
them** (25 September 2026, untouched by the Cold Frame's answer of 2 October);
a drill's last odd place waiting for a plant of one place.

- **The table**, `tools/layouts/tables/seedbed_drills.py`
  (`PlaceTable.seedbedDrills`, `SeedbedDrillsTable`, `tables/seedbed_drills.js`),
  48 places. The bed falls toward `z+`, so each drill is a contour: an arc
  about a point 7.4 m below the plot's middle, wandering 2.5 cm, bowing 0.17 m
  (the top drill) to 0.30 m (the foot) over its length. The drills now run
  across the bed in `x` and are stacked down it in `z`; drill 0 is the top.
  The middle drills begin a little further in than the outer ones, so the
  labels stand on a curve rather than in a ruled column. Each drill's line is
  in the table, its first point where its label stands.
- **The water lies low.** A dry kind claims the highest drill nobody has sown,
  and a lily or a reed the lowest: the flooded drills gather at the foot of the
  bed and the dry ones at its head.
- **A drill is sown from its middle**, Marcus's answer of 23 September changed
  on purpose. A dry drill takes the place nearest its middle first, then
  farthest-first, so one plant stands in the middle and three at the middle
  and both ends. A flooded drill is sown in pairs the same way, because a lily
  takes two places; a reed takes the first free place in that order, so two
  reeds share a pair before a third opens another.
- **Plots alternate**, mirrored one to the next (`Seedbed.variants`): the labels
  stand at the west end of even plots and the east of odd ones, and the water
  stays low in both.
- **The nudge** is still 0.06 m along a drill and 0.035 m across it, now along
  `x` and across `z`.
- **The stored shape is the same**: `drill`, `slot_index` (how far along the
  drill from the label) and `slot_span`. `Seedbed::spot` works the spot out
  when it serves a planting: the middle of its places, the nudge, the mirror.
- **The checks**: the vector rows gain `variant` and `spot`, compared exactly;
  *filled from the label with no gap* became three checks (a dry drill is a
  prefix of its order, a flooded drill's pairs a prefix of its pair order, and
  each drill claimed was the first on its own side of the bed); `SeedbedTests`
  proves that sowing in pairs lets in and turns away exactly the plants that
  sowing from the label did, for every mix of reeds and lilies up to nine.
- **The drawing** (`seedbed.js`): each furrow follows its drill's line, dark in
  the bottom, pale on the crest; a flooded drill's trough is dug along its arc
  and closes in a rounded pool at each end; each label stands on its line's
  first point, turned to face along the drill. A drill claimed by a reed is now
  drawn flooded on the workbench too, as the service draws it.

**The fill is the baseline's, to the place**: 36 plots at 1,000, 73.8% held,
77.3% in settled plots, 370 settled places empty. Claiming by side changes
which drill a kind claims, never whether a plot has one free, and sowing in
pairs takes a lily while a whole pair is free, which is the same count.
**Option A cannot honestly reduce the 370**: they are drills claimed by kinds
that come rarely, and which drills are claimed depends only on the arrivals
and the claim rule. Eight drills of six would leave 239, in 33 plots rather
than 36, but eight drills at 0.74 m do not fit the bed; letting kinds share a
drill is the rule Marcus chose against. Neither was built.

**A deploy re-lays every plot by itself**, each planting onto its place on the
curved drill, odd plots mirrored, none colliding and none changing drill; but
only the replant gives the old plots the new claims and the new order. Plot
assignment is unchanged.

**Left open, as built:** the drills curved gently, 0.17–0.30 m over 3.6 m,
because six drills 0.74 m apart fill 3.7 m of the bed's depth and leave no
room for more bow; seen from the page's eye the flooded drills read as arcs and
the dry ones nearly straight, and a stronger curve needed a narrower gap
between drills, which was Marcus's number. **He gave it the same day** (below).
A drill of two looks lopsided, the middle and one end, which is what
focal-first gives on a row; from three up it is balanced. Three stems in five
hundred stood inside a lotus's pads (one before): two are reeds beside a lily's
pair, each nudged toward it, under the test's bar of 1%.

### Curved more, closer together, 2 October 2026

**Decided.** *Curve more, narrower gaps.* Marcus, from the renders of the
contour bed, so that every drill reads as an arc from the page's eye, the dry
ones at the head included. Notes and renders:
`design/garden-layouts-2026-10-02/built/seedbed.md`, *Curved more*.

- **0.60 m between drills, where there were 0.74 m**, about a point 4.8 m below
  the top drill rather than 9.4 m. Along a drill is unchanged, 0.52 m. Each
  drill still stands centred across the bed, so on the tighter arcs at the foot
  its ends come in and the labels stand on a curve.
- **Every drill bows**, measured over its eight places: 0.33 m at the top,
  then 0.39, 0.46, 0.52, 0.64 and 0.84 m at the foot, where the flooded drills
  now curve round like paddies. The dry drills, which claim from the head,
  bow 0.33–0.46 m; they bowed 0.17–0.25 m. The foot drill's ends and their
  pools still lie inside the slab.
- **A plant's nudge is laid along and across its drill** where it stands
  (`Seedbed.along`, `Seedbed::along`): 0.06 m along it and 0.035 m across,
  turned to the line between the places either side, or a lotus's two. On the
  tighter arcs the `x` the nudge ran along before is half across the drill at
  its ends, and a drill has to read as a line. Only a difference, a square root
  and a division, so a spot is still exact on every host.
- **What is unchanged**: six drills of eight, every drill's capacity, which
  plot every plant goes to, which drill it claims and how many places it
  holds, and the lotus's two places along a drill. Every drill is sown in
  the order it was but drill 1, whose fifth and sixth places swap on its new
  arc, so 17 of the 500 vector rows take another place in that drill.
- **The fill is the baseline's, to the place**: 36 plots at 1,000, 73.8% held,
  77.3% in settled plots. Where a drill lies cannot change which drills are
  claimed or how full they get.
- **The spacing floors that moved**, and by how much:
  - the gap itself, 0.74 → 0.60 m; the nearest two places in neighbouring
    drills are 0.58 m apart (0.72), still wider than along a drill;
  - the test's floor across, `drillGap − 0.06`, so 0.68 → 0.54 m;
  - a flooded drill's trough keeps its 0.54 m width, Marcus's, so two flooded
    drills side by side are dug with 0.06 m of tilth between the dishes (0.20
    m before) and their water lies 0.20 m apart across a wet bank (0.34 m);
  - **stems inside a lotus's pads: five of 501, the test's bar of 1%** (two,
    with the nudge laid along the drill, at 0.74 m). One is along a drill as
    before; four are across one, a lily beside a lily or a reed in the next
    drill 0.54–0.65 m away, which the widest pads now reach. The rule along a
    drill is untouched.
  - Nothing else moved: 0.48 m between any two places in the table, 0.39 m
    between any two plants, ±2.06 m for every place, a plant within 0.06 m of
    its drill's line.
- **A deploy re-lays every plot by itself**, as before: each planting moves
  onto its place on the tighter drill, none colliding and none changing drill
  or plot. The replant needs nothing new for this.

## The Cold Frame, built

The seventh area, `waiting`, 23 September. `SeedCore/WebGardens/ColdFrame.swift`,
`Morphology/Structures/GlazedFrame.swift`, `Server/.api/ColdFrame.php`,
`ColdFrameStore.php`, `Server/assets/js/frame.js`, `framepage.js`, `/frame`,
`/dev/frame`, `tools/reference/check_cold_frame.php`. **The first area that draws
a plant as something other than what it will be.**

Marcus answered its three questions on 23 September, after a measurement that
changed the first one: **every plant, drawn young; four frames of twelve; colour
claims a frame and the grown height orders its ranks.** (Two frames of twelve
and a tank of thirty-nine since 29 September 2026: *A bigger tank*, below. The
tank became a pond of the same thirty-nine places on 2 October 2026: *A pond
planted as a pond*, below.)

### Nobody is turned away, and that was measured

The layout's first reading was *small plants only*. The plants whose names put
them in `waiting` — about 9% of arrivals — grow to **0.33–1.64 m, median 0.85**,
and a low frame holds about 0.4 m, so a height limit would have refused nine in
ten of the area's own plants. With the shapes of 24 September 2026 every one of
them is a lotus or a fern, 0.23–0.82 m, median 0.38, and a limit would still
refuse four in ten. So every plant is admitted and **placed by the
height it will grow to, drawn at an early stage**. The drawn height is never
stored and never read by the rule; it is a matter of drawing.

### The rule

Colour picks the frame, height picks the rank. In order: a frame already
holding this plant's colour family, oldest plot first — its own rank if there
is room and nothing would stand out of order, otherwise the other rank on the
same terms; failing that the first frame nobody has claimed; failing that a new
plot. A rank fills from its west end. The claim is read off the plants, as the
Knot Garden's and the Seedbed's are.

- **The cut is 0.49 m, the median of this area's plants that stand in the
  frames** (0.50 m from 27 September 2026, 0.38 m from 24 September, 0.85 m
  before that), and it is the
  first cut measured over one area's plants rather than all of them. Five hundred `waiting` arrivals took 5,805 crossings
  to find. A borrowed cut would have divided them unevenly — the Orchard's 0.58
  puts 12% at the back, the Long Walk's 0.77 puts 1% — where this one puts
  49.8%. `ColdFrameTests`
  draws its sample the same way, and so does the workbench.
- **At five hundred: 12 plots, 46 frames claimed, 35 of them full, 87% of every
  place holding a plant**, and 472 of 501 plants in the rank their height asks
  for (485 before 24 September 2026: two in five of these plants now stand
  within 5 cm of the cut, and a plant near it is the one sent to the other rank
  when its own is full; no cut near the median does better). Between the two other areas whose places are claimed — the Knot
  Garden's 92% and the Seedbed's 65% — and nearer the Knot's, for its reason: a
  claim is made only when a plant needs one, and seven colour families are
  far fewer than forty-six kinds. Since 25 September a lotus takes two places,
  and the numbers are the ones under *A lotus takes two places*, below.
- **The margin holds.** The nearest recorded height to the cut is 0.37 mm clear,
  thirty-seven times the tolerance two hosts are allowed to disagree by, and
  `ColdFrameVectorTests` runs `placementCannotTurn` over plot and frame.

### Drawn young

`ColdFrame.drawn` is not a moment on the plant's own timeline, and cannot be:
`GrowthModel` grows height first and buds only once the height is done, so a
plant young enough to stand under glass has never shown its colour — and colour
is what claims a frame. The state is put together: `heightScale` 0.30,
`leafUnfurl` 0.7, `budSwell` 0.2, nothing open. Each number was measured:

- **Below 0.25, `PlantBuilder` draws the seed's husk** at the foot of the stem.
- **Leaves fully open stood above the glass.** A young plant's leaves are drawn
  at nearly half their grown size on a stem a third of its height.
- **A bud swollen further is a full-size flower head on a seedling** — at 0.8
  the tallest plant was 0.9 m.

That draws the five hundred **0.05–0.34 m tall**, and `ColdFrameTests` holds
every one under the glass above it with 2 cm to spare. The shortest are young
water lilies, their pads on the soil 0.26 m and more across, so since 24
September 2026 the test's floor on how small a seedling may be asks its larger
extent rather than its height: none is under 0.15 m. The grading does the
rest: the glass is lowest at the front, and the front rank holds the plants
that will grow shortest, whose young stages are shortest too.

**The slope is the ranks' own grading.** A cold frame is built higher at the
back so rain runs off and the glass faces the light, and the rule stands the
plants that will grow tallest at the back. The two were never designed
together, and they agree.

### The frame, and the glass

`Organic.coldFrame`, `frameLights` and `frameGlass` — the seventh structure, in
three pieces because it is three materials. The box is four of the bench's
planks, the ends cut down to the slope; the lights are painted bars resting on
the back wall and propped at the front on a block, which is how a frame is by
day and why there is a gap under the front of the glass. **The garden is lit at
midday on every page**, so the lights are always propped; *shut at night* would
need a page that knows its own hour.

**The glass is the first thing in the garden a reader has to see through.**
`makePlotStage` gained a pass for it: a ground builder may hand back a `glass`
mesh, and it is drawn after the plants, blended and without writing depth.
Every other area returns none and draws exactly as it did. Clear glass is seen
by what it reflects and where it doubles, so each light is glazed in panes
**lapped** down the slope, as a frame light is, with a ripple a couple of
millimetres deep in each — the lap is a line of more light and the ripple a
glint. At 30% opacity the seedlings under it were a milky smudge; at 14% they
read and so does the glass.

### The lights open, 24 September 2026

**Decided.** *Tapping a frame's glass opens that frame, and then a plant in it
can be tapped* — a reader trying to reach a seedling was tapping the glass over
it, and the frame should answer by opening rather than by being tapped
through. Marcus.

**As built.** `makeFrameLids` in `frame.js`; `cover` in `plantpanel.js`;
`pieces` and `toScreen` on the stage in `longwalk.js`.

- **The lights leave the ground.** The box and the two blocks stay baked into
  it; each frame's lights and their glass are drawn by the stage as `pieces`,
  moved where they stand now and uploaded only when they move. Nothing in the
  module changed: the blocks are told from the bars as the two planks that
  reach below the lights' underside.
- **Both lights of a frame swing up together, 60°, on the top of the back
  rail**, the high edge a light rests on, eased over about half a second — no
  swing at all for a reader who asks for reduced motion. Once up, each is
  propped on a stay stood on its block and meeting the light where it rested
  on it; the stay is the light's own stile, thinner and stretched, so it has
  the plank's wander rather than a ruled edge.
- **Glass first while shut.** A tap inside a shut light's outline on the
  screen opens that frame and opens no panel, whatever is under it. A plant in
  the open frame standing in front of that glass keeps the tap. A plant found
  where it shows outside the glass, or by the `p` key, or by a postcard, has
  its frame opened first and its panel once the light is up.
- **One open at a time.** Tapping another frame's glass shuts the open one as
  it opens; so does a tap on nothing, and going to another plot shuts every
  frame at once. **Closing the panel leaves the frame open** — the reader is
  still looking into it — and a tap on the gravel after that shuts it.
- **The keyboard opens a frame by `p`**, which opens the plant nearest the
  middle and its frame with it. No new key and no new strings: a frame with
  nothing in it has nothing to open it for.

### A lotus takes two places, 25 September 2026

**Decided.** *A lotus takes two places, standing centred across two
neighbouring places, in the Cold Frame and the Seedbed only.* Marcus. Drawn
young here, a lotus's pads reach a median **0.31 m** from the stem (0.40 m at
the ninetieth percentile) — exactly the 0.31 m between places along a rank —
and **a quarter of the Cold Frame's plants stood with their stem inside a
lotus's pads**. Simulated beforehand, the rule took that to none, at the cost
of **twelve plots becoming eighteen**. A narrower front rank, fewer places a
rank, and pads drawn smaller were the options set aside. **Replaced for this
area on 2 October 2026**: Marcus decided that a lotus takes one place in the
pond (*A pond planted as a pond*, below). The Seedbed keeps its two.

**As built.** `ColdFrame.span(of:)`, `Planting.span` and `slots`, `slot_span`
and `habit` in `ColdFrameStore`, `ColdFrame::span` and `::next` in the port. The
rest is the Seedbed's, above, point for point: the habit read only for
`lotus`, the next two places the rank would fill, the middle of them plus the
nudge, the second place held, a missing span read as one place, taking back
keeping both.

- **A rank's last single place is no place for a lotus**, which goes on as a
  plant finding its rank full does: the other rank of the same frame if it
  stands in order there, then a frame of its colour elsewhere, then an
  unclaimed frame. The place waits for a plant of one.
- **The ambassador is a lotus.** *Nyxisora crassicaulis* now holds the first two
  places of the first frame's front rank and stands between them, 0.155 m east
  of where it stood; it is derived, not stored, so it moved by itself.
- **The wire is unchanged.** The page draws a plant at its spot, which is
  already the middle of a lotus's places, and has no marks to count.

At five hundred, 274 of them lotuses: **18 plots, 69 frames claimed, 57 of them
full, 90% of every place held**, and one stem inside a lotus's pads — a lotus
among the widest tenth and a fern in the next place of its rank, 0.44 m apart
after their nudges, the case the simulation found too. **Fewer plants have the
rank their height asks for: 448 of 501, from 472.** Three in four lotuses
belong in the front rank, and a front rank that held six plants now holds
three lotuses, so it fills sooner and more of what follows is sent behind.

### The tank, 27 September 2026

**Decided.** *A tank of water down the middle of the yard, and every water
lily in it.* Marcus, from two renders rather than from the arithmetic — a full
plot and a middling one — having changed direction twice before asking to see
it. Seven places along by three across at **0.62 m**, the gap a lotus's pads
were measured against on 25 September: **twenty-one to a plot**, 4.4 m by
1.8 m. The two rows of frames were pushed out from `frameZ` 0.9 to **1.55** to
make room, and nothing inside a frame moved.

**Why here at all, and why only here.** An area is chosen from a plant's genus
head and the head is its archetype's own root, so the two are one fact:
`Areas.genusHeads` sends `Nyx` here and `Lir` to the Seedbed, and those are the
lotus's two roots. **No other area in the garden ever receives a water lily** —
which is also why the Quiet Garden's pool, built two days earlier, can hold
one in a test and never in the live garden. **274 of every 501 arrivals here
are lilies**, and until the tank was sunk every one of them was in dry compost
taking two places under glass.

**As built.** `ColdFrame.Frame.tank` (raw 4, `isDry`, `places`, `at(_:rank:)`),
`Archetype.wantsWater`, `PlantTraits.wantsWater`, the water branch at the head
of `place(for:)`; `ColdFrame::TANK` and the same branch in the port;
`pg_frame_plan` sending the dry frames and a `tank` block; `frame.js` fanning
its gravel from the tank's rim and calling `sinkPool`. The tank is a fifth
frame rather than a new kind of place, for the reason `QuietGarden.Corner.pool`
is a fifth corner: **a slot stays one set of numbers in the table and on the
wire**, and every planting already filed decodes as it did.

- **The tank has no ranks.** Water is flat and a lily has no view to be given,
  so every place in it is rank 0 and its three rows come out of the index.
- **A full tank opens a new plot rather than putting a lily under glass.** The
  frames are graded by colour and by height and a lily is sorted by neither, so
  there is no frame to fall back to — which is what keeps a plot's water full
  before the next plot's is used.
- **A lily in the tank holds one place.** The two it held under glass were
  0.31 m apart; the tank's are 0.62 m and were measured for its pads. The span
  is a fact about the place as much as about the plant. The two-place rule is
  therefore unreachable under glass now, and stays in the source because rows
  written before today hold lilies in frames 0–3 with a span of two.
- **The ambassador is in the water.** *Nyxisora crassicaulis* opens the tank at
  its west end rather than the first frame; it is derived, not stored.

**The cut moved with it, from 0.38 to 0.50.** The cut divides the plants that
stand in the frames, and that is no longer every arrival: the 274 lilies were
pulling the median down by 0.12 m. Left at 0.38 it put **81% of the frames'
plants at the back**, and it showed — the front ranks stood empty under the
glass while the back ranks filled. 0.50 is the dry median and puts 50.2% there.

At five hundred: **14 plots, 25 frames claimed, 14 of them full, 274 of 294
places in the water (93%) and 227 of 672 under glass (34%)**, with **219 of 227
plants under glass in the rank their height asks for** — the best this area has
measured, from 197 at the old cut. The frames are thin, and that is this area
being mostly water rather than the rule failing: only 227 of every 501 arrivals
here want dry compost at all. **Fewer frames and smaller frames were both
measured and both are worse** — a frame holds one colour, so fewer frames
strand more plots and smaller frames are claimed faster and never fill.

### A bigger tank, 29 September 2026

**Decided: Marcus, 29 September.** *A bigger tank, so the tank and the frames
fill in step, and fewer plots.* The re-roll of the 28th gave this area the
reed's root `Syr`, and the reed wants water: **343 of every 501 arrivals here
go in the tank** and 158 under glass. At twenty-one to a tank the water opened
**seventeen plots**, and the frames' plants, which fill the oldest plot's frames
first, all stood in the first five — the frames stood empty in twelve plots of
seventeen, 19% of the glass held.

**The ratio, measured on the area's own five hundred** (`ColdFrameTests`'s
stream). The frames alone, with the water left out, need **five plots** for 158
plants at four frames of twelve, and **nine** at two; the water needs 343 ÷ its
places. For the two to open the same number of plots, four frames need a tank
of about seventy places — more water than a plot has ground — and two frames a
tank of about thirty-nine to forty-two. Three rows of seven, as it was, is out
of step with either.

**What changed: the front row of frames gave up its ground to the water.**
That is the smallest change that fits: each frame is exactly what it was — two
ranks of six under a pair of lights, the lotus-takes-two-places rule, the glass,
the lids that open — and there are two of them, the back row, where there were
four. The frames move back a tenth (`frameZ` 1.55 → **1.65**) and the tank lies
across the yard in front of them: **4.4 m by 3.16 m, its middle 0.6 m toward
the front, thirty-nine places in six rows, seven and six in turn**, each row
shifted half a place from the one behind it. Along a row the places are still
**0.62 m** apart, the gap a lily's pads were measured against; the rows stand
**0.57 m** apart, so two places a row apart are 0.649 m, and the two nudges
pulling toward each other along that slant leave 0.567 m — no closer than two
places along a row come. (At 0.54 m between rows the slant came 2 cm closer,
and `testNoTwoLiliesFloatCloserThanTheTankAllows` caught it.) Staggered rather
than square: a square lattice of six rows does not fit in front of the frames,
and lilies in a grid read as a planting plan rather than a pond.

- **The front row is retired, not removed.** `Frame.frontWest` and `frontEast`
  keep raw values 2 and 3, so a planting filed there still decodes and draws
  where it stood until the replant; `ColdFrame.frames` is the back row, and it
  is all the rule and the plan offer. The tank stays raw 4.
- **The page.** `pg_frame_plan` sends the two frames and the tank's middle
  (`tank.at`). The gravel ring is walked round the tank from its middle out to
  the plot's edge, as `floorAround` walks round a pool, because the tank is off
  the plot's middle now. `sinkPool` takes a **`bank`** (0.25 m here): a dish
  falling to its middle leaves a fifth of its reach as wet silt above the water
  line, which at three metres across was a third of a metre of silt with lilies
  sitting on it; with a bank the water reaches to within a few centimetres of
  the rim. Pools that do not ask for a bank are as they were. No straight
  lines: the tank's outline is the plot's own wandering one, grown and squeezed.
- **The cut is 0.49**, the frames' plants' median measured again after the
  re-roll (0.486 m; see *Every cut measured again*, below).

At five hundred: **9 plots where there were 17, and frames in all nine.** Eight
full tanks and a ninth with thirty-one, **343 of 351 places in the water
(98%)**; **158 of 216 under glass (73%, where it was 19%)**; seventeen frames
claimed and ten of them full, as before — the frames hold what their colours
bring, and what changed is that the plots no longer outrun them. **153 of 158**
under glass in the rank their height asks for. A plot's frames still lag its
tank — a frame waits for its colour, and the first plot's frames are full at
about arrival 250 where its tank is full at about 50 — but no plot's frames
stand empty while its water is used, and `ColdFrameTests` holds that.

### A pond planted as a pond, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026. Notes and renders:
`design/garden-layouts-2026-10-02/built/frame.md`.

**The tank became a pond, and kept its thirty-nine places.** The choice of 29
September stands: two frames and thirty-nine places of water, so the water and
the glass fill in step. The frames, the glass, the lids and everything under
glass are as they were, and straight.

- **The table**, `tools/layouts/tables/cold_frame_pond.py`
  (`PlaceTable.coldFramePond`, `ColdFramePondTable`), holds the pond's outline,
  the inner edge of its shelf and thirty-nine places:
  - **the margin**, fifteen places in **five clumps of three** on the shelf,
    0.26 m in from the edge, each clump a small scalene triangle about 0.26 m
    across, the west clump first, then farthest-first round the pond;
  - **the open water**, twenty-four on a sunflower from the deepest point,
    centre first, so a pond of three lilies is three in the middle, never
    three in a row.
- **The pond** is a wandering kidney 4.6 m by 3.2 m (12.8 m²; the tank was 4.4
  by 3.16), its bay toward the frames and 0.15 m short of their fronts.
- **The rule** (`ColdFrame.Ways.place`, `ColdFrame::place`): what wants water
  goes in the pond and nothing else does, oldest plot first, as before. A reed
  is offered the margin clump by clump, then the open water from its outer
  edge in, so the middle stays for the lilies; a lily is offered the open
  water from the deepest point out, then the margin. A plot's water is full
  before the next plot's is used. `Frame.tank` is now `Frame.pond`, the same
  raw value, 4.
- **Plots alternate**, mirrored only (`ColdFrame.variants`): the bay leans east
  and west in turn, the frames stay at the back, and a mirror changes only
  which of the two a plot fills first. The service sends the mirrored spot
  (`ColdFrame::spotOn`).
- **The page** (`frame.js`) sinks the pond from the table's outline, mirrored,
  with its bank, a paler band of shallower water over the shelf, and the gravel
  walked round it from the deepest point.
- Nearest two lilies' places 0.53 m (the tank's rows were 0.62 m apart); a
  lily's place 0.36 m at least from a reed's and 0.24 m from the water's edge;
  a reed's 0.11 m from the edge.

**Decided by Marcus, 2 October 2026:**

- **A lotus takes one place in the pond.** For the Cold Frame this replaces the
  rule of two places decided on 25 September and kept with the bigger tank on
  29 September; a lily held one place in the tank from 27 September, and the
  pond's places were laid for one lily's pads. Two places a lotus would have
  needed about 27 plots at 1,000 rather than 18, and the frames would have
  stood empty in about half of them. **The Seedbed's two places are
  untouched**: `Seedbed.span(of:)` still gives a lotus two, and nothing of this
  area's reaches it.
- **Five reed clumps of three are kept.** Reeds are 46% of the water here and
  the margin 38% of its places, so about two reeds a plot spill into the open
  water (18 of 150 at 500); six clumps, with twenty-one in the open water,
  would match the plants better. The research's picture had five.

**The fill is the baseline's, every figure**: 18 plots at 1,000, 88.3% held,
94.4% in settled plots, 56 settled places empty. Every plant goes to the plot
it went to and every frame fills as it did; only which of a pond's places a
water plant takes has changed.

**A replant of the water, and nothing else.** Capacities are unchanged (24
under glass, 39 in the water) and so is plot assignment, but a water place's
number now means the pond's *n*th place: the margin for the first fifteen, the
open water after. Of the 500 vector arrivals only 22 of the 342 in the water
keep their index on replay, so a deploy alone would stand reeds in the open
water and lilies in the clumps until `tools/replant` re-files them. It needs
nothing new.

**Left open:** the frames are not set askew, as the research drew them; that
would turn their places, boxes, lights, glass and lids with them.

## Water as scenery in the other eight, 27 September 2026

**Prototype, on the branch `water/scenery`, waiting for Marcus to see it.**
Only the Cold Frame and the Seedbed ever receive a water lily, so the water in
the other eight holds no plant and moves none: it goes on ground no rule plants.
It is drawn in the browser only; no rule, vector or PHP port changes.

It follows the grading Marcus approved — open water at the foot of the garden,
where water gathers, and contained water as the ground climbs, where it has to
be carried and held — read against `COLUMN_RISE`:

| Rise | Area | Water | Where |
| --- | --- | --- | --- |
| 0 m | Quiet Garden | pool, dug (already built) | the middle of the lawn; since 2 October 2026 off the middle toward the bench, 2.1 × 1.2 m, holding the room's two lily places |
| 1.2 m | Orchard | dipping pond, dug, 0.70 m | the near meadow pocket, (0, 1.72), clear of every mown disc; since 2 October 2026 0.64 m, in a pocket between two crowns |
| 1.2 m | Home Ground | stone trough, 0.36 × 0.80 m | lengthways at the near end of a path, (0.83, 1.98); since 2 October 2026 turned to lie along its path, which sways |
| 2.4 m | Knot Garden | low stone basin, 0.60 m | the empty middle the four inner stretches close round; since 2 October 2026 the middle ring's heart |
| 3.6 m | Glasshouse | stone trough, 2.4 × 0.42 m | on the tiles under the staging; since 2 October 2026 bent to the ring of staging, 0.24 m across, under its `x+` side |
| 3.6 m | Coppice | spring basin, round, 0.54 m | at the end of the near ride, (2.0, 0.9); since 2 October 2026 beside the outer end of a ride the table chooses |
| 4.8 m | Crossing | raised basin, round | on the roundel where the four paths meet |
| 4.8 m | Long Walk | stone rill | down the path, meandering across it, stopping short of both ends |

The Home Ground is the exception to the grading: it is at 1.2 m, which is
still open water, but its beds take the ground a pond would need. So its
water is held in stone.

`water.js` gained what the eight needed. `raiseTrough` is a stone-walled basin
standing on the floor, with a plot's squeezed outline or, with `round`, a
wandering circle. `raiseRill` is a kerbed channel along any centre line.
`footing` sets a trough into a floor that is not level. `floorAround` walks a
floor out from a pool that is not in the middle of its plot. The Quiet
Garden's fan between two loops walked in step folds over itself off the
middle, and a fold can lay turf across the water. `sinkPool` takes a `lining`
and `round`.

What the renders changed:
- The rill down the exact middle of the path drew a rule down the page.
- The Knot's basin sunk flush read as a drain.
- The Home Ground's trough laid across the headland had room for 0.24 m of
  width and read as a breeze block.
- The Crossing's basin at trough height read as a well head.

## The Glasshouse, chosen

The eighth area, `light`, chosen on 23 September and built on the 24th (below). It
comes before the Home Ground and the Coppice because **it holds the most plants
still waiting for a place** — 12.6% of arrivals, against 11.7% and 8.4% — and
because it reuses the Cold Frame's glass.

**What was measured first** (4,000 crossings): `light` plants are the tallest
in the garden, **0.44–1.88 m, median 1.03 m, none under 0.5 m**. On staging at
bench height a 1.88 m plant would stand 2.7 m, which decided the first answer.

Marcus's three answers:

1. **Staging and a border.** Pots on staging along the sunny side, and the
   tallest in a soil border along the back, where they cannot shade the pots.
   That is how a glasshouse grows its tomatoes.
2. **Thirty-two a plot**: twenty-four pots on the staging, two deep and twelve
   long, and a border of eight. The border takes the tallest quarter, which puts
   the cut near the 75th centile, about 1.26 m. To be measured over this area's
   own plants, as the Cold Frame's was.
3. **A spectrum of colour along the staging.** Each place on the bench stands
   for a band of hue, and a pot takes the free place nearest its own, so a bench
   fills as a run of colour. The first rule that sorts by hue rather than
   claiming by colour family. **The fill is to be simulated before anything is
   built**, and this answer comes back to Marcus if the fill is poor. Two things
   it must settle: where pale plants go, since they have no hue; and how a
   border plant is ordered, since the spectrum is the staging's.

### The fill, simulated

23 September, before any rule was written. 500 `light` plants (3,930 crossings),
twelve positions along the staging with two pots at each, a border of eight.

- **Plants of this area avoid green.** Hues from 100° to 140° hold two plants
  in five hundred, so the circle is cut there: the bench runs from blue-green
  through blue, violet, magenta, red, orange and yellow, and its two ends are
  the colour flowers are least often. Nineteen plants in five hundred are pale
  and have no hue.
- **Bands of equal width fill badly.** Hue is not spread evenly, so the
  crowded bands open new plots while others stand empty: 68% held if a pot must
  have its own band, 82% if it may stand one place off.
- **Bands of equal share fill well.** Each position stands for a twelfth of the
  plants rather than a twelfth of the circle. Plant by plant, a pot looks for
  its own band in every open plot first, then one place off, then opens a new
  plot. Pale plants take any free place.
  - **Measured on a fresh 500 the bands were not fitted to: 18 plots, 87% of
    places held, the staging 92% full, 86% of pots in their own band and none
    more than one place off.** On the sample the bands were fitted to it was 98%
    and 94%, which is how much fitting flatters.
  - The band edges are to be set from a larger sample, so less is fitted.
- **The border cut is the Orchard's 1.30, borrowed and named as such.** The
  75th centile of these plants is 1.294 m. (Since 24 September 2026 the border
  has its own, 1.14; see §*The Glasshouse, built*.) The border fills more loosely than
  the staging, 70% on the fresh sample, because plots are opened by whichever
  runs out first.
- **The border is planted in arrival order from the door end**, Marcus's answer on
  23 September. The spectrum belongs to the staging alone.
- **Hue is exact on every host.** It is drawn from the seed by arithmetic, with
  no `sin` or `pow` in it, so a band edge needs no tolerance, unlike a height
  cut. It does need carrying: `PlantTraits` holds a colour family, not a hue,
  so a hue is a fourth trait, sent by the phone and stored like the Seedbed's
  kind, by both arrival paths.

## The Glasshouse, built

24 September. `SeedCore/WebGardens/Glasshouse.swift`,
`Morphology/Structures/SpanHouse.swift` and `Staging.swift`,
`Server/.api/Glasshouse.php`, `GlasshouseStore.php`,
`Server/assets/js/glasshouse.js`, `glasshousepage.js`, `/glasshouse`,
`/dev/glasshouse`, `tools/reference/check_glasshouse.php`. **The first area
that sorts by hue, and the first whose plants do not all stand on the ground.**

### The rule

Height picks the bed. A plant of 1.14 m or more (1.16 m since 29 September 2026) goes in the border: the next place from the door in the oldest plot with one,
whatever its colour. Anything shorter is potted on the staging:

1. its own band, in every open plot, oldest first;
2. one band off, in every open plot — the neighbour its hue leans to first, and
   never across the cut, where the two ends of the bench are the two ends of
   the spectrum rather than neighbours;
3. a new plot, at its own band.

A pale plant, or one whose hue was never sent, takes the first free pot from
the door. A position fills its row by the glass before its row by the path.
(Since 2 October 2026 a pale plant takes the first free pot in the table's
order, the pot opposite the door and then farthest-first, and a band's two
pots are its first and second in that order: §*The colour wheel, 2 October
2026*, below.)

- **The band edges were set from 2,864 hued plants** of the area's own (3,000
  out of 23,259 crossings, less 136 pale), under a label the tests do not use,
  and written in as literals: 166.6°, 190.8°, 215.9°, 239.8°, 265.8°, 291.0°,
  315.7°, 345.4°, 15.7°, 40.3° and 69.6°, as turns past the 114° cut.
- **The border's cut is its own, 1.14 m** (**1.16 since 29 September 2026**,
  measured again after the re-roll: 1.160 m): the 75th centile of five hundred of
  the area's plants drawn under a label the tests do not use, 1.139 m. It was
  the Orchard's crown, borrowed, until 24 September 2026; the new shapes brought
  these plants down further than the garden's as a whole (their 75th centile by
  0.16 m, the garden's by 0.09), and the Orchard's new 1.20 would have taken 18%
  of them rather than a quarter. **The band edges stay**: they are cut across
  hue, and no hue moved.
- **On a fresh five hundred: 18 plots, 87% of places held, the staging 89% full
  and the border 81%, and 340 of 372 hued pots in their own band**, none more
  than one off. It was 17 plots and 92% before the shapes changed: the border's
  quarter of these five hundred is 24%, a little under its quarter of the
  places, so the staging opens plots a little ahead of the border. Own band is
  better than the simulation's 86%, because the edges were fitted to six times
  the sample and a pot one band off tries the side its hue leans to first — a
  choice the simulation did not make, taken here because Marcus's answer was
  *the free place nearest its own*.
- **Hue became `PlantTraits.hue`**, a turn of the circle, optional: the phone
  sends it (`WalkArrival.hue`), `walk_offers` gained a nullable `hue` column,
  and a plant without one is placed as a pale one is. `GlasshouseStore::exactly`
  binds it as the shortest text that reads back as the same double, because
  PDO binds a float at fourteen significant digits — harmless for a height,
  and not for a number compared with a band edge exactly. `check_offers.php`
  holds a hue to the bit through the asking.
- **The vector file compares the hue exactly**, under WebAssembly as on the
  Mac, and `placementCannotTurn` checks only the border's cut: nothing here
  weighs one plant's height against another's.

### The house

**The house of 24 September to 2 October 2026**; since then it is round (§*The
colour wheel*, below), and `SpanHouse.swift` is gone.
`Organic.spanHouse` and `spanHouseGlass`: a span house 4.4 m by 3.4 m, eaves
at 2.1 m and ridge at 2.9 m, glazed to the ground, with its sliding door slid
open in the `x−` gable — the end the spectrum and the border both count from.
**The eaves and ridge were set by the plants under them**: a potted plant
stands 0.83 m off the floor and may be 1.30 m tall, and `GlasshouseTests` holds
every one of the five hundred under the roof with a tenth of a metre to spare
(the nearest was 0.23 m clear). Since 24 September 2026 a potted plant is under
1.14 m and the nearest stands 0.39 m under the roof; the house was left as
built, with more air over the pots. `Organic.staging` is five slats on five frames
of legs; `Organic.pot` is a turned clay pot, round by `Organic.turn`, which
sums the board's corner series four times rather than calling `sin`.

The page draws a pot under every planting with a `lift`, which the service
sends beside its spot. So the ground is built again for each plot
(`makePlotStage`'s `rebuild`), and `add` takes a lift. The glass is the Cold
Frame's pass at 5% rather than 7%, because two or three layers of it stand
between the eye and a pot. The floor is quarry tiles, the map's `LOOK.light`
ground, laid on the Knot Garden's jittered lattice with a tone to a tile, so
the grid a tiled floor is shows as tone rather than as ruled lines.

### The colour wheel, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026. The plot does not vary:
a colour wheel has one way round (`Glasshouse.variants` is `.fixed`, and is
read, so a spot is found the way every other area's is). Notes and renders:
`design/garden-layouts-2026-10-02/built/glasshouse.md`, with
`glasshouse-after2-10.jpg` and `glasshouse-after2-full.jpg` for the painted
band.

- **The house is round** (`Morphology/Structures/RoundHouse.swift`): a wall of
  glass 2.2 m in radius, laid by hand, its radius wandering outward by up to
  4 cm and never inward, so nothing stands under a roof lower than
  `Glasshouse.roof`. Fourteen bays and a doorway, a post at each, and a rib
  curving up a parabolic dome from every post to a ring at the crown, with a
  second ring partway up and a turned cap. **Eaves 2.2 m, crown 3.5 m.** Every
  bar is the bench's board section swept along a curve, and each post leans a
  few millimetres off true.
- **The door is in the green gap**, at `z+`, between the staging's two ends,
  slid open round the outside toward `x+`, with a threshold stone across the
  doorway, half in and half out.
- **The staging is a ring** (`Structures/Staging.swift`, `ringStaging`) of four
  curved slats on twelve frames of legs, 0.40 m deep, its middle 1.8 m out.
  **24 pots stand on it 0.43 m apart**, two to each of the twelve hue bands,
  where the span house's stood 0.30 m apart and 99% of these plants were wider
  than that. Band 0 (blue-green) is just past the door going round toward `x−`,
  band 11 (yellow) just before it; from the page's first view the warm half is
  nearest.
- **The border is a round bed of eight in the middle**, under the crown, filled
  from its middle and then farthest-first. The ambassador, *Elora elata*,
  stands in the middle of it.
- **The floor**: outside the wall the jittered lattice of tiles; inside, five
  rings of tiles from the bed to the wall, each following the bed's wander on
  its inside and the wall's on its outside.
- **The trough** stays under the staging, bent to the ring under its `x+` side,
  0.24 m across, to stand between the legs; `glasshouse.js` walks it along the
  staging's line, because `water.js`'s troughs are fanned from a middle.
- **The rule is unchanged where it was settled**: the height cut at 1.16 m, the
  band edges and the hue rule as pinned, a pot trying its own band in every
  plot, then one band off on the side its hue leans to, never across the cut,
  then a new plot. Thirty-two places a plot, 24 and 8. **One placement
  changed**: a pale or unsent pot takes the first free pot in the table's
  order, the pot opposite the door and then farthest-first, where it took the
  first free pot from the door, which stood every pale pot in band 0 or 1.
- **The table**, `tools/layouts/tables/glasshouse_wheel.py`
  (`PlaceTable.glasshouseWheel`, `GlasshouseWheelTable`,
  `tables/glasshouse_wheel.js`), carries the wall, the staging's line and the
  bed. Named `glasshouse_wheel` because a generated `Glasshouse.swift` cannot
  sit beside the rule's file.
- **The app does not draw the Glasshouse**: its structures are in SeedCore, and
  only the plant module calls them.

**Decided by Marcus, 2 October 2026: the dome is kept, and a painted band is
added.** The dome's height was set for the eye, not the plants: a dome rising
less than about 1.3 m over its eaves hides inside the ellipse its own eaves
make and reads as a drum with a lid. The band answers the open question of
whether the wheel reads, because colour shows only through flowers, which are
small beside the leaves:

- **A thin band of paint along the top of the staging's outer slat**, the one
  by the glass, under the pots' rims, as the research's sketch drew it. From
  the page's eye the near half of the ring shows its outer edge and the far
  half shows over its own staging, so the whole wheel reads; on the front slat,
  tried first, the near half was hidden behind its own boards.
- **It shades through the hues round the ring**: each band of the twelve is at
  its middle hue midway between its two pots, and the colour shades evenly from
  one band's middle to the next, blue-green past the door through blue, violet,
  magenta, red and orange to yellow, with no seam between bands. Its ends,
  toward the door, run on into the green of the gap. The cut and the band edges
  are the rule's, sent by `pg_glasshouse_plan`, and where the pots stand is the
  table's, so the paint cannot disagree with the pots.
- **Hand-painted, with an organic edge**: chalky, softer than the flowers it
  keys; each edge wanders on its own by a few millimetres and feathers into the
  boards over a centimetre; each step's tone is a little off the last, as a
  brush leaves it; and it thins to a rounded end at each end of the staging.
  The staging's line already wanders a centimetre, so the band is no
  machine-perfect circle. Page only (`paintBand` in `glasshouse.js`).

**The fill, at 1,000, is the baseline's exactly**: 33 plots, 94.8% held, 98.7%
in settled plots; only where a pale pot goes changed. At 100 the settled plots
are a little fuller, 98.4% against 96.9%.

**A deploy re-lays the existing plots by itself.** The service stores a
planting's slot (bed, band or bed place, row) and its nudge, and works the spot
out from the table when it serves it, so every plant already in the live
Glasshouse stands in the round house at its slot's new spot with no data
changed. Only the pale pots differ from a replant's answer: re-recording the
vectors moved 161 of 500 placements and changed the plot of 72, each a pale pot
taking a different pot or a hued pot taking the place a pale one left.
`slot_row` changes meaning harmlessly, from by the glass or by the path to a
band's first or second pot.

**The map's glyph** is a round house with a dome, ribs and a door (a pitched
roof until 2 October 2026).

## The Coppice, chosen

The ninth area, `renewal`, designed on 24 September with a simulation and no
code, the way the Glasshouse was, and built the same day (§*The Coppice,
built*). The numbers below are the design's, and the build measures its own. It holds 8.4% of arrivals, the fewest
of the three areas still shut. It also answers the question this document has
carried since it was written (§*Open questions*): how a coppice shows its
rotation.

### What was measured first

`tools/coppice/` grew 4,000 plants whose names put them in the Coppice: 2,000
from 23,791 crossings to measure on, and another 2,000 from 24,054 crossings to
check against.

- **Every plant in the Coppice is a fern or a star.** Its genus heads are `Dros`
  and `Ros`, and `PlantName.roots` gives those two to many-merous ferns and
  many-merous stars and to nothing else. That is not a tendency in a sample. It
  is a fact of the naming table, which is frozen. The split is 48 ferns to 52
  stars in both samples. **This is the first area whose own plants divide by
  habit, and they divide exactly.** The *Habit* row of §*Slots and roles* has
  had nothing to act on until now.
- **A fern has no bloom to speak of.** Its profile sets `bloomPresence` to 0.05.
  A star carries every flower in the area.
- **Ferns are the shorter habit**: 0.22–0.92 m, median 0.49. Stars are
  0.48–1.77 m, median 1.00. A fern spreads 0.67 m, a star 0.79 (the median of
  each; with the shapes before 24 September 2026, 0.31–1.40 and 0.52–1.95 m,
  both about half a metre across).
- **Drawn young, a fern is 0.08–0.38 m tall**, at the Cold Frame's
  `heightScale` of 0.30 with no bud. That makes the shortest star in either
  sample, 0.43 m, taller than the tallest cut fern. The design below rests on
  that fact.
- The ambassador, *Rosea caerulea*, is a star of 0.906 m.

### Three layouts, and the one chosen

A coppice is a wood cut in panels, called coupes. Each year one coupe is cut to
the stool and left to grow back, so every stage stands at once: stumps, poles
waist-high, and poles grown. The flowers come up in the light a cut lets in. The
three layouts considered all show that; they differ in where.

1. **One coupe to a plot.** Each plot would stand at one stage, and plot *n*
   would be cut in year *n* mod 3, so the rotation would show on the map. It is
   the simplest rule of the three. It was rejected because a visitor comes down
   onto a plot and would see one stage there. *Every stage at once* is the
   coppice's picture, so it has to be inside the plot.
2. **Four coupes round a standard.** The plot would be quartered round one tall
   plant left uncut, which is coppice-with-standards, the commonest English
   form. It was rejected on three counts. It is the Crossing's plan with a tree
   where the paving is. The standard is a height place that waits for a tall
   plant, and the Orchard showed that such a place can wait hundreds of
   arrivals. And four coupes need a four-year rotation, which shows only three
   distinct stages.
3. **Three coupes in bands, cut in turn — chosen.** Two rides cross the plot
   and divide it into three long panels side by side. That is what a worked
   coppice looks like from above: cants laid alongside each other and cut in
   sequence, which gives the stepped profile, stumps next to half-grown next to
   grown. Three bands give three stages, and three is as many as a plant's
   growth shows distinctly: young, half-grown and grown.

### What is cut: the ferns

Something in each coupe has to be cut, and three ways of deciding what were
simulated side by side (§*The fill, simulated* has the numbers):

- **By height**, with the tallest 45% on the stools. This fills at 96.2% at two
  thousand. It also cuts 81% of the stars, so the showiest flowers in the wood
  would be out of flower two years in three.
- **The stars on the stools and the ferns on the floor.** The heights stand in
  their natural order, the tall habit growing over the short one, and it fills
  at 96.2%. It cuts 89% of the stars. Colour is the one thing a star has, so
  this was rejected.
- **The ferns on the stools and the stars on the floor — chosen.** It fills at
  97.8% and cuts no star, ever. Every flower in the Coppice is drawn in flower
  every year. A fern loses nothing a visitor could see by being cut, because it
  had no bloom to lose, and a fern growing back from a cut comes up as a fern
  always does, in croziers, which is as plain a picture of renewal as a garden
  has. **In a coupe's cut year every star stands over every fern in it**, with
  0.15 m to spare at the closest. Each winter one band of the plot becomes a
  glade of flowers over new growth, and the other two show the ferns coming
  back. That is also true to the practice: in real woods the cutting is what
  brings the flowers.

**The cost: a grown fern does not overtop the stars.** Measured at five hundred, 5 of 233 ferns on stools stand over the front
row of their coupe in their grown year, and none over the shortest star behind
them. So the rotation reads at knee height, under the flowers, not as poles
over them. What says *coppice* at a glance is the stool, the old cut wood each
fern grows out of (§*The stool*). The fern is what the stool grows.

### The plot

**Thirty-three a plot: three coupes of eleven.** That is five stools down the
middle of each band and three places in the light on either side, a back row
and a front row. The Glasshouse has thirty-two in the same square and the Long
Walk forty-eight. **The bands below are the layout of 24 September to 2 October
2026**; since then the three coupes lie round a glade, with the same counts,
rows and indices (§*Coupes round a glade, 2 October 2026*, below).

| | Where, in metres from the middle of the plot |
| --- | --- |
| **Coupes** | Bands along `x`, their middles at `z` −1.80, 0 and +1.80. Coupe 0 is `z−`, the far band before the page is turned |
| **Rides** | Two, their centrelines at `z` ±0.90. Each is 0.48 m wide and wanders up to 0.08 m off its line |
| **Stools** | `x` −1.8, −0.9, 0, 0.9, 1.8, on the coupe's middle |
| **The floor** | `x` −1.35, 0, 1.35, in a back row 0.40 m behind the stools and a front row 0.40 m in front |
| **Nudge** | 0.06 m either way, from the seed |

The nearest two places stand 0.40 m apart before the nudge. At the worst nudge
and the worst wander, every place is 0.18 m clear of the plot's rim and 0.12 m
clear of a ride. `simulate.py` checks both. A row fills from its middle outward:
stools in the order 2, 1, 3, 0, 4, and floor places 1, 0, 2. A coupe holding
three plants then reads as a clump, where filling from one end would make it a
line. Which place a plant takes along its row changes no count, so none of this
needed simulating.

### The rule

An arrival is either a fern or a star, and the two are placed by different
steps.

**A fern:**

1. A free stool in the oldest plot that has one, in whichever of that plot's
   coupes holds fewest ferns on stools. A tie goes to the lowest coupe.
2. Failing that, the floor, by a star's rule below, **but no more than one fern
   to a coupe's floor.** A fern standing on the floor is not cut, just as a fern
   on a woodland floor is not.
3. Failing that, a new plot, on the middle stool of its first coupe.

**A star:**

1. Its own row of the floor, which is the back row from 1.00 m up and the front
   row below. The search runs oldest plot first, and within a plot takes the
   coupe with fewest on its floor.
2. Failing that, the other row on the same terms, but only if nothing would
   stand out of order. Nothing in a coupe's front row may be taller than
   anything in its back row. This is the Cold Frame's `inOrder` asked of a
   floor.
3. Failing that, a new plot, in its own row of the first coupe.

The loops are the Crossing's: row outside, plot inside, and the emptiest coupe
within the plot, with coupes standing in for quarters. That keeps the three
coupes of a plot level, so each of the three stages has plants from a plot's
first few arrivals. That matters more here than anywhere, because one coupe is
always in its cut year.

**The cap of one fern to a coupe's floor was found by the simulation, not
guessed.** Stools make up 45% of the places and ferns 48% of the arrivals, so
some ferns have to stand on the floor. With no ferns allowed there, the floor
fell behind the stools and never caught up, finishing at 94.7%. With no limit,
a long run of ferns took the floor from the stars, and the plots the stars
opened afterwards had stools no fern would come to: 74.9% against 85.4% in that
order. A cap of one keeps the realistic fill where no limit put it, and it
keeps the floor the stars'.

**The traits it reads, and the thresholds:**

- **Habit, a fifth trait.** `PlantTraits` gains the archetype's name, sent by
  the phone and stored in a column by both arrival paths, as the Seedbed's kind
  was and the Glasshouse's hue will be. The rule asks one question of it: is
  this a fern. It is exact on every host, because an archetype is picked from
  seed bytes with no `sin` or `pow` involved, so the test needs no tolerance.
  If the Glasshouse's hue is built first, one `walk_offers` migration can carry
  both.
- **One height cut, 1.00 m** (**0.99 since 29 September 2026**: the regrown
  design sample's 1,067 stars stand at 0.991 m), the median of this area's own stars, measured
  over the area's own plants as the Cold Frame's was (1.10 m before 24 September
  2026). It divides the fresh sample's stars 49.0% to the back. A borrowed cut
  would divide them unevenly: the Orchard's 1.20 would put 28% at the back, the
  Long Walk's 0.77 would put 75%. The nearest of 2,084 stars stands 0.25 mm from
  it. The vector file will
  still need `placementCannotTurn` over plot, coupe and row, because a height
  comes out of `sin`.
- **Colour is not read.** Carpets were considered: the first star on a coupe's
  floor would claim it for its colour family, the way bluebells hold a coupe. It
  held 97.8%, as the rule did, but left 15 places empty in settled plots where
  the rule left 3, and a Coppice whose three bands were three colours
  would ask the eye to read colour stripes where it should read the cut. The
  Knot Garden and the Cold Frame already sort by colour, and the Glasshouse
  will. This one sorts by the year.
- **Arrival order** decides the rest. A place is taken once and never changes,
  as in every area.

The ambassador is a star under 1.00 m, so it opens plot 0 in the front row of
coupe 0. An empty floor refuses nobody.

### The rotation

A coupe's stage is arithmetic on its place in the wood and the year:

    stage = (year − (3 × plot + coupe)) mod 3      0 cut, 1 regrowing, 2 grown

`year` counts the winters since the Coppice opened, so the first coupe of
plot 0 is the first one cut. The coupes are cut in sequence along the wood, so
the stepped profile runs unbroken from the last coupe of one plot into the
first coupe of the next. In
every year a third of the ferns on stools are in each stage: at five hundred it
is 78, 77 and 78 of 233, and it stays that way year after year.

| Stage | The fern on a stool is drawn | Height, measured |
| --- | --- | --- |
| **Cut** | `heightScale` 0.30, `leafUnfurl` 0.6, no bud — the Cold Frame's young state without its bud | 0.08–0.38 m, median 0.20 |
| **Regrowing** | `heightScale` 0.65, `leafUnfurl` 0.9, `budSwell` 0.4 | 0.15–0.65 m, median 0.35 |
| **Grown** | At its best, `Maturity.bloomPreview`, as everywhere else | 0.22–0.92 m, median 0.49 |

The two young stages are the Cold Frame's `drawn` with its numbers changed, so
they are the same kind of thing: a stage assembled for drawing, never stored and
never read by the rule. A star, and a fern on the floor, is drawn at its best
every year.

**The year is the plot service's to say.** It goes out with the plantings, so
two visitors on either side of midnight see one wood, and a check can pin the
year. This would be the first page that knows its date. Every other page is lit
at midday and knows nothing of time.

### The stool

Each fern on a stool stands on one: a low boss of old wood, 0.35–0.45 m across
and about 0.10 m high, its outline wandering, with the cut face on top. The
fern's foot stands on the face. **The face is pale in the year of cutting and
weathers grey over the next two**, so the stool is the one structure in the
garden that shows the year. It is drawn in the same pass as the plant it
carries, so it belongs to a planting and not to the plot: an empty stool place
shows the woodland floor, not a dead stump. It is grown wood that was cut,
so its outline can wander more than a sawn bench's and less than a hedge's.
At 0.45 m across, the widest stool still leaves the nearest floor plant 0.05 m
clear at the worst nudge.

### How it reads from the page's eye

- **The ground is a woodland floor**: leaf litter at `LOOK.renewal`'s `#5e4a33`,
  moss where the ground dips, and gentle relief so that no two stools stand at
  one height. None of the eight worlds is a wood, so this is a new one.
- **The rides are trodden, not mown.** They are litter worn paler, with no
  stripes, and they bow and change width along their length. They meet the rim
  where they meet it, not at a corner of a grid. A coupe has no drawn edge: the
  rides are its only boundary, as the mown paths are the Crossing's. **Nothing
  in the plot is a straight line**: not the rides, not a stool's outline, not a
  shadow. A stool's shadow is its footprint moved away from the light, as a
  hedge's is.
- **Seen at the page's angle, the three bands ran corner to corner** across the
  diamond of the plot, one of them open (until 2 October 2026; the coupes now
  lie round a glade, and the cut one lies round it too). The cut coupe shows pale stool faces
  and croziers under a stand of stars in flower. The next shows ferns
  half-grown, and the third ferns grown, still under the flowers. The cut moves
  one band a year, so from the page's first view the open band is the far one
  one year, the middle the next, and the near one the third. Turning the plot
  shows the other orders.
- **Back is `z−`**, as in the Cold Frame. The floor's taller row is further
  from the eye before a turn, and a half turn reverses it, as it reverses the
  frames' ranks.
- **Its words belong to the page.** Which stage a coupe is in, *cut this
  winter*, is a string, and a string is forty-two translations
  (§*Structures need drawing properly*). The stool stays unnamed, as every
  structure is.

### The fill, simulated

24 September. `tools/coppice/coppice-sample` is a small Swift tool built
against SeedCore. It grows each arrival and writes down its height, spread,
colour, archetype and the height it is drawn at in each young stage.
`tools/coppice/simulate.py` plants those arrivals by the rule above, and by the
rules it was chosen over, in Python. The rule has not been written in Swift yet,
so there is nothing to call. Both samples are committed, so the script runs
without Swift. The cut was measured on one sample and every number below comes
from the other, unless it says otherwise.

**The realistic stream**, the fresh sample in the order it was drawn:

| Arrivals | Plots | Full | Held | Empty in settled plots |
| --- | --- | --- | --- | --- |
| 250 | 8 | 7 | 95.1% | 0 |
| 500 | 16 | 14 | 94.9% | 0 |
| 1,000 | 31 | 30 | 97.8% | 0 |
| 2,000 | 62 | 59 | 97.8% | 3 of 1,980 |
| 4,000, both samples end to end | 122 | 120 | 99.4% | 0 |

*Settled* means every plot but the newest two, which are where a visitor would
find an empty place in the old part of the wood.

- **At five hundred it holds 94.9%.** That sits between the Knot Garden's 92%
  and the Orchard's 96%, and it rises with the count, because nearly every
  empty place is at the growing end.
- **Fitting does not flatter it.** On the sample the cut was measured on, the
  numbers are 94.9% and 97.8% at five hundred and a thousand, and at two
  thousand 96.2% with 22 settled places empty — worse than the fresh sample,
  which is two samples differing rather than anything the cut did (with the
  shapes before 24 September 2026 the two samples came out alike). The Glasshouse's twelve band edges gained eleven points from
  fitting. The Coppice has one fitted number, a median, and that is the
  difference.
- **The distribution at two thousand**: 59 plots of 33, then 30, 23 and 1 at
  the growing end. In all 60 settled plots the three coupes hold exactly the
  same number of ferns on stools and of plants on the floor.
- **1,042 of 1,087 plants on the floor are in their own row** (95.9%). **Nothing
  stands out of order anywhere**, in any stream tried, with or without the cap.
- **37 of 951 ferns stand on the floor** (3.9%).
- **The worst wait**: one plot stayed unfinished for 120 arrivals.

**Worst cases.** The same two thousand plants in orders no real garden would
send. The longest run of one habit in either realistic stream is 11.

| Order | Held at 1,000 | Held at 2,000 |
| --- | --- | --- |
| Runs of twenty, stars then ferns | 97.8% | 99.4% |
| Runs of sixty | 97.8% | 97.8% |
| Every star first, then every fern | 54.2% (840 stools empty) | 96.2% |
| Every fern first, then every star | 57.2% | 85.4% (74.9% with no cap) |
| Heights sorted within each habit, in windows of a hundred, shortest first / tallest first | 94.8% | 96.2% / 97.8% |
| Heights sorted within each habit over the whole stream, shortest first / tallest first | 94.8% / 97.8% | 71.3% / 68.1% |
| One colour at a time | 97.8% | 97.8% |
| Shuffled | 97.8% | 97.8% |

- **A stool waits for a fern, and a fern always comes.** A thousand stars in a
  row open 56 plots with every stool empty, and the ferns that follow fill them
  back to 96.2%.
- **The one order it cannot recover from is every fern first.** The ferns fill
  the stools and their share of the floor, then run out, and the stars open
  plots with stools no fern will ever come to. The cap is what brings it from
  74.9% to 85.4%.
- **Sorting heights across the whole stream defeats any rule that grades by
  height**, and the Cold Frame and the Crossing grade the same way. Late in a
  sorted stream, half of each new plot's floor wants a plant shorter, or
  taller, than any still to come. Sorted within windows of a hundred, which is a strong
  fashion for tall plants and no more, it makes no difference.

**The rules it was chosen over**, on the fresh sample at two thousand:

| Rule | Held | Settled empty | Stars out of flower two years in three |
| --- | --- | --- | --- |
| **Ferns to stools, stars to the floor, one fern to a coupe's floor** | 97.8% | 3 | none |
| The same, with carpets of one colour | 97.8% | 15 | none |
| The same, with no fern on the floor | 94.7% | 66 | none |
| The same, with any number of ferns on the floor | 97.8% | 2 | none, but 74.9% if the ferns come first |
| The tallest 45% on stools, by height (cut 0.71 m) | 96.2% | 24 | 848 of 1,049 |
| Stars on stools, ferns the floor | 96.2% | 41 | 934 of 1,049 |

**The template's one real number is its stool share.** `simulate.py --sweep`
tried stools from three to seven a coupe and floor rows from two to four. Every
share between 43% and 47% fills well: 95.2% to 98.8% at two thousand. At 50%
and above the stools are left waiting, at 94.7% down to 68.9%. At 40% and below
the ferns crowd onto the floor's front rows and leave the back rows waiting, at
95.2% down to 75.8%. Forty-five a plot, seven stools and four a row, holds
98.8%. It was passed over because a wood that dense is a border. Twenty-one a
plot holds 98.2%, but at seven plants a coupe the stages are too thin to read.

### Decided, 24 September 2026

1. **The rotation turns once a year, at the winter solstice**, taken as
   21 December UTC. Marcus.
2. **Ferns stand on the stools**, and the stars on the floor are never cut.
   Marcus.
3. **The stars' colours are mixed as they arrive**, with no carpets. Marcus.
4. **The stool is a low boss of old wood whose growth is its fern**, with no
   poles of its own. Taken as recommended, open to change.
5. **A plant's own page draws it grown**, whatever its coupe's year. Taken as
   recommended, open to change.
6. **Thirty-three a plot.** Marcus.

## The Coppice, built

24 September, the same day it was designed. `SeedCore/WebGardens/Coppice.swift`,
`Server/.api/Coppice.php`, `CoppiceStore.php`,
`tools/reference/check_coppice.php`. **The first area whose rule reads a
habit, and the first that knows its date.**

### The rule, as built

The rule is §*The rule* above, unchanged. Built, it holds the simulation's
numbers exactly, because the tests draw the design's fresh sample
(`coppice-fresh`) in the same order:

- **At five hundred: 16 plots, 14 full, 94.9% of places held**, nothing empty
  in a settled plot, 259 of 268 plants on the floor in their own row, and 2
  ferns on the floor.
- **The closest star over a cut fern stands 0.15 m clear of it**, and the
  tallest cut fern is 0.36 m (0.23 m and 0.35 m before 24 September 2026). `CoppiceTests` grows every fern on a stool at
  `Coppice.cutDrawn` to hold that.
- **No star is on a stool, no floor holds two ferns, and nothing stands out of
  order**, in the Swift and in the port.

**Habit became `PlantTraits.habit`**, the archetype's name, a string:
`WalkArrival.habit` carries it, `walk_offers` gained a `habit` column that is
emptied when an offer is answered, and the Coppice's table stores it. Empty
where it was never sent, and read as a star's, so an older phone's fern stands
in the light rather than being refused. It is exact on every host, so the
vector file compares it as a word.

**The year is the service's.** `Coppice.year(utcYear:month:day:)` counts the
21 Decembers since the wood opened, so year 0 runs to 21 December 2026 and in
it the first coupe of plot 0 stands cut. `GET /api/coppice/plot/{n}` sends the
year, each coupe's stage in it, and each fern on a stool with its stage; a
star, and a fern on the floor, is sent with no stage, which is *drawn at its
best*.

**Taking back keeps the height and the habit**, which the rule reads of a
coupe's floor, and writes over the family, which it never reads.

### The page

`Morphology/Structures/Stool.swift`, `Server/assets/js/coppice.js`,
`coppicepage.js`, `/coppice`, `/dev/coppice` (with `?year=` and a *Next winter*
button, since the service stays in year 0 until 21 December 2026).

- **The stool** is bark and a cut face, 0.35–0.45 m across from the fern's
  seed, its outline wandering inward only, by up to 3 cm, so no stool is wider
  than the spacing was worked out for. The bark stands 3 cm into the ground so a
  stool on a slope never floats. The face is cream in the cut year, weathering
  the next, grey in the third. Round by `Organic.turn`.
- **The floor rises and falls by up to 5 cm**, level at the rim, and is a
  little lighter in the cut band and a little darker in the grown one, blended
  across the rides. It is read from the service's per-coupe stages, so the open
  band shows before any stool in it has a fern.
- **The rides are 0.48 m wide, give or take 12%**, and wander up to 0.08 m off
  their line. At the narrowest that leaves a floor plant about 8 cm clear of a
  ride, where the design measured 12 cm at a constant width.
- **Stools cast shadows**, their footprints moved away from the light; the
  first page to draw any.
- **No stage words.** *The far band is cut* is wrong after a turn, and the pale
  faces say which band it is. The page's two new strings, `coppiceAbout` and
  `coppiceAway`, are English only for now, as the Glasshouse's were.

### Coupes round a glade, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026. Notes and renders:
`design/garden-layouts-2026-10-02/built/coppice.md`.

**The rule did not change**: thirty-three a plot, three coupes of eleven, five
stools and a floor of six; ferns to stools in the coupe with fewest, stars to
their own row, one fern at most on a coupe's floor; the Crossing's loops; the
rotation, one coupe cut a winter. Re-recorded, the 500 vector rows keep every
plot, slot and nudge and gain only their variant and spot.

- **The table**, `tools/layouts/tables/coppice_glade.py`
  (`PlaceTable.coppiceGlade`, `CoppiceGladeTable`): three feature variants, 33
  places each.
- **Three rides meet at a small sunny glade** and bend out past the rim, by up
  to 18° by their far end, dividing the plot into **three coupes of unequal
  size**: each takes 27–42% of the turn round the glade, and no two are alike
  (30%, 32% and 37% of the plot in variant 0). Each feature variant moves the
  glade, the rides' angles and the coupes' shares.
- **The stools stand scattered, as a stand**: blue noise over the coupe, the
  five nearest its heart kept, at least 0.55 m from each other and from a
  ride's line, 0.45 m from a star's place and 0.85 m from the glade's middle. A
  stand strung out in a line is refused. **The old order 2, 1, 3, 0, 4 is kept
  as the index a stool is numbered by**, now from the stand's middle out, so a
  coupe of three stools is still a clump and every stored planting still
  means the place it meant.
- **The stars stand in clumps of three along the ride edges, where the light
  is**: the front row at the ride's edge, 0.48 m from its line, for the shorter
  stars, the back row 0.90 m from it for the taller, so from the ride short
  stands in front of tall. One clump by each of the coupe's two rides; each
  row's first place is in the first clump, so a coupe's first two stars stand
  together. `floorOrder` (1, 0, 2) is kept as the indices.
- **Plots vary by number**: four turns, a mirror and three feature variants,
  24 ways (`Coppice.variants`). The service sends the turned spot
  (`Coppice::spot`).
- **The page** (`coppice.js`, from `pg_coppice_layout(plot)`): the three rides
  trodden 0.48 m wide (±12%), edges wandering 4 cm; the glade lighter, sunlit
  and greening, with no drawn edge; each coupe lit by its stage, blended across
  a ride, the glade open in every year; the spring basin beside a ride's outer
  end. What the litter reads is worked out at each lattice corner and averaged
  over a leaf.
- Nearest two places 0.46 m (0.40 m in the bands); the widest stool still
  leaves every floor place more than 0.05 m clear at the worst nudge of both;
  at the worst nudge and the widest ride a star stands 0.09 m clear of a ride's
  trodden edge, where the bands' straight rides left 0.12 m.

**The fill is the baseline's, every figure**: 31 plots at 1,000, 97.8% held,
100% in settled plots. **A deploy re-lays every plot at once with no row
changed**; a coupe's stage is unchanged, so each plot's cut coupe is the same
coupe, lying round the glade rather than across the plot.

**Left open:** the ride edges are 3 cm nearer a star than the bands' were, on
purpose; if a render shows a star's leaves on a ride the front row can move out
to 0.52 m. The spring stands beside a ride's outer end chosen by the table, so
it is not always the near one before a turn.

## The Crossing, built

21 September, the same day as the Quiet Garden. `SeedCore/WebGardens/Crossing.swift`,
`Server/.api/Crossing.php`, `CrossStore.php`, `Server/assets/js/crossing.js`,
`/cross`, `/dev/cross`, `tools/reference/check_crossing.php`.

- **Twenty-four a plot: four quarters of six.** Between the walk's forty-eight
  in the same square and the room's ten. Six is three nearest the middle, two
  behind them and one at the outer corner, so a quarter builds outward from the
  middle of the place: along the path edges until 2 October 2026, on three arcs
  round the basin since (§*Four ways turning in, 2 October 2026*, below).
- **The rule is *wherever there is least*.** An arriving plant goes to the
  emptiest quarter of the oldest plot that has a slot it fits, and a tie goes to
  the lowest-numbered quarter. That is the whole of it, and it is what the area
  is about: a quadripartite garden reads as four ways arriving at one place only
  while all four look equally used. **`<` and not `<=` on that count** is the
  thing the port has to get right, and the only thing it could get wrong while
  agreeing about every number.
- **Cuts at 0.91 m and 1.30 m**, measured at the 50th and 83rd centiles of three
  hundred crossings for a bed of 3:2:1 (0.97 m and 1.43 m before 24 September
  2026; **0.85 m and 1.34 m since 29 September**, on three thousand). Deliberately neither the walk's 0.77/1.20 nor the room's 1.09: the same
  population divided three ways by three templates.
- **The three at the path rank share an arc**, which is what frees them from
  having to be in order with each other. Only ranks are compared, never
  distances, so the rule never has to say which of three equals stands in front
  of which.
- **At 500 arrivals: 22 plots, 20 full**, the two at the growing end holding 15
  and 6. 478 of 501 plants got a slot of their own rank; the other 23 took the
  rank beside it.
- **The rule held first time**, as the room's did, and for the same reason: it
  borrowed a shape that had already been argued about rather than inventing one.
- **The quarters are grass, not beds.** They were bare soil until Marcus looked
  at a plot holding one plant: four brown quarters read as ground waiting to be
  dug. Grass left rough between mown paths is a garden whether it holds one
  plant or twenty-four, and it means a quarter needs no edge drawn at all — a
  mown path's own wandering edge is the only boundary in the place.
- **A round of paving, and the first structure that is neither hedge nor
  bench.** `Organic.roundel`: a low disc standing proud of the grass with a
  wandering edge and a rim down to the ground. It holds no plant, which is what
  lets the 0.46 m meeting ambassador be a plot's first arrival — the same test
  the Quiet Garden's specimen had to pass.

**What looking found**, all of it in the drawing and all of it about the
paving. It arrived as a bright dish two metres across and went through four
states before it was stone: too big (1.0 m radius against a 1.2 m path, now
0.85), too bright and too blue (a near-neutral albedo under a blue sky ambient
is a blue lid), drawn with its own mesh's rings showing as spokes, and finally
too smooth — **smooth normals over a cambered disc take one broad highlight and
read as a polished cover.** It is the one thing on the page shaded flat, one
normal and one tone a triangle, which is what makes it faces rather than a
surface.

### Four ways turning in, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026. Notes and renders:
`design/garden-layouts-2026-10-02/built/cross.md`.

**The rule did not change**: a plant goes to the emptiest quarter of the oldest
plot with a slot of its rank, `<` not `<=`, the rank beside its own if it must.
Re-recorded, the 500 vector rows keep every plot, quarter, index and nudge, and
gain only their variant and spot. What changed is where a slot stands, and the
paths.

- **The table**, `tools/layouts/tables/crossing_ways.py`
  (`PlaceTable.crossingWays`, `CrossingWaysTable`): 24 places, six to a
  quarter, and the four paths' centre lines.
- **The four paths turn in.** Each comes onto the plot at the middle of its
  side and turns evenly, 56° by the time it reaches the paving, all four the
  same way, so they meet the round turning rather than crossing it, and each
  quarter is a comma of rough grass wrapped round the basin. Each centre line
  wanders 3.5 cm by its own seed, so the four are not one path turned four
  ways.
- **The paths are narrower, and narrow as they turn in**: 0.9 m across where
  they come onto the plot, 0.7 m at the round (`Crossing.pathHalfWidth`, 0.45,
  and `pathHalfWidthAtRound`, 0.35). They were 1.2 m all the way, the Long
  Walk's figure, a settled number: a path that turns crosses each arc at a
  slant and covers more of it, and at 1.2 m the inner arc had no room for
  three. **Marcus kept the narrower paths, 2 October 2026.**
- **Six places a quarter on three arcs round the basin**: three at 1.95 m, two
  at 2.45 m, one at 2.80 m (1.90, 2.42 and 2.95 before), all facing in, each
  arc's places 0.23 m clear of both paths. The inner arc is listed middle
  first, then its ends; slot 0 is the middle of the inner arc, 3 and 4 the
  middle arc, 5 the corner. The ambassador still opens quarter 0 at slot 3.
- **Plots vary by number**: four turns and a mirror, eight ways
  (`Crossing.variants`); a mirror sets the four ways turning the other way.
  The service sends the turned spot (`Crossing::spotOn`), and
  `check_crossing.php` measures every plant against the paths as its plot lays
  them.
- **The page** (`crossing.js`) mows four paths along the table's centre lines,
  turned for the plot, striped across their width and kept to the plot's own
  edge; the paving and the basin are as built. The workbench draws only the
  area's own plants (`pg_cross_arrive`): orchids, bells and cushions.
- Nearest two places 0.55 m (0.53 m before); the nearest plant to a path's
  edge, after its nudge, 0.08 m; every plant at least 0.3 m inside the plot's
  edge.

**The fill is the baseline's, every figure**: 46 plots at 1,000, 90.7% held,
92.6% in settled plots, 78 settled places empty. The 78 are today's rule's
(`tools/layouts/BASELINE.md`); this layout neither causes nor fixes them.
**A deploy re-lays every plot at once with no row changed.**

**Left open:** the commas read gently at the page's scale, the mown paths only
a little lighter than the rough grass, their turn clearest in the inner metre;
the inner arc stands at 1.95 m, not the research's 1.32 m, which stood plants
on the paths, so ten plants make a ring a little wider than the research drew.

**The map's glyph** (`gates.js`, `LOOK.meeting`) draws the four paths turning
in to the round, read off the table's lines. Four straight paths until 2
October 2026.

## The dressing: what we place by hand

The rules place the plants. What we choose by hand is everything else, per plot:

- **Its ground**, from the app's eight worlds, or new ones made for the areas
  (the Glasshouse's is quarry tiles, drawn by its page rather than taken from a
  world).
- **Its lights and figures**: a lantern at the Crossing's centre, fireflies in
  the Orchard's grass, a glow-in-the-dark hare in the Quiet Garden. They are
  `Bed.lamps`, stored as strings, so a web garden can hold a figure the app has
  not heard of.
- **Its specimen**, where the template marks one.
- **Its turn**: which corner faces the visitor when they come down onto it.

Dressing never touches a plant. It can be changed at any time, because nothing
anybody visited depends on where a lantern stood.

## Curating it: the tool

A private page, for us alone:

- **Templates, per area.** Slots, roles, spacing, structures, drawn on a live
  plot with real plants dropped into it to see how it fills. Versioned: a new
  version applies to plots opened after it.
- **A preview that fills.** Run an area's template forward over the next five
  hundred plants that *would* arrive (minted seeds, the way the ambassadors
  were found) and look at the plots it makes. This is how a template is judged
  before it is live, and it is the web's version of what the app learned the
  hard way: **the meadow hides terrain faults** and a garden of fourteen
  hides layout faults. Judge a template at five hundred.
- **Dressing, per plot**, as above.
- **Reports**: hide a plant, suspend a plot, reset a name. `WEBSITE.md`
  §*Moderation* already has these; the tool is where they are done.

## The Wild Fields

The opposite of the gardens, and it should look like it.

- **Unarranged.** A released plant's place comes from its seed, the way the
  garden's did before this document: the old rule was right for the wild. No
  slots, no roles, no templates, no curator.
- **One landscape, not plots.** The gardens float, because a made garden has an
  edge and somebody's work inside it. The wild does not have an edge. It is one
  continuous ground running on past the screen, walked by panning rather than
  by a map, and the relief is a landscape's rather than a bed's.
- **No names, no senders, no dates** (`PHASES.md`), and so nothing on it to tap
  but the plant itself. *Superseded 1 October 2026: a name, and where and when
  two gardeners met, stand beside a plant when they choose (§*Who stands
  beside it*); a plant opens the areas' panel when tapped.*
- **No lamps.** Nobody put anything out. At night it is lit by the Milky Way,
  and by fireflies that are simply there, which is the one light the wild has
  of its own.
- **A plant stands where it stands.** Collisions are allowed and drawn, as they
  were in the old garden: two released plants in one place are two plants
  growing together, which is a thing a field does.

### Paths that visitors wear

Proposed by Marcus, 18 September: **paths through the Wild Fields grow more
marked the more visitors take a route, and fade as fewer do**, the way a path
through a wild place stays only while people keep walking it and is otherwise
taken back.

It is the right shape for the wild. Nobody curates it, and yet it is not
featureless: its only paths are made by everybody walking, and nobody made any
one of them. A desire line is the one thing in a landscape that is authored by a
crowd.

- **Wear, per ground cell, that decays.** Each cell crossed adds a little wear;
  every cell loses a fixed fraction a day. A half-life of about a month means a
  route walked all summer is a clear path in autumn, and one abandoned in autumn
  is grass again by spring. Drawn as the ground's own colour trodden paler and
  flatter, never as a line on top: a path is where the grass gave up, not
  something laid.
- **Walking is moving, not looking.** Wear comes from the view crossing ground
  while a visitor pans, not from where it rests. Somebody standing to look at a
  plant wears nothing, which is also true of grass.
- **Capped per cell per day**, so one visitor panning back and forth, or a
  script, cannot carve a road. A path is many people, or it is nothing.

**This is the first thing on the site that learns where people go**, and
`WEBSITE.md` says the site has no analytics. The wear can be made to hold
nothing about anyone: the browser sends only which cells were crossed, in
batches, with no cookie, no identifier and no address logged, and the service
keeps a number per cell and nothing else. That is aggregate footfall and not
tracking. **Accepted by Marcus, 18 September, on exactly those terms**: counts
per cell and nothing else, and the privacy page says so before it runs.

#### Built on /dev, 2 October 2026

**Built, and off on the live site.** Marcus approved it on 1 October. It runs
only where `Server/.api/config.php` says `'wear' => true`. That file is
git-ignored and written on the server, and the server's does not say so.
Where wear is off, both routes answer 404 before the rate limit or the
database is touched, `GET /api/wild` carries no `wear`, `/wild` never loads
`wear.js`, so it counts, sends and draws nothing, and `/privacy` leaves out
`privacy9`. The sweep fades the field only where wear is on.
`tools/reference/check_wild_wear.php` asks a copy with no `config.php` for
both routes and the privacy page, in CI, and expects 404 and eight
paragraphs.

- **The cells** are half a metre square, 128 to a side, so they come round
  with the field. A path is about one cell wide.
- **Walking** is the ground under the middle of the window, crossed while the
  visitor drags the field or presses one of the pad's four directions
  (`walkOn`, `wear.js`). A turn, closer or further, the glide home, going to a
  plant and a postcard's arrival count nothing. Checked on the page: looking
  about sent nothing, and a drag and three presses sent 9 and 32 cells.
- **What is sent:** `POST /api/wild/wear` with `{cells: [[x, z], …]}`. Each
  cell appears once, sorted so the batch is a set of places rather than a
  route, at most 256 of them. A batch goes every half minute while walking,
  and whatever is waiting goes when the page is put away. It is sent with no
  credentials and no referrer. A batch that fails is dropped. The route is
  rate-limited like every write, at the hourly 120 (110 a window), and stores
  nothing new about the caller.
- **What is kept** (`WildWear.php`): `wild_wear` holds the cell, its wear in
  crossings, and how many it has counted today. That is all, and it is
  `WITHOUT ROWID` on SQLite. **No cell carries a date.** Instead one row,
  `wild_wear_day`, holds the day the whole field was last faded to. The first
  batch of a day, or the sweep, fades every cell by the days since, clears
  the counts, and deletes cells below half a crossing. This is stricter than
  a per-cell last-decayed day would be, and no harder.
- **The rule:** each crossing adds one. A cell counts at most **six a day**.
  Wear **halves in thirty days**. The page draws nothing below **eight**, so
  the most one visitor can add in a day shows nothing. Above eight it pales
  on a logarithm, up to 160, a little short of the most a cell can ever hold
  (six over a day's fading, about 260). The check holds the doc's sentence to
  numbers. Walked once a day from June to September, a cell is a clear path
  at 40. Walked as much as the cap allows and left on 1 October, it is down
  to 4.6 by the spring equinox, below what is drawn.
- **Drawn** in the ground's shader as its own colour: paler, drier and
  browner, with the normal laid towards the sky, which makes it flatter. It is
  never a mark on top. (Since the joining, the same day, the ground's detail
  draws it instead — tufts thinned, flattened and given way to trodden earth;
  `wear.js` answers only how worn a point is: §*The Wild Fields joined*.)
  The wear is read as a smooth B-spline over the cells,
  because read straight between them every edge was a run of half-metre
  straight pieces (seen on a render). The read wanders on a slow noise and
  frays at the edge from a stride down to a tuft. The rewrite is injected
  into `GROUND_FRAGMENT` the way the fireflies are. `wildfields.js` itself
  gains three things: a `wear` option, a `looked` callback, and finding the
  ground under the middle of the window.
- **The workbench:** `/dev/wild?wear=demo` invents 150 days of walking over
  the invented field, by the service's own rule. Desire lines run from a hub
  near the middle to its neighbours and on beyond them; one busy line is left
  after fifty days to show fading; a thin web covers the rest; and four
  strangers a day wander anywhere and should show nothing. The page opens
  over the hub. `/dev/wild?source=service` draws the local service's wear and
  sends what a drag crosses.
- **Renders:** `design/wild-wear-2026-10-02/wide.png`, at the furthest look
  over the hub, and `close.png`, at 2.2× on the busiest line.

**Settled by Marcus, 2 October 2026**, on the draft and the renders:

1. **The wording** of the privacy page's paragraph, his own:
   > When you walk through the Wild Fields on this site, by dragging the field
   > or pressing its arrows, the page notes which squares of ground the middle
   > of your view crosses, each half a metre across. Every half minute or so,
   > and when you leave the page, it sends the Wild Fields that list of squares
   > alone, sorted. The Wild Fields keep one number for each square, for how
   > worn it is, and draw the numbers as paths for everyone to see. Each square
   > counts a few crossings a day at most, and every number halves each month,
   > so a path stays only while people keep walking it. The numbers are all
   > that is kept: a count for each square of ground, the same whoever walked
   > it and whenever. Only walking counts; looking around, coming closer and
   > opening a plant leave the ground as it was.
2. **Its place:** `privacy9`, straight after `privacy8`, so the page reads 1,
   2, 3, 4, 6, 7, 8, 9, 5 — and **only while wear is on**, so a deploy with
   wear off never describes something that is not running. `index.php` keeps
   the paragraph between its two `wear` marks only where `WildWear::on` says
   so: the same switch, read the same way (`.api/settings.php`), as the routes.
   Checked headless in English and Danish both ways: on, nine paragraphs, the
   ninth in English under a Danish page; off, eight, and no trace of the ninth
   in the page. In CI, `check_wild_wear.php` checks the off state.
3. **The width:** about a metre is right as it is.

`privacy9` is its own commission (`WEAR` in `tools/strings/commission.py`),
printed by `commission.py --privacy <code>` after the eight, so the 41
catalogues that already have the privacy page and the Wild Fields' strings
are awaiting it rather than half-commissioned. `check.py` counts it.

**Before it goes live:**

1. `privacy9` is translated into every language the site speaks.
2. The branch is merged and deployed, and `'wear' => true` is written into
   the server's `config.php`, which turns on the routes, the page, the sweep's
   fading and the privacy paragraph together. Nothing else changes.

**What this build could not settle:**

- **A daily walker is a crowd.** The cap stops a road being carved in a
  day. Somebody who comes back every day and walks the same line is, to the
  field, a few people a day, as they would be in a real field. Without
  knowing who walks, nothing can tell the two apart.
- **The middle of the window is not a pair of feet.** Different visitors'
  routes between the same two plants will lie wider apart than footsteps do,
  so real wear will be broader and slower to form than the invented lines. A
  path is never drawn narrower than about 60 cm, because the cell is half a
  metre. Worth judging again once there is real traffic.

### What had to be fixed before it opened

All three were done on 1 October 2026, in the build below.

- **`/wild` described the wrong thing.** Its `wildBody` string described a
  seed waiting for somebody else, which is *The Winds* and is the opposite of
  release. It now says where a released plant goes.
- **The privacy page** gained a paragraph, `privacy8`, saying what release
  sends and what the field keeps, before anything sends it.
- **Release uploaded nothing.** `PlantDetailView.release()` animated and
  deleted. It is a different action from *Show in the peace garden*: release
  is letting a plant go, and the Wild Fields have no asking because a released
  plant is not put anywhere in particular.

### Built, 1 October 2026

**Marcus decided on 1 October 2026 to build it.** He had released a plant on
his phone believing it went somewhere, under a sentence saying *It leaves your
garden for the Wild Fields*, and it had gone nowhere: release animated, deleted
the plant and sent nothing, because there was nowhere to send it. The sentence
was true of a place that did not exist. Building the place was the way to make
it true, rather than rewording it.

**The rule** is SeedCore's `WildFields` (`WebGardens/WildFields.swift`), ported
to `Server/.api/WildFields.php` and held to it by
`tools/reference/check_wild_fields.php` over 304 seeds, in CI.

- **The place is the seed's first four bytes**: two across and two along, each
  the middle of its step, so a place is a whole number of 1/1024ths of a metre
  and exactly the same double on the phone, the service and the page. No
  order of arrival, no neighbours, no nudge — two seeds that agree that far
  stand together, drawn.
- **The field is 64 metres square and its edges meet.** "One continuous ground
  running on past the screen" is said as geometry: walk off one side and you
  walk in from the other, so there is nowhere a reader meets the end of it. 64
  was chosen for the number of plants likely to be in it rather than for a
  screen: a few hundred read as a field rather than a search, and a thousand
  stand one to every four square metres, a meadow rather than a bed (judged on
  `/dev/wild?plants=1000`). **It can never change**, because every place is a
  fraction of it.
- **Read in 8-metre tiles**, which is how a page fetches an edgeless field a
  piece at a time.

**The service** (`WildStore.php`, routes in `router.php`):

- `POST /api/wild/release` takes `{seed, parents, encounter, token?}`. It
  checks the seed is the cross of those parents at that meeting, as an offer is
  checked. It keeps **the seed and the two parents' seeds and nothing else**:
  no time, no token, no meeting, no address, and no order of arrival — the
  table has no counter, and on SQLite it is `WITHOUT ROWID` because SQLite's
  hidden row number would count arrivals for us. The meeting is read to check
  the cross and dropped; the token is compared and dropped.
- **Once per plant.** A second release of a plant already standing is answered
  with that planting, so a phone whose first answer was lost is told the truth
  by the second, and the other gardener releasing their own copy finds it
  already there.
- **A plant the asking has ever held goes only on one of its two tokens**
  (`Offers::letGo`). While it stood in an area its seed, parents and meeting
  were public, which is all a release otherwise asks for, so without this a
  stranger could stand in the wild a plant both gardeners had taken down. A
  plant the asking never held needs no token: its meeting's number was never
  published, so knowing it is the proof.
- **A plant stands in one public place.** Released, it is taken out of the
  asking first — an offer waiting is withdrawn, a planting in an area is taken
  back and keeps only its place — by the same withdrawal either gardener can
  always make, and the other phone hears of it as a withdrawal. And a released
  plant is refused by every area afterwards: an offer of it is answered `410`,
  and the app says *This plant is in the Wild Fields, so it cannot be shown
  anywhere else* without saying which of the two let it go.
- **Abuse.** Anybody can invent two parents and a meeting and release their
  child, as anybody can offer one; a token carries consent, not authenticity
  (§*The asking*). What is in front of that is the rate limit — release is the
  tightest write, nine a window, because it is the one nobody else agrees to
  and nobody can undo — and a `hidden` column, so a plant that should not
  stand can be taken down by hand without a migration. **Since 2 October 2026
  the curator's tool exists**: `Server/.api/curate.php`, run over ssh (`hide`,
  `unhide`, `show` and `list`, by seed or a beginning only one plant has;
  `Server/README.md`, *Taking a plant down*). Hiding sets the flag and writes
  nothing else — no reason, no time, not who — and deletes nothing. A hidden
  plant is in no count and no tile, so neither are the names beside it; its
  row stays, so the seed cannot be released again or offered to an area, and
  the nightly copy keeps it. It will not run as a web page.
  `tools/reference/check_curate.php` holds all of it, in CI.
- `GET /api/wild` answers the field's size and how many plants stand in each
  tile that has any, which is what a page opens on; `GET /api/wild/tile/{x}/{z}`
  answers a tile's plantings, each its seed, parents and spot.
- The nightly copy carries `wild_fields`: there is no order to lose, but a lost
  row is a plant somebody let go of that is nowhere at all.

**The app** (`PlantDetailView.release()`, `GardenModel.release`,
`PlotService.release`):

- **The plant goes only on the service's word that it has arrived.** The hold
  sends it; the plant stands still with *Sending it to the Wild Fields…* under
  the row; the reply has to carry this plant's seed back; then the light
  leaves and the record goes. A plant must never again vanish into nowhere.
- **If the word does not come, the plant stays and the screen says so** — *The
  Wild Fields could not be reached just now, so this plant is still here. Try
  again in a little while.* One sentence for every failure, as the asking has.
- **Nothing is queued.** A plant waiting to go would be neither here nor
  there, and a request made later on its behalf would be one the gardener did
  not make at that moment. Keeping it and saying so is the honest one.
- **Not behind *Alert me when a joint seed is shared*.** That switch stops the
  one request the app makes unprompted (`pending`); release is made by a
  three-second hold.
- The sentence on the mark is unchanged, because it is now true.

**The page** (`/wild`: `wildpage.js`, `wildfields.js`; `/dev/wild` invents a
field):

- **Not the plot stage.** A made garden is a floating slab framed whole; the
  wild is a window onto ground that runs on past it, with a pasture's swells
  (a metre and a half from hollow to rise, each swell a whole number of waves
  across the field so the ground meets itself), and the band it is drawn in
  thins into the night at every side rather than ending at a rectangle.
- **A plant is lit by the gardens' own plant shader** (`PLANT_FRAGMENT`,
  exported from `longwalk.js`), with the fireflies' light added to its sum and
  nothing taken out, so a plant released from the Long Walk is the same plant
  in another light. It is grown from its seed and both parents, like every
  hybrid in every garden.
- **Night, always.** No sun and no lamps: the app's galaxy as the one
  directional light (a third brighter than the app's, judged on renders — the
  app's night has a moon and a plot a few metres across, and this has
  neither), its night sky and bounce, and the Milky Way drawn in the sky where
  it really is tonight (`sky.js`, `milkyWay`). Fireflies are the app's drift
  (`GardenLamps`), two to a tile, placed by the tile and not by the plants.
- **It opens over a plant**, chosen at random in proportion to where they
  stand, because a reader set down in the middle of four thousand square
  metres would most likely be looking at grass. It is walked by dragging, and
  by the pad every area has (`movepad.js`, with `roam`).

**The decision this build could not make: whether the field publishes the
parents.** A hybrid cannot be drawn without both parents' seeds
(`GeneSource.hybrid`: every trait is read from one parent, the other, a blend,
or the child), so the field serves them, and the page grows the true plant.
But `PHASES.md` settled two things that this contradicts. *A released plant is
unattributed for good: it carries no lineage back to either gardener* — and
the parents are the lineage; a gardener's own seed is a parent of every plant
their meetings make, and the seeds travel in every link. And `WEBSITE.md`,
amended 18 September, says publishing a hybrid publishes both parents' seeds
and **therefore needs both gardeners' consent**, which is why the ten areas
have an asking — while *releasing is one person's*. All three cannot hold. As
built, release publishes who met whom for the plants somebody lets go, without
the other gardener's say; `privacy8` says so plainly. The ways out, each cheap
to switch to before the first deploy and expensive after it:

1. **Keep it** (as built): the true plant, both parents public, the other
   gardener not asked.
2. **Ask the other gardener**, as the areas do: release becomes an offer to
   the wild. A plant with no tokens — every plant from before 19 September,
   and every plant from a link — could then never be released anywhere.
3. **Keep the parents on the service and serve the seed alone**: the page
   grows the child seed as if it had been minted, which is a different-looking
   plant from the one released — unattributed, and not the plant.

**Settled by Marcus on 1 October 2026: the first, and more.** Releasing stays
one gardener's act and the plant, with both parents' seeds, is published as
built. In his words: *the one who released it can choose for something about
them to be included or not, and the other gardener gets a notification that
asks them if they want to be anonymous or have anything included. We want to
encourage releasing plants into the wild so people can make space for the new
in their app peace gardens, and also allow for the release to be another
moment of contact for the gardeners whose seeds germinated the plant.* Built
the same day, below.

### Who stands beside it, built 1 October 2026

**What each may show, and nothing else:** their gardener name (the one they
chose for meetings), where they met (the meeting's place as their phone kept
it — the typed or figurative words, never the coordinate), and when they met
(month and year). No free text. Default for all three: not shown.

**Claude's call, accepted by Marcus as built on 1 October 2026:**

- **A name is its owner's alone to show; the place and the month belong to the
  meeting both had**, so each stands only once both chose it.
- **And only if both phones hold the same account of it.** Each phone sends its
  own words for the place and its own month. Until both have chosen, the
  service keeps only a keyed fingerprint of each side's choice, which can
  confirm the other's words match and cannot give them back; when the second
  chooses and the two match, the words are kept in the clear because they are
  shown. Two phones that remember the place differently show no place — a
  place one of them never wrote is not one either agreed to — and the screen
  says so. The figurative place is drawn from the child seed, so two phones
  that kept it match unless one is in another language.
- **Either changes their answer at any time**, withdrawing included, without
  the other, as the walk's withdrawal is. A name can be shown again after it
  is withdrawn: it is its owner's. Nothing is final, because nothing here
  publishes anything of the other's.
- **The page does not say which of the two let it go**: names are served in
  alphabetical order, and a plant with one name is shown as one person's
  (*Grown by Wren*), never with a hint of a second.

**The service** (`WildStore.php`, `wild_names`): one row per plant released
with a meeting's tokens — fingerprints of the two tokens (`Keyed.php`, under
the `offer_key` the asking uses), the two names shown, each side's place and
month fingerprints, and the place and month both chose. No time, no counter,
`WITHOUT ROWID`. The release takes `theirs` and `shown`;
`POST /api/wild/answer` takes either gardener's whole choice; `pending`
answers `wild` beside `offers`, so the other phone hears on the request it
already makes and the *Alert me* switch stops both. A stranger releasing an
already-standing plant again, with tokens of their own, stands nobody beside
it. The nightly copy carries the table, and since this build makes its tables
itself before it copies, so a deploy can never cost the 03:17 copy.

**The app.** The release mark's sentence is unchanged and the hold is still
three seconds; under the sentence, three small switches — *Your name*, *Where
you met*, *When you met* — all off, only for a plant with a meeting's tokens.
The other phone, on its poll, is shown once a sheet with the plant, *Wren has
let the plant you grew together go into the Wild Fields. Yours stays here.*,
the same three switches, a preview of what would stand beside it, and *See it
in the Wild Fields*, which opens `/wild#p=` and the seed's first twelve
characters. Afterwards the plant's own screen says who let it go and has a
mark (the meeting glyph) to change the choice; the one who released it
changes theirs from Settings, *Let go into the Wild Fields*, where a short
note of each released plant — seed, lineage, tokens, the other's name, this
phone's place and meeting time, nothing else — is kept for this. A reset
withdraws what is shown first, as it takes back an offer. The app posts no
local notifications for offers, so it posts none for this either.

**The page.** A plant on `/wild` can be tapped and opens the areas' panel
(`plantpanel.js`, given a `place` and a `beside` of the field's own): its name,
meaning and passage, and *Grown by* with the names, then the place and month
in the gardeners' own words and the reader's month. `#p=` opens the page over
the plant — the seed's first eight characters are where it stands — and then
opens it. `wildBody` and `privacy8` say what is published and that all of it
is optional.

**Not built, and why.**

- **Paths that visitors wear** (§above, accepted 18 September). A later step:
  it is the first thing on the site that learns where people go, and the
  privacy page has to say so before it runs. The field is ready for it — wear
  would be per ground cell, and the ground is already on a fixed grid.
  *Built on /dev on 2 October 2026 and off on the live site until the privacy
  page says so: §Paths that visitors wear, *Built on /dev*.*
- **Water under a lotus**: built 2 October 2026, below. Reeds, which want the
  same water, are not yet given it.
- **Whether a released plant can be found again** is partly answered: a plant
  released with a meeting's tokens is kept as a note so its gardener can
  change what stands beside it, and *See it in the Wild Fields* finds it. A
  plant released without tokens still cannot be found by anyone.

### Water under a lotus, chosen and built, 2 October 2026

**Decided by Marcus on 2 October 2026, from renders**
(`design/wild-lotus-2026-10-02/`): of three — a pool dug under every lotus
(`a`), the land's own hollows holding water (`b`), and the gardens' pool dug
under each lotus (`c`) — **the hollows**. The wild is unarranged and nobody
digs it, so its water is found rather than made: it lies where the field's
swells would hold it. The other two were prototypes and are not in the code;
their renders stay beside the chosen one's.

**The rule** is the page's (`wildwater.js`). SeedCore, the service and the
vector files are unchanged, as the relief has only ever been drawn.

- **The hollows are known before any plant is.** The swells are fixed
  (§*Built*), so the field's fourteen hollows are too. Each holds a pond at the
  deepest level up to 12 cm that keeps it inside the hollow and no wider than
  22 m². Six hold the full 12 cm, four 8 to 11 cm, and four only 2.5 to 5.
- **A hollow holds its pond once a lotus sheds water into it.** From the lotus
  the way water runs downhill is followed, and if it ends in the hollow within
  7 m, the pond is there. A lotus standing a little over the water, up to
  20 cm above the hollow's bottom, raises the pond to 5 cm over its spot if the
  hollow can hold that much.
- **The same plants give the same water in any order**, so the field is the
  same whichever tile came first: each lotus's claim is weighed against the
  hollow's own pond, and the pond takes the highest it can hold.
- **A lotus in a pond floats on it, and anywhere else it lies in a damp
  patch**: the ground round it wet, and water standing in the low spots between
  the tussocks. **Most lotuses are in damp patches**: 26 of 27 in an invented
  field of 400, and 83 of 85 in one of 1,000, where thirteen ponds cover
  190 m², a twentieth of the field. That was known when it was chosen.
  Since the joining the ground's detail draws the wet and the mud: sedge on
  a pond's bank, mud at its edge, rushy grass in a damp patch with silt in
  its low spots (§*The Wild Fields joined*).
- **Any other plant whose seed puts it in a pond stands where it stands**
  (§*The Wild Fields*), on a tussock that comes up 1.5 cm through the water
  under it, lobed by its own seed. Its foot is seen and nothing of it is
  drowned: it reads as a plant growing out of a tussock in the shallows.
- **Reeds want the same water** (`Archetype.wantsWater`: a reed stands in the
  shallows at a pool's edge as a lily lies on it). Not built: a reed released
  into the field is drawn as any other plant is, on grass, or on a tussock if it
  lands in a pond. Giving it a lotus's claim on a hollow, or a place at the
  shore, is the next step.

**At night, which out here is always, a pond shows the sky.** The gardens'
water is a colour rather than a window, and under the field's light a pond of
it read as a hole. The water keeps the gardens' two colours and adds:

- **the stars, and the Milky Way's haze, that `sky.js` draws behind the
  field**, read from that canvas and mirrored: the same column of the sky, at
  an altitude that climbs toward the zenith the nearer the water is to the
  reader, dimmed, and drawn out a little down the view. Plausible rather than
  exact: an orthographic view has no one angle to mirror the sky at, and an
  exact reflection would cost a second render pass;
- **slow, low ripples** of three sizes, each turned its own way so nothing in
  them runs straight. They make the stars waver and change how much sky the
  water gives back, brighter where a ripple turns the surface from the eye,
  and they hold still for a reader who has asked for less motion;
- **the fireflies' light**, as on the grass, and a faint image of each firefly
  over water, swaying and drawn out with the ripples.

The sky comes in only with depth, so a damp patch's puddles show their floor
rather than stars.

**On the page.** Each tile's plantings are told to the water when the service
answers it. When that changes the water on the ground already built, the
ground is built again where it stands and every plant is set again on it, and
the window does not move. Tiles out of sight round a hollow in sight are asked
for, though not grown, so a pond does not depend on which way the reader
walked to it. Near water the ground is drawn at 3.75 cm rather than 0.3 m,
cell by cell, and each cell is kept for the water that reaches it.

**What it costs**, measured headless in Chrome on a Mac (its own GPU, through
Metal), 1400 × 900 at twice the pixels:

- **The field is drawn again thirty times a second only while open water is
  in the window**; otherwise it is drawn when it moves, as before. A frame is
  0.25 ms of script and about 4 ms of GPU with a pond across a third of the
  window, against 2 to 3.6 ms for a view with none (the GPU timer is noisy).
- **Building the ground** takes 55 to 65 ms the first time a pond's cells are
  worked out, 13 to 40 ms when a lotus arriving near it changes them, and 5 to
  17 ms walking past it.

## What has to exist first

In order, because each needs the one before:

1. **A plant drawn in a browser.** `WEBSITE.md` §*What renders the plant* settled on
   `SeedCore` compiled to WebAssembly, feeding WebGL, with a CI-checked JavaScript
   port as the fallback, and no third copy of the geometry. The size of the wasm
   is the open question there. Nothing on the web can be judged until this runs.
2. **A plot drawn in a browser.** The ground is 2D arithmetic (`GardenTerrain`
   draws paths into a context) and ports to a canvas directly; the worlds atlas
   is already a file. The sky and orbit are formulas. The plants and figures
   are the WebGL above. Whether a plot is one WebGL scene or sprites laid on a
   canvas the way the app does it is a decision for when (1) runs.
3. **One area's template**, built and judged at five hundred plants. **Done
   for the Long Walk, 18 September**, in the browser (`/walk`, and
   `/dev/walk` for a walk invented to look at).
   The rule held: every plot full but the growing end, 3% of plants a tier from
   their own. The look did not: one row a tier was about 1.4 plants a square
   metre and read as single stems on turf, with drifts too far apart to read
   as colour. Doubled to two staggered rows a tier (48 a plot, about 2.8 a
   square metre); a partly filled plot is shown as it is. The Long
   Walk is the best first one: its rule is the plainest best practice there is
   (tall at the back, drifts, repetition), and its plots open end to end, so
   the map is a line before it has to be a shape.
4. **The plot service's slot assignment**, append-only. **Done, 19–20
   September.** The service places every arrival by the Long Walk's rule
   (`check_long_walk.php` holds the PHP to the Swift over 600 placements), and
   since 20 September it knows there are ten areas and keeps nine shut:
   `SeedCore/WebGardens/Areas.swift`, `Server/.api/Areas.php`,
   `GET /api/garden`, and a 409 for a plant whose area is not planted yet. A
   table for each area rather than an area column, because `plot`, `side`,
   `tier` and `slot_index` mean a double border on a travel row and would mean
   something else on a knot-garden row.

   **The travel ambassador stands at the head of it**, since 20 September,
   derived rather than stored — §*The ambassador, standing*.

   **The app asks which areas are open** rather than reading a list compiled
   into itself, since 21 September (`PlotService.garden()`), so a phone learns
   that an area has opened on the day rather than at its next update. What it
   was built believing stands in when the service cannot be reached, and errs
   toward *not yet*.

   **A plant is offered to the area its own name belongs to**, from the app,
   since 20 September. That is nine plants in ten refused for now, which the
   app says on the screen before it asks rather than after: a plant whose area
   is still to be planted gets two sentences and no question.
   **A second area, 21 September.** The Quiet Garden is open: its rule is in
   `SeedCore`, its port in `Server/.api/QuietGarden.php`, its plantings in a
   `quiet_garden` table of their own beside the walk's, and `/quiet` draws it.
   An offer now carries the area it is for and is planted there when it is
   answered. That is the point at which *a table for each area* stopped being a
   prediction: the two tables share no column after `encounter`.

5. **The structures**, modelled, per area as each area is built. **The hedge,
   the mown grass and the bench exist**; the glazed frame, the staging, the bed
   edging, the row labels, the tree positions and the knot hedging do not.
6. **The curator's tool.**
7. **The Wild Fields**, once release uploads something. **Done, 1 October
   2026** — §*The Wild Fields*, *Built*.

## The asking, and what a shared plant consents to

**Built 19 September.** Nothing reaches the Long Walk until both gardeners have
said so, and the whole of what stands in for an account is the pair of tokens a
meeting leaves on the two phones. `Server/.api/Offers.php`, `Server/README.md`
§*The plot service*, and `SeedCore`'s `Sharing.swift`.

- **The token is the address, and consent is what it carries.** An offer is
  addressed to the sixteen bytes its recipient minted at that meeting, so only
  that phone can answer it. The service holds a bag of offers keyed by opaque
  bytes and no directory of people at all: it never learns a name, and two
  offers concerning the same pair of gardeners are not linkable.
- **What it does not carry is authenticity.** A service cannot tell two tokens
  minted at a real meeting from two minted by one person on one machine, so it
  cannot tell a real pair of gardeners from somebody planting invented
  crossings. Nobody can plant *somebody else's* plant or answer for them, which
  is the property the address being secret actually buys. Spam is abuse control
  and belongs in front of the service.
- **This supersedes *a plant is published by a plot, proved by a key*** for the
  Long Walk (`WEBSITE.md` §*Who can put a plant there*) and only there. That
  argument is about a page carrying somebody's name, and its premise is that a
  seed is public. A token is not public. A plant's own page, which does carry a
  name, still needs the plot and the sign-in.
- **A plant in the Long Walk carries no name, no note and no date** — the seed,
  both parents and the meeting, which is what a browser needs to grow it. So the
  consent asked on the phone is about one thing: the plant standing where anyone
  walking the garden can come across it. The name-and-note flow `WEBSITE.md`
  specifies is a plant's own page, and it is a second consent with its own
  screen — folding it in here would publish prose on a yes given to a different
  question, which `PHASES.md` forbids.
- **A meeting from before the tokens were kept can never be asked about.** Every
  plant grown before 19 September is in that position. The app says nothing
  about it rather than offering a row that cannot work.
- **A seed that arrived by link leaves no tokens**, because an offer link is
  forwardable and a secret in a forwarded link is held by everybody it reached.
  So a plant grown from a link cannot be shown. Whether the *reply* link should
  carry one — which would let the offerer be reached but not the replier — is
  open, and is a change to the link format.
- **Withdrawing is either gardener's, at any time, without the other.** An
  accepted planting keeps its place, hidden: the walk stays append-only, the
  slot stays taken, and the border is left with a gap, which is what lifting a
  plant out of a border leaves. **Everything else about it is deleted** (24
  September): the seed, both parents, the meeting and the traits the area's
  rule does not read, and the offer keeps only fingerprints (`Server/.api/
  TakenBack.php`, `Offers.php`). An offer nobody answers lapses into a
  withdrawal after thirty days.

## Open questions

- **Whether the app's Thematic arrangement should use these templates.**
  `ARRANGING.md` has the app's Thematic arrangement reuse the site's ten areas,
  so a plant stands in the Crossing in both. If the Crossing is laid out as a
  quadripartite garden on the web, whether a person's own Crossing is laid out
  the same way in the app is a choice. Doing it would mean the templates live in
  `SeedCore`, where both can read them.
- **Whether plots in an area can be walked between**, or only reached from the
  map. The app's pan stops at the plot's edge. The Quiet Garden answered it one
  way for itself by accident: an enclosure is a room, so `/quiet` shows one plot
  and *On* goes into the next rather than panning along a line.
- **Whether a released plant can be found again** by whoever released it
  (`PHASES.md`, still open). The Wild Fields work either way.
- **How the Coppice shows its rotation.** A coupe cut this year and a coupe
  uncut for seven are both true at once; whether a plot's stage is fixed when it
  opens or turns with the real year is a question about what renewal means here.
  **Decided on 24 September**: it turns with the year at the winter solstice,
  and only the ferns on the stools are cut (§*The Coppice, chosen*).
- **Whether a plot can be too empty to open.** The Quiet Garden's rule makes a
  plot with three plants correct; a Long Walk plot with three plants is
  unfinished. Opening a plot only when the last is full says nothing about the
  first days of an area — though no area's first plot is ever quite empty now,
  because its ambassador is in it.

## The Home Ground, chosen

The last area, `ground`, designed on 24 September. Nothing is built. The theme
holds the soil itself, a place you are from, and a kept place, and the name was
chosen because *home ground* carries both the earth and the belonging
(`strings.js`, the comment on `areaGround`). The table above already says what
kind of garden it is: a kitchen garden, rectangular beds 1.2 m wide so no soil
is ever stood on, paths between, crops in rows across each bed. What was left
to choose is what a *crop* is, when every plant is unique.

### The finding that decided it: this area has three crops, and you can see them

The genus is read off the flower (`PlantName.roots`), and the three roots that
mean `ground` belong to three families: **`Cer` is always a spire, `Fen` always
an umbel, `Pell` always a succulent.** Every plant in the Home Ground is one of
three forms, in nearly equal shares, and the three are as unlike each other as
three crops in a vegetable garden. Measured over 2,000 Home Ground plants
(16,990 crossings, 12% of all):

| Root | Form | Share | Height, median (range) | Across, median (90th centile) |
| --- | --- | --- | --- | --- |
| `Cer` — the grain | spire | 32% | 1.35 m (0.59–2.32) | 0.39 m (0.59) |
| `Fen` — the fennel's family | umbel | 35% | 0.93 m (0.40–1.60) | 0.62 m (0.85) |
| `Pell` — the earth's skin | succulent | 33% | 0.47 m (0.19–0.84) | 0.20 m (0.29) |

That is a kitchen garden already standing in the name: spires in a stand, like
a grain; flat umbel heads, which are what carrots, parsnips and fennel are when
they run to seed; low rosettes packed close, like a salad bed. **The crop is the
genus root**, and it is the first reading in the garden that is a fact about a
plant's name and also something a visitor can see without being told.

### Three layouts considered

1. **The rotation — recommended.** Three beds side by side, a crop to a bed,
   rows across each, the tall end away from the sun. A kitchen garden groups
   its crops by family so that a family can move bed together, and here the
   families are the three roots: three beds is a three-course rotation drawn at
   the moment it stands still. Which bed holds which crop is not fixed by the
   plan, as it is not in a rotated garden; it is set by what arrives.
2. **The allotments.** A place you are from, read literally: each plot divided
   into strips, a strip to a gardener, their plants in it. **Rejected on
   privacy first.** A planting carries both its parents' seeds so that a
   browser can grow it, and a gardener's own seed is a parent of every plant
   their meetings make; a strip per seed would gather one person's meetings
   into one place on a public page. That is a map of who met whom, which the
   plot service was built not to hold (§*The asking*: two offers concerning the
   same pair are not linkable). It would also fill worse than the Seedbed:
   most gardeners will share a handful of plants, so most strips would hold
   one or two.
3. **The walled potager.** A kept place, read as *pairidaeza*: four beds round
   a cross of paths, a feature where they meet, a wall round. **Rejected
   because it is two areas already built**: the Crossing's plan inside the
   Quiet Garden's hedge. A kitchen garden's truth is in its beds and rows, not
   in its quarters.

### The plot

- **Three beds, each 1.2 m wide and 4.2 m long**, running the length of the plot
  from −z to +z, their middles at x = −1.65, 0 and +1.65 m. Paths of 0.45 m
  between them and a headland of 0.5 m at each end; the outermost bed edge is
  0.35 m inside the plot, clear of the outline's 0.16 m wander. **Superseded on
  2 October 2026**: the beds sway together in a lazy S about x = −1.60, 0 and
  +1.60 m, with paths of 0.40 m (§*Lazy beds, 2 October 2026*, below).
- **North is −z**, the end away from the page's midday sun, which lights the
  plot from (−x, +z). A tall row there shades nothing but the headland. A
  kitchen garden puts its runner beans and its sweetcorn at the north end for
  the same reason.
- **The crop sets the spacing**, which is what every seed packet is for. Each
  crop is spaced at about its own median spread, so neighbours meet as a sown
  crop's do:

  | Crop | Across a row | Down the bed | A bed holds |
  | --- | --- | --- | --- |
  | spire | 3, at 0.40 m | 9 rows, 0.45 m apart | 27 |
  | umbel | 2, at 0.60 m | 7 rows, 0.60 m apart | 14 |
  | succulent | 4, at 0.28 m | 13 rows, 0.30 m apart | 52 |

  About half the spires and umbels are wider than the gap to their neighbour,
  and one rosette in eight is, which is a bed at maturity rather than a
  nursery. At most 2% of any crop reaches more than 0.2 m into a path, so the
  paths stay open.

  **The rosette row is superseded** — this section records the design as it was
  chosen, before the plant shapes changed. On the new shapes a rosette bed is
  three across at 0.38 m, ten rows 0.40 m apart, **30 a bed rather than 52**.
  See *Decided*, item 6.
- **A plot therefore holds 42 to 156 plants**, depending on which crops claimed
  its beds; the largest in any simulated run held 93. The Long Walk's page
  already draws three plots of 48, so 93 is inside what a page has done.
  **Also superseded by item 6**: with a rosette bed at 30 the range is **42 to
  90** and the largest simulated plot holds **71**.
- **The nudge is 0.025 m down the bed and 0.05 m along the row.** A row across
  a bed has to read as a row, for the reason a drill does in the Seedbed.

### The rule

Two traits: **the crop decides the bed, the height decides the end.**

1. A bed already sown with this plant's crop and not yet full, oldest plot
   first, beds west to east.
2. Otherwise the first bed nobody has sown, oldest plot first. It takes this
   crop's spacing from then on.
3. Otherwise a new plot, its west bed.

Within the bed, **a plant at least as tall as its crop's cut takes the next
place from the north end** — row by row, west to east along each row — **and a
shorter one the next place from the south end**, east to west, working north.
The bed is full when the two meet.

- **The cuts are each crop's own median**, measured on the 2,000: **spire
  1.346 m, umbel 0.928 m, succulent 0.469 m.** Three cuts rather than one,
  because the three crops barely overlap: a single cut would send nearly every
  rosette to the south end and every spire to the north, and a bed of one crop
  would not be graded at all. The umbel's 0.928 is two millimetres from the
  Long Walk's 0.93, and it is **not** borrowed: the walk's divides the whole
  garden into thirds and this divides one crop in half. The Knot Garden
  refused to make one fact look like two; this is the other side of the same
  rule, two facts that happen to agree.
- **Nothing is ever displaced.** If a bed of a plant's crop has any place left,
  it has a place for this plant, because either end will take it. So the fill
  does not depend on a single height, only on the mix of crops, and no plant
  ever stands at the wrong end.
- **Everything that came in from the north end is at least as tall as
  everything that came in from the south**, in every bed. That is the whole of
  the grading, and it is as much as an append-only bed can promise without
  bands: arrivals come in no order of height, so within each end they stand in
  the order they came.
- **A height is compared only with a cut, never with another plant.** The Long
  Walk, the Orchard and the Cold Frame all ask whether a plant would stand out
  of order against its neighbours; this rule never does. The one place two
  hosts' heights can disagree is at the three cuts, and the nearest of 2,500
  fresh arrivals is 0.09 mm from its cut — nine times `VectorFile.height` — so
  the vector test needs `placementCannotTurn` over the three cuts, as the Cold
  Frame's does.
- **The crop is a fifth trait**, after the Glasshouse's hue. The service cannot
  grow a plant to read its name, so the phone sends the genus root and the
  store keeps it in a column, arriving by both paths as the Seedbed's kind
  does. It is three or four letters, exact on every host, and the PHP port
  compares it as a string and needs to know nothing about botany.
- **The ambassador opens the west bed for umbels.** *Fenunora patentifolia* is
  1.102 m, over the umbel cut, so it takes the first place from the north end
  of the first bed: the north-west corner of plot 0, the head of the garden.
  It is 0.93 m across, wider than nine umbels in ten, and leans a little into
  the row beside it, which the first plant in a bed is allowed to do.

### How it reads in the isometric view

- **The page opens looking up the beds from their south ends.** At the first
  turn the eye is over the (+x, +z) corner, so in every bed the short end is
  nearer than the tall one: the way a gardener looks up a bed. The camera is
  always on a diagonal, so the beds are never seen square-on; two of the four
  turns look up them from the south and two from the north, and in those two
  the spires' north ends stand in front, as every area has turns that are its
  worst.
- **One plot a page**, as the Seedbed shows one: a kitchen garden is a
  rectangle you stand at the end of, and two of them end to end read as one
  garden with a seam.
- **The crop can be told from across the plot.** A spike, a flat head and a
  low rosette are silhouettes nobody takes for each other, so three beds read
  as three crops before anything on the page names them.
- **Everything is soil, and nothing is ruled.** The beds are raised about
  0.08 m and mounded, with soft shoulders down to the path, and their outlines
  wander by a few centimetres (`Organic`), so no bed has a straight edge. The
  paths are the same soil trodden paler and flatter, and **the edge of a path
  is the shoulder of a bed**, not a line drawn between them. No boards: a board
  is a ruled line, and a mounded bed is how a no-dig garden is made anyway.
  The soil is dark, the map's `#4d3b2c` — darker than the Seedbed's tilth,
  which is the same earth raked fine for sowing — and toned per face, as the
  tilth is, because soil is crumbs rather than a surface.
- **No new structure.** The beds are the ground's own relief, as the Seedbed's
  drills are. An empty bed in a new plot is dug ground waiting to be sown,
  which is what an unsown bed in a kitchen garden looks like; the reading the
  Crossing had to escape is the one this area wants.

### The fill, simulated

24 September, before any rule was written. The simulation is **Swift: a small
package at `tools/homeground/` that links SeedCore**, so every height, spread
and root is the garden's own, from `Maturity.bounds` and the name. It is not a
SeedCore test, because nothing about a rule that does not exist yet should run
in CI. `swift run -c release --package-path tools/homeground` prints every
number below; the grown samples are kept in its `.build`, so a second run takes
seconds.

**Four streams**, each placed after the ambassador: the 2,000 the cuts were
measured on; a fresh 500 and a fresh 2,000 they were not; and **a village**:
500 plants from sixty gardeners meeting unevenly, weights falling as one over
rank, every meeting a new crossing of their own two seeds. The village is the
realistic stream and the unkind one. Arrivals come in runs, the crops are no
longer even (39% spire, 42% umbel, 19% succulent) and the heights lean, which
is the Long Walk's warning about a sample drawn from few gardeners.

Six rules were run, to separate what each part of the design buys:

| Rule | Fresh 500 | Fresh 2,000 | Village 500 | Plots with all three crops, fresh 2,000 | Pairs in shading order |
| --- | --- | --- | --- | --- | --- |
| **A** fixed beds (a `Cer`, a `Fen` and a `Pell` bed in every plot), one spacing of 24 a bed, arrival order | 8 plots, 87% held | 31, 90% | 9, **77%** | 25 of 31 | 50% |
| **B** as A, from two ends | 8, 87% | 31, 90% | 9, 77% | 25 of 31 | 77% |
| **C′** claimed beds, one spacing, two ends | 8, 91% | 28, 99% | 8, 91% | 24 of 28 | 77% |
| **C** claimed beds, the crop's spacing, arrival order | 8, 91% | 29, 97% | 9, 92% | 10 of 29 | 50% |
| **D — recommended.** Claimed beds, the crop's spacing, two ends | **8, 91%** | **29, 97%** | **9, 92%** | 10 of 29 | **72–78%** |
| **E** claimed beds, the crop's spacing, three bands of rows | 8, 91% | 29, 96% | 10, **75%** | 11 of 29 | 85–86% |

*Held* is the share of places in sown beds holding a plant. *Pairs in shading
order* is how often, of two plants in one bed standing in different rows, the
northern one is at least as tall; chance is half.

- **D at a fresh 500: 8 plots, 6 of them full, 23 beds sown and 20 full, 91% of
  places held.** At 2,000: 29 plots, 28 full, 97%. In the village: 9 plots, 7
  full, 92%. Within a point of the Knot Garden's 92% at five hundred, the best
  in the garden, and it holds in the stream built to break it.
- **Fixed beds fail the village.** A bed that belongs to a crop in every plot
  waits for that crop, so a garden short of rosettes opens plots for the others
  and leaves a rosette bed half empty in each: 77%. Claiming is the Knot
  Garden's, the Seedbed's and the Cold Frame's move, and it is what makes the
  fill indifferent to the mix.
- **The two ends cost nothing.** C and D put the same plants in the same beds
  and hold the same share; D stands three pairs in four in shading order where
  C stands half. It is grading for free, which is the whole argument for it.
- **Three bands grade better and break in the village.** E stands 85–86% of
  pairs in order and 93–96% of plants in their own band on strangers. But a
  band waits for heights, and when the heights lean the bands run out
  unevenly: 75%, ten plots where D needs nine, and only four of them full.
- **In every bed of every run, everything from the north end is at least as tall
  as everything from the south.** The meeting falls anywhere from 14% to 79% of
  the way down a full bed, which is how uneven the halves of a small crop are.
- **What the crop's spacing costs is variety between plots, not fill.** With
  one spacing a plot usually holds one bed of each crop (24 of 28 plots at
  2,000). With the crop's, an umbel bed is full at 14 and a rosette bed at 52,
  so umbels claim more than half the beds (48 of 86) and only 10 of 29 plots
  hold all three. That is what an allotment looks like — the ground goes to the
  crops that take room, and the salad gets one bed — and it is the price of
  beds that read as crops. At one spacing, 91% of umbels would be wider than
  the gap to their neighbour and half the rosettes less than half as wide as
  theirs: a thicket in one bed and a scatter in another.

### Simulated again on the new shapes, 24 September 2026

The same package, run again after the plants' shapes changed (its samples are
now kept under the name of what the plants grow into, so an old sample cannot
answer for a new SeedCore). **The decided design fills as it did**: rule D holds
8 plots and 91% at a fresh five hundred, 29 plots and 97% at two thousand, and
9 plots and 92% in the village, the same as above, and every bed still stands
everything from its north end at least as tall as everything from its south.
Pairs in shading order are 76%, 76% and 68% (72–78% above); E, three bands,
does worse than it did (83% at a fresh five hundred, 70% and eleven plots in
the village).

What moved is the plants, and it touches two decisions before anything is
built:

| Root | Height, median (range) | Across, median (90th centile) |
| --- | --- | --- |
| `Cer` spire | 1.35 m (0.60–2.32) | 0.47 m (0.70) |
| `Fen` umbel | 0.93 m (0.40–1.60) | 0.67 m (0.95) |
| `Pell` succulent | 0.28 m (0.11–0.61) | 0.38 m (0.51) |

- **The rosettes are nearly twice as wide**, 0.38 m against the 0.28 m they are
  spaced at, so 88% of them are wider than the gap to their neighbour (one in
  eight was), and spires and umbels 63% and 61% (about half were). Six in a
  hundred spires and five in a hundred umbels reach more than 0.2 m into a path
  (2% was the most). *Each crop spaced at about its own median spread* would
  now put rosettes at about 0.38 m, three across and ten rows, thirty a bed:
  worth deciding before the bed is built.
- **The cuts**: spire 1.346 m, umbel 0.932 m, succulent 0.275 m. At the rounded
  umbel cut a fresh arrival in the village stands 0.009 mm from it, under
  `VectorFile.height`, so the built cut will need nudging off it the way the
  other areas' comments describe. The umbel's median is no longer beside the
  Long Walk's cut, which is 0.77 m now; the argument for not borrowing it stands
  without the coincidence.
- The ambassador, *Fenunora patentifolia*, is 1.100 m tall and 1.06 m across.

### Decided, 24 September 2026

Marcus took all five recommendations.

1. **Spacing is the crop's own**: umbels 14 a bed, spires 27, rosettes 52.
2. **A bed fills from both ends**: tall from the north, short from the south.
3. **The paths are trodden soil**, paler than the beds, so the whole plot is
   earth.
4. **The beds are mounded, with no boards**; a path's edge is a bed's shoulder.
5. **The map's glyph shows three beds**, redrawn the same day in `gates.js`
   `LOOK.ground`: three bed outlines, with short upright strokes for the
   spires, flat bars for the umbels' heads and close dots for the rosettes.
   Since 2 October 2026 the beds in it sway in a lazy S and the marks follow.

Then, on the new shapes, two more, both on the recommendation:

6. **Rosettes are spaced at their new median spread**: three across at 0.38 m,
   ten rows 0.40 m apart, **thirty a bed** rather than fifty-two. Half of them
   (49%) are wider than the gap to their neighbour, in line with the spires'
   63% and the umbels' 61%, and none reaches 0.2 m into a path. Rule D fills
   as before: 9 plots and 90% at a fresh five hundred, 32 plots and 98% at two
   thousand, 10 plots and 89% in the village. Plots holding all three crops
   rise from 10 to 16 of 32 at two thousand, because a rosette bed now fills at
   thirty; the largest plot holds 71 plants, not 93.
7. **The umbel cut is 0.930 m**, moved off the measured 0.932, where a village
   arrival stood 0.009 mm from it. At 0.930 the nearest of every sample is
   0.58 mm away and the tall share is unchanged, 50.1%. The spire cut stays
   1.346 m (0.89 mm clear) and the rosette cut 0.275 m (0.48 mm clear).
   **Measured again on 29 September 2026**, after the re-roll: spire 1.261 m,
   rosette 0.266 m, the umbel still 0.932 so its 0.930 stands; the nearest
   plant in any sample is 0.03 mm from its cut.
   Rounding all three to two places does not work: 1.35 falls 0.002 mm from a
   spire.

## The Home Ground, built

24 September, the same day it was designed, and the last of the ten.
`SeedCore/WebGardens/HomeGround.swift`, `Server/.api/HomeGround.php`,
`HomeGroundStore.php`, `tools/reference/check_home_ground.php`. **With it every
area is open.**

### The rule, as built

The rule is §*The rule* above, with Marcus's two answers of the same evening:
rosettes three across at 0.38 m, thirty a bed, and the umbel's cut at 0.930 m.
`tools/homeground` now runs that design, and the tests draw its fresh stream in
the same order, so the two agree exactly:

- **At five hundred: 9 plots, 7 full, 26 beds sown and 23 full** (6 of spires,
  13 of umbels, 7 of rosettes), **90% of places held**, and 4 plots holding all
  three crops.
- **In every bed, everything from the north end is at least as tall as
  everything from the south**, and each end is a run from its own end, in the
  Swift and in the port.

**The crop is read off the habit, not sent as a new trait.** The design called
it a fifth trait, the genus root sent by the phone. By the time the rule was
written the Coppice had made the habit the fifth, and in this area it names the
root exactly — `Cer` only ever a spire, `Fen` an umbel, `Pell` a succulent —
so `HomeGround.Crop(habit:)` is the whole of it. No new column in the offers,
no new field on the wire. `HomeGroundTests` holds the naming table to it: if
that test fails, the table has changed.

**A habit never sent is sown as an umbel**: the widest spacing, so whatever
the plant is it has room, and the commonest crop. It matters now, because the
phone does not send a habit until its next build: until then every Home Ground
arrival is an umbel, sorted by the umbel's cut. The replant after that build
puts each in its own crop's bed.

**The vector test holds each height clear of its own crop's cut**, not of all
three: a spire in the recorded five hundred stands 0.005 mm from the umbel's
0.930, and a spire is never asked about it.

**The crop is a column; the claim is read off it.** A bed is claimed by the
first plant sown in it, as a Seedbed drill is, and a planting taken back keeps
its bed, its crop and its place, and gives up its height, family and habit: no
standing plant's height is ever read. The replant writes the crop from the PHP
rule's answer and checks it against the habit, since the plan's places are
numbers and a crop is a word.

### The page

`Server/assets/js/ground.js`, `groundpage.js`, `/ground`, `/dev/ground`.

- **The soil is `LOOK.ground` brought down a quarter**, as the tilth and the
  litter are, on the jittered lattice with a tone to a crumb.
- **A bed is the ground's own relief**: 8 cm high, domed a little across its
  top, a shoulder 16 cm wide down to the path, corners rounded, and each side
  and end wandering by up to 4.5 cm on its own (2.5 cm since 2 October 2026,
  when the beds began to sway: the sway is the bold curve and this the fine
  wander on it). No boards. Plants stand on it: each is lifted by the ground's
  height at its spot.
- **Paths are the same soil trodden paler**, with less spread in the crumb.
- **A sown bed is raked, an unsown one dug**: rougher, in clods of up to
  1.5 cm. Which beds are sown is read off the plantings' spots.
- **No words for the crops.** Three shapes nobody takes for each other say it.
  `groundAbout` and `groundAway` are English only for now.

### Lazy beds, 2 October 2026

Option A of the layouts Marcus chose on 2 October 2026: lazy beds that follow
the land. Plots vary by their number, mirrored only. Notes and renders:
`design/garden-layouts-2026-10-02/built/ground.md`, with
`ground-after2-three.jpg` for the bolder sway.

**The rule did not change**: the crop claims the bed, tall plants come from the
north end and short from the south, a crop's own spacing, 27 spires, 14 umbels
or 30 rosettes to a bed. Re-recorded, the 500 vector rows keep every plot, bed,
crop, index and nudge and gain only their variant and spot.

- **The beds sway together in a lazy S**, west in the north half and east in
  the south, straight at the two ends and the middle, shaped `u (1 − u²)²` so
  they leave each headland square to it. The middle bed sways; the other two
  are its line moved sideways, square to it all the way, so the paths keep
  their width where the beds lean as well as where they run straight. Each bed
  then strays up to 1 cm off the S on its own, as a spade leaves a ridge.
- **Decided by Marcus, 2 October 2026: paths of 0.40 m and a sway of about
  0.15 m.** As first built the beds swayed 0.10 m, as far as they could with
  the beds and paths as wide as they were (paths 0.45 m, settled on 24
  September). Marcus asked for a bolder sway, and the paths narrowed to make
  the room: the beds' middles stand 1.60 m apart, so the outer beds have 0.18 m
  between their straight edges and the nearest any slab's edge comes, and at
  0.15 m their outer edge, wandering as the page draws it, comes to 2.377 m,
  inside the 2.38 m the slab allows. The paths measure 0.39–0.41 m along their
  length, and a bed leans at most 14°.
- **Rows run square to the curve**, `rowGap` apart along the bed's line,
  centred on it, so every crop's rows still span 3.6 m of it and three beds of
  three crops end level. On the inside of a bend a row's outer places draw
  closer to the next row's: at 0.15 m the closest spires stand 0.348 m apart
  (0.387 at 0.10, 0.45 down a straight bed), umbels 0.469 m (0.60), rosettes
  0.275 m (0.40). The rows near an end lean too, so a row's end place comes to
  0.20 m from the bed's end (0.22 at 0.10, 0.275 straight), and an outer bed's
  rows sit up to 1.6 cm toward the half of it on the outside of its bend.
- **The tables**: one per crop (`tools/layouts/tables/home_ground_{cer,fen,pell}.py`),
  because two crops' places can fall on one point and a table holds a point
  once, and `home_ground_beds.py`, each bed's middle and line, which the page
  reads. The geometry is shared in `_home_ground.py`.
- **Plots alternate, mirrored and not** (`HomeGround.variants`): one plot sways
  one way and the next the other, north staying north, so every bed's tall end
  does. The nudge is added before the mirror, in the table's frame, so the
  narrower nudge down the bed turns with its row.
- **The page** (`ground.js`) raises each bed along its line, its width square to
  it, laid as the plot's variant. A bed's side wanders 2.5 cm, not 4.5: the S
  is the bold curve and this is the fine wander on it. **The trough is turned
  to lie along its path**: the beds leave each end square to the headland, but
  over the half metre the trough runs beside them the path leans up to 8°, and
  a trough laid square to the plot would have stood 5 cm up a bed's shoulder.
- **The map's glyph** sways its three beds, the crop marks following.

**The fill is the baseline's, every figure, at both sways**: 16 plots at
1,000, 96.3% held, 100% in settled plots. **Nothing for a replant to do**:
capacities and plot assignment are unchanged, and the service works each spot
out from the plot, bed, crop, slot and nudge it stores
(`HomeGroundStore::planting`), so a deploy re-lays every plot, mirrored plots
included.

## A plant's panel, decided

### Decided, 24 September 2026

1. **Tapping or clicking any plant on an area page opens a panel about it**:
   its Latin name; what the name means — its theme's line and the part of the
   theme it belongs to, as `/meanings` gives them; and one passage from the
   passage bank in the reader's language. An area's ambassador is marked as
   the area's ambassador. Marcus.
2. **Every plant, not only ambassadors, and only what the seed implies.**
   Everything the panel shows follows from the seed and the parents the page
   already has from the plot service. Nothing about the gardener — no name, no
   note, no date. Marcus.
3. **A postcard is a link to the plant.** *Send as a postcard* shares an
   address that opens the area at that plot, close in on that plant, with its
   panel open — through the browser's own share sheet where there is one, and
   otherwise copied, with the panel saying so. Nothing is stored on the
   service to make it. Marcus.

**This is not the plant's own page** (`WEBSITE.md` §*What a shared plant page
is*, and *Names live on a plant's own page* in §*And it has been answered,
before anything was published*). That page carries the
gardener's name and note, and is a second consent with its own screen, as
§*The asking, and what a shared plant consents to* says. The panel carries
only what the seed already implies, which is what the plant standing in the
garden was consented to: so it needs no consent of its own, and a postcard
publishes nothing that walking the garden did not already show.

### As built, 24 September 2026

`Server/assets/js/plantpanel.js`, handed to the pad (`movepad.js`) by all ten
area pages in one line each; `pg_name` in `tools/wasm/Sources/PlantWasm/
Name.swift`; `sharedTheme` in `passages.js`.

- **The name is SeedCore's.** `pg_name` takes the words the page grew the plant
  from and answers its binomial, its genus head and ending, and for a crossed
  plant the two parents' own heads and the pair's two rolls.
- **The passage is the app's, for a reader on the same bank.** A crossed
  plant's is drawn as `Quotes.passage(for:)` draws it at the meeting: the
  parents' shared theme, the part the child's ending picks in it, the line
  folded from the child's seed. So it can come from a different theme from
  the one the name means, as it does in the app. `passages.js` mirrors the
  theme positions and `passage_reference.py` holds the mirror to
  `Quotes.swift`; on the forty crossed plants in a local Knot Garden, the
  module's rolls and the page's theme agreed with the reference's own
  hashing every time. An ambassador was never crossed and has no passage in
  the app; it takes the one its own name and seed draw, as `/s` does.
- **Picking is on the screen.** The stage keeps each planting's seed, parents,
  meeting and plot beside its mesh, and a tap goes to the plant whose stem,
  foot to top as drawn, passes nearest, within a fingertip plus the plant's
  own half-width at that zoom. A tap is a press that neither moved eight
  pixels nor had a second finger, answered on the click after it.
- **The keyboard's way in is `p`**: the plant nearest the middle of the
  window, after moving the window with the pad's keys. Listed in the sheet
  under `?`.
- **The panel is a dialog over the drawing**, in the two panels' shape: from
  the foot of a phone's screen, at the end of the line on a wider window. The
  plant is brought, closer, to the middle of the part of the drawing the panel
  leaves clear. A tap outside closes it, or opens the plant it lands on.
- **A postcard is `/<area>?plot=N#p=<the first twelve of the seed>`**, `N`
  counted from one. The page opens on that plot and, if the plant is there,
  goes to it with its panel open; if it is not, the plot is simply open. The
  share sheet where there is one, the clipboard where there is not, and the
  link itself to copy where neither works.
- **Seven strings, English only for now**: `plantKey`, `plantAmbassador`,
  `plantPostcard`, `plantPostcardText`, `plantCopied`, `plantCopyThis`,
  `plantClose`. While a sentence falls back to English, the area name set in
  it is the English one too.

## Shadows: under every plant and beside the low structures, built 24 September 2026

A close look at the Knot Garden showed the box lit from the upper left and the
plants standing on the gravel as though laid over it, not grown out of it. No
plant cast anything; the only shadow on any page was a Coppice stool's.

**A first pass sized a soft oval by each plant's spread**, and Marcus saw the
fault in it at once: a spindly plant with a few wide branches got a broad pool
it had nothing to cast, and a dense rosette whose leaves are piled up its stem
got a small one. So the size and the strength now come from what the plant
actually puts between the sun and the ground.

- **From its own triangles** (`Server/assets/js/shadow.js`). When a plant is
  added, every triangle of it is slid along `LIGHT.sun` down onto the ground
  and laid into a small grid (1.2 cm cells, at most 112 a side), each cell
  counting the layers over it — a triangle smaller than two cells is spread
  by its area, a bigger one covers the cells whose middles it contains. Layers
  become lost light as `0.42 × (1 − e^(−1.1 × layers))`, so a pile of leaves
  darkens to six tenths of the ground's light and no further, and one thin
  leaf is well under that.
- **Low sharp, high soft.** Each triangle's share is split by its height:
  what is low is blurred 2 cm and counts fully, what is 40 cm up or more is
  blurred 7 cm and counts half. A dense rosette sits in a dark pool; a spire's
  flowers are a faint smudge off to the side; a spindly umbel's thin branches
  blur to almost nothing. The grid is faded to exactly nothing over its last
  cells, so the sheet it is drawn on never shows an edge.
- **Where the light is** comes free: the projection is along the sun in the
  world's frame, so the shadow leans away from it and turns with the plot.
- **On what the plant stands on**, as before: a sheet 1 cm over the floor
  following its height (the Home Ground's beds, the Coppice's litter); in a
  Glasshouse pot, the compost, within 6.8 cm; on a Coppice stool, the cut
  face, within 10 cm. That disc fades out from a third of the way and its rim
  wanders by the plant's place, so it is not a ring on the compost. A fern on
  a stool still gets no second shadow on the litter.
- **Multiplied**, drawn after the ground and before the plants, depth-tested
  and not depth-written, and now **kept to the ground by the stencil**: the
  ground is drawn a second time into the stencil only, keeping what faces up,
  and shadows are laid only there. So a shadow reaching past the plot's
  wandering edge is not laid down the slab's side or over the sky.

About 2.4 ms a plant to work out (27,000 triangles on average on the Home
Ground workbench, 10 ms for the largest), once, when it is added; drawing is
one extra textured sheet a plant.

**The structures' shadows.** A ground builder may hand back `casting` beside
its mesh — the triangles that throw a shadow — and the stage lays them down
the same way over the whole plot (2 cm cells), clipped to it, once each time
the ground is built (a turn, or another plot). Handed back now:

- **The Knot Garden's box**, bands, swells and edging: a hand's width of soft
  shade on the side away from the light, following each band's curve. The
  first of these and the reason for them.
- **The Cold Frame's boxes** (not the lights' bars, whose shadows would be ruled
  lines, and not the glass) and **the Seedbed's labels**.
- **The tall ones**: the Long Walk's yew and low hedge and the Quiet Garden's
  hedge round and its bench. A 2 m yew throws a metre, which falls across the
  border on two of the four turns and off the plot on the others; clipped by
  the stencil, it read as shade and not as a fault, so it stayed.

**After a look, 24 September 2026.** The tall hedges' shadows had a far edge
as straight as the hedge top, so each point's slide now wanders by where it
is — three slow waves and a grain, a fifth either way — with a wider blur
beyond the foot; the foot stays where the hedge stands. The Knot's box gets
the same, a centimetre or two at its height. **The Orchard's trees** are
handed back as `canopy`: each crown laid at half the sun's slide, so it pools
under the tree leaning away from the light, at most two tenths of the grass's
light taken, and broken by dapple from smooth noise (a sum of waves drew a
trellis); the foot of each trunk casts as a plant does, and only the foot,
because a bare trunk's whole shadow is a two-metre stripe. **The Cold Frame's
lights**, since they open, are pieces drawn apart from the ground and cast
nothing; the boxes still do, and opening a light redraws without working any
shadow out again.

Left for now: the Glasshouse (its staging's slats and the house's bars would
throw ruled stripes, and a pot's shadow falls on slats with the floor showing
between them, which one sheet at one height cannot follow) and the Crossing,
whose roundels are paving and throw
nothing. A turn costs roughly 10–30 ms more than it did, for working the structures'
shadow out again; the plants' are kept.

## The at-scale work

**Written down once on 24 September, in a handover, and lost when the next one
dropped it.** It is recorded here so it stops living in `git log`. The evidence
is `design/at-scale/2026-09-24-sheet.jpg`: every area rendered at its share of
10,000 shared plants, which is the first time any of them was looked at full.

It is about **how a full garden reads**, not about throughput. Every item is a
"this was right at one plot and is wrong at a hundred" item.

1. **Open each area on its newest plot.** Every area page opens on plot 0 — the
   oldest, the ambassador's — so a visitor to a hundred-plot area is shown the
   first bed ever planted and has to walk to reach anything recent. The default
   is `plantpanel.js`'s `start`, `postcard?.plot ?? 0`, read by `movepad.js`.
2. **Give each area an overview.** There is no way to see an area whole. The
   pad walks plots as a line, and since 24 September the hub sends an open area
   straight to its page, so the map does not serve as one either.
3. **Make the colour rules visible.** The Knot Garden's compartment-per-colour,
   the Glasshouse's spectrum along the staging, the Quiet Garden's one-colour
   groups — rules that only become legible across many plots, and that nobody
   has yet seen doing their work. **The Glasshouse's is answered on 2 October
   2026**: a colour wheel round a ring of staging, with a band of the hues
   painted along it, so the wheel reads with few plants (§*The colour wheel*).
4. **The Quiet Garden's near-empty rooms.** It is the one area whose rule is
   *fewer*: 10 places a plot, so it opens more plots than anything else — 51 at
   five hundred arrivals against the Long Walk's 11. At its share of 10,000
   that is about a hundred rooms.
5. **Seedbed rows left part-empty in the middle of a run.** A drill is one kind
   repeated, so the gaps are structural, not a placement fault: 73% of places
   held at five hundred.
6. **The crowded Glasshouse staging.** 99% of its plants are wider than the
   0.30 m gap between pots. Deferred into this work on purpose. **Eased on 2
   October 2026**: the ring of staging stands its pots 0.43 m apart.

**How to see any of it**: every workbench takes `?arrivals=N`, and the
simulations already run well past five hundred — the Coppice is tabulated out
to 4,000, `tools/homeground` runs 2,000. Re-running them is how the faults
become visible; it is not itself the work.

### One cost nobody had written down

**Every one of the ten stores loads the whole area into PHP on each arrival**
to decide where the plant goes — `SELECT * FROM <area> ORDER BY arrival`, in a
transaction, N being every plant ever placed there. It is by design, because
the rules grade an arrival against the whole area, and it is why the ambassador
has to be prepended. But it is O(N) per placement with no ceiling: nothing ever
fills up, since a new plot opens whenever the newest will not take an arrival.

The read path is fine and bounded: pages fetch one plot at a time, and `plot`
and `hidden` are indexed. **Only the write path is unbounded**, and at a
thousand plants in an area it is a whole-table read for every offer answered.
