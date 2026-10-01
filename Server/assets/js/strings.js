// The site's own words.
//
// **The target is the low tens and it is a target to defend.** Every string
// here is a commission in forty-two other languages, so a paragraph added
// casually is forty-three paragraphs. Most of a page needs no word at all — the plant, its
// binomial, the marks, the date and the age all say themselves — and the list
// below is what is left after that. See docs/WEBSITE.md §"Most of a plant page
// is already in every language".
//
// **The ten area names at the foot of this file were added against that target
// on purpose, and they are the only thing here that is not prose.** Marcus
// reversed the English-only rule on 5 September 2026, which cost four hundred
// and twenty commissions in one decision. It buys the map: an area is a place
// somebody stands in, and a reader walking a garden in Greek should not find
// the ten places in it labelled in English. They are commissioned separately,
// by `tools/strings/NAMING.md`, because naming a place is a different job from
// translating a paragraph — and the defence above still holds against the
// nineteen. A twentieth paragraph is still forty-three paragraphs.
//
// English is written here rather than fetched, because it is the fallback and
// a fallback that can fail to arrive is not one. The other forty-two live in
// `/strings/<code>.json`, one file per language, fetched only for the reader
// who needs it — the same shape as a passage bank.
//
// **A missing label falls back to English in silence.** Only a missing *bank*
// is announced, under the passage, because that is the one moment the site
// speaks at length. docs/WEBSITE.md §"When the site is behind the app" draws
// that distinction and this module keeps it: nothing here ever says which
// language a label came from.

