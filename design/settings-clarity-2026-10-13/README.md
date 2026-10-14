# Settings, made clearer — 13 October 2026

Marcus, 13 October: the switches *the calm sage background instead of light
grey*; *Light and dark* to show the chosen answer *with colours inside the
ring … a warm orange for the sun line art, and pale yellow for the moon*; the
seed-planting location settings, *very cryptic, not in a good way*, renamed;
and the long text under them shown only in parts. Then, the same day: that long
text *reads more like something that can be shown on an About page under
Privacy — it's not Settings text*, so Settings keeps one short line for the
chosen answer; and the cog from the stage's row beside the *Settings* heading.

- `before-after.png` — Settings on an iPhone Air, main and this branch, Dark and
  Light: the top of the screen (switches, *Light and dark*, the heading), each
  answer of *Light and dark* chosen, and *Seed planting location* with each
  answer of *Location description* chosen.
- `about-AB.png` — where the long account could go instead: **A** or **B**,
  below. Nothing is built for either yet.

Shot on a scratch simulator with `-pgMint pedicel-9 -pgStage blooming -pgOpen
settings -pgSettingsAt <display|location|again> -stage.appearance.v1
<dark|light> -places.mode.v1 <abstract|geographic|custom> -place.enabled.v1 YES
-garden.daylight.v1 <always|byTheClock|alwaysNight>`. `-pgSettingsAt` is new on
this branch (Debug only); `about-AB.png` came from a throwaway build that was
not committed.

## What changed

**Switches.** On is `Chrome.sage`, the sage stop of the logo's own ramp in the
pair `docs/BRAND.md` gives it: `#9CC29E` in Dark, `#397E3D` in Light. The track
against the ground is 10.6 : 1 on black and 4.6 : 1 on the light ground; the
white knob on it is 2.0 : 1 in Dark — the same as against the grey it replaced
— and 5.0 : 1 in Light. Because the brand pair fits both, there were no
candidates to choose between.

**Light and dark.** The chosen mark is drawn in colour; the other two stay
faint grey. The middle answer, *Follows the hour*, has its sun and its moon each
in its own colour.

| Token | Dark | Light | On the chosen capsule, Dark / Light |
|---|---|---|---|
| `Chrome.sunOrange` | `#F2A65A` | `#B5561A` | 8.6 : 1 / 3.7 : 1 |
| `Chrome.moonYellow` | `#F4E4A1` | `#8C6A00` | 13.6 : 1 / 3.8 : 1 |

In Light a pale yellow cannot stay pale: on the capsule's light grey it is
1.0 : 1 and vanishes, so the moon deepens to a gold. The garden's tray draws the
same control, so its chosen mark is in colour too.

**The heading.** The stage's cog (`CogShape`), in the same 1.2-point pen, in the
heading's ink, at 22 points beside the word. VoiceOver reads only the word. The
two-second hold that opens *Testing* now covers the cog and the word.

**Seed planting location.**

| Was | Now |
|---|---|
| How the place is said | **Location description** |
| One of the places | **A place from abstract list** |
| Where you actually are | Where you actually are |
| Something you write | Something you write |
| Which one | **Abstract list** |

Under the menu stands one line, for the answer that is chosen, and nothing
else:

| Answer | The line under the menu | Also on screen |
|---|---|---|
| A place from abstract list | *Where you met is given as a place from the abstract list.* | *Abstract list*: Wherever the seed travelled, and the forty places |
| Where you actually are | *Where you met is logged on this phone as the coordinates it measured, when you both ask.* | *Waiting for you to allow location.*, until the phone allows it |
| Something you write | *What you write here is kept in this phone's settings, and for now it appears only there.* | *What it says*, and the field |

There is no sentence common to all three. The third line is the sentence
that already stood under the field, kept as it was because it is already one
plain sentence and true, and already translated. What left the screen: the
line under *Which one*, the two sentences on coordinates, and the long account
of what two phones hand each other at a meeting.

## The new words, in Danish

Danish is marked translated; Spanish, French, Italian, Norwegian, Dutch and
Swedish are in the catalogue as *needs review*.

| English | Dansk |
|---|---|
| Location description | Stedsbeskrivelse |
| A place from abstract list | Et sted fra den abstrakte liste |
| Abstract list | Abstrakt liste |
| Where you met is given as a place from the abstract list. | Hvor I mødtes, angives som et sted fra den abstrakte liste. |
| Where you met is logged on this phone as the coordinates it measured, when you both ask. | Hvor I mødtes, registreres på denne telefon som de koordinater, den målte, når I begge beder om det. |
| *(kept)* What you write here is kept in this phone's settings, and for now it appears only there. | *(kept)* Det, du skriver her, gemmes i denne telefons indstillinger, og indtil videre vises det kun der. |

*Registreres* is the catalogue's own word for *log* (*Et møde kan registrere
koordinaterne …*), and *Hvor I mødtes* its words for *where you met*.

## Where the long account goes: A or B

The app has no About or Privacy screen today, so neither is built. The account
is out of Settings and its key is untouched in the catalogue, translated in all
seven languages, ready for either.

**A (recommended): a small About sheet, from the foot of Settings, with a
Privacy section holding the account.** A row at the foot of Settings — an
`info.circle` and *About* — opens a sheet in the app's own voice: the heading,
then *Privacy*, then the account as it stood in Settings. Optionally the same
`info.circle` beside *Location description* opens it too, which is the glyph
rather than a new word. It keeps the account in the app, offline, in all seven
of its languages already, and gives the two sentences on coordinates somewhere
to go if they are wanted back. It costs two new words, *About* and *Privacy*.

**B: a link from the foot of Settings to `peacegarden.app/privacy`.** No new
screen, and the page is in forty-one languages. Its **second paragraph**
(`privacy2`) says what the account's first sentence says — the direct, encrypted
connection, the seed and when it was made, the plant's name, the chosen name,
whether a place may be kept, and the two random numbers — and adds that the
chosen name can be seen by phones nearby while meeting. It does **not** say the
account's last sentence, what each phone keeps afterwards (both second numbers
and a number for the meeting); the third paragraph says only that seeds and
plants stay in the app's own storage. It sends somebody out of the app to read
it.

**One thing for whichever is built.** On main the paragraph in Settings said
*when that seed was **drawn***, but the catalogue's key — translated in all
seven languages — says ***made***, changed on purpose on 26 September
(`620893f`) because eleven languages could not carry *drawn*. The words in
Settings had drifted back, so the paragraph showed in English in every
language. Built from the catalogue's key, it comes back translated.
