# App fixes applied from the 1 October 2026 review

Applied on 2 October 2026 to `App/PeaceGarden/Resources/Localizable.xcstrings`, following
Marcus's decisions of the same day on `REVIEW.md` (branch `claude/strings-review-2026-10-01`).
This file covers the app only. The site changes are recorded in `REVIEW.md` by another job.

## Code and English source

- **`Light` split.** `SettingsView.swift:328`, the heading over the day/night control, now uses
  a new key, `Light and dark`. `SettingsView.swift:822` is
  `.accessibilityLabel(Text("Light"))` on `LightToggle`, the day/night control itself. The
  heading above it is `accessibilityHidden`, so this label is the name VoiceOver reads for
  the same control. It belongs with the heading and now uses `Light and dark` too. `LightToggle`
  is also used in the garden's tray (`PlotView.swift:1273`), which now gets the same label.
  `Light` stays the appearance option beside *Dark* (`Chrome.swift:215`), with its translations
  unchanged.
- **Anonymity line.** `WildBesideView.swift:144` now reads *Beside it stands only what each of
  you chooses. Left as it is, no name is shown.* The old key was removed from the xcstrings
  after a search of `App/` found no other use. Its comment was moved across word for word.
- `Server/assets/js/strings.js` has no claim of anonymity. A case-insensitive search for
  *anonym*, *left as it is* and *no name* finds nothing, so nothing there needs reporting.

## Changes by language

New keys, in all seven languages: `Light and dark` and `Beside it stands only what each of you
chooses. Left as it is, no name is shown.` For the second key, each language keeps its existing
first sentence and translates the second sentence fresh.

| Lang | Key | Was | Now |
|---|---|---|---|
| da | `Release to the Wild Fields` | Løssæt den på Vildmarken | Løssæt den i Vildmarken |
| da | `Release to the Wild Fields?` | Løssætte den på Vildmarken? | Løssætte den i Vildmarken? |
| da | `It leaves your garden for the Wild Fields…` | …tager ud på Vildmarken… | …tager ud i Vildmarken… |
| da | `Gardener username` | Brugernavn som gartner | Dit brugernavn |
| da | `Light and dark` | (new) | Lys og mørke |
| da | `Beside it stands…no name is shown.` | (new) | …Lader du det være, vises intet navn. |
| es | `How the place is said` | Cómo se dice el lugar | Cómo se indica el lugar |
| es | `Light and dark` | (new) | Luz y oscuridad |
| es | `Beside it stands…no name is shown.` | (new) | …Si lo dejas como está, no se muestra ningún nombre. |
| fr | `How the place is said` | Comment le lieu est dit | Comment le lieu est indiqué |
| fr | `Light and dark` | (new) | Lumière et obscurité |
| fr | `Beside it stands…no name is shown.` | (new) | …Si tu ne changes rien, aucun nom n’est affiché. |
| it | `How the place is said` | Come si dice il luogo | Come viene indicato il luogo |
| it | `Light and dark` | (new) | Luce e buio |
| it | `Beside it stands…no name is shown.` | (new) | …Se lasci tutto com'è, non viene mostrato alcun nome. |
| nb | `Release to the Wild Fields` | Slipp den ut på Villmarka | Slipp den ut i Villmarka |
| nb | `Release to the Wild Fields?` | Slippe den ut på Villmarka? | Slippe den ut i Villmarka? |
| nb | `It leaves your garden for the Wild Fields…` | …drar ut på Villmarka… | …drar ut i Villmarka… |
| nb | `What it says` | Hva det skal stå | Hva som skal stå |
| nb | `Gardener username` | Brukernavn som gartner | Brukernavnet ditt |
| nb | `Light and dark` | (new) | Lys og mørke |
| nb | `Beside it stands…no name is shown.` | (new) | …Lar du det være som det er, vises ikke noe navn. |
| nl | `Light and dark` | (new) | Licht en donker |
| nl | `Beside it stands…no name is shown.` | (new) | …Laat je het zoals het is, dan wordt er geen naam getoond. |
| sv | `%@ has let the plant you grew together go into the Wild Fields. Yours stays here.` | %@ har släppt ut växten ni odlade tillsammans på Vildmarken. Din stannar här. | %@ har släppt ut växten ni odlade tillsammans. Nu står den på Vildmarken, och din stannar här. |
| sv | `In the middle, the sun and moon go round…` | …stannar den i dag eller natt… | …står den still på dag eller natt… |
| sv | `What it says` | Vad det står | Vad som står |
| sv | `Waiting for you to allow location.` | Väntar på att du tillåter plats. | Väntar på att du ger tillgång till din plats. |
| sv | `Light and dark` | (new) | Ljus och mörker |
| sv | `Beside it stands…no name is shown.` | (new) | …Lämnar du det som det är visas inget namn. |

Keys changed or added per language: da 6, es 3, fr 3, it 3, nb 7, nl 2, sv 6.

After this change, Danish and Norwegian use *i* throughout the app. Swedish already used *på
Vildmarken* in every string, so it needed no change.

## Declined or not applied

- **da, nb, sv `wildTitle`** (*De Vilde Marker*, *De ville markene*, *Vilda fälten*): declined.
  Marcus is keeping *Vildmarken*, *Villmarka* and *Vildmarken*.
- **it `the other gardener`** (*a l'altra persona*): not applied. The fix in the review is a
  code change. `PlantDetailView.swift:354` and `:371` and the templates `Chiedi a %@` and
  `In attesa di %@` would need fallback variants, and those files are outside this job. The
  string is unchanged and the problem is still open.
- **nl *ze/haar* on the site against *hij/hem* in the app**: no app change. The review suggests
  keeping *hij*, which is what the app already uses, so any change falls on the site.
- **fr `wildAway`** and every other site finding: these are site strings and belong to the
  other job.

## Checks

- `dump(json.loads(raw)) == raw` on the untouched xcstrings. Keys are in code-point order, and
  the new keys were inserted where that order puts them. Localisations are sorted by language
  code. Both new keys have `comment` and `localizations` but no `extractionState`, matching the
  `Text(...)` keys around them.
- `python3 tools/strings/app_check.py`: exit 0.
- Format specifiers: every translated value in da, es, fr, it, nb, nl and sv has the same
  multiset as its English (2,415 values, 0 mismatches). A plural `one` is allowed to drop the
  count.
- `git diff --diff-algorithm=histogram --stat`: the xcstrings changes by 74 insertions and 27
  deletions.