/// The English catalogue, and the shape every other language fills.
///
/// `{name}` is the only interpolation. Keeping it to one placeholder in one
/// string is what lets a translator work without being told a syntax.
export const EN = Object.freeze({
  // The page with no seed in it: what this is.
  tagline: "A plant grown from a meeting.",
  // Marcus's wording, 4 September. The similes are the point: *a plant that is
  // the two of them together* was the abstract version, and a handshake is a
  // thing a reader has already done.
  //
  // **"Combines their features" is a fair account of the cross rather than an
  // exact one.** A trait comes from one parent, the other, a blend of the two,
  // or — about six times in a hundred — a mutation belonging to neither. The
  // reference implementation prints the mix. Saying so here would be true and
  // would cost the sentence its shape; the exact rule is in `Pollination`.
  //
  // The fourth sentence is restored from the paragraph this replaced: it was
  // the only place the site said a plant takes weeks rather than appearing
  // finished, which is most of what there is to come back for.
  about1:
    "Peace Garden makes a plant out of two people meeting. Two phones hand each other a seed. What grows from the two seeds is a plant that combines their features, like a handshake or a joint garden that has some of each person. It opens over real days, in its own time.",
  about2:
    "A seed travels in a link as well as by touch, so it reaches a phone that has never heard of any of this.",
  // **This block is what somebody sees when there is no seed.** `page.js` sets
  // `about.hidden = Boolean(state.link)`, so the about section and the seed
  // section are mutually exclusive: the reader here typed the address, or
  // followed a link that lost its seed on the way. They have no seed in front
  // of them, and the question they arrived with is how one would ever reach
  // them.
  //
  // It used to explain that a seed rides after the `#` and stays in the
  // browser — a mechanism, addressed to a reader whose seed is the one thing
  // that is not there, and jargon to a gardener besides. The privacy argument
  // it was making is true and lives in `WEBSITE.md`; the reader it protects is on
  // the seed path and never sees this block.
  about3:
    "A seed reaches you from someone you meet in person. Peace Garden is on iPhone and iPad.",

  // The page with a seed in it.
  seedTitle: "A seed has arrived",
  replyTitle: "A seed has come back",
  sentBy: "Sent by {name}",
  gardener: "a gardener",
  planted: "Planted",
  growTitle: "Growing it",
  // **A meeting grows one plant, and this sentence has to say so.** It used to
  // say the same two seeds always make the same plant, which is the one
  // property the design deliberately does not have: `Pollination.encounterID`
  // hashes both seeds *and* both nonces, each side drawing its own, so meeting
  // the same person again grows a different plant and neither of them can
  // steer which. A fresh nonce per offer also means this very link, opened
  // twice, grows two plants — so nothing here may imply that a link reproduces
  // anything.
  //
  // What is true is what the reply code exists to deliver: one meeting, one
  // plant, held by both of them, and a pure function of its own seed and
  // birthday from then on. The thing the two seeds alone do derive is
  // `pairID`, which chooses the passage shown when they cross, not the plant.
  growBody:
    "Peace Garden crosses this seed with one of your own, and the plant that comes of the pair is yours to keep. This meeting grows one plant, you both have it, and it stays the same for as long as you do.",
  // Launched tense, 4 September, and it names both platforms the app ships
  // for. It used to say the app was *being made for iPhone*, which was a
  // future tense `about3` no longer agrees with and a platform list the
  // `Info.plist` no longer agrees with either.
  //
  // The second sentence stays because it is the useful half: a link carries
  // its seed and nothing expires, so somebody who reads this on a bus has
  // lost nothing by not acting on it.
  appNote: "Peace Garden is on iPhone and iPad. This link keeps, so there is no hurry.",

  // Under the passage, when the reader's language has no bank of its own.
  inEnglish: "in English",

  // The chooser.
  language: "Language",

  // The heading on the sheet under `?`, and the only word the keyboard layer
  // costs: every row in that sheet is labelled by the control it operates, in
  // words already on the screen. See assets/js/keys.js.
  keys: "Keys",

  // The garden's one control that is not labelled by something already on the
  // page. The four directions take their names from the pad, and `g` takes its
  // name from the wordmark, which is a proper noun.
  random: "Somewhere at random",

  // What a link that arrived broken says. The wording is the app's own, from
  // `PollenLink.LinkError`, so the two say the same thing to the same person.
  damaged: "This link arrived damaged, so the seed could not be read.",
  notASeed: "That link does not carry a seed.",
  newerVersion: "This seed came from a newer version of Peace Garden.",

  // The privacy page, at `/privacy`. **A mandatory App Store listing field.**
  //
  // Eight keys against a `strings.js` that opens by defending the low tens —
  // paid deliberately, Marcus's call on 6 September, on the grounds that a page
  // about what leaves your phone, in English only, to a reader who was handed a
  // link by a friend and is wondering whether it is a scam, is the one page
  // where falling back to English costs the most. Six until 24 September, when
  // the web garden gave the page something to say about a server and two
  // paragraphs were added to say it; the keys are next to `privacyTitle`.
  //
  // Every sentence says what the app *does*, per the register in
  // tools/strings/BRIEF.md: *it stays on this phone* rather than *it never
  // leaves*. A negative reads as a warning even when it was meant as a
  // reassurance, and this reader is already slightly on guard.
  // The front, at `/`, and the two pages it opens onto.
  //
  // **Eight keys, and the count was the whole design.** This file opens by
  // defending the low tens, and a front page is the easiest place in a project
  // to spend forty of them. So the front says what this is using `tagline` and
  // `about1`–`about3`, which were written for the seedless `/s` and are already
  // commissioned in forty-one languages — a reader arriving at the domain and a
  // reader arriving at a spent link are asking the same question, and it was
  // already answered. What is left is a heading and a sentence for each of the
  // three places the front page can send somebody.
  //
  // The ten areas are not listed here either. `AREA_KEYS` already names them in
  // every language the map has, so the front page reads them from there.
  //
  // **That front was replaced on 24 September 2026** by the one the `front*`
  // keys below are for. `gardenBody`, `walkBody` and `goOn` were said only on
  // it and are said nowhere now; they are kept, commissioned, until Marcus
  // decides whether they go.
  // Also the bar's way back to the hub, on every page of the site. It is the
  // hub's own name, so naming the link a second time would be one word saying
  // what another word already says.
  gardenTitle: "The garden",
  gardenBody:
    "Ten areas, each one a theme, laid out as a map you can walk. Every plant standing in the garden was grown from a meeting, and the words under it come from the reader's own language rather than a translation of somebody else's.",
  downloadTitle: "The app",
  downloadBody:
    "Peace Garden is for iPhone and iPad. A seed is drawn once, on one device, and the plant that grows from it is nobody else's.",
  // **The Wild Fields, built on 1 October 2026.** The paragraph used to
  // describe a seed set down to wait for another, which is The Winds
  // (docs/PHASES.md) and the opposite of release; it said what the place
  // would be before anything stood in it. It says now what is there: where a
  // released plant goes, that nobody arranges it, what it carries and does
  // not, and how it is walked. *Only what the two who grew it chose to show*
  // is Marcus's decision of the same day: each gardener may show their name,
  // and where and when they met once both choose them (`WildStore.php`,
  // `wild_names`); nothing is shown unless chosen.
  wildTitle: "The Wild Fields",
  wildBody:
    "Where a plant goes when it is let go. Nobody arranges the Wild Fields: each plant stands where its own seed puts it, and the field runs on in every direction. Beside a plant stands only what the two who grew it chose to show. Drag to walk it.",
  // Said under the field before anybody has released a plant, so a reader
  // knows the grass is not hiding something.
  wildEmpty: "Nothing has been released here yet.",
  // The field could not be drawn at all, as `walkAway` is for the walk.
  wildAway: "The Wild Fields cannot be reached just now.",
  // In a released plant's panel, under its name, when its gardeners chose to
  // show their names (`wildpage.js`). One name or two, never a hint of a
  // second person who chose not to be named: a plant shown with one name is
  // shown as one person's. In alphabetical order, so neither says who let it
  // go. Where and when they met follow on a line of their own, in their own
  // words and the reader's month, and need no string.
  wildByOne: "Grown by {name}",
  wildByTwo: "Grown by {a} and {b}",
  // A postcard from the field, as `plantPostcardText` is from an area.
  wildPostcardText: "{name}, growing in the Wild Fields, in Peace Garden.",
  walkTitle: "The Long Walk",
  // The way out of the garden's travel area and into the walk itself. It is
  // the same place: `/g` draws it as dots from the stand-in, `/walk` grows
  // every plant in it from what the plot service holds. A visitor who has
  // walked to this one area of ten should be told the real one is there, and
  // the other nine have nothing to offer such a link.
  // Named by the area's heading beside it, so the same two words carry a
  // reader to whichever of the built areas they are standing in.
  walkThisArea: "Walk this area",
  // On the front page, beside the other three. Shorter than `walkAbout`, which
  // is the walk's own page saying how to move around it — how to walk is not
  // an invitation to.
  //
  // **It says which area it is.** The Long Walk is one of the garden's ten and
  // not a second garden, and the front page lists it in both places — among
  // the ten area names under *The garden*, and here with a way in. Saying so
  // is what keeps that from reading as two places with one name.
  walkBody:
    "The one area of the garden with real plants in it: a double border either side of a mown path, tall at the back and graded to the front. Every plant standing in it grew from a meeting, and it goes on as long as the meetings do.",
  // **Two sentences, and the second one is the same on all five area pages.**
  // Each of these used to open by saying *one of the garden's ten areas*, which
  // the bar at the top of the page now says by standing the area's name beside
  // a link to the garden — and then ran to four or five lines, which is a
  // paragraph to read before you are allowed to look at the thing it describes.
  // What is left is what the place is, and what the keys do.
  walkAbout:
    "A double border either side of a mown path, tall at the back and graded to the front. Go on down the walk, or turn to see the plots from another side.",
  // While the plants are being grown. They are grown one at a time, in this
  // browser, from the same arithmetic the phone uses, and on a long plot that
  // takes a moment worth naming.
  walkGrowing: "Growing the plants\u2026",
  walkEmpty: "Nothing has been planted here yet.",
  // The walk could not be drawn at all. Said in words rather than left as an
  // empty night, which a reader would take for the garden.
  walkAway: "The walk cannot be reached just now.",
  // The pad under every area's plot (`movepad.js`). The two turns turn the
  // camera on the spot without moving anybody.
  //
  // **They were `walkLeft` and `walkRight` — *Turn left*, *Turn right* — and
  // the words were needed elsewhere.** The foot of an area page named the
  // areas to the left and the right of this one on the map, and a page with
  // *Turn left* on it and a gate to the left of it is a page with two meanings
  // for one word. So the turn is named as a turn: a quarter of the plot, in the
  // direction the words say, which is also what the reader is doing — going
  // round it rather than along anything.
  //
  // The two old keys are gone rather than kept: nothing else used them, and
  // they were still uncommissioned, so no other language has to be told. Two
  // out and two in, and the count does not move.
  //
  // **The pad draws these four as glyphs now, and the words are their names**
  // — each key's `aria-label` and tooltip, through `data-s-label` in
  // `plain.js`. Nothing is spent and nothing is lost: a screen reader still
  // hears the words, in the reader's language, and the eye gets a chevron and
  // a ring that need no language at all.
  walkTurnAnti: "Turn anticlockwise",
  walkTurnClock: "Turn clockwise",
  // **The pad became four directions and two magnifiers, 24 September**, when
  // Marcus asked for a way to see the plants close to. `walkBack` and `walkOn`
  // — *Back* and *On*, down the path — went with the two chevrons they named:
  // the left and right keys now do their paging and more, and a key named *On*
  // that moves the window to the left after a turn would be a name that lies.
  // They had not been commissioned, so nobody has to be told. Six in, two out.
  //
  // **English only for now**, like `coppiceAbout`. The directions are the
  // screen's, not the plot's: *up* is up the screen whichever way the plot is
  // turned, which is why these do not say north or along. Each is a key's
  // name, never text on it.
  moveUp: "Move up",
  moveDown: "Move down",
  moveLeft: "Move left",
  moveRight: "Move right",
  zoomIn: "Zoom in",
  zoomOut: "Zoom out",
  moveHome: "Show the whole plot",

  // A plant's panel, since 24 September (`plantpanel.js`): what opens when a
  // plant on an area page is tapped. **Seven strings, and the panel's real
  // words cost none**: the name is Latin and travels as it is, what it means
  // is the `meaning*` line and the `subtheme*` part the area's own block
  // already says, and the passage is the reader's bank.
  //
  // **English only for now**, like the pad's. `plantKey` is the `p` key's row
  // in the sheet under `?`, which has no control of its own to be labelled by;
  // `plantAmbassador` marks the one plant in an area that was minted rather
  // than crossed. A postcard is a link to the plant: `plantPostcardText` goes
  // with the link into whatever the reader sends it by, and the two after it
  // say what happened when there was no share sheet to send it with.
  plantKey: "Read about the plant in the middle",
  plantAmbassador: "{area}'s ambassador: the first plant to stand here",
  plantPostcard: "Send as a postcard",
  plantPostcardText: "{name}, growing in {area}, in Peace Garden.",
  plantCopied: "The link to this plant is copied, ready to send.",
  plantCopyThis: "Copy this link to send it:",
  plantClose: "Close",

  // `nextTo`, *Next to this area*, stood here over the worded gates at the
  // foot of an area page. The gates are a small map now, labelled by
  // `gardenTitle` and named cell by cell from `AREA_KEYS`, so the label went
  // with them. It had not been commissioned, so no other language has to be
  // told.

  // The Quiet Garden's own page. **Two strings and no more**, because the rest
  // of what the page says it already had: the heading is `areaPeace`, which is
  // commissioned in forty-one languages along with the other nine area names,
  // and `walkBack`, `walkOn` (since gone to the pad's `move*`), `walkTurnAnti`,
  // `walkTurnClock`, `walkGrowing` and `walkEmpty` never said *walk* in any of them — they are how you move
  // and what is happening, not where you are. A second area costing two strings
  // rather than nine is the whole argument of `LANGUAGES.md` working.
  quietAbout:
    "A hedge round a lawn, a bench in one corner, and the fewest plants of any area, because room is what it is for. Go on to the next enclosure, or turn to see this one from another side.",
  // The room could not be drawn. `walkAway` names the walk, so this is its own.
  quietAway: "The Quiet Garden cannot be reached just now.",

  // A third area, and the same two strings again: the heading is `areaMeeting`,
  // already commissioned, and the four keys still never say where you are.
  crossAbout:
    "Two mown paths crossing at a round of paving, with planting in each of the four quarters, low along the paths and tall at the far corners. Go on to the next crossing, or turn to see this one from another side.",
  // The Crossing could not be drawn.
  crossAway: "The Crossing cannot be reached just now.",

  // A fourth area, and the same two strings a fourth time: the heading is
  // `areaKinship`, already commissioned in all forty-two, and the four keys
  // still never say where you are. Four areas have now cost eight strings
  // between them, which is the whole argument of `LANGUAGES.md` holding.
  orchardAbout:
    "Five trees standing in a quincunx, each with a guild of four plants under it and the meadow grass cut back to a disc round its trunk. Go on to the next orchard, or turn to see this one from another side.",
  // The Orchard could not be drawn.
  orchardAway: "The Orchard cannot be reached just now.",

  // A fifth area, and the same two strings a fifth time: the heading is
  // `areaPattern`, already commissioned in all forty-two, and the four keys
  // still never say where you are. Five areas have now cost ten strings
  // between them against the ninety-odd a page apiece would have been.
  knotAbout:
    "Two bands of low clipped hedging woven over and under each other, with a block of one colour in each of the eight compartments they make. Go on to the next knot, or turn to see this one from another side.",
  // The Knot Garden could not be drawn.
  knotAway: "The Knot Garden cannot be reached just now.",

  // A sixth area, and the same two strings a sixth time: the heading is
  // `areaBeginnings`, already commissioned in all forty-two, and the four keys
  // still never say where you are. Six areas have now cost twelve strings
  // between them, and the map that joins them none, against the hundred-odd a
  // page apiece would have been.
  //
  // **The six drills under the plot cost nothing**, and that was the point of
  // drawing the count as eight marks rather than writing it: an epithet is a
  // proper noun and travels, and *three of eight* would have been a thirteenth
  // string in forty-three languages for a fact a row of marks already says.
  //
  // **Nothing here says the bed is full or filling.** A plot opens as soon as a
  // seventh kind arrives and it opens holding one plant, so most drills in most
  // plots are part-sown — *sown with one kind* is what a drill is, and how far
  // along it has got is the list's business, not this sentence's.
  seedbedAbout:
    "Six drills across a bed of fine tilth, each one sown with a single kind of plant and filling from the label at its head. Go on to the next bed, or turn to see this one from another side.",
  // The Seedbed could not be drawn.
  seedbedAway: "The Seedbed cannot be reached just now.",

  // A seventh area, and the same two strings a seventh time: the heading is
  // `areaWaiting`, already commissioned in all forty-two.
  //
  // **It says the plants are young, because the drawing cannot say why.** Every
  // other page shows a plant at its best; this one shows each at a stage it
  // passed long ago, and a reader who has seen their plant in flower elsewhere
  // should be told that is what the frames are for rather than left to think
  // the page has drawn it wrong.
  frameAbout:
    "Four low frames on gravel with their glass propped open, each holding young plants of one colour, the ones that will grow tallest at the back. Go on to the next four, or turn to see these from another side.",
  // The Cold Frame could not be drawn.
  frameAway: "The Cold Frame cannot be reached just now.",

  // An eighth area, and the same two strings an eighth time: the heading is
  // `areaLight`, already commissioned in all forty-two.
  //
  // **It says the pots run as a spectrum, because a reader looking down on
  // them may not see it.** Twenty-four pots in two rows read first as a crowd,
  // and the order in them — blue-green at the door, yellow at the far end — is
  // what this area is. It names the two ends and not the twelve places: the
  // colours between them are there to be seen, and a list of twelve would be
  // longer than the plot is wide.
  //
  // **"House", in the paging clause**, where the Cold Frame says *the next
  // four* and the Seedbed *the next bed*: a plot here is one glasshouse, and
  // that is the word a reader will have for it.
  glasshouseAbout:
    "A glasshouse, its pots set out along the staging as a run of colour from blue-green at the door to yellow at the far end, and the tallest plants in a border along the back. Go on to the next house, or turn to see this one from another side.",
  // The Glasshouse could not be drawn.
  glasshouseAway: "The Glasshouse cannot be reached just now.",

  // A ninth area, and the same two strings a ninth time: the heading is
  // `areaRenewal`, already commissioned in all forty-two.
  //
  // **It says the wood is cut in turn, because the drawing cannot say that it
  // moves.** One visit shows one year: a band of pale stools and new shoots
  // beside two of ferns coming back. That the open band moves on each winter,
  // and that the ferns are cut and the flowers never are, is what this area is,
  // and a reader looking once cannot see it.
  //
  // **No word for which band is cut**, where the design allowed one: *the far
  // band* is the near one after a half turn, and the pale faces already say
  // which it is.
  //
  // **"Further into the wood", in the paging clause**, where the Glasshouse
  // says *the next house*: a plot here is not a thing with a name of its own,
  // and the coupes run on from one plot into the next.
  coppiceAbout:
    "A wood cut in three bands, one each winter in turn, with ferns coming back from the old stools and flowers standing in the light between them, never cut. Go on further into the wood, or turn to see this part of it from another side.",
  // The Coppice could not be drawn.
  coppiceAway: "The Coppice cannot be reached just now.",

  // The tenth and last area, and the same two strings a tenth time: the
  // heading is `areaGround`, already commissioned in all forty-two.
  //
  // **It names the three crops by their shapes**, because that is how a
  // reader tells them apart and the drawing already shows it: the words give
  // the reason the beds differ, not a list of what is in them. **And it says
  // why the tall end is where it is**, because a bed graded from one end reads
  // as an accident unless the reader knows a kitchen garden does it for the
  // light.
  //
  // **"Plot", in the paging clause**, where the Glasshouse says *the next
  // house*: a kitchen garden is kept in plots, and that is the word a reader
  // will have for it.
  groundAbout:
    "A kitchen garden of three raised beds, each sown in rows with one crop: tall spikes, flat heads or low rosettes, the taller plants at the north end, where they shade nothing but the path. Go on to the next plot, or turn to see this one from another side.",
  // The Home Ground could not be drawn.
  groundAway: "The Home Ground cannot be reached just now.",

  // What the plants in each area mean. **Every area gathers the plants of one
  // theme, and the pages above say only how each is laid out**, so a reader
  // standing in the Cold Frame was never told that what brought these plants
  // here is waiting. One line apiece, under the area's paragraph, and again in
  // the table at `/meanings`. `meanings.js` is the table both are drawn from.
  //
  // **Ten rather than seven**, because the table names every area, open or not.
  //
  // **Not the `sense` lines in `commission.py`**, though those were the start.
  // Each of those lists the theme's three parts in prose — *how a seed goes, the
  // road, and the far off* — and the block these sit in lists the three parts
  // anyway, one row down. Said twice on one screen is once too many, as the bar
  // found. So each of these says what the theme is *about*, in the words the
  // project already gave it where it had some: *the earth, and the earth that is
  // yours* is the Home Ground's reason for its name, and *kept rather than
  // happened upon* is Marcus's reading of the Orchard.
  //
  // **Commissioned since 24 September 2026**, when the front page put one on
  // each of its ten cards beside an area name already in the reader's
  // language; Danish first. Falling back in silence where a language has none
  // yet. Each is `Headword: definition.` and `splitEntry` cuts at the first
  // colon, so a translation keeps one, straight after the headword.
  meaningWaiting:
    "Waiting: what is held back until its time, however long that is, and whoever keeps watch.",
  meaningGround: "Ground: the earth a plant stands in, and the earth that is yours.",
  meaningBeginnings: "Beginnings: the first thing a seed does, and how much comes of it.",
  meaningRenewal: "Renewal: what is cut back and comes again, and what is mended.",
  meaningTravel: "Travel: the ways a seed and a person go, and the pull of somewhere else.",
  meaningPeace: "Peace: the quiet a garden is for, and the ease that comes with it.",
  meaningKinship: "Kinship: what grows together, and the people kept rather than happened upon.",
  meaningPattern: "Pattern: the order in living things, and the names given to order.",
  meaningLight: "Light: what a plant turns towards, and the day it keeps time by.",
  meaningMeeting: "Meeting: two coming together at the right moment, and what each owes the other.",
  // The lookup at `/meanings`, and the link to it from every area page. The
  // title is also the link's words, so the link says where it goes.
  meaningsTitle: "What the names mean",
  // **Says the rule and no more.** The worked example under it takes a name
  // apart piece by piece, which is what makes the rule legible; a paragraph
  // explaining it as well would be the same thing twice.
  meaningsAbout:
    "A plant's name says where it belongs. The start of its first word chooses the area it stands in, and the ending chooses which of that area's three parts the words under it come from.",
  meaningsSecond:
    "The second word names the one way a plant most differs from the rest of its genus. After a first word ending in -ynth it takes its masculine form, so rubra becomes ruber.",
  // Over the name-starts in each entry at `/meanings`, where a dictionary
  // gives a word's etymology. The one heading the entries need: the area is
  // named by its own name, the senses are numbered and headed by their
  // endings, and the second words are introduced by `meaningsSecond`. The four
  // other headings the page had while it was two tables went with the tables.
  meaningsNames: "Names beginning",

  // The three parts of each theme, as the numbered senses of its entry: under
  // the definition on an area page, and at `/meanings` with the endings that
  // choose them. **In the catalogue since 24 September 2026**, when Marcus
  // moved them out of `meanings.js`, where they had been English data. The app
  // keyed them from the start as `subtheme.<case>`, and these are the same
  // cases, so a language that has one catalogue has the words for the other.
  //
  // `meanings.js` keeps each English label beside its key, and `selfTest`
  // holds the two to each other. Labels, not sentences: no full stop.
  subthemeHeldBack: "Held back",
  subthemeTheLongCount: "The long count",
  subthemeStandingAndWatching: "Standing and watching",
  subthemeTheSoilItself: "The soil itself",
  subthemeAPlaceYouAreFrom: "A place you are from",
  subthemeAKeptPlace: "A kept place",
  subthemeTheFirstAct: "The first act",
  subthemeSmallToLarge: "Small to large",
  subthemeWhatAStartSettles: "What a start settles",
  subthemeCutAndComeAgain: "Cut and come again",
  subthemeTheTurningYear: "The turning year",
  subthemeMadeWhole: "Made whole",
  subthemeHowASeedGoes: "How a seed goes",
  subthemeTheRoad: "The road",
  subthemeFarOff: "Far off",
  subthemeQuietAsASound: "Quiet as a sound",
  subthemeTheWordsForStopping: "The words for stopping",
  subthemeAtEase: "At ease",
  subthemeGrownTogether: "Grown together",
  subthemeTheWordsForIt: "The words for it",
  subthemeTwoPeople: "Two people",
  subthemeCounted: "Counted",
  subthemeFittedTogether: "Fitted together",
  subthemeOrderNamed: "Order named",
  subthemeTheEdgesOfTheDay: "The edges of the day",
  subthemeReadingTheLight: "Reading the light",
  subthemeLightItself: "Light itself",
  subthemeTheMoment: "The moment",
  subthemeTwoThatNeedEachOther: "Two that need each other",
  subthemeTheMannersOfIt: "The manners of it",

  // Said once and used on both of the pages that are not built yet, because two
  // ways of saying *not yet* is one more than a reader needs.
  notYet: "Not open yet.",
  // What the front page's four links are called where a link needs a word of
  // its own rather than the heading above it.
  goOn: "Go on",

  // The front, since 24 September 2026: one plant on a stage, then how a plant
  // comes to be in three steps, then the ten areas as cards. **Eight keys, and
  // they buy the page Marcus chose** over the one built from `about1`–`about3`.
  // The cards need none: each is its area's name and its `meaning*` line, which
  // the area pages and `/meanings` already carry.
  //
  // The lead is the three steps said once, in the order they happen, so a
  // reader who goes no further than the first screen has the whole of it.
  frontLead:
    "Two phones touch and hand each other a seed. What grows is a plant neither could have grown alone, opening over real days.",
  // Under the plant, which turns under a finger or a pointer.
  frontTurn: "Drag to turn",
  // The three steps, as the app's first run has them. The headings are one
  // word each and carry a glyph, so they are read as a sequence, not as prose.
  frontMeet: "Meet",
  frontMeetBody: "Two people touch phones, in the same room.",
  frontCross: "Cross",
  frontCrossBody: "Each hands the other a seed, and the two seeds cross.",
  frontGrow: "Grow",
  frontGrowBody: "A plant neither could have grown alone opens over real days.",

  // **Rewritten on 24 September, Marcus's wording**, because the page had
  // stopped being true: it said no server held a copy, that one random number
  // crossed at a meeting and reached nobody else, and that the site was plain
  // files, and since the web garden opened none of that holds. Each sentence is
  // checked against the code it describes, and the comment above each names
  // that code, so the next change to the code knows which sentence it moves.
  //
  // On the page in the order 1, 2, 3, 4, 6, 7, 5: the phone, the meeting, the
  // storage, the link, then the web garden and the asking, and the website
  // last. The numbers are the order the keys were made, not the order read.
  privacyTitle: "Privacy",
  // The phone is where a garden lives. There is no account anywhere, in the
  // app or on the site; the site's tester latch is a shared word in
  // `testers.js`, not a sign-in.
  privacy1:
    "Peace Garden keeps what you grow on your own phone. There is no account and nothing to sign in to.",
  // The one paragraph a reviewer is most likely to ask about, so it is the
  // most specific: every field of `PollenCard`, the nonce that travels beside
  // it, and the name the phone advertises while `PollenExchangeService` is
  // looking for a partner. `SettingsView` says the same things inside the app,
  // and the two should agree.
  privacy2:
    "When two phones touch, they connect directly, encrypted. Each hands the other its seed and when that seed was made, its plant's name, whether a place may be kept with the meeting, the name you chose to show, and two random numbers: one that makes the meeting's plant, and one the other phone can use later to offer that plant to the web garden. While you are meeting, that chosen name can be seen by other phones nearby that are open to a meeting.",
  // `GardenStore`: one file in the app's own storage, which the phone's
  // backups include and removing the app removes.
  privacy3:
    "Your seeds, your plants, and anything you write about a meeting stay in the app's own storage on your phone, and in your phone's backups. Removing the app removes them from the phone.",
  // The fragment argument, said without the word fragment, and what the
  // fragment carries: `PollenLink`'s fields, which whoever holds the link can
  // read as surely as the page does.
  privacy4:
    "A seed travels in a link after the # sign, which is the part of a web address a browser keeps to itself. The link carries the seed and when it was made, the plant's name, the name you chose to show and a random number, so whoever you send it to can read them.",
  // The web garden, `Server/.api/`: what an offer and a planting keep
  // (`Offers.php` and the area stores), what taking back leaves
  // (`TakenBack.php`), the backups (`backup.php`, `tools/backup.sh`) and the
  // thirty days an offer waits (`Offers::LAPSES_AFTER`, swept every five
  // minutes by `sweep.php`). The traits are said plainly rather than left
  // inside *what the garden needs*, because each of them is stored. *Its empty
  // place in the plot* is `TakenBack.php`'s placeholder: the row that holds the
  // gap, kept so every later plant stands where the rule put it.
  privacy6:
    "If you and the person you met both agree to share a plant, the web garden keeps it: its seed, the seeds of its two parents, a number for the meeting, your two random numbers, and what the garden needs to place it — its height, colour, area, the second word of its name, and when it was offered. Anyone can see it standing in the garden. No one's name goes with it. Either of you can take it back; the garden then forgets the plant, keeping only its empty place in the plot and a scrambled record, so that it cannot be planted again. The site's backups keep what they held for 30 days. An offer nobody answers is taken back after 30 days.",
  // `GardenModel.catchUpOnTheAsking`, run when the app starts and only while
  // `sharing.invitations.v1` is on: it sends this phone's own token for each
  // meeting — every meeting's, shared or not, which is what *the random numbers
  // from your meetings* says — and nothing else, and hears back about the
  // plants that were offered.
  privacy7:
    "With alerts on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings.",
  // Release, since 1 October 2026: `WildRelease` in SeedCore is what is sent,
  // `router.php`'s release route what is checked, and `WildStore.php` what is
  // kept — the seed and the two parents, and no column for anything else. The
  // meeting's number checks the cross and the random number finds the plant
  // in the asking (`Offers::letGo`), and neither is written down. *Taken back
  // from there first* is that same route withdrawing the offer. The sentence
  // on the parents' seeds is what publishing them means, said plainly rather
  // than left for a reader to work out.
  //
  // **What stands beside it, since 1 October 2026** (Marcus's decision that
  // day, `WildStore.php`'s `wild_names`). Each of the two may show their
  // username, and where and when they met, which stand only once both chose
  // them; nothing is shown unless chosen, and either can withdraw. *Both
  // random numbers* is `theirs` on the release: the other phone's, so the
  // other gardener can be told and answer. *A scrambled form* is the keyed
  // fingerprints the row keeps of the two tokens, and of each side's place
  // and month until both have chosen the same.
  privacy8:
    "If you release a plant, the app sends it to the Wild Fields: its seed, the seeds of its two parents, the number for the meeting, the two random numbers from that meeting if it has them, and whatever you chose to show beside it. The Wild Fields keep the plant's seed and its parents' seeds, and no date. Beside the plant they show only what each of the two people who grew it chose: their username, and where and when they met once both chose those. Nothing is shown unless it is chosen, and either of you can withdraw what you chose at any time. So that each of you can answer for yourself, the Wild Fields keep a scrambled form of the two random numbers, and of the place and month each of you chose until both have. Its parents' seeds are the two seeds that met, so anyone who already knows one of them can tell the plant grew from it. If the plant was standing in the web garden, it is taken back from there first. Anyone can see a released plant, and the plant cannot be taken back.",
  // The website: `Limits.php` for the scrambled address and its hour — a
  // fifty-five-minute window and `sweep.php` every five minutes, which is what
  // keeps it inside the hour when nobody asks — `languages.js` for the
  // language kept in the browser, and nothing anywhere that sets a cookie.
  privacy5:
    "This site runs on a web host, with no advertising, no analytics and no cookies. Your language choice is remembered in your own browser. To limit abuse, the web garden keeps a scrambled form of your internet address for up to an hour, and the host keeps its usual request logs.",

  // The ten areas of the garden, in the order they are walked: the top row of
  // the map left to right, then the bottom. Each names one passage theme, and
  // `docs/NAMES-AND-THEMES.md` has what each theme contains.
  //
  // **These are names, not sentences, and they are commissioned apart from the
  // six paragraphs** — `tools/strings/NAMING.md`, and `commission.py --areas`.
  // A translator handed the paragraph brief would render *The Knot Garden* as a
  // description of a knot garden; what is wanted is whatever that language's
  // own gardening already calls the thing, which for French is *parterre de
  // broderie* and is not a translation of anything.
  //
  // Four of the ten cannot be translated at all, only renamed — the Knot
  // Garden is Tudor, the Coppice is English woodland practice, the Crossing
  // holds two senses that most languages outside Europe have to choose between,
  // and the Cold Frame is the one that looks safe: most languages have a word
  // for the object and it usually means a *forcing* frame, which is the
  // opposite of what this area is for. The naming brief says so, area by area.
  //
  // They fall back to English one at a time like every other key, so a language
  // may arrive with four of them. `check.py` asks for the ten together anyway:
  // a map labelled half in Greek is worse than a map labelled in English.
  areaWaiting: "The Cold Frame",
  // Renamed from *The Root Ground*, 5 September 2026. That name carried the
  // soil and left out the belonging, which is two of the theme's three thirds.
  areaGround: "The Home Ground",
  areaBeginnings: "The Seedbed",
  areaRenewal: "The Coppice",
  areaTravel: "The Long Walk",
  areaPeace: "The Quiet Garden",
  areaKinship: "The Orchard",
  areaPattern: "The Knot Garden",
  areaLight: "The Glasshouse",
  areaMeeting: "The Crossing",
});

