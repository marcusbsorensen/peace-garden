// The site's own words.
//
// **The target is the low tens and it is a target to defend.** Every string
// here is a commission in seventeen languages, so a paragraph added casually is
// seventeen paragraphs. Most of a page needs no word at all — the plant, its
// binomial, the marks, the date and the age all say themselves — and the list
// below is what is left after that. See docs/WEBSITE.md §"Most of a plant page
// is already in every language".
//
// English is written here rather than fetched, because it is the fallback and
// a fallback that can fail to arrive is not one. The other sixteen live in
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
  about1:
    "Peace Garden makes a plant out of two people meeting. Two phones hand each other a seed, and what grows from the pair is a plant that is the two of them together, opening over real days in its own time.",
  about2:
    "A seed travels in a link as well as by touch, so it reaches a phone that has never heard of any of this.",
  about3:
    "The seed in a link rides after the # in its address, and that part stays in your browser. This page is a file, and it draws what your own link already holds.",

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
  appNote: "The app is being made for iPhone. This link keeps until it arrives.",

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
});

/// Every key, in order. The commission sheet, and what `/strings/<code>.json`
/// is generated against.
export const KEYS = Object.freeze(Object.keys(EN));

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
    /// the site's own prose, waiting on docs/FOR-REVIEW.md §1 — so on Arabic
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
      cache: "force-cache",
    });
    if (!response.ok) return catalogue(null, code);
    const file = await response.json();
    return catalogue(file && file.strings, code);
  } catch {
    return catalogue(null, code);
  }
}
