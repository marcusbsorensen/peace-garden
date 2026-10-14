# The site's new strings in Danish, 14 October 2026

For Marcus to read. The 44 keys that were in no language, written into
`Server/strings/da.json` on `claude/translate-site-g1-2026-10-14`; `privacy10`
was already there and was checked rather than rewritten (below). Danish is
final for you to read; the other nine languages in this group are marked for
review in `SITE-g1.md`.

Terms are the catalogue's own: *frø*, *have*, *haven på nettet*, *plante* as
*den*, the ten area names exactly as `area*` has them, *kan ikke nås lige nu*
as `wildAway` says it, *Der er ikke … her endnu* as `wildEmpty` does. People
appear nowhere in these keys, so *folk*/*personer* does not arise.

## Choices worth your eye

1. **Plot is *bed***, as `privacy6` already has it (*dens tomme plads i
   bedet*): `moveHome` *Vis hele bedet*, `walkAbout` *se bedene*. In the
   kitchen garden, where a plot holds three raised beds, the paging clause says
   *den næste køkkenhave* instead, so *bed* does not mean two things in one
   sentence.
2. **`walkAway` names the area**, *Den Lange Allé kan ikke nås lige nu*, where
   the English says *The walk*. The other nine say their area's name, and this
   is the same place.
3. **Each area's paging noun is a Danish garden word, not the English one**:
   *haverum* (the Quiet Garden's enclosure), *krydsning* (matching
   *Krydsningen*), *frugthave*, *parterre* (the Knot Garden is *Barokhaven*, so
   its plot is a parterre rather than a knot), *bed*, *de næste fire*,
   *drivhus*, *længere ind i skoven*, *køkkenhave*.
4. **The quincunx is *som femmeren på en terning***, which names the pattern
   exactly and plainly; *kvinkunks* exists, and few would know it.
5. **The Cold Frame's frames are *glaskasser … med lågene sat på klem***.
   *Bænk* would bring back the forcing frame the area name was chosen to avoid.
6. **Border is *rabat***: *to rabatter, én på hver side af en slået græssti*.
7. **`plantAmbassador` takes the name with *-s***: *Dvalebedets ambassadør*.
   None of the ten Danish names ends in *s*, so the genitive is always right.

## `privacy10`, checked

In the catalogue since 12 October. It carries all five claims in order: the
name and version for a moment and the question to the App Store *i dit eget
land*; *kun landet og appens id*, received *fra din internetadresse, som ved
enhver forespørgsel*; the small arrow and the App Store opening; the question
skipped when the phone cannot say its country; and *Reducer bevægelse*, which
is iOS's own Danish name for the setting. It breaks none of the six *must
not*s. No change made.

## Two keys that changed job in the site fixes

- `plantClose` *Luk* is now read aloud as the ✕ button's name and in the `?`
  sheet, not shown. *Luk* is the app's own word for Close, and reads right
  spoken.
- `gardenTitle` *Haven* also names `/g`'s hidden heading. It reads right
  there too.

## English | Danish

| Key | English | Danish |
| --- | --- | --- |
| `gardenBody` | Ten areas, each one a theme, laid out as a map you can walk. Every plant standing in the garden was grown from a meeting, and the words under it come from the reader's own language rather than a translation of somebody else's. | Ti områder, hvert med sit tema, lagt ud som et kort, du kan gå rundt i. Hver plante, der står i haven, er groet af et møde, og ordene under den kommer fra læserens eget sprog i stedet for at være oversat fra en andens. |
| `downloadBody` | Peace Garden is for iPhone and iPad. A seed is drawn once, on one device, and the plant that grows from it is nobody else's. | Peace Garden er til iPhone og iPad. Et frø trækkes én gang, på én enhed, og planten, der gror af det, er ingen andens. |
| `walkTitle` | The Long Walk | Den Lange Allé |
| `walkThisArea` | Walk this area | Gå rundt i dette område |
| `walkBody` | The one area of the garden with real plants in it: a double border either side of a mown path, tall at the back and graded to the front. Every plant standing in it grew from a meeting, and it goes on as long as the meetings do. | Det eneste område i haven med rigtige planter: to rabatter, én på hver side af en slået græssti, høje bagest og gradvis lavere mod forkanten. Hver plante, der står i det, er groet af et møde, og det fortsætter, så længe møderne gør. |
| `walkAbout` | A double border either side of a mown path, tall at the back and graded to the front. Go on down the walk, or turn to see the plots from another side. | To rabatter, én på hver side af en slået græssti, høje bagest og gradvis lavere mod forkanten. Gå videre ned ad alléen, eller drej for at se bedene fra en anden side. |
| `walkGrowing` | Growing the plants… | Planterne gror frem… |
| `walkEmpty` | Nothing has been planted here yet. | Der er ikke plantet noget her endnu. |
| `walkAway` | The walk cannot be reached just now. | Den Lange Allé kan ikke nås lige nu. |
| `walkTurnAnti` | Turn anticlockwise | Drej mod uret |
| `walkTurnClock` | Turn clockwise | Drej med uret |
| `moveUp` | Move up | Flyt op |
| `moveDown` | Move down | Flyt ned |
| `moveLeft` | Move left | Flyt til venstre |
| `moveRight` | Move right | Flyt til højre |
| `zoomIn` | Zoom in | Zoom ind |
| `zoomOut` | Zoom out | Zoom ud |
| `moveHome` | Show the whole plot | Vis hele bedet |
| `plantKey` | Read about the plant in the middle | Læs om planten i midten |
| `plantAmbassador` | {area}'s ambassador: the first plant to stand here | {area}s ambassadør: den første plante, der kom til at stå her |
| `plantPostcard` | Send as a postcard | Send som postkort |
| `plantPostcardText` | {name}, growing in {area}, in Peace Garden. | {name}, der gror i {area} i Peace Garden. |
| `plantCopied` | The link to this plant is copied, ready to send. | Linket til denne plante er kopieret og klar til at blive sendt. |
| `plantCopyThis` | Copy this link to send it: | Kopiér dette link for at sende det: |
| `plantClose` | Close | Luk |
| `quietAbout` | A hedge round a lawn, a bench in one corner, and the fewest plants of any area, because room is what it is for. Go on to the next enclosure, or turn to see this one from another side. | En hæk omkring en græsplæne, en bænk i det ene hjørne og færrest planter af alle områderne, for det er pladsen, haven er til for. Gå videre til det næste haverum, eller drej for at se dette fra en anden side. |
| `quietAway` | The Quiet Garden cannot be reached just now. | Den Stille Have kan ikke nås lige nu. |
| `crossAbout` | Two mown paths crossing at a round of paving, with planting in each of the four quarters, low along the paths and tall at the far corners. Go on to the next crossing, or turn to see this one from another side. | To slåede græsstier, der krydser hinanden ved en rund, flisebelagt plads, med beplantning i hvert af de fire kvarterer, lav langs stierne og høj ude i de fjerneste hjørner. Gå videre til den næste krydsning, eller drej for at se denne fra en anden side. |
| `crossAway` | The Crossing cannot be reached just now. | Krydsningen kan ikke nås lige nu. |
| `orchardAbout` | Five trees standing in a quincunx, each with a guild of four plants under it and the meadow grass cut back to a disc round its trunk. Go on to the next orchard, or turn to see this one from another side. | Fem træer, der står som femmeren på en terning, hvert med et fællesskab af fire planter under sig og enggræsset slået kort i en cirkel om stammen. Gå videre til den næste frugthave, eller drej for at se denne fra en anden side. |
| `orchardAway` | The Orchard cannot be reached just now. | Frugthaven kan ikke nås lige nu. |
| `knotAbout` | Two bands of low clipped hedging woven over and under each other, with a block of one colour in each of the eight compartments they make. Go on to the next knot, or turn to see this one from another side. | To bånd af lave, klippede hække, der fletter sig over og under hinanden, med en blok i én farve i hvert af de otte felter, de danner. Gå videre til det næste parterre, eller drej for at se dette fra en anden side. |
| `knotAway` | The Knot Garden cannot be reached just now. | Barokhaven kan ikke nås lige nu. |
| `seedbedAbout` | Six drills across a bed of fine tilth, each one sown with a single kind of plant and filling from the label at its head. Go on to the next bed, or turn to see this one from another side. | Seks såriller på tværs af et bed med fintkrummet jord. Hver er sået med én slags plante og fyldes op fra skiltet for enden. Gå videre til det næste bed, eller drej for at se dette fra en anden side. |
| `seedbedAway` | The Seedbed cannot be reached just now. | Såbedet kan ikke nås lige nu. |
| `frameAbout` | Four low frames on gravel with their glass propped open, each holding young plants of one colour, the ones that will grow tallest at the back. Go on to the next four, or turn to see these from another side. | Fire lave glaskasser på grus med lågene sat på klem, hver med unge planter i én farve og dem, der bliver højest, bagest. Gå videre til de næste fire, eller drej for at se disse fra en anden side. |
| `frameAway` | The Cold Frame cannot be reached just now. | Dvalebedet kan ikke nås lige nu. |
| `glasshouseAbout` | A round glasshouse, its pots set out round the staging as a wheel of colour from blue-green just past the door to yellow just before it, and the tallest plants in a round bed in the middle. Go on to the next house, or turn to see this one from another side. | Et rundt drivhus med potterne sat rundt på plantebordene som et farvehjul, fra blågrøn lige efter døren til gul lige før den, og de højeste planter i et rundt bed i midten. Gå videre til det næste drivhus, eller drej for at se dette fra en anden side. |
| `glasshouseAway` | The Glasshouse cannot be reached just now. | Drivhuset kan ikke nås lige nu. |
| `coppiceAbout` | A wood cut in three bands, one each winter in turn, with ferns coming back from the old stools and flowers standing in the light between them, never cut. Go on further into the wood, or turn to see this part of it from another side. | En skov, der skæres ned i tre bælter, ét hver vinter på skift, med bregner, der kommer igen fra de gamle stubbe, og blomster, der står i lyset mellem dem og aldrig skæres. Gå længere ind i skoven, eller drej for at se denne del af den fra en anden side. |
| `coppiceAway` | The Coppice cannot be reached just now. | Stubhaven kan ikke nås lige nu. |
| `groundAbout` | A kitchen garden of three raised beds, each sown in rows with one crop: tall spikes, flat heads or low rosettes, the taller plants at the north end, where they shade nothing but the path. Go on to the next plot, or turn to see this one from another side. | En køkkenhave med tre højbede, hvert sået i rækker med én afgrøde: høje aks, flade skærme eller lave rosetter, med de højeste planter i den nordlige ende, hvor de kun skygger for stien. Gå videre til den næste køkkenhave, eller drej for at se denne fra en anden side. |
| `groundAway` | The Home Ground cannot be reached just now. | Hjemstavnen kan ikke nås lige nu. |
| `goOn` | Go on | Gå videre |