/// Every key, in order. The commission sheet, and what `/strings/<code>.json`
/// is generated against.
export const KEYS = Object.freeze(Object.keys(EN));

/// The ten areas, by theme, in map order. `walk.js` reads a name through this.
///
/// Kept beside the catalogue rather than in `walk.js` so that the mapping from
/// a theme to its key is one fact in one place: `check.py` needs the ten keys
/// as a group, `commission.py` needs them in this order, and the page needs to
/// go from `area.theme` to a string.
///
/// **It has to sit below `KEYS`, and that is load-bearing.** `commission.py`
/// reads the English out of this file by slicing between `export const EN` and
/// `export const KEYS` and matching `key: "value"` — so an object of ten string
/// values placed above that line is read as ten more catalogue entries, whose
/// English is the word `areaWaiting`. Caught by the assertion in the script
/// that filled the catalogues, on the first run.
export const AREA_KEYS = Object.freeze({
  waiting: "areaWaiting",
  ground: "areaGround",
  beginnings: "areaBeginnings",
  renewal: "areaRenewal",
  travel: "areaTravel",
  peace: "areaPeace",
  kinship: "areaKinship",
  pattern: "areaPattern",
  light: "areaLight",
  meeting: "areaMeeting",
});

/// A language's words, with English underneath.
///
/// Anything absent, null, or blank is English — silently, and per key rather
/// than per file, so a language part-way through a commission shows every line
/// it has and no gaps.
///
/// `code` is the language asked for, and the catalogue keeps it so it can say
/// which keys came back in English instead. See `borrowed` and `dress`.
export function catalogue(values, code = "en") {
  const merged = { ...EN };
  const fellBack = new Set();
  for (const key of KEYS) {
    const value = values ? values[key] : undefined;
    if (typeof value === "string" && value.trim() !== "") merged[key] = value;
    else if (code !== "en") fellBack.add(key);
  }
  return {
    /// `t("sentBy", { name: "Marcus" })`.
    t(key, vars) {
      let text = merged[key] ?? EN[key] ?? "";
      if (vars) {
        for (const [name, value] of Object.entries(vars)) {
          text = text.replaceAll(`{${name}}`, value);
        }
      }
      return text;
    },

    /// Whether this key came back in English on a page that asked for
    /// something else.
    ///
    /// **Silent to the reader, and it stays silent.** Only a missing *bank* is
    /// announced, under the passage; a missing label says nothing anywhere,
    /// which is the rule this module opens with. This tells the page what
    /// language a run of text is in, which is a different question from
    /// whether to mention it.
    borrowed(key) {
      return fellBack.has(key);
    },

    /// Writes the text of one `[data-s]` element, and says what language it is
    /// in while doing it.
    ///
    /// **This is not decoration; it is the difference between a sentence and a
    /// scrambled one.** An English sentence inside a right-to-left document is
    /// reordered by the bidi algorithm at its punctuation — *A plant grown from
    /// a meeting.* is drawn as *.A plant grown from a meeting*, with the full
    /// stop at the head of the line. Marking the run as English is the fix, and
    /// it is the same fix `/g`'s invented-garden notice carries in its markup.
    ///
    /// Six of the nineteen strings are `null` in every language on purpose —
    /// the site's own prose, `null` in every catalogue — so on Arabic
    /// and Hebrew this is most of the words on the page rather than an edge
    /// case. It was invisible until there was a way to stand in those two
    /// languages and look.
    ///
    /// The attributes are cleared rather than left when a key stops falling
    /// back, because a stale `lang="en"` on a commissioned Hebrew string is the
    /// same bug the other way round.
    dress(node, key) {
      if (this.borrowed(key)) {
        node.lang = "en";
        node.dir = "ltr";
      } else {
        node.removeAttribute("lang");
        node.removeAttribute("dir");
      }
      return node;
    },
  };
}

