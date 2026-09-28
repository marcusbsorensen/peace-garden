// The passage, drawn in the reader's language.
//
// A page carries a theme and a subtheme. Both are language-neutral, both are
// derived rather than written by anybody, and **the reader's own bank supplies
// the words**. That is the app's rule rather than a second one: two people on
// different banks deliberately see different lines, because a bank is a
// commission and not a translation — sixty of the English passages are
// etymologies of English words, which are facts about English and false in
// Dutch. `QuoteBanks.swift` carries the argument; docs/WEBSITE.md §"The
// passage: one page, two readers" extends it to the web.
//
// So a page is not the same page twice, and that is the point: the same plant,
// on the same subtheme, offers a line from the *Kalevala* and then a *refrany
// català*, and they are not translations of each other.
//
// **A plant's name says which passage it can be given.** The head of the genus
// carries the theme and the ending of the genus carries the subtheme, and both
// were in the seed before either mattered. docs/NAMES-AND-THEMES.md is the
// record. That is what lets a page derive a passage from a name and nothing
// else — no lineage, no geometry, no derivation.

/// Mirrored from `PlantName.genusHeads`: every root a flower can be named
/// from, in alphabetical order. Twenty-eight since 28 September 2026, when the
/// reed and the cushion brought `Don`, `Syr`, `Tyl` and `Or`. Nothing here or in
/// the app draws from it by position, so a root is added where the alphabet
/// puts it; `PlantName.genusHeads` says why that was once not so.
export const GENUS_HEADS = Object.freeze([
  "Ael", "Aur", "Bel", "Cal", "Cer", "Cyn", "Don", "Dros", "El", "Fen",
  "Hal", "Ith", "Lir", "Mel", "Nyx", "Ol", "Or", "Pell", "Quin", "Ros",
  "Sel", "Syr", "Thal", "Tyl", "Umbr", "Ver", "Vin", "Zeph",
]);

/// Mirrored from `PlantName.genusTails`, and read the same way: ten endings
/// banded 3/3/4 over three subthemes, which suits the bank rather than fighting
/// it — the last third is the words and the sayings and is reliably the largest.
export const GENUS_TAILS = Object.freeze(["ia", "is", "a", "ea", "ina", "ora", "yne", "era", "ula", "ynth"]);

/// Mirrored from `Area.genusHeads`. Every head appears exactly once. Two themes
/// take four heads, four take three and four take two: the reed's two roots
/// went where the lily's are and the cushion's to the head of the slope.
const THEME_HEADS = {
  beginnings: ["Thal", "Lir", "Ver", "Don"],
  waiting: ["Nyx", "Umbr", "Syr"],
  renewal: ["Dros", "Ros"],
  light: ["El", "Aur", "Sel"],
  pattern: ["Cal", "Quin"],
  ground: ["Cer", "Fen", "Pell"],
  travel: ["Zeph", "Ael", "Hal", "Or"],
  meeting: ["Mel", "Ith", "Tyl"],
  kinship: ["Vin", "Cyn"],
  peace: ["Ol", "Bel"],
};

/// Mirrored from `Quotes.Subtheme`, in the order the genus endings read them.
const THEME_SUBTHEMES = {
  beginnings: ["theFirstAct", "smallToLarge", "whatAStartSettles"],
  waiting: ["heldBack", "theLongCount", "standingAndWatching"],
  renewal: ["cutAndComeAgain", "theTurningYear", "madeWhole"],
  light: ["theEdgesOfTheDay", "readingTheLight", "lightItself"],
  pattern: ["counted", "fittedTogether", "orderNamed"],
  ground: ["theSoilItself", "aPlaceYouAreFrom", "aKeptPlace"],
  travel: ["howASeedGoes", "theRoad", "farOff"],
  meeting: ["theMoment", "twoThatNeedEachOther", "theMannersOfIt"],
  kinship: ["grownTogether", "theWordsForIt", "twoPeople"],
  peace: ["quietAsASound", "theWordsForStopping", "atEase"],
};

