# The second serif voice

A finding, not a rule. Written 31 August 2026 for the brand work, which is
pulling the guidelines together from [BRAND.md](BRAND.md), `design/*.dc.html`
and `App/PeaceGarden/Views/Chrome.swift`. This is the thing those three do not
agree about, set out so it can be settled once rather than argued at each site.

## What the canvas says

`design/Type.dc.html` records four voices, and is explicit about the serif:

> Reserved for the binomial a plant is given. An italic serif for a species name
> is the convention botany already has, and it is the only place a serif
> belongs. Interface headings take the sans.

`Chrome.swift` says the same in its own words: `plantName` is "the serif voice,
used only for plant names", and "only" is meant literally. Commit `69708e8`
enforced it, taking three screen titles off `plantName` and putting them in the
heading voice, on the reasoning that a title in the name voice claims the title
is what something is *called*.

## What the code does

Seven sites set a serif inline, through neither helper. None of them is a plant
name.

| Site | Size | Italic | What it sets |
| --- | --- | --- | --- |
| [ExchangeView.swift:173](../App/PeaceGarden/Views/ExchangeView.swift#L173) | 20 | no | the waiting title: "Looking for someone nearby", "Touch the tops of your phones together", "Waiting for {peer}", "Crossing" |
| [ExchangeView.swift:198](../App/PeaceGarden/Views/ExchangeView.swift#L198) | 20 | no | "Nothing took" |
| [SeedView.swift:54](../App/PeaceGarden/Views/SeedView.swift#L54) | 17 | no | the rename field |
| [EncounterNoteView.swift:60](../App/PeaceGarden/Views/EncounterNoteView.swift#L60) | 16 | no | the note field |
| [EncounterNoteView.swift:97](../App/PeaceGarden/Views/EncounterNoteView.swift#L97) | 16 | no | the `field()` helper, which is Where |
| [PlantDetailView.swift:68](../App/PeaceGarden/Views/PlantDetailView.swift#L68) | 16 | **yes** | a kept note, read back |
| [UnfurlingBackdrop.swift:335](../App/PeaceGarden/Rendering/UnfurlingBackdrop.swift#L335) | 20 | no | a `#Preview`, mirroring the exchange screen |

So there is a serif that is *upright*, untracked, mixed-case and unnamed,
against a `plantName` that is italic, large and named. Two serifs, where the
canvas records one. Being inline rather than a helper is why it survived the
tidy-up in `69708e8`: that commit could grep for `plantName`, and this does not
answer to a grep for anything.

## It is doing two jobs, not one

Worth separating before deciding whether it is legitimate, because the answer
may differ.

**The app's own quiet voice, at 20pt.** The exchange screen's phase titles and
its failure. These are the moments the app has nothing to instruct and only
something to say, and they are the only screen titles in the app not set in the
heading voice.

**The person's hand, at 16 and 17pt.** Every field typed into — a name, a
place, a line to remember a meeting by — and, at `PlantDetailView:68`, that line
read back afterwards, where it picks up an italic that nothing else in this
group has.

## Three places the app already disagrees with itself

1. **Three text fields, three answers.** `SeedView:54` sets the rename field in
   serif 17. `EncounterNoteView:60,97` set their fields in serif 16.
   [ExchangeView.swift:126](../App/PeaceGarden/Views/ExchangeView.swift#L126) —
   the naming step, which asks the same question `SeedView` does — sets it in
   **sans 24**. Whatever the rule is, one of these is wrong.

2. **A note is upright as it is typed and italic as it is read back.** That may
   be deliberate and good: live text upright, a remembered voice italic. Nothing
   records it either way.

3. **The heading voice uppercases, and a title can carry a person's name.**
   `69708e8` noted this chafe and left it alone: the encounter note's heading now
   shouts a name at whoever has just met someone. `ExchangeView:173` has the same
   problem and solves it silently — "Waiting for Sarah" is in the serif, which is
   why it does not shout. The second serif voice is not only an oversight, then.
   At one site it is load-bearing.

## What has to be settled

1. **Is the second voice real?** If it is, it needs a name and a place in the
   canvas, and the canvas's "the only place a serif belongs" has to go. If it is
   not, seven sites move to the sans and the exchange screen's titles need an
   answer to the shouting.
2. **If real, is it one voice or two** — the app's own at 20, the person's hand
   at 16/17?
3. **What does a field wear**, and does the naming step at `ExchangeView:126`
   come into line with `SeedView:54` or the other way round?
4. **Is a note italic when it is read back?**
5. **What does a title carrying a person's name wear?** This is the question
   under all of it, and the reason the canvas's single-serif rule broke in
   practice.

## What applying it touches

Six shipping sites and one `#Preview`, all listed above, plus a helper in
`Chrome.swift` if the voice is kept — which is the point of settling it, because
an inline font is a rule that cannot be checked. `design/Type.dc.html` and the
`plantName` documentation both need the outcome either way.