/// Fetches one language's catalogue.
///
/// A file that is missing, unparseable, or still all nulls resolves to English
/// without saying so. There is deliberately no second list of "which languages
/// are done": the file itself answers that, so there is nothing to keep in
/// step. docs/WEBSITE.md is emphatic that remembering is the option this
/// repository has already rejected twice.
export async function loadStrings(code) {
  if (!code || code === "en") return catalogue(null, "en");
  try {
    const response = await fetch(`/strings/${encodeURIComponent(code)}.json`, {
      // **Store it, but ask every time whether it has changed.** This was
      // `force-cache`, which returns a stored copy fresh or stale and never
      // asks. The host sends an ETag and no `Cache-Control`, so a reader who
      // had seen a language once held that catalogue for good: a corrected
      // sentence would ship, the page would look exactly as it had, and
      // nothing anywhere would say why. Found on 5 September, with three
      // corrections live on the origin and the old words still on the screen
      // in front of the person who had asked for them.
      //
      // The cost is one conditional request per page load, answered 304 with
      // no body. Nothing is paid twice within a load — every module here holds
      // what it fetched, and this one is behind `loadStrings`. The same change
      // is in `languages.js`, `testers.js` and `passages.js`, which all read
      // files a deploy replaces.
      cache: "no-cache",
    });
    if (!response.ok) return catalogue(null, code);
    const file = await response.json();
    return catalogue(file && file.strings, code);
  } catch {
    return catalogue(null, code);
  }
}
