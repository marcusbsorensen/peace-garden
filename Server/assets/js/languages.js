// Which language a page is read in.
//
// **The language is never in the path.** Not `/nl/s#…`, not a subdomain. A link
// is minted by one person and read by another, and a language in the URL is the
// sender's language imposed on the receiver at exactly the moment this app is
// meeting somebody new. docs/WEBSITE.md §"The language is not in the URL"
// settles it, and it is settled because it cannot be settled later: every link
// already minted points at `/s`.
//
// So the order is: `?l=` if somebody deliberately asked, then whatever the
// chooser was last set to in this browser, then `navigator.languages`, then
// English. `?l=` is never minted by the app and is only ever present because a
// person put it there — *read this one in Dutch* — which is why it outranks a
// remembered choice rather than being outranked by it.
//
// Two answers come out of this, and confusing them costs the borrowed-language
// line its meaning:
//
//   `ui`   — which language the site's own labels are drawn in. Missing labels
//            fall back to English in silence.
//   `bank` — which passage bank supplies the words. When that is not the
//            reader's own language, `isBorrowed` is true and the page says so
//            under the passage.
//
// In the app `isBorrowed` has never been true for anybody, because every
// language with an interface also has a bank. A browser can be set to anything
// at all, so on the web it is the ordinary case.

const STORAGE_KEY = "site.language.v1";

/// Written case is kept in these, rather than uppercased.
///
/// The same four as `Chrome.keepsWrittenCase`, and for the same reasons:
/// Turkish and Azerbaijani have two letter i's and uppercasing the wrong one
/// changes the word; Greek drops accents it cannot get back; Irish keeps a
/// lowercase prefix no general-purpose uppercaser knows about. Turkish is the
/// one that bites today — it has a bank, so it is in the chooser.
export const KEEPS_WRITTEN_CASE = new Set(["tr", "az", "el", "ga"]);

/// Scripts with no capitals at all, so there is no uppercasing to do.
///
/// Distinct from `KEEPS_WRITTEN_CASE`, which is four languages that *have*
/// capitals and are harmed by them. These have none: `text-transform:
/// uppercase` is a no-op on Arabic, Hebrew, Chinese, Japanese and Korean, and
/// asking for it is a statement about the label voice that the script cannot
/// carry. Named rather than left to the no-op so the rule reads as a decision.
export const CASELESS = new Set(["ar", "he", "ja", "zh", "ko", "th", "fa", "ur", "yi"]);

/// Scripts that letter-spacing damages, where `KEEPS_WRITTEN_CASE` only
/// undresses them.
///
/// **This is the one that actually breaks something.** The label voice is
/// tracked out to 0.218em, which is a Latin small-caps device. On Arabic it is
/// not a stylistic choice, it is a defect: Arabic is a joined script, and
/// putting space between letters severs the joins and leaves a row of
/// disconnected forms that a reader has to reassemble. Persian and Urdu are the
/// same script and the same damage.
///
/// CJK is here for a different reason. It is not damaged — the glyphs do not
/// join — but a Han or Kana line tracked to a Latin caption's rhythm reads as
/// badly set, and the device it is imitating has no meaning in a script with no
/// capitals to space out.
///
/// Hebrew is deliberately absent: it is right to left and caseless, and its
/// letters do not join, so tracking is merely a choice there rather than a
/// wound.
export const NEVER_TRACKED = new Set(["ar", "fa", "ur", "ja", "zh", "ko"]);

/// Languages written right to left.
///
/// The site was built with logical properties throughout on the argument that
/// no round-two language is right to left and the pass should not have to be
/// earned twice. This is that pass arriving, and the CSS is why it is three
/// lines rather than a rewrite.
export const RIGHT_TO_LEFT = new Set(["ar", "he", "fa", "ur", "yi"]);

/// `"rtl"` or `"ltr"`, for the document's own `dir`.
export function direction(code) {
  return RIGHT_TO_LEFT.has(normalise(code).primary) ? "rtl" : "ltr";
}

/// Whether the label voice may letter-space this language.
export function tracks(code) {
  return !NEVER_TRACKED.has(normalise(code).primary);
}

/// Tags a browser may send that name a language the manifest files elsewhere.
///
/// Deliberately tiny. `no` is the macrolanguage over Bokmål and Nynorsk and a
/// browser set to `no` is asking for Norwegian; the app writes Bokmål. Nynorsk
/// (`nn`) is left alone: it is a different written language and answering it
/// with Bokmål would be a decision nobody has taken.
const ALIASES = { no: "nb" };