/// Mirrored from `Quotes.Theme.position`: where each theme sits in the four
/// dimensions `Quotes.Dimension` names — company, motion, duration, register —
/// in `Theme.allCases` order, which is the order a tie is settled in. Only the
/// plant panel reads it, to take a crossed plant's passage from the theme its
/// two parents share, as the app does at the meeting. `passage_reference.py`
/// holds this copy to the app's.
const POSITIONS = Object.freeze({
  beginnings: [0.30, 0.45, 0.60, 0.35],
  waiting: [0.15, 0.10, 1.00, 0.40],
  renewal: [0.25, 0.70, 0.70, 0.35],
  light: [0.30, 0.60, 0.35, 0.50],
  pattern: [0.40, 0.25, 0.50, 0.70],
  ground: [0.25, 0.05, 0.85, 0.45],
  travel: [0.35, 1.00, 0.45, 0.75],
  meeting: [0.90, 0.70, 0.10, 0.55],
  kinship: [1.00, 0.30, 0.90, 0.30],
  peace: [0.55, 0.00, 0.75, 0.20],
});

/// `GeneSource.inheritFirstParent` and `inheritSecondParent`: a pair takes the
/// first parent's theme below the first, the second's below the second, and
/// one lying between them otherwise.
const INHERIT_FIRST = 0.36;
const INHERIT_SECOND = 0.72;

/// The theme nearest to two others along one dimension, neither of them — a
/// port of `Quotes.between`. Nearness on the governing axis first, and over all
/// four only to break a tie; the first of equals wins, as Swift's `min` has it.
export function between(one, other, axis) {
  const a = POSITIONS[one], b = POSITIONS[other];
  const midpoint = (a[axis] + b[axis]) / 2;
  const centre = a.map((value, i) => (value + b[i]) / 2);
  let best = null, bestNear = Infinity, bestAll = Infinity;
  for (const [theme, at] of Object.entries(POSITIONS)) {
    if (theme === one || theme === other) continue;
    const near = Math.abs(at[axis] - midpoint);
    const all = at.reduce((sum, value, i) => sum + (value - centre[i]) ** 2, 0);
    if (near < bestNear || (near === bestNear && all < bestAll)) {
      best = theme; bestNear = near; bestAll = all;
    }
  }
  return best ?? one;
}

/// The theme two parents share — a port of `Quotes.sharedTheme`, with what only
/// SeedCore can work out handed over by the module's `pg_name`: each parent's
/// own genus head, the lower seed's first, and the pair's two rolls.
export function sharedTheme({ heads, inherit, axis }) {
  const mine = themeOf(heads[0]);
  const theirs = themeOf(heads[1]);
  if (inherit < INHERIT_FIRST) return mine;
  if (inherit < INHERIT_SECOND) return theirs;
  const dimensions = POSITIONS.beginnings.length;
  return between(mine, theirs, Math.min(dimensions - 1, Math.floor(axis * dimensions)));
}

/// Reads the two syllables back off a written genus.
///
/// A port of `PlantName.init(genus:epithet:)`, and the fussy part is deliberate:
/// **the ending is searched in what is left after the head**. Take *Cera* — the
/// longest ending that fits its last letters is `era`, and the answer is `a`,
/// because `Cer` has already spoken for the C, the e and the r. Searching the
/// whole word puts `Cer`, `Quin` and `Ver` in the wrong third of their own theme
/// whenever they take the shortest ending. `ThemeMappingTests` found that;
/// nothing on screen would have.
///
/// A name that answers to neither list falls back the way the app falls back —
/// to the first of each — so it lands in a theme rather than in nothing at all.
export function syllables(genus) {
  const name = String(genus || "");
  let head = GENUS_HEADS.filter((candidate) => name.startsWith(candidate)).sort(
    (a, b) => a.length - b.length
  ).pop() || GENUS_HEADS[0];

  const remainder = name.startsWith(head) ? name.slice(head.length) : name;
  const tail = GENUS_TAILS.filter(
    (candidate) => candidate.length <= remainder.length && remainder.endsWith(candidate)
  ).sort((a, b) => a.length - b.length).pop() || GENUS_TAILS[0];

  return { head, tail };
}

