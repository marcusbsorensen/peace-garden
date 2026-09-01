# The chrome, and the settings screen

Written 1 September 2026, from a round of feedback on the built app. This is a
build spec: every decision is made, and the copy below is the copy to ship.

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

- **A cog and the word SETTINGS, top right.** It appears and hides with the
  SEED / MEET / GARDEN row, on the same `controlsVisible` state, so the stage
  is still a plant and nothing else until somebody asks.
- **The word is set in `chromeLabel()`** — the same voice as the buttons along
  the bottom. The cog sits to its left, optically centred on the cap height.
- **Draw the cog rather than borrowing one.** `gearshape` at any weight is a
  chunky, mechanical, right-angled thing and this app has no other right
  angles in it. Draw it as a `Shape`: eight rounded teeth on a thin circle,
  stroked at the hairline weight, around 13pt across, with the same
  `Chrome.muted` fill as an unselected button. It should read as an
  instrument rather than machinery — closer to the spiral finials on the
  `SproutingRule` than to a settings icon.

`SeedView` keeps its own Close and loses its Settings button.

## The name

One layout, always. No swap between a display state and an edit state, because
the swap is what makes the rule and the field collide.

- **A `TextField` from the beginning**, carrying `model.shownName`, set in the
  serif face it uses now.
- **On the `SproutingRule`.** The unfolded bar is the field's underline from
  the moment the screen opens, not something that appears when editing starts.
  A rule under a value is the oldest signal in print that the value is yours to
  fill in.
- **A pencil to its right**, drawn thin to match the cog, in `Chrome.faint`. It
  is an affordance rather than a button: tapping anywhere on the row focuses
  the field.
- **Committed on submit and on losing focus**, so a name typed and then
  dismissed is kept rather than silently dropped.

Because the layout never changes, there is nothing left to clash. The rule owns
the bottom of the row in both states and the field sits on it.

## The copy

The rule: **the control says what it does, and a line underneath is earned only
where something would otherwise surprise somebody.** Three of the five sections
need no line at all.

| Section | Control | Line underneath |
| --- | --- | --- |
| Name | Label `WHAT PEOPLE SEE WHEN YOU MEET`, field on the rule | *Plants already grown keep the name you had then.* |
| Preferred place | Label `WHERE A MEETING STARTS OUT SAYING`, menu | none |
| Location | Toggle **Log where you meet** | *Kept on this phone. Both of you have to ask, every time.* |
| Being told | Toggle **Tell me when a plant we made is shared** | *The page waits for your answer before it names you.* |
| Starting again | Three rows, held rather than tapped — see below | revealed while held |

That is around forty words against roughly three hundred.

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

An alert is a reflex — the hand taps *Start from nothing*, the eye reads
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
| Draw a new seed | Pink-gold, light and warm — around `#D9A88C` | Near-black |
| Empty the garden | Between the two, an ochre — around `#B07A4A` | Near-black |
| Start from nothing | Crimson, deep and sobering — around `#7E1D28` | Stays `Chrome.ink` |

Add them as `Chrome.pinkGold`, `Chrome.ochre`, `Chrome.crimson`.

The middle row is inferred: only the outer two were specified, and a row with no
colour sitting between two that have it reads as unfinished rather than as
restraint. It sits between them because its consequence does — your seed and its
plant stay, and only what you grew with other people goes.

**Check the contrast on a device before settling the values.** Near-black on
pink-gold is comfortable; white on that crimson needs looking at, and the
crimson should go darker rather than the text lighter if it is close.

### The icons

Monoline, round free ends, no filled shapes — [BRAND.md](BRAND.md) §3.2, the
same rule the app icon is drawn to, and the same stroke weight as the cog.
Around 15pt, in the row's own colour, to the left of the label.

- **A seed**, on *Draw a new seed*. Echo the silhouette `SeedHusk` draws: an
  ovoid with the horizontal seam across it, because the seam is the meaningful
  part — it is where the thing opens. One stroke for the body, one for the seam.
- **A recycling turn**, on *Start from nothing*. Three arrows in a triangle is a
  corporate glyph and this app has no right angles; draw it instead as three
  curved fronds chasing one another round, each unwinding into the next, which
  is the app's own spiral repeated three times. The meaning is worth having —
  *recycling* says the material returns rather than that it is destroyed, which
  is true here and is the kinder and more accurate word for it.
- **The middle row** takes a small grid of three ovoids, the garden emptied to
  its outlines.

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

**Log where you meet**, on both the settings screen and the offer inside
Exchange, and in the `NSLocationWhenInUseUsageDescription` string.

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
  `controlsVisible`.
- `App/PeaceGarden/Views/Chrome.swift` — the cog, pencil, seed, recycling and
  garden `Shape`s; the three colours; `ChromeIconLabel`; and `HoldToConfirm`,
  which owns the fill, the mask, the drain and the haptics.
- `App/PeaceGarden/Views/SeedView.swift` — loses Settings.
- `App/PeaceGarden/Views/SettingsView.swift` — the name row, and the copy.
- `App/PeaceGarden/Views/ExchangeView.swift` — the place offer's wording.
- `App/PeaceGarden/Resources/Info.plist` (via `project.yml`) — the location
  purpose string.

## How to know it is right

Reduce Motion on and off, and at the largest Dynamic Type size the app
supports: the cog and its word must stay on one line with the plant's name, or
wrap in a way that is deliberate. Then the name row with the keyboard up, which
is the case that was broken — the rule under the field, the pencil beside it,
nothing overlapping, and the field still visible above the keyboard.
