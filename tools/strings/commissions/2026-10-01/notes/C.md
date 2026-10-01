# Batch C — Spanish (es) and Italian (it), 1 October 2026

Job 1: the 8 site strings (`wildTitle`, `wildBody`, `wildEmpty`, `wildAway`,
`wildByOne`, `wildByTwo`, `wildPostcardText`, `privacy8`) added to
`Server/strings/es.json` and `it.json`. Job 2: 79 app strings per language in
`app/es.json` and `app/it.json` (the 2 `stale` keys skipped).

## Spanish (es)

**The Wild Fields: *los Campos Silvestres*** (heading *Los Campos Silvestres*).
Not chosen here: the app already ships it, in *Soltarla en los Campos
Silvestres* and *Se va de tu jardín a los Campos Silvestres*, so one name
across site and app meant keeping it. It is also right on its own terms:
*silvestre* is what grows without being sown or tended, the opposite of a
garden, and *campos* keeps it open ground and plural. Not *salvaje* (wild as
in fierce), not *prado* or *parque*.

**Release: *soltar*.** Already the app's word (*Soltarla*), and the verb for
letting a bird or an animal go free. The button `Release` is *Soltar*, an
infinitive like the app's other buttons (*Registrar*, *Enviar una de vuelta*).
The site uses *alguien la suelta*, *se ha soltado*, *una planta soltada*.

**No vosotros, as `LANGUAGES.md` requires.** Strings about the two gardeners
are turned round it: *la planta que nació del encuentro* (for *the plant you
grew together*), *las dos personas*, *cada uno*, and the chip *When you met*
as *La fecha del encuentro*, matching the shipped *Where you met* → *El lugar
del encuentro*.

Uncertain:

- **`Light`** is one key used twice: the appearance option (Dark / Light /
  Follow the phone) and the section heading over the sun-and-moon control.
  Written *Claro*, which is right for the option and odd as a heading over the
  day/night switch (*Luz* would be right there). The key wants splitting; the
  same is true in Italian (*Chiaro* / *Luce*).
- **`Gardener username`** → *Nombre de jardinero*: shorter than *nombre de
  usuario*, for a tracked-capitals label. A reviewer may prefer *Tu nombre de
  usuario*.
- **`the other gardener`** → *la otra persona*, gender-neutral and already the
  app's way of saying it (*Pídele…*, *La otra persona tiene que…*). It is a
  fallback for `%@`, so it can open a line in lower case, as in English.
- **`wildByTwo`** *Cultivada por {a} y {b}*: Spanish writes *e* before a name
  starting with an *i* sound (*Ana e Inés*). The string cannot know the name.
- **`Wireframe`** → *Malla* (the mesh), short enough for a menu; a 3D reader
  may expect *Alambre*.
- **`Display`** → *Pantalla*, as iOS names the section.
- **Five decimal places** is a quantity, so *5 decimales*; *three seconds* is
  *3 segundos*, matching the shipped *Mantén pulsado 3 segundos*.
- **`privacy8`**: *withdraw what you chose* is *revocar su elección*, so that
  *retirar* stays the take-back of the web garden, as in `privacy6`.

## Italian (it)

**The Wild Fields: *i Campi Selvatici*** (heading *I Campi Selvatici*). Also
already shipping, in *Lasciala andare nei Campi Selvatici*. *Selvatico* is
the botanist's word for what grows uncultivated (*fragole selvatiche*), where
*selvaggio* is untamed or savage; *campi* keeps it open and plural.

**Release: *lasciar andare*.** Already the app's (*Lasciala andare*), and the
phrase for setting a living thing free. The button `Release` is *Lascia
andare*, imperative like the app's other Italian buttons (*Registra*,
*Rimandane uno*, *Continua come Giardiniere*).

Uncertain:

- **`Light`**: the same collision as Spanish; written *Chiaro*.
- **`the other gardener`** → *l'altra persona*. **It breaks after a
  preposition**: *Chiedi a %@* and *In attesa di %@* read *a l'altra
  persona* and *di l'altra persona* where Italian needs *all'* and *dell'*.
  It only shows when the other phone sent no name at all (the name is usually
  a real name or *Giardiniere*), so it is left as written. The fix belongs in
  the code: fallback variants of those templates, not a better word.
- **`Gardener username`** → *Nome da giardiniere*; *Il tuo nome utente* is the
  alternative.
- **`Wireframe`** → *Fil di ferro*, the Italian term (*modello a fil di
  ferro*); some readers will expect the English word.
- **`Hidden`** / **`Marks only`**: *Nascosta* agrees with *la barra dei menu*.
- **`privacy8`**: *revocare la propria scelta* for *withdraw*, keeping
  *ritirare* for the take-back, as in `privacy6`.

Both languages: the gender of a plant (*planta*, *pianta*) is feminine
throughout, as in the shipped strings (*Plantada*, *Lasciala andare*).
