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

## de — German

45 keys: the 44 and `privacy10`. For review.

- **Terms.** *Bereich* for area, as `meaningsAbout` and `privacy6` have it;
  *Beet* for plot, as `privacy6` does (*Ganzes Beet zeigen*); *Samen … gezogen*
  for a seed drawn, as `privacy2`; *gerade nicht erreichbar* as `wildAway`.
  Area names take their article in a sentence (*Der Stille Garten ist gerade
  nicht erreichbar*), as `wildAway` does with *Wilde Felder*.
- **`{area}`** stands after *Bereich*, in the nominative: *Botschafterin des
  Bereichs {area}*, *wächst im Bereich {area}*.
- **Garden words.** *Doppelrabatte*, *gemähter Rasenweg*, *Gartenraum*,
  *freigemähte Baumscheibe*, *Pflanzengilde* (as *Gilde*), *Parterre* for the
  Knot Garden's plot (its area is *Barockgarten*), *Saatrillen* in
  *feinkrümeliger Erde*, *auf den Stock gesetzt* and *Stöcke*, *Parzelle* for
  the kitchen garden's plot. The quincunx is *wie die Fünf auf einem Würfel*.
- **The Cold Frame's frames** are *Glaskästen … mit hochgestellten
  Glasdeckeln*, not *Frühbeetkästen*, which are the forcing frame the area
  name avoids.
- **Controls.** Infinitives, as German software writes buttons: *Schließen*,
  *Vergrößern*, *Verkleinern*, *Im Uhrzeigersinn drehen*; the four moves are
  *Nach oben/unten/links/rechts*, short for the small keys.
- **`privacy10`**: *„Bewegung reduzieren“*, iOS's German name.
- **For a native reader:** *Botschafterin* (feminine, agreeing with *die
  Pflanze*) against the generic *Botschafter*; *oder dreh dich* for the turn,
  which may read as turning on the spot rather than going round the plot;
  *dessen, der liest* in `gardenBody`.

## es — Spanish

45 keys: the 44 and `privacy10`. For review.

- **Terms.** *Zona* for area, as `meaningsAbout` and `privacy6`; *parcela* for
  plot (no earlier string names one); *se saca* for a seed drawn, as
  `privacy2`'s *cuándo se sacó*; *tú* throughout, and the plural address
  avoided as `docs/LANGUAGES.md` asks.
- **Area names first in each `…Away`**, *El vergel está fuera de alcance ahora
  mismo*, because the catalogue's names carry a capitalised article and *a El
  vergel* cannot contract. `wildAway`'s *Ahora mismo no se puede llegar a…*
  could not take them.
- **`{area}`**: *Embajadora de {area}* and *que crece en {area}*, which give
  *de El vergel*, *en Las cepas*: uncontracted, as the RAE writes a name that
  carries its article (*de El Salvador*), but worth a native look.
- **Garden words.** *Doble arriate*, *camino de césped segado*, *recinto*,
  *glorieta enlosada*, *cuadros* and *cuarteles*, *al tresbolillo* for the
  quincunx, *gremio* for the guild, *parterre* for the Knot Garden's plot (its
  area is *El jardín de arrayanes*), *surcos* in a *bancal*, *cajoneras* for the
  frames, *mesas de cultivo* for the staging, *macizo*, *bosquete* and *cepas*
  (matching *Las cepas*), *huerto* of *bancales elevados*, and *espigas* and
  *umbelas*, as the app names those plant forms.
- **Controls.** Infinitives: *Cerrar* (the app's word), *Acercar*, *Alejar*,
  *Girar en sentido horario*, *Mover arriba*.
- **`privacy10`**: *«Reducir movimiento»*, iOS's Spanish name.
- **For a native reader:** *arriate*, *bancal* and *glorieta* are Peninsular;
  a Latin American reader may want *cantero*. *Embajadora* is feminine to agree
  with *planta*.

## ca — Catalan

45 keys: the 44 and `privacy10`. For review.

- **Terms.** *Zona* for area; *parterre* for plot, as `privacy6` has it (*el
  lloc buit del parterre*), so a round flower bed is a *massís* and the
  kitchen garden's plot a *parcel·la*; *es treu* for a seed drawn, as
  `privacy2`'s *quan es va treure*; *tu* throughout.
- **Area names first in each `…Away`**, *El verger és fora d'abast ara mateix*:
  normative Catalan contracts an article that is part of a name (*al Verger*),
  and the catalogue's names arrive with a capital article, so *a El verger*
  would be wrong.
- **`{area}`** stands after *la zona* for the same reason: *Ambaixadora de la
  zona {area}*, *que creix a la zona {area}*.
- **Garden words.** *Doble bordura*, *camí de gespa segada*, *tanca vegetal*
  for the hedge, *rotonda enllosada*, *quarters*, *a portell* for the quincunx,
  *gremi* for the guild, *dibuix* for the Knot Garden's plot (its area is *El
  trencadís*), *solcs* in a *bancal*, *caixes de cultiu … amb el vidre
  entreobert* for the frames, *taules de cultiu*, *bosquet* and *soques*
  (matching *Les soques*), *hort*, *espigues*, *umbel·les*.
