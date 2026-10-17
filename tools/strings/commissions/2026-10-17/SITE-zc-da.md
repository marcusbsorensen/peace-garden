# Zone C W2: privacy7 and privacy11 in Danish, 17 October 2026

Two keys in `Server/strings/da.json`, on `claude/translate-zonec-site-da`:
`privacy7` (the older translation replaced) and `privacy11` (new, straight
after `privacy7`). The English is Marcus's, approved 17 October 2026, and is
unchanged; its wording and context are in
`design/space-seeds-2026-10-16/WORDING-en.md`, sections 1 and 2. Nothing else
in `da.json` was touched.

**Nobody who speaks Danish has read this yet.** Marcus reads it before it ships.

## privacy7

> With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.

> Med nyt fra haven slået til spørger appen haven på nettet om jeres delte planter, hver gang den starter, ved at sende de tilfældige tal fra jeres møder. Den spørger, uanset om du har mødt nogen eller ej. Hver forespørgsel sender også én tilfældigt udseende værdi og ét tilfældigt udseende svar op, og haven svarer med nogle få af hver.

## privacy11

> The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The garden's nightly backup leaves the pools out. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.

> Haven på nettet gemmer de tilfældigt udseende værdier, den modtager, i to puljer: én med værdier på 64 byte og én med værdier på 104 byte. Hver værdi gemmes for sig, uden tid, adresse eller rækkefølge. En værdi bliver, indtil nyere værdier skubber den ud. Havens natlige sikkerhedskopi tager ikke puljerne med. Et svar åbner sig kun på den telefon, der sendte sit frø. Frø fra Autonaut rejser også på denne måde. For haven på nettet er enhver værdi tilfældige tal.

## Terms

- *web garden* = *haven på nettet*, *garden* = *haven*, *seed* = *frø*,
  *plant* = *plante*, *random numbers* = *tilfældige tal*, *meetings* =
  *møder* (all as `privacy2`, `privacy6`, `privacy7` already had them);
  *backup* = *sikkerhedskopi* (as `privacy3`, `privacy6`).
- *reply* = *svar* (the reply to a seed); *request* = *forespørgsel* (as
  `privacy10`). *Autonaut* and *Peace Garden* untranslated.
- Informal *du*; no *mennesker*; no exclamation marks.
- Numerals: *64 byte*, *104 byte*. *One* stays a word (*én*, *ét*). No other
  quantity is stated; *a handful* is *nogle få*, not a number.
- The switch: the app has no Danish label for *News from the garden* yet; its
  only Danish is the old row, »Sig til, når et fælles frø deles«
  (`Localizable.xcstrings`), which is the label being replaced. So the
  setting is rendered plainly, as *nyt fra haven*, lower case, as the English
  has it. If the app's Danish label comes out differently, `privacy7` should
  match it.

## For Marcus to decide

1. **Switch name.** *Med nyt fra haven slået til.* Alternative: with quotes as
   the old string had them, *Med »Nyt fra haven« slået til*, once the app's
   Danish label is fixed.
2. **"Random-looking."** *Tilfældigt udseende værdi.* Alternatives:
   *en værdi, der ligner tilfældige tal*; *tilfældig-udseende*.
3. **Reply.** *Svar* is used both for the reply to a seed and, in
   `privacy7`, avoided for "the answer": I wrote *haven svarer med nogle få af
   hver* instead of repeating *svaret*, so the two cannot be mistaken.
   Alternative: *og svaret bringer nogle få af hver tilbage*.
4. **"A handful."** *Nogle få.* Alternative: *en håndfuld* (closer to the
   English, but sounds like a measure).
5. **Pools.** *Puljer.* Alternatives: *samlinger*, *bassiner* (water, so no).
6. **"Leaves out."** *Tager ikke puljerne med.* Alternative: *udelader
   puljerne*.
7. **"Stays until pushed out."** *En værdi bliver, indtil nyere værdier
   skubber den ud.* Alternative: *En værdi forbliver, til nyere værdier
   presser den ud.*
8. **"Is random numbers."** *Er enhver værdi tilfældige tal.* Alternative:
   *er alle værdier blot tilfældige tal* (*blot* is an addition the English
   does not have).
9. **Byte.** *64 byte* (no plural ending). Alternative: *64 bytes*.
