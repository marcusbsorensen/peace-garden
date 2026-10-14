# The app's translation round, 14 October 2026

This covers `App/PeaceGarden/Resources/Localizable.xcstrings` and `InfoPlist.xcstrings` in da,
es, fr, it, nb, nl and sv, and Greenlandic's place in the site's chooser. The work is on branch
`claude/translate-app-2026-10-14`, from `main` at `84194c8`. Marcus's decisions that day:
**19A**, one round for the site and the app together, with Danish final and the rest marked
for review. **20A**, Greenlandic hidden from the language list until a native reader finishes
it. **25B**, the VoiceOver grounds are *Landskab %lld* in Danish. The site's
`Server/strings/<lang>.json` were done by four other jobs, so they are not covered here.

Danish is final and is listed value by value for Marcus in `DANISH-app.md`. Every other new or
changed value is `needs_review`, waiting for a native reader.

## Brought up to the code

`tools/strings/sync.sh` was run on a fresh Debug simulator build of `84194c8`, using `xcodegen`
and then `xcodebuild -jobs 4` while holding the shared Xcode lock. The build produced 261
`.stringsdata` files.

**17 keys added**, all without translations or comments:

- The public website garden: `Show this plant in the public website garden.`, `%@ would like
  this plant to stand in the public website garden.`, `In the public website garden`, `The
  public website garden could not be reached`, `All right`, and `Nothing has changed. Plants of
  yours are still standing there…`.