- **Controls.** The imperative, as Catalan software writes buttons and as
  `frontTurn` already does: *Tanca*, *Mou amunt*, *Amplia*, *Redueix*, *Gira
  en sentit horari*. *Venen* without the accent, as the 2017 norm has it.
- **For a native reader:** *«Reduir el moviment»* is my best recollection of
  iOS's Catalan name for Reduce Motion and wants checking against a phone;
  *la zona El verger* (a name in apposition) against *la zona del Verger*;
  *tanca vegetal* against *bardissa* for a clipped hedge.

## cs — Czech

45 keys: the 44 and `privacy10`. For review.

- **Terms.** *Oblast* for area and *záhon* for plot, as `privacy6` has them;
  *ty* throughout; *teď není dostupná/ý/é* as `wildAway`, agreeing with each
  area's gender (*Sad teď není dostupný*, *Semeniště teď není dostupné*,
  *Výmladky teď nejsou dostupné*).
- **A seed drawn** is *Semínko vznikne jen jednou*: `privacy2` already avoids
  the lottery sense with *kdy se objevilo*, so this does too.
- **`{area}`** stands after *oblast*, in the nominative: *Velvyslankyně
  oblasti {area}*, *roste v oblasti {area}*.
- **Garden words.** *Dvojitý záhon*, *posečená travnatá cesta*, *živý plot*,
  *kruhová dlážděná plocha*, *čtvrtiny*, *jako pětka na hrací kostce* for the
  quincunx, *společenství* for the guild, *parter* for the Knot Garden's plot
  (its area is *Barokní zahrada*), *výsevní rýhy* in *jemně drobtovitá půda*,
  *bedny se sklem* for the frames (not *pařeniště*, which is the forcing
  frame), *pěstební stoly*, *lesík* and *pařezy*, *klasy*, *okolíky*, *růžice*,
  *parcela* for the kitchen garden's plot.
- **Controls.** Infinitives, as Czech software writes buttons: *Zavřít*,
  *Přiblížit*, *Oddálit*, *Posunout nahoru*. The turns are the full *Otočit
  proti směru / po směru hodinových ručiček*; long for a tooltip, and there is
  no shorter standard form that keeps *anticlockwise*.
- **`privacy10`**: *obchod App Store* where a case would otherwise decline the
  name; *„Omezit pohyb“* for Reduce Motion, which I believe is iOS's Czech and
  a reader with a Czech iPhone should confirm.
- **For a native reader:** *k dalšímu ohrazenému prostoru* for the Quiet
  Garden's enclosure is plain rather than a garden word; *Velvyslankyně*
  (feminine, with *rostlina*).

## el — Greek

45 keys: the 44 and `privacy10`. For review.

- **Terms.** *Περιοχή* for area and *παρτέρι* for plot, as `privacy6`;
  *τραβιέται* for a seed drawn, as `privacy2`'s *πότε τραβήχτηκε*; *δεν είναι
  προσβάσιμος/η/ο αυτή τη στιγμή* as `wildAway`, agreeing with each area's
  gender and number (*Οι παραφυάδες δεν είναι προσβάσιμες*); *εσύ*
  throughout. Greek keeps its written case on the site, so nothing here is
  uppercased.
- **`{area}`** arrives with its nominative article (*Ο οπωρώνας*), so it is
  quoted as Greek quotes a title: *της περιοχής «{area}»*, *στην περιοχή
  «{area}»*.
- **Garden words.** *Μπορντούρες*, *μονοπάτι από κουρεμένο γρασίδι*,
  *φυτοφράχτης*, *περίκλειστος κήπος*, *λιθόστρωτος κύκλος*, *τεταρτημόρια*,
  *σαν το πέντε στο ζάρι* for the quincunx, *συντεχνία* for the guild,
  *σχέδιο* for the Knot Garden's plot (its area is *Ο μαίανδρος*), *αυλάκια*,
  *κασόνια με τζάμι* for the frames, *πάγκοι* for the staging, *δασύλλιο* and
  *πρέμνα* for the stools, *στάχυα*, *σκιάδια*, *ροζέτες*. The kitchen
  garden's raised beds are *υπερυψωμένα παρτέρια*, so its plot is *ο επόμενος
  λαχανόκηπος* rather than another *παρτέρι*.
- **Controls.** Verbal nouns, as Greek software writes buttons: *Κλείσιμο*,
  *Μεγέθυνση*, *Σμίκρυνση*, *Μετακίνηση πάνω*, *Περιστροφή δεξιόστροφα*.
  `plantKey` and `plantCopyThis` are informal imperatives, being sentences.
- **`privacy10`**: *«Μείωση κίνησης»*, iOS's Greek name.
- **For a native reader:** *Πρεσβευτής* (masculine generic) for the plant;
  *Συνέχεια* for `goOn`; whether *πρέμνα* is too technical beside the
  catalogue's *παραφυάδες*.
