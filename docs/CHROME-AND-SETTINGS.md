# The chrome, and the settings screen

Written 1 September 2026 from a round of feedback on the built app, and **built
the same day**. It was a build spec; it is now the record of what was built, so
the copy below is the copy in the app and the departures are marked as such.
Where the built thing differs from the specified thing, the section says so and
says why — see also *[What the drawing changed](#what-the-drawing-changed)* at
the foot, which is where the marks that could not be drawn as written are
recorded.

## What is wrong today

- **Settings hides inside the seed modal.** `SeedView` is a screen about your
  seed, and Settings is a screen about your preferences. One is not a
  sub-topic of the other, and nobody looking for their preferences thinks to
  open a modal about a seed first.
- **The settings screen explains itself three times.** Every control carries a
  paragraph underneath. Read end to end it is around three hundred words for
  five decisions, and the paragraphs repeat what the confirmation alerts then
  say again.
- **The name looks like a button.** It is a `Button` wrapped in `.pressable()`,
  so it wears the same capsule outline as *Draw a new seed*. It reads as
  something that will do something, not as a value you can change.
- **The rule and the field collide.** Editing swaps the button for a
  `TextField` with `.underlining()`. Two different layouts occupy one slot, and
  the `SproutingRule` lands on top of the field's own baseline.
- **"Keep where you meet" is ambiguous.** *Keep* can mean hold on to, and it
  can mean keep away, keep back, keep out. On a privacy control that ambiguity
  points in exactly the wrong direction.

## The settings control

Settings leaves `SeedView` entirely and becomes part of the stage chrome.

- **A cog, top right.** It appears and hides with the SEED / MEET / GARDEN row,
  on the same `controlsVisible` state, so the stage is still a plant and
  nothing else until somebody asks.
- **The cog stands alone until it is touched**, and the first touch unrolls it
  into the full control — the cog and the word SETTINGS in one capsule. The
  second opens the screen. It is the bargain the rest of the stage already
  makes, held one step further for the one control that is not about the plant:
  the word is what the first touch buys, so you find out what the mark does
  before committing to it. The control rolls back up when the chrome times out
  and when the screen closes. With VoiceOver the two steps collapse into one,
  because the word is already being read aloud and the first touch would buy
  nothing.
- **The word is set in `chromeLabel()`** — the same voice as the buttons along
  the bottom. The cog sits to its left, optically centred on the cap height.
- **Draw the cog rather than borrowing one.** `gearshape` at any weight is a
  chunky, mechanical, right-angled thing and this app has no other right
  angles in it. It is a `Shape`: eight teeth on a thin circle, stroked at the
  hairline weight, in the same `Chrome.muted` as an unselected button. It
  reads as an instrument rather than machinery — closer to the spiral finials
  on the `SproutingRule` than to a settings icon.

**The screen comes down from the top**, because that is where the cog is. A
sheet rises from the bottom whatever opened it, which reads as arriving from
the wrong end, so Settings is a layer `PlantStageView` slides over the stage
rather than a presented screen. It takes an explicit `close` closure instead of
`@Environment(\.dismiss)`, since there is no sheet for `dismiss` to reach.
Reduce Motion gets a crossfade: the panel still has to arrive.

`SeedView` keeps its own Close and loses its Settings button.

## The name

One layout, always. No swap between a display state and an edit state, because
the swap is what makes the rule and the field collide.

- **A `TextField` from the beginning**, set in the serif face it uses now.
  "Gardener" is its *prompt* rather than its text: that is what the other phone
  shows until a name is chosen, so it belongs on screen — but writing it into
  the field would let a stray commit turn the fallback into an actual choice.
- **On the `SproutingRule`.** The unfolded bar is the field's underline from
  the moment the screen opens, not something that appears when editing starts.
  A rule under a value is the oldest signal in print that the value is yours to
  fill in.
- **Centred on the rule**, and the tendrils curl *down*. Two things were
  learned by building it leading-aligned first: a short name tucked against the
  left end looks like it has fallen off the rule, and the tendrils open upward
  with their coils about twenty points in from either end — clear air under a
  centred name, and the first two letters of a leading-aligned one. Turning the
  pair over puts the coils in the empty band below the line. They stay
  mirrored, so the rule still reads as one thing sprouting.
- **A pencil laid over the trailing end**, drawn thin to match the cog, in
  `Chrome.faint`. Over rather than beside, so the field keeps the full width of
  the rule and its centre is the rule's centre. It is an affordance rather than
  a button: tapping anywhere on the row focuses the field.
- **Committed on submit and on losing focus**, so a name typed and then
  dismissed is kept rather than silently dropped.

Because the layout never changes, there is nothing left to clash. The rule owns
the bottom of the row in both states and the field sits on it.

## The copy

The rule: **the control says what it does, and a line underneath is earned only
where something would otherwise surprise somebody.** One of the five sections
needs no line at all.

| Section | Control | Line underneath |
| --- | --- | --- |
| Name | Label `YOUR PEACE GARDEN USERNAME`, field on the rule | *Plants grown under this name will keep it.* |
| Preferred place | Label `DEFAULT SEED PLANTING LOCATION`, menu | none |
| Location | Toggle **Log where new seeds are planted** | *By default, only you see this.* |
| Being told | Toggle **Alert me when a joint seed is shared** | *Your username will only show publicly if you approve.* |
| Starting again | Three rows, held rather than tapped — see below | revealed while held |

That is around forty words against roughly three hundred.

**The section labels are `Chrome.sectionLabel`, not `Chrome.faint`.** At 0.28
they all but vanished. `faint` is right for a label standing beside the value it
explains, where the value should win; it is wrong for a heading somebody is
meant to read on the way past. Letterspacing thins a line of type as surely as a
lighter weight does, so wide-tracked small caps need more of the ground back
than ordinary text of the same size would — 0.72 here.

Two notes on what has gone:

- **The reset rows lose their standing detail lines**, and get them back at the
  moment they matter. Each consequence fades in under its row as the hold
  begins and fades out if the hold is abandoned. The screen stays short when
  you are reading it and explains itself when you are deciding, which is the
  only moment the words were ever for.
- **The closing paragraph about other people's gardens has gone from the
  screen** and belongs in the two alerts that need it, which already carry it.

## Starting again: held, not tapped

The three resets stop being buttons with an alert behind them and become buttons
you hold. **The hold is the confirmation**; the alert goes.

An alert is a reflex — the hand taps *Reset everything*, the eye reads
nothing, the thumb finds the rightmost button. Three seconds of deliberate
pressure cannot be done by reflex, and unlike an alert it can be abandoned
halfway through by simply letting go, which is the gentlest possible way out of
a decision somebody has started making by accident.

- **Three seconds, filling left to right** inside the existing capsule.
- **Its consequence fades in beneath it as the hold begins.** This is the whole
  reason the hold is long: three seconds is roughly how long the sentence takes
  to read, so the words and the fill finish together.
- **Letting go early drains the fill** back to nothing in about a third of a
  second, faster than it filled, so abandoning reads as a release rather than a
  rewind. Nothing happens and nothing is said about it.
- **The action fires the moment the fill completes.** No further confirmation.
- **Haptics**: a light tick as the hold takes, and a heavier one on completion.

### The label as the fill passes under it

Draw the label twice and mask the second copy to the fill's leading edge, so the
words wipe from one colour to the other exactly as the fill reaches them. One
mechanism, all three rows, and it makes the fill feel like it is passing *through*
the button rather than sliding behind it.

### Colour

Colour has been the plants' alone until now — all chrome is white at four
opacities against black. These three rows are the exception, and they earn it
because they are the only places in the app where something is lost. Keeping
colour rare is what will make it mean anything here.

| Row | Fill | Label once filled |
| --- | --- | --- |
| Get a new seed | Pink-gold, light and warm — `#D9A88C` | Near-black |
| Empty the garden | Between the two, an ochre — `#B07A4A` | Near-black |
| Reset everything | Crimson, deep and sobering — `#7E1D28` | Stays `Chrome.ink` |

Add them as `Chrome.pinkGold`, `Chrome.ochre`, `Chrome.crimson`.

The middle row is inferred: only the outer two were specified, and a row with no
colour sitting between two that have it reads as unfinished rather than as
restraint. It sits between them because its consequence does — your seed and its
plant stay, and only what you grew with other people goes.

**Contrast, computed rather than eyeballed.** Near-black on pink-gold is 9.2:1,
near-black on ochre 5.3:1, and `ink` on crimson 10.0:1. All three clear AA at
this text size with room to spare, so the crimson stayed where it was. The
figures are recorded on `Chrome.pinkGold` so that changing a value means
recomputing them.

### The icons

Monoline, round free ends, no filled shapes — [BRAND.md](BRAND.md) §3.2, the
same rule the app icon is drawn to, and the same stroke weight as the cog.
15pt, in the row's own colour, to the left of the label.

- **A seed**, on *Get a new seed*. An ovoid, broad at the crown and tapering to
  a point. The seam went; see *[What the drawing
  changed](#what-the-drawing-changed)*.
- **A recycling turn**, on *Reset everything*. Three arrows in a triangle is a
  corporate glyph and this app has no right angles; it is drawn instead as
  three curved fronds chasing one another round, each unwinding into the next,
  which is the app's own spiral repeated three times. The meaning is worth
  having — *recycling* says the material returns rather than that it is
  destroyed, which is true here and is the kinder and more accurate word for it.
- **The middle row** takes three ovoids standing on a ground line, the garden
  emptied to its outlines.

### Reach

A three-second hold is a motor task, and some people cannot make one.

- **With VoiceOver, Switch Control or AssistiveTouch running**, the row is an
  ordinary button again and the confirmation alert comes back. `consequence(_:)`
  already holds the words; keep it.
- **The fill is information, not decoration**, so Reduce Motion keeps it. It is
  the only thing telling somebody how much longer to hold.
- **The consequence must be announced** when it appears, not left to the
  fill's progress to imply.

## Keep becomes log

**Log**, on the settings screen, the seed screen, the offer inside Exchange,
and in the `NSLocationWhenInUseUsageDescription` string. The seed screen was
not on the original list and carries a third copy of the same switch; leaving
it saying *keep* would have been the drift this section exists to prevent.

*Log* says what happens: a coordinate is written down. It has no second reading
that means the opposite, which *keep* does. It is also the plainer word, and
this is the one control on the screen where somebody's guess about what it does
has consequences they cannot undo.

The place offer inside Exchange shortens to match:

> **WHERE YOU MEET**
> A meeting can log the coordinates of the spot it happened in. They stay on
> this phone, and a meeting logs them only when both of you have asked.
>
> `NOT NOW` · `LOG PLACES`

## Files this touches

- `App/PeaceGarden/Views/PlantStageView.swift` — the cog, top right, on
  `controlsVisible`; the two-step unroll; and Settings as a layer that slides
  down rather than a sheet.
- `App/PeaceGarden/Views/Chrome.swift` — the cog, pencil, seed, recycling and
  garden `Shape`s; `Chrome.sectionLabel` and the three warm colours;
  `ChromeIconLabel`; `PressReporting`; and `HoldToConfirm`, which owns the
  fill, the mask, the drain and the haptics. `underlining()` gains
  `curlingDown` and `pressable()` gains `horizontal`.
- `App/PeaceGarden/Views/SeedView.swift` — loses Settings; *keep* becomes *log*.
- `App/PeaceGarden/Views/SettingsView.swift` — the name row, the copy, and the
  three held rows. Takes `close` rather than reading `dismiss`.
- `App/PeaceGarden/Views/ExchangeView.swift` — the place offer's wording.
- `App/PeaceGarden/Resources/Info.plist` — the location purpose string.

## What the drawing changed

Everything in this section was specified one way, drawn at true size, found not
to work, and drawn another. The reasons are recorded because all four sound
wrong until you see them at fifteen points.

- **The cog is a ring with notches, at 15pt rather than 13.** Teeth drawn as
  outlines merge into blobs: at this size a tooth is about as wide as it is
  long, so its two flanks and the arc across the top fill in and the mark is a
  washer with bumps. Inverting the emphasis — a small ring with long teeth —
  gives the brightness glyph instead, which arrives before the cog does. A
  dominant ring with short teeth on it reads as a graduated dial, which is the
  instrument the section above asks for.
- **The seed lost its seam.** Four ways of drawing it failed: a bar across an
  oval is a Greek theta, and neither shortening it nor dropping it below centre
  shakes that off; a shallow curve turns the mark into a face; the two halves
  slightly apart is an O with a nick in each side; far enough apart to read as
  parted, they stop being one seed. A neutral oval is what made a seam
  necessary in the first place — it says nothing, so something has to be added.
  A shape round at one end and pointed at the other is already a seed.
- **The garden gained a ground line**, and the grid became a row. Fifteen
  points cannot hold two rows of anything taller than it is wide, so the
  two-over-one cluster came out round and read as punctuation; the row on its
  own reads as three zeros. A line under the same three outlines makes it a
  bed with things planted in it.
- **The hold is driven by a button's press state, not a `DragGesture`.** A
  `DragGesture(minimumDistance: 0)` inside a `ScrollView` never began at all:
  the scroll view takes the touch first and hands it on only once it is
  satisfied the finger is not scrolling, which for a finger deliberately
  holding still may be never. A `ButtonStyle` reading `configuration.isPressed`
  has no such problem, and is better behaved besides — `isPressed` goes false
  when the finger leaves the button, so wandering off mid-hold abandons the
  hold with no bookkeeping.

## How to know it is right

**The hold needs a thumb.** Injected touches on a simulator are not sustained
however long a path says to hold for: the press arrives and is released in the
same instant, so a hold begins and is abandoned before a frame is drawn. Each
link was proved separately there — the press registers, the fill animates, its
completion fires the action — but the gesture end to end has only ever been
run in pieces. Two things to watch on the phone: that three seconds is right
rather than long, and that a thumb drifting during the hold does not hand the
touch to the scroll view and cancel it.

Then Reduce Motion on and off, and the name row with the keyboard up, which is
the case that was broken — the rule under the field, the pencil over its
trailing end, nothing overlapping, and the field still visible above the
keyboard.

Dynamic Type is not a variable here and it is worth knowing why: every size in
this app is a fixed `.system(size:)`, so nothing on these screens scales with
it. That is a separate decision to make rather than a thing to check.