- The garden's notice, with names: `%@ has asked to show a plant you grew together` and `%@ have
  asked to show plants you grew together`.
- An area that is not planted yet: `The garden is being planted an area at a time…`, `A plant
  stands in the area its own name belongs to…`, `It goes on growing here meanwhile, and you can
  ask %@ the day its area opens.`, and `This plant's area of the garden is still to be
  planted…`.
- The Wild Fields: `This plant is in the Wild Fields, so it cannot be shown anywhere else.`,
  `Sending it to the Wild Fields…`, and `The Wild Fields could not be reached just now, so this
  plant is still here…`.
- The two Settings consequences that say *Plants of yours standing in the public website garden
  come down first*.

**9 keys newly marked stale**: `%@ would like this plant to stand in the peace garden.`, `Show
this plant in the peace garden.`, `In the peace garden`, `Somebody has asked about a plant
here`, `Close`, `Hold for three seconds.`, `Let it go`, `Let this plant go?` and `This cannot be
undone. The plant cannot be grown again.` Each was searched for as a substring in every Swift
file under `App/` and `Packages/`. None appears except in a comment or a test name, so all nine
are unused. The 16 keys already stale were left as they were. `xcstringstool` removed two stale
keys that had no translations at all: the *Whatever you write goes to the other phone…* line
and the *two random numbers* version of the privacy paragraph.

Comments were written for the 17 new keys and for `One character left`, which had none. Each
comment says where the string appears, what %@ is, and which sibling key holds the other form.

## Translated

**23 keys** were missing at least one of the seven languages: the 17 above, the five
English-only sentences of 12 October (`The other gardener would like this plant to stand in the
public website garden.`, `It goes on growing here meanwhile, and you can ask the other gardener
the day its area opens.`, `The other gardener has asked to show a plant you grew together`, `The
other gardener has asked to show plants you grew together` and `%@ has asked to show plants you
grew together`), and `Newer version in the App Store`, which had only Danish.

| | da | es | fr | it | nb | nl | sv |
|---|---|---|---|---|---|---|---|
| New values | 22 | 23 | 23 | 23 | 23 | 23 | 23 |

That is 160 values. Danish values are `translated`; the other six languages are
`needs_review`. Every key the code uses now has all seven languages. After this round, all 376
Danish values that are not stale are `translated`.

## The agreed terms

**One term per language for *public website garden***. Each is built on the word the app and
the site already use for the web garden (*A plant you both share goes to the web garden…*, and
the site's `privacy5` to `privacy7`), with *public* added. That way *the web garden* and *the
public website garden* read as the same place in every language.

| | public website garden | web garden (settled) | area | Wild Fields |
|---|---|---|---|---|
| da | den offentlige have på nettet | haven på nettet | område | Vildmarken (*i*) |
| es | el jardín público de la web | el jardín de la web | zona | los Campos Silvestres |
| fr | le jardin public en ligne | le jardin en ligne | espace | les Champs Sauvages |
| it | il giardino pubblico sul web | il giardino sul web | area | i Campi Selvatici |
| nb | den offentlige hagen på nettet | hagen på nettet | område | Villmarka (*i*) |
| nl | de openbare tuin op het web | de tuin op het web | gebied | de Wilde Velden |
| sv | den offentliga trädgården på webben | trädgården på webben | område | Vildmarken (*på*) |

*Area* is the word each language's site uses in `meaningsAbout`. French *espace* follows the
site rather than *zone*. The fallback for the other gardener stays as each language already has
it: *den anden gartner*, *la otra persona*, *l'autre jardinier*, *l'altra persona*, *den andre
gartneren*, *de andere tuinier*, *den andra trädgårdsmästaren*. Spanish avoids *vosotros* as it
does everywhere. *A plant you grew together* is *una planta nacida de un encuentro contigo*,
which uses the same phrasing as the plural *Una nacida de un encuentro*.

## Changed in review

Every value that was `needs_review` in es, fr, it, nb, nl and sv was read again against its
English and its comment: 39 keys in use, 6 languages. A fortieth key, `Release to the Wild
Fields`, is stale and was left alone. That covers today's Settings, Share, time-lapse, About and
accessibility strings, and the older drafts. Twenty values changed. Each stays `needs_review`.

| Lang | Key | Was | Now | Why |
|---|---|---|---|---|
| es, fr, it, nb, nl, sv | `A plant you both share goes to the web garden without your username.` | the old *Your username will only show publicly if you approve* | es *Una planta que las dos personas comparten va al jardín de la web sin tu nombre de usuario.* · fr *Une plante que vous partagez tous les deux va dans le jardin en ligne sans ton nom d’utilisateur.* · it *Una pianta che condividete entrambi va nel giardino sul web senza il tuo nome utente.* · nb *En plante dere begge deler, havner i hagen på nettet uten brukernavnet ditt.* · nl *Een plant die jullie allebei delen, gaat zonder je gebruikersnaam naar de tuin op het web.* · sv *En växt som ni båda delar hamnar i trädgården på webben utan ditt användarnamn.* | **Wrong in all seven.** When the English was rewritten, the old translations were carried across to the new key. They still said that approving could publish the username, which is what the rewrite removed. |
| nb, sv | `Ground %lld` | Terreng / Terräng %lld | Landskap %lld | Marcus's 25B for Danish. The Norwegian and Swedish cognates carry the same sense of off-road or military terrain. Dutch *terrein*, French *terrain* and Spanish and Italian *terreno* mean a piece of land and stay. |
| sv | `%lld grown from meetings`, `one` and `other` | En vuxen ur ett möte / %lld vuxna ur möten | En framvuxen ur ett möte / %lld framvuxna ur möten | *En vuxen* reads first as *an adult*, and *12 vuxna* as *12 adults*. *Framvuxen* is already the Swedish catalogue's word (*framvuxen ur sitt frö*). `other` was `translated`, and it changed with `one`. |
| it | `%@ moved out of range before the plant took.` | non era più a portata | non era più raggiungibile | *A portata* without *di* is loose. *Raggiungibile* (reachable) is neutral for gender. |
| es | `About` | Acerca de | Información | The comment asks for one word where the language allows it, and *Información* is iOS's own word for About in Spanish. |
| fr | `Hold for 3 seconds.` | Maintiens pendant 3 secondes. | Maintiens appuyé pendant 3 secondes. | The verb had lost what is being held. |
| fr, it, nl | `It leaves your garden for the Wild Fields. The person you grew it with keeps theirs…` | fr *avec qui elle a poussé* · it *con cui è cresciuta* · nl *De plant van de persoon … blijft* | fr *avec qui tu l’as fait pousser … garde la sienne* · it *con cui l'hai fatta crescere … conserva la sua* · nl *Degene met wie je hem hebt laten groeien, houdt de zijne* | fr and it said *the person it grew with*, which drops *you*. nl had turned *keeps theirs* into *their plant stays*. |
| fr | `Release it` | Relâcher | La relâcher | The confirm button keeps the row's own words and its object, as *Release it* does. Every other language already had the object. |
| es | `Save as moving wallpaper` | Guardar como fondo animado | Guardar como fondo de pantalla animado | The comment asks for the same word for wallpaper as the row above (*fondo de pantalla*). |
| fr, it | `Saved to Photos. Open it there, tap %@, then Use as Wallpaper.` | …puis Utiliser en fond d’écran. / …poi Usa come sfondo. | …puis choisis Utiliser en fond d’écran. / …poi scegli Usa come sfondo. | The system action needed a verb in front of it. The other five languages already had one (*elige*, *velg*, *kies*, *välj*, *vælg*). |

Danish: two values changed, *A plant you both share…* and *Landskab %lld*, and six values that
stood `needs_review` were confirmed word for word. See `DANISH-app.md`.

**Read and left as they are**, still `needs_review`: `%@ moved out of range…` in fr; the `one`
of `%lld grown from meetings` in es, fr, it, nb and nl; `A place from abstract list`, `Abstract
list`, `Location description` and the two lines under it; `About` in fr, it, nb, nl and sv;
`Allow Peace Garden to add to Photos in Settings.`; the garden's figures and lights (`Fox`,
`Hare`, `Moth`, `Snail`, `Fireflies`, `Lantern`, `Paper lamp`); `Hold for 3 seconds.` outside
French; the no-name sentences for the other gardener (`Ask…`, `Waiting on…`, `…let it go into
the Wild Fields`, and the two *It grew from your seed and the other gardener's together*); `One
character left`, which agrees with each language's `%lld left`; `Play`, `Stop` and `Share
time-lapse`, where every language uses the iOS Camera mode's own name (French *accéléré*, the
rest *time-lapse*); `Privacy`, which matches each site's `privacyTitle`; `Release it` outside
French; `Release to the Wild Fields?`; `Reset view`, which matches each language's own *Reset
everything*; `Save as wallpaper`; `Share`, `Share picture` and `Share turning video`.

## For the native readers

Points this round noticed and did not change:

- **nb `Menneskene`**, in the two shipped Settings consequences (*Menneskene du dyrket fram de
  plantene sammen med…*, *Menneskene du har møtt…*). The two new longer forms keep the same
  wording so the pairs match. Danish moved to *folk* on Marcus's reading. A Norwegian reader may
  want *De du …* in all four.
- **it and nl, the joint-seed switch**: *Avvisami quando un seme condiviso viene pubblicato* and
  *Waarschuw me als een gedeeld zaadje gepubliceerd wordt* say *published* where the English
  says *shared*. The site's `privacy7` quotes the label word for word, so the two would change
  together. The note under the switch, retranslated today, says *share*.
- **Snail**: nb *Snegle*, sv *Snigel* and it *Lumaca* can each mean a slug as well as a snail.
- The term choices above, especially fr *jardin public en ligne* and it *giardino pubblico sul
  web*. Both read as a public garden that is on the web, which is the meaning wanted.

## InfoPlist.xcstrings

All four purpose strings already had all eight languages. Only
`NSPhotoLibraryAddUsageDescription` was `needs_review`, in es, fr, it, nb, nl and sv. It was read
again against its English. Each language uses its system names for Photos (*Fotos*, *Photos*,
*Foto*, *Bilder*, *Foto's*, *Bilder*) and for wallpaper. Nothing changed, and the file was not
written, so its own layout is untouched.

## Greenlandic: held back from the site's chooser (20A)

`kl` reached `Server/languages.json` through `tools/site/export.py`. The app has a Kalaallisut
bank, so the manifest marked it `bank: true`, and the chooser offers every language with a bank.
There is now an `UNFINISHED` table beside `NAMES` in `export.py`:

- **The manifest keeps the row**, with `"offered": false`. Every other row is `"offered": true`.
  `Server/passages/kl.json`, `Server/strings/kl.json` and the kl tester in `testers.json` all
  stay.
- **`Server/assets/js/languages.js`**: `readable()` leaves `kl` out of the chooser. In
  `negotiate()`, a remembered choice and the browser's own list are matched only against offered
  languages, and `?l=` is matched against every language. So `kl` negotiates exactly as `fo`,
  which the site does not have. A browser that asks for `kl` and then lists Danish reads Danish.
  A browser that asks for `kl` and lists nothing else reads English, and the page says under the
  passage that the passage is borrowed. A remembered `kl` falls through to the browser's list.
  Nothing maps `kl` to Danish: they are unrelated languages, and like Nynorsk to Bokmål it would
  be a decision nobody has taken. `?l=kl`, or standing in the kl tester at `/t`, still reaches
  Kalaallisut for labels and bank, which is how a reader finishes it. On such a page the chooser
  shows no selection, because `kl` is not one of its options.
- To offer it again, take `kl` off `UNFINISHED` and run `python3 tools/site/export.py`.
  `export.py` exits if `UNFINISHED` names a code the site does not have.
- Tested in Node against the regenerated manifest. The cases were: browser `kl` (gives `en`,
  borrowed), browser `kl-GL, da` (`da`), remembered `kl` with browser `fr` (`fr`), `?l=kl`
  (`kl` labels and `kl` bank), and browser `fo` (`en`, borrowed, the same as `kl`). The chooser
  has 42 languages and the manifest 43. It has not been looked at in a browser.
- Recorded in `docs/LANGUAGES.md`, under Greenlandic in *Round two*.

## Checks

- `python3 tools/strings/app_check.py`: exit 0. It found 32 plural `one` cases, and none prints a
  numeral.
- `python3 tools/strings/check.py`: exit 0, 42 catalogues clean. This only reads the site, and
  the site was not changed here.
- `python3 tools/site/export.py --check`: in step.
- Placeholders: all 2,793 values in the seven languages have the same specifiers as their
  English, with 0 mismatches. A plural `one` may drop its `%lld`. No Danish value contains
  *mennesk-*.
- Layout: the catalogue was written back by a writer that keeps key order as read and puts each
  new key where code-point order places it. Run on the untouched file, a round trip is
  byte-identical. The file ends with a newline, as on `main`; `xcstringstool` writes it without
  one, and that was put back after the sync. `InfoPlist.xcstrings` was not written.
