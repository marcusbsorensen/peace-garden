# Danish in the app, 14 October 2026: every new or changed value

For Marcus to read. Every value here is in `App/PeaceGarden/Resources/Localizable.xcstrings`
as `translated`, so it ships as it stands. Branch `claude/translate-app-2026-10-14`. The
other six languages are in `APP.md`.

Three choices run through the tables:

- **The public website garden is *den offentlige have på nettet***. The app and the site
  already call the web garden *haven på nettet*. *Offentlige* carries the English *public*,
  and keeps it apart from *fredshaven*, which in the app is the garden on this phone.
- **Area is *område***, the site's word in `meaningsAbout`. A garden area being planted is
  *tilplantet*.
- **Folk, not mennesker**, throughout. The new sentences say *De folk, du …*, as the shorter
  versions beside them already did.

## New (22)

| English | Dansk |
|---|---|
| %@ has asked to show a plant you grew together | %@ har bedt om at vise en plante, I groede frem sammen |
| %@ has asked to show plants you grew together | %@ har bedt om at vise planter, I groede frem sammen |
| %@ have asked to show plants you grew together | %@ har bedt om at vise planter, I groede frem sammen |
| The other gardener has asked to show a plant you grew together | Den anden gartner har bedt om at vise en plante, I groede frem sammen |
| The other gardener has asked to show plants you grew together | Den anden gartner har bedt om at vise planter, I groede frem sammen |
| %@ would like this plant to stand in the public website garden. | %@ vil gerne have, at denne plante står i den offentlige have på nettet. |
| The other gardener would like this plant to stand in the public website garden. | Den anden gartner vil gerne have, at denne plante står i den offentlige have på nettet. |
| Show this plant in the public website garden. | Vis denne plante i den offentlige have på nettet. |
| In the public website garden | I den offentlige have på nettet |
| The public website garden could not be reached | Den offentlige have på nettet kunne ikke nås |
| Nothing has changed. Plants of yours are still standing there, and this is the only phone that can take them down, so try again when you have a signal. | Intet er ændret. Nogle af dine planter står der stadig, og kun denne telefon kan tage dem ned, så prøv igen, når du har forbindelse. |
| All right | I orden |
| Your own seed and its plant stay. Plants of yours standing in the public website garden come down first. The people you grew those plants with keep theirs. | Dit eget frø og dets plante bliver. Dine planter, der står i den offentlige have på nettet, tages ned først. De folk, du groede de planter sammen med, beholder deres. |
| Your seed, your plant and your garden all go. Plants of yours standing in the public website garden come down first. The people you have met keep the plants you grew together. | Dit frø, din plante og din have forsvinder alle sammen. Dine planter, der står i den offentlige have på nettet, tages ned først. De folk, du har mødt, beholder de planter, I groede frem sammen. |
| It goes on growing here meanwhile, and you can ask %@ the day its area opens. | Den gror videre her i mellemtiden, og du kan spørge %@, den dag dens område åbner. |
| It goes on growing here meanwhile, and you can ask the other gardener the day its area opens. | Den gror videre her i mellemtiden, og du kan spørge den anden gartner, den dag dens område åbner. |
| A plant stands in the area its own name belongs to, and the areas are being planted one at a time. | En plante står i det område, dens eget navn hører til, og områderne bliver tilplantet ét ad gangen. |
| The garden is being planted an area at a time, and this plant's area comes later. | Haven bliver tilplantet ét område ad gangen, og denne plantes område kommer senere. |
| This plant's area of the garden is still to be planted. It can stand there once that area opens. | Denne plantes område i haven er endnu ikke tilplantet. Den kan stå der, når området åbner. |
| This plant is in the Wild Fields, so it cannot be shown anywhere else. | Denne plante er i Vildmarken, så den kan ikke vises andre steder. |
| Sending it to the Wild Fields… | Sender den ud i Vildmarken… |
| The Wild Fields could not be reached just now, so this plant is still here. Try again in a little while. | Vildmarken kunne ikke nås lige nu, så denne plante er her stadig. Prøv igen om lidt. |

*%@ has asked … plants* and *%@ have asked …* read the same in Danish, because a Danish verb
does not follow the number of people. That is right: the code picks between them, and each
gets the sentence its language needs. In the *have asked* sentence, %@ is several names
joined by the phone's own Danish list format, for example *Cai og Ines*.

*Nogle af dine planter* (some of your plants) translates *Plants of yours*, which has no
direct Danish equivalent. *Dine planter* alone would mean all of them.

## Changed (2)

| English | Was | Now |
|---|---|---|
| A plant you both share goes to the web garden without your username. | Dit brugernavn vises kun offentligt, hvis du godkender det. | En plante, I begge deler, kommer i haven på nettet uden dit brugernavn. |
| Ground %lld | Terræn %lld | Landskab %lld |

The first was a real fault, in all seven languages. When the English under the joint-seed
switch was rewritten, the old translations were carried across to the new key and marked for
review. So they still said that approving could publish your username, which is the claim
the rewrite was made to remove.
The second is your 25B. Norwegian and Swedish *Terreng* and *Terräng* carry the same sense,
so they became *Landskap %lld*, marked for their readers.

## Read again and kept word for word, now final (6)

These stood as `needs_review` in Danish. Each was checked against its English and its
comment and is unchanged. Only the state moved to `translated`.

| English | Dansk |
|---|---|
| One grown from a meeting (the `one` of *%lld grown from meetings*) | Én groet frem af et møde |
| Hold for 3 seconds. | Hold nede i 3 sekunder. |
| It leaves your garden for the Wild Fields. The person you grew it with keeps theirs, and every other plant here stays where it is. | Den forlader din have og tager ud i Vildmarken. Den, du groede den sammen med, beholder sin, og alle andre planter bliver her, hvor de er. |
| One character left | Ét tegn tilbage |
| Release it | Løssæt den |
| Release to the Wild Fields? | Løssætte den i Vildmarken? |

`Release to the Wild Fields` (without the question mark) is still `needs_review`. The code no
longer uses it and it is marked stale, so it was left alone.

`InfoPlist.xcstrings` has no new or changed Danish. Its four Danish values were already final.