/// The theme a name says it belongs to. Unknown heads land in the same place
/// the app puts them, by way of the fallback head above.
export function themeOf(head) {
  for (const [theme, heads] of Object.entries(THEME_HEADS)) {
    if (heads.includes(head)) return theme;
  }
  return "beginnings";
}

/// Which third of a theme, read off the ending.
export function subthemeOf(tail, theme) {
  const index = GENUS_TAILS.indexOf(tail);
  const band = index < 0 ? 0 : index <= 2 ? 0 : index <= 5 ? 1 : 2;
  const subthemes = THEME_SUBTHEMES[theme] || THEME_SUBTHEMES.beginnings;
  return subthemes[Math.min(band, subthemes.length - 1)];
}

/// Theme and subtheme for a binomial, which is all a page carries.
///
/// The genus is the first word. An epithet says nothing about either.
export function placement(binomial) {
  const genus = String(binomial || "").trim().split(/\s+/)[0] || "";
  const { head, tail } = syllables(genus);
  const theme = themeOf(head);
  return { theme, subtheme: subthemeOf(tail, theme), head, tail };
}

/// FNV-1a over bytes, ported from `deterministicFold` in `Draw.swift`.
///
/// The algorithm is spelled out there rather than borrowed from a standard
/// library precisely so that every implementation agrees — a different device,
/// a later OS, years from now. This is one more of those. Every byte is folded
/// rather than a prefix taken, and the wrapping arithmetic is the point of it.
export function deterministicFold(bytes) {
  const MASK = (1n << 64n) - 1n;
  let hash = 0xcbf29ce484222325n;
  for (const byte of bytes) {
    hash ^= BigInt(byte);
    hash = (hash * 0x100000001b3n) & MASK;
  }
  return hash;
}

const banks = new Map();

/// One bank, fetched once.
///
/// **Only ever the one the reader needs.** A bank of three hundred-odd passages
/// is tens of kilobytes and seventeen of them is over a megabyte, so the page
/// asks for one. That request is the thing that tells the origin roughly what
/// language a reader has — recorded here so it is a known cost rather than a
/// discovery. The fragment still never arrives.
export function loadBank(code) {
  if (!banks.has(code)) {
    banks.set(
      code,
      fetch(`/passages/${encodeURIComponent(code)}.json`, {
        // A deploy replaces this file. `force-cache` never asks whether it
        // has; see the note in `strings.js`. A bank is tens of kilobytes and
        // an unchanged one comes back 304 with none of them.
        cache: "no-cache",
      })
        .then((response) => (response.ok ? response.json() : []))
        .catch(() => [])
    );
  }
  return banks.get(code);
}

/// The passage a subtheme gives to one particular set of bytes.
///
/// Selection is: filter by theme and subtheme, fold the bytes, take one. The
/// app folds the *child* seed — the plant two people made — which a static page
/// cannot compute; see the note where this is called.
///
/// A subtheme with nothing behind it widens to its theme and then to the whole
/// bank. The app treats that as a programming error and stops; a page has a
/// reader in front of it and shows a line instead.
export function choose(bank, theme, subtheme, bytes) {
  const exact = bank.filter((p) => p.theme === theme && p.subtheme === subtheme);
  const pool = exact.length
    ? exact
    : bank.filter((p) => p.theme === theme).length
      ? bank.filter((p) => p.theme === theme)
      : bank;
  if (!pool.length) return null;
  const index = Number(deterministicFold(bytes) % BigInt(pool.length));
  return pool[index];
}