let manifestPromise = null;

/// The generated manifest: every language the app knows, whether it has an
/// interface, whether it has a bank, and what to call it in a chooser.
///
/// `Server/languages.json` is written by `tools/site/export.py` and CI fails on
/// a diff, which is what keeps the site's languages the app's rather than a
/// second list that agrees for a while. The site adds none of its own.
export function manifest() {
  if (!manifestPromise) {
    manifestPromise = fetch("/languages.json", { cache: "force-cache" })
      .then((response) => (response.ok ? response.json() : null))
      .then((file) => (file && Array.isArray(file.languages) ? file.languages : []))
      .catch(() => []);
  }
  return manifestPromise;
}

/// The languages a reader can be offered: the ones with a bank.
///
/// The chooser is the manifest. A language with an interface and no bank is the
/// normal state rather than the exception — an interface is a fortnight and a
/// bank is a commission — and it is reachable by negotiation without being
/// something to choose, because what a chooser offers is a reading.
export function readable(languages) {
  return languages.filter((language) => language.bank);
}

function normalise(tag) {
  const lower = String(tag || "").toLowerCase().replace(/_/g, "-");
  const primary = lower.split("-")[0];
  return { lower, primary: ALIASES[primary] || primary };
}

function match(tag, codes) {
  const { lower, primary } = normalise(tag);
  if (codes.has(lower)) return lower;
  if (codes.has(primary)) return primary;
  return null;
}

function firstMatch(tags, entries) {
  const codes = new Set(entries.map((entry) => entry.code));
  for (const tag of tags) {
    const found = match(tag, codes);
    if (found) return found;
  }
  return null;
}

/// What this browser last chose here. Storage that is unavailable reads as no
/// choice, which is the right answer rather than an error.
export function remembered() {
  try {
    return window.localStorage.getItem(STORAGE_KEY);
  } catch {
    return null;
  }
}

export function remember(code) {
  try {
    window.localStorage.setItem(STORAGE_KEY, code);
  } catch {
    /* A browser that keeps nothing still reads the page. */
  }
}

/// Reads `?l=`, which the app never mints.
export function override(search = window.location.search) {
  const asked = new URLSearchParams(search).get("l");
  return asked ? normalise(asked).lower : null;
}

/// Settles both languages for this reader.
export function negotiate(languages, options = {}) {
  const asked = options.override !== undefined ? options.override : override();
  const stored = options.remembered !== undefined ? options.remembered : remembered();
  const offered = options.navigator || navigator.languages || [navigator.language || "en"];
  const banks = readable(languages);

  const codes = new Set(languages.map((entry) => entry.code));
  const wanted =
    (asked && match(asked, codes)) ||
    (stored && match(stored, codes)) ||
    firstMatch(offered, languages) ||
    null;

  // The bank is settled against the same wish, over the languages that have
  // one. A reader whose language has an interface and no bank keeps their own
  // labels and borrows the passage, which is the case this is built for.
  const bankCodes = new Set(banks.map((entry) => entry.code));
  const bank =
    (asked && match(asked, bankCodes)) ||
    (stored && match(stored, bankCodes)) ||
    firstMatch(offered, banks) ||
    "en";

  const ui = wanted || bank || "en";

  // What this reader actually asked for, before anything fell back. The
  // borrowed line is measured against this rather than against `ui`: somebody
  // whose browser is set to Japanese gets English labels *and* an English
  // passage, and the passage is the one of the two that has to say so.
  const preferred = normalise(asked || stored || offered[0] || "en").primary;

  return {
    ui,
    bank,
    preferred,
    // Borrowed is about the passage and about nothing else. A label that came
    // out in English says so nowhere.
    //
    // English is named in the condition rather than implied, because the line
    // under the passage names English in so many words. A bank that is not the
    // reader's own but is not English either — they asked for one language in
    // `?l=` and had already chosen another — is a passage in the language they
    // chose, and saying *in English* over it would be false. If the fallback
    // ever stops being English, this line and that string move together.
    isBorrowed: bank === "en" && preferred !== "en",
    entry: languages.find((entry) => entry.code === ui) || null,
  };
}

/// Whether this language's label voice is uppercased.
///
/// Two ways to answer no, and they are not the same fact: a language that has
/// capitals and is harmed by them, and a script that has none.
export function uppercases(code) {
  const { primary } = normalise(code);
  return !KEEPS_WRITTEN_CASE.has(primary) && !CASELESS.has(primary);
}
