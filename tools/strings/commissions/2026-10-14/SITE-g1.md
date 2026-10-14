# The site's untranslated strings, group 1, 14 October 2026

Arabic, Belarusian, Bulgarian, Catalan, Czech, Welsh, Danish, German, Greek and
Spanish, on `claude/translate-site-g1-2026-10-14`. Marcus chose 19A on 14
October: translate now, Danish final for him to read, the rest marked here for
review. **Nobody who speaks any of the nine non-Danish languages has read
these yet.**

What was missing, verified against `strings.js` and each catalogue: the 44
keys in no language (the list in `design/mass-test-2026-10-13/site/README.md`,
*The catalogues*, which matched exactly), and `privacy10` in every language
here but Danish. Each catalogue now has all 146 keys; nothing is left in
English on purpose. New keys sit straight after the key before them in
`strings.js`'s order, so each file's existing order is unchanged.

**The same rules in every language:**

- The area names exactly as each catalogue's `area*` keys have them. Each
  `…Away` names its area, and `walkAway` names the Long Walk by its area name
  where the English says *The walk*, so the ten read alike. `walkTitle` is
  `areaTravel` word for word.
- `{area}` in `plantAmbassador` and `plantPostcardText` is filled with the
  area's name as the catalogue writes it, in the nominative and with its
  article where the language has one. In the languages that decline, the
  sentence is built so the name stands in the nominative (after a noun such
  as *area*, or before a colon), rather than leaving a nominative in a slot
  that wants another case.
- Move and key labels are each language's ordinary control wording (infinitive
  or imperative or verbal noun, as its own software writes buttons) and short.
- `plantClose` is the language's ordinary *Close* button word, since it is now
  read aloud as the ✕ button's name and in the `?` sheet. `gardenTitle` was
  checked as `/g`'s hidden heading in every language and reads right as one.
- `privacy10`: *App Store* and *Peace Garden* untranslated; Reduce Motion by
  iOS's own name for it in the languages iOS is written in (flagged where I am
  unsure, and where iOS has no such language at all).
- A plant is *it* in each language's own grammar (the catalogue's existing
  pronoun for *plant*); informal address as each catalogue already has it.

`check.py` does not yet count these 44 keys (it counts the commissioned
groups); a script checked every catalogue for all 146 keys, the placeholders,
exclamation marks, English area names and length. `check.py` is clean.

## da — Danish

Final, for Marcus: the full English | Danish table and the choices worth his
eye are in `DANISH-site.md`. 44 keys added. `privacy10` checked and unchanged.
