#!/usr/bin/env python3
"""
The brief for one language, with that language's own material filled in.

    python3 tools/strings/commission.py da            # the six paragraphs
    python3 tools/strings/commission.py --areas da    # the ten area names
    python3 tools/strings/commission.py --privacy da  # the privacy page

Prints everything needed to write one commission for Danish and nothing else:
the rules, what each string has to carry, the English, and — the part that
cannot be got from anywhere else — the vocabulary Danish has already settled on
in the strings it has.

**Two commissions, and they take opposite instructions.** The six paragraphs are
a translation: every language says the same things about how the app works, and
a fluent sentence that says something else is the failure. The ten area names
are not a translation at all — they are naming, and the right answer is often
whatever that language's own gardening already calls the place. Handing a
namer the paragraph brief produces *le jardin de nœuds* where the answer is
*parterre de broderie*. Hence two briefs, two modes, and this note in both.

**The English is read from `strings.js` rather than repeated here.** It has
changed four times in one day; a second copy would be wrong by the afternoon.
The claims and the area material below are the one thing this file owns,
because they exist nowhere else in a form a translator can be handed.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = ROOT / "Server/assets/js/strings.js"
CATALOGUES = ROOT / "Server/strings"
BRIEF = pathlib.Path(__file__).resolve().parent / "BRIEF.md"
NAMING = pathlib.Path(__file__).resolve().parent / "NAMING.md"

# The six, and what each one has to be true about.
#
# **`must not` is the useful half.** Every line in it is the fluent, obvious
# sentence that says the wrong thing — which is how the English got one wrong for
# weeks. A translator who reads only the source will write exactly these.
CLAIMS = {
    "tagline": {
        "seen": "Under the mark, on the page somebody reaches with no seed.",
        "must": [
            "A plant comes out of a meeting between two people.",
        ],
        "must not": [
            "Be a slogan or a call to action. It is a name for the thing, not a "
            "sentence about it — closer to a book's subtitle than to an advert.",
        ],
    },
    "about1": {
        "seen": "First paragraph, on the page with no seed.",
        "must": [
            "The app makes a plant out of two people meeting.",
            "Two phones hand each other a seed.",
            "What grows carries features of both seeds.",
            "It opens over real days, at its own pace.",
        ],
        "must not": [
            "Say the plant is an average or a blend of two plants. Traits come "
            "from one parent or the other, and a few belong to neither.",
            "Lose the last sentence. A reader who expects a finished picture "
            "reads a seedling as a failure, and this is the only place the site "
            "says a plant takes weeks.",
        ],
        "note": "The two similes — a handshake, a shared garden — are Marcus's, "
                "and the point of them is that they are things a reader has "
                "already done. If a handshake carries something else where you "
                "are, find the nearest ordinary thing two people do together on "
                "meeting, and say so in your notes.",
    },
    "about2": {
        "seen": "Second paragraph, on the page with no seed.",
        "must": [
            "A seed can travel in a link as well as by phones touching.",
            "That is what lets it reach a phone that has never had the app.",
        ],
        "must not": [
            "Suggest the receiver has to sign up, install anything first, or "
            "have heard of Peace Garden.",
        ],
    },
    "about3": {
        "seen": "Third paragraph, on the page with no seed — and read only by "
                "somebody who has none. The seed block and this block are "
                "mutually exclusive, so this reader typed the address or "
                "followed a link that lost its seed on the way.",
        "must": [
            "A seed reaches you from a person you meet, face to face.",
            "Peace Garden exists, on iPhone and iPad.",
        ],
        "must not": [
            "Imply a seed can be got from the website, downloaded, or asked "
            "for. It cannot. That is the whole point of the sentence.",
            "Say the app is coming or being made. It is out.",
        ],
    },
    "growBody": {
        "seen": "Under *Growing it*, on the page that does have a seed in it.",
        "must": [
            "The app crosses this seed with one of the reader's own.",
            "The plant that comes of the pair is theirs to keep.",
            "This meeting grows one plant, and both people have that one.",
            "It stays the same plant for as long as they have it.",
        ],
        "must not": [
            "Say, or imply, that the same two seeds always make the same "
            "plant. **This is the one that was wrong in English for weeks.** "
            "Both sides contribute a random nonce, so meeting the same person "
            "again grows a different plant, and neither of them can steer it.",
            "Imply the link can be opened twice to get the same plant back. A "
            "fresh nonce each time means it cannot.",
        ],
    },
    "appNote": {
        "seen": "The quiet line under growBody, on the page with a seed.",
        "must": [
            "Peace Garden is on iPhone and iPad.",
            "The link keeps, so there is no hurry.",
        ],
        "must not": [
            "Give the link an expiry, or suggest acting quickly.",
            "Say the app is coming. It is out.",
        ],
        "note": "Its first sentence is the same claim as about3's second. The "
                "two are never on screen together, so they may be worded alike "
                "or differently as your language prefers.",
    },
}

# The privacy page, at `/privacy`.
#
# **Its own group, and not part of `CLAIMS`, for the reason the areas are their
# own group: a language may have one commission and not the other.** Folding
# these in with the six paragraphs made every catalogue that already had the
# prose fail as half-commissioned the moment the keys existed — 41 of 42, on
# the first run after they were added. A group is what lets a page arrive on
# its own.
#
# **Eight keys since 24 September**, when the English was rewritten because it
# had stopped being true — it said no server held a copy, and the web garden
# does — and `privacy6` and `privacy7` were added to say what it holds and what
# the app asks it. No language had translated the page yet, so nothing had to
# be withdrawn.
#
# The claims themselves matter more here than anywhere else on the site.
# `privacy2` is the sentence a reviewer is most likely to ask about, and the
# one where a fluent overstatement — *nothing is sent* — would be both untrue
# and the most reassuring thing to write. `privacy6` is the one where a fluent
# softening — *nothing is kept* — would be.
PRIVACY = {
    "privacyTitle": {
        "seen": "The heading of /privacy.",
        "must": ["Name the subject of the page in one word or two."],
        "must not": ["Be a sentence, or promise anything. It is a heading."],
    },
    "privacy1": {
        "seen": "First paragraph of /privacy.",
        "must": [
            "What you grow is kept on your own phone.",
            "There is no account and nothing to sign in to.",
        ],
        "must not": [
            "Say data is 'encrypted' or 'secure'. Neither is the claim here.",
            "Say no server is involved. The web garden is one, and "
            "`privacy6` says what it keeps.",
        ],
    },
    "privacy2": {
        "seen": "Second paragraph of /privacy — **the load-bearing one.**",
        "must": [
            "When two phones touch, they connect directly and encrypted.",
            "Each hands the other: its seed and when that seed was made, its plant's "
            "name, whether a place may be kept with the meeting, the chosen "
            "name, and two random numbers — one makes the meeting's plant, "
            "one lets the other phone offer that plant to the web garden later.",
            "While meeting, the chosen name can be seen by other phones nearby "
            "that are open to a meeting.",
        ],
        "must not": [
            "Leave out any item of that list, or add one. **It is the whole of "
            "what crosses, and a reviewer reads it as that.**",
            "Say *nothing is sent*, or that it reaches nobody else. Something is "
            "sent, and the name is visible nearby while meeting.",
            "Imply a server or a service is involved in the meeting itself.",
        ],
        "note": "`SettingsView` says the same things inside the app. If your "
                "language has the app, agree with it. **Keep whether-a-place "
                "may-be-kept away from the chosen name**: where the two sit "
                "side by side, a verb meaning *show* swallows the *whether* "
                "and the list silently loses an item. Danish and Slovene both "
                "did it, and the English did it to them (26 September).",
    },
    "privacy3": {
        "seen": "Third paragraph of /privacy.",
        "must": [
            "Seeds, plants and anything written about a meeting stay in the "
            "app's own storage on the phone, and in the phone's backups.",
            "Removing the app removes them from the phone.",
        ],
        "must not": [
            "Say removing the app removes them everywhere. The phone's own "
            "backups keep what they hold, which is why *from the phone* is "
            "there.",
        ],
    },
    "privacy4": {
        "seen": "Fourth paragraph of /privacy.",
        "must": [
            "A seed travels in a link after the # sign.",
            "That part of a web address is kept by the browser.",
            "The link carries the seed and when it was made, the plant's name, "
            "the chosen name and a random number.",
            "Whoever it is sent to can read them.",
        ],
        "must not": [
            "Use the word *fragment*, or any other term of art. The reader is "
            "a gardener who was handed a link.",
            "Claim the link is private or secret. Anyone holding it can open "
            "it — that is what a link is, and docs/SEEDS-ON-THE-WIND.md is "
            "explicit that a link can be forwarded and posted publicly.",
        ],
    },
    "privacy6": {
        "seen": "Fifth paragraph of /privacy, about the web garden.",
        "must": [
            "If both people agree to share a plant, the web garden keeps it: "
            "its seed, its two parents' seeds, a number for the meeting, the "
            "two random numbers, and what the garden needs to place it — its "
            "height, colour, area, the second word of its name, and when it "
            "was offered.",
            "Anyone can see it standing in the garden.",
            "No one's name goes with it.",
            "Either of them can take it back; the garden then forgets the plant, "
            "keeping only its empty place in the plot and a scrambled record, so "
            "it cannot be planted again.",
            "The site's backups keep what they held for thirty days.",
            "An offer nobody answers is taken back after thirty days.",
        ],
        "must not": [
            "Say *nothing is kept* after taking back, or that it is deleted "
            "everywhere. Its empty place and a scrambled record stay, and the "
            "backups keep it for thirty days.",
            "Make *its empty place in the plot* sound like the plant, or a "
            "marker with its name. It is the gap where it stood, kept so that "
            "nothing planted after it moves.",
            "Turn *the second word of its name* into a technical term. It is "
            "the plant's epithet, said as a gardener would find it.",
            "Imply the plant can be put back after it is taken back.",
        ],
    },
    "privacy7": {
        "seen": "Sixth paragraph of /privacy, about the app asking the web "
                "garden.",
        "must": [
            "With alerts on, each time the app starts it asks the web garden "
            "about your shared plants.",
            "It asks by sending the random numbers from your meetings.",
        ],
        "must not": [
            "Say it asks all the time, or in the background. It asks when it "
            "starts.",
            "Narrow *the random numbers from your meetings* to the shared plants' "
            "alone. It sends one for every meeting, and the answer is about the "
            "shared plants.",
            "Name the setting differently from the app's own switch, if your "
            "language has the app.",
        ],
    },
    "privacy5": {
        "seen": "Last paragraph of /privacy, about the website rather than "
                "the app.",
        "must": [
            "The site runs on a web host, with no advertising, no analytics "
            "and no cookies.",
            "The language choice is remembered in the reader's own browser.",
            "To limit abuse, the web garden keeps a scrambled form of the "
            "internet address for up to an hour.",
            "The host keeps its usual request logs.",
        ],
        "must not": [
            "Extend the claim to the app, which is a different thing with a "
            "different answer.",
            "Say the address is not kept, or is anonymised. It is scrambled, "
            "and kept for an hour.",
        ],
    },
}

# The front page, at `/`, since 24 September 2026.
#
# **Its own group, as the privacy page is, and for the same reason**: a language
# may have one commission and not the other, and a group with nothing written
# is allowed. The eight `front*` keys, and the three other keys the new front
# draws — its two buttons and the word on a closed card.
#
# `must not` appears only where there is a known trap: the fluent, obvious
# rendering that says the wrong thing. First commissioned by
# `tools/strings/commissions/2026-09-24/`, whose sheets print these.
_NOTES = {
    "frontLead": {
        "seen": "The front page, `/`, directly under the heading (`tagline`). "
                "It is the whole of the page for a reader who goes no further "
                "than the first screen.",
        "must": [
            "Two phones touch, and each hands the other a seed.",
            "What grows is one plant that took both of them: neither person "
            "could have grown this plant alone.",
            "It opens over real days.",
        ],
        "must not": [
            "Read as *neither can grow anything alone*. The claim is about this "
            "plant needing both seeds, and a reader with a plant of their own "
            "already knows the other reading is false.",
        ],
        "note": "Two of its three claims are already in your `about1`: *two "
                "phones hand each other a seed* and *it opens over real days*. "
                "Use the same words for them here.",
    },
    "frontTurn": {
        "seen": "A small hint under the plant on the front page, which turns "
                "when somebody drags it with a finger or a mouse. Visual only: "
                "a screen reader skips it.",
        "must": [
            "Dragging the plant turns it.",
        ],
        "note": "The one instruction in this commission, and it is a hint on a "
                "control rather than a sentence. Use the form your language's "
                "interfaces use for such a hint — an infinitive or a short "
                "phrase is usual — and a verb for *drag* that covers a finger "
                "as well as a mouse.",
    },
    "frontMeet": {
        "seen": "The first of three steps on the front page, each a heading of "
                "one word under a glyph, read left to right as a sequence: "
                "*Meet*, *Cross*, *Grow*.",
        "must": ["Two people meet, in person."],
        "note": "The three are one form between them — three verbs, or three "
                "verbal nouns, whichever your language uses for the steps of a "
                "process. One word each where your language allows.",
    },
    "frontMeetBody": {
        "seen": "Under *Meet*.",
        "must": [
            "Two people touch their phones together.",
            "They are in the same place, physically together.",
        ],
        "note": "*In the same room* stands for being there together; your "
                "language's everyday way of saying *face to face* or *in the "
                "same place* is right if a room is too literal.",
    },
    "frontCross": {
        "seen": "The second step, under its glyph.",
        "must": ["The two seeds are crossed, as a gardener crosses two plants."],
        "must not": [
            "Be a word that means only crossing a road, or a cross as a shape. "
            "A word that holds the gardener's sense as well — *krydse*, "
            "*croiser* — is exactly right.",
        ],
        "note": "Your `growBody` already has the verb: *Peace Garden crosses "
                "this seed with one of your own*. Use it. Where your "
                "`areaMeeting` is the plant-cross word, the two will visibly "
                "belong together, which is right.",
    },
    "frontCrossBody": {
        "seen": "Under *Cross*.",
        "must": [
            "The exchange goes both ways: each person hands the other a seed.",
            "Then the two seeds are crossed.",
        ],
        "note": "*Hand each other a seed* is the phrase your `about1` already "
                "has. Agree with it.",
    },
    "frontGrow": {
        "seen": "The third step, under its glyph.",
        "must": ["A plant grows."],
    },
    "frontGrowBody": {
        "seen": "Under *Grow*.",
        "must": [
            "The plant is one neither of the two could have grown alone.",
            "It opens over real days.",
        ],
        "note": "It repeats the second sentence of `frontLead`, a screen "
                "further down. Word the two alike.",
    },
    "gardenTitle": {
        "seen": "The front page's second button and the heading over the ten "
                "cards. Also the name of the garden's glyph in the bar on every "
                "page, read aloud and shown on hover, and the heading of the "
                "small map at the foot of each area page.",
        "must": ["The garden: the place of ten areas that a reader can walk."],
        "note": "A name for the place, with the article your language gives a "
                "place it means as *the one*. The word for *garden* your "
                "catalogue already uses.",
    },
    "downloadTitle": {
        "seen": "The front page's first button, which opens `/download`, and "
                "that page's heading.",
        "must": ["The app — Peace Garden on the phone — as a thing, by name."],
        "must not": [
            "Be a command such as *Download* or *Get the app*. It is a heading.",
        ],
    },
    "notYet": {
        "seen": "On the card of each area that is still being built, on the "
                "front page, and beside the same areas' names in their entries "
                "at `/meanings`.",
        "must": ["This area opens later."],
        "note": "A plain statement of where things stand, matter-of-fact "
                "rather than apologetic. Keep the full stop.",
    },
    "meaningsTitle": {
        "seen": "The heading of `/meanings`, and the words of every link to it: "
                "the book glyph in the bar on every page (read aloud and shown "
                "on hover) and the headword on each area page.",
        "must": ["What the names of the plants mean."],
        "note": "A heading, so no full stop. In the app's languages the app's "
                "own button says *What the name means*, of one plant; the two "
                "should read as the same phrase in the singular and the plural.",
    },
    "meaningsAbout": {
        "seen": "The first paragraph of `/meanings`, above a worked example "
                "that takes one name apart piece by piece.",
        "must": [
            "A plant's name says where the plant belongs.",
            "The beginning of the name's first word chooses the area it "
            "stands in.",
            "The ending of that same first word chooses which of the area's "
            "three parts the words shown under the plant come from.",
        ],
        "must not": [
            "Suggest anybody chooses or gives the name. It is drawn from the "
            "seed.",
        ],
        "note": "*The words under it* are the quotation shown under a plant. "
                "*First word* is said plainly on purpose; the term *genus* "
                "arrives in the next paragraph.",
    },
    "meaningsSecond": {
        "seen": "The paragraph after the ten entries at `/meanings`, above "
                "the glossary of second words it introduces.",
        "must": [
            "The second word of the name names the one way this plant most "
            "differs from the rest of its genus.",
            "After a first word ending in -ynth, the second word takes its "
            "masculine form: rubra becomes ruber.",
        ],
        "note": "`-ynth`, `rubra` and `ruber` are Latin and copied exactly, "
                "letter for letter. *Genus* and *masculine form* are the "
                "ordinary botanical and grammatical terms in your language.",
    },
    "meaningsNames": {
        "seen": "A small label in each entry at `/meanings`, where a "
                "dictionary gives a word's etymology, leading straight into "
                "the name-starts that bring a plant to that area — *Nyx-*, "
                "*Fen-*, each with a drawing and its root.",
        "must": ["Names that begin with the syllables that follow."],
        "note": "It has to lead straight into a list of name-beginnings, so "
                "choose the grammar that runs into one.",
    },
}


# The ten entries. `must` is what the definition has to carry, half by half;
# `headword` is the trap in the theme's own word. The three parts each theme
# holds come from `commission.py`'s AREAS, printed under each.
ENTRIES = {
    "waiting": {
        "headword": "Waiting as a noun, the act of it. The word for waiting "
                    "rather than for hope or expectation.",
        "must": [
            "What is held back until its time comes, however long that is.",
            "And whoever keeps watch over it — a person standing by.",
        ],
    },
    "ground": {
        "headword": "Ground as earth. Where your language's word for it also "
                    "means *reason* or *floor*, pick the one a gardener means.",
        "must": [
            "The earth a plant stands in.",
            "And the earth that is yours — home ground, belonging.",
        ],
        "note": "*Yours* addresses the reader, informally. If your language "
                "has one word that is both soil and home, as Latin *colere* "
                "is both to till and to dwell, it is the headword.",
    },
    "beginnings": {
        "headword": "Beginnings, in whichever number your language speaks of "
                    "beginnings as a subject.",
        "must": [
            "The first thing a seed does — germination.",
            "And how much comes of it — small becoming large.",
        ],
    },
    "renewal": {
        "headword": "Renewal: coming again, being made new.",
        "must": [
            "What is cut back and grows again, in the gardener's sense.",
            "And what is mended — made whole after breaking.",
        ],
    },
    "travel": {
        "headword": "Travel as a noun: going, the journey.",
        "must": [
            "The ways a seed goes and the ways a person goes, both.",
            "And the pull of somewhere else — longing for a far place.",
        ],
        "must not": [
            "Make *pull* a physical pulling. It is the tug of elsewhere.",
        ],
    },
    "peace": {
        "headword": "Peace in the quiet, inward sense.",
        "must": [
            "The quiet a garden exists for.",
            "And the ease that comes with that quiet.",
        ],
    },
    "kinship": {
        "headword": "Kinship: belonging together as kin, by blood or by "
                    "choice.",
        "must": [
            "What grows together — grafts, roots and fungi joined.",
            "And the people kept rather than happened upon: chosen and held "
            "on to, set against chance.",
        ],
        "note": "*Kept rather than happened upon* is Marcus's reading of the "
                "Orchard. The contrast between keeping and chance is the point "
                "of the half; keep both sides of it.",
    },
    "pattern": {
        "headword": "Pattern as order in living things.",
        "must": [
            "The order in living things — spirals, tiling.",
            "And the names given to order — the words people have for it.",
        ],
        "must not": [
            "Be a sewing pattern, a template or a model to copy.",
        ],
    },
    "light": {
        "headword": "Light as a noun, as in sunlight.",
        "must": [
            "What a plant turns towards.",
            "And the day it keeps time by — a plant measures the length of "
            "the day.",
        ],
        "must not": [
            "Be *light* as in weight, or the light appearance in the app's "
            "settings.",
        ],
    },
    "meeting": {
        "headword": "Meeting: two coming together, the word your `tagline` "
                    "already uses for *a meeting*.",
        "must": [
            "Two coming together at the right moment.",
            "And what each owes the other — the obligations of host and guest, "
            "of flower and pollinator.",
        ],
        "must not": [
            "Be an appointment or a conference.",
        ],
    },
}


FRONT = {key: _NOTES[key] for key in [
    "frontLead", "frontTurn", "frontMeet", "frontMeetBody", "frontCross",
    "frontCrossBody", "frontGrow", "frontGrowBody",
    "downloadTitle", "gardenTitle", "notYet"]}


# The ten areas, in map order, and what each is a place for.
#
# **`thirds` is the load-bearing part.** An area name has to cover a whole
# theme, and the three subthemes are what that theme actually contains — the
# heaps its thirty passages fell into when they were read, in
# `docs/NAMES-AND-THEMES.md`. Two of the ten were renamed in English on
# 5 September precisely because the name carried one third and left two.
#
# `why` says what the English name is doing, so that a namer can tell whether
# their own language's word does the same work. It is not a gloss to translate.
AREAS = {
    "areaWaiting": {
        "theme": "waiting",
        "sense": "Being held back until the time is right — and standing and "
                 "watching while it is not.",
        "thirds": [
            "Held back — dormancy, stratification, marcescence",
            "The long count — Masada dates, Beal's bottles, bamboo mast years",
            "Standing and watching — patiens, abide, the gardener's shadow",
        ],
        "why": "A cold frame is where a plant is kept until it can go out. It "
               "is all three thirds at once: held back, for a long time, under "
               "somebody's eye.",
        "note": "**Cannot be translated, only renamed — and this is the one "
                "that looks safe.** The nearest word in your language is very "
                "likely a *forcing* device: Danish mistbænk and drivbænk, "
                "German Frühbeet, all of them for getting a plant going sooner "
                "than the season allows, often on the heat of manure. That is "
                "the opposite of this theme. English gets away with the name "
                "because an unheated cold frame is also where a plant is "
                "hardened off — held back in a halfway house until it can go "
                "out — and that use may not exist under the same word where "
                "you are. **Keep the holding, not the frame.** Marcus caught "
                "this in Danish on 6 September 2026, on the first language "
                "commissioned.",
        "renameable": True,
    },
    "areaGround": {
        "theme": "ground",
        "sense": "The soil itself, the place you are from, and a place "
                 "somebody keeps.",
        "thirds": [
            "The soil itself — rhizosphere, a teaspoon of earth, Darwin's worms",
            "A place you are from — querencia, Heimat, petrichor",
            "A kept place — pairidaeza, colere, garden as enclosure",
        ],
        "why": "**Renamed 5 September 2026.** It was *The Root Ground*, which "
               "carried the soil and left out the belonging — two of the three "
               "thirds. *Home ground* carries both: the earth, and the earth "
               "that is yours.",
        "note": "Most languages already have this phrase and it is what to "
                "reach for — terre natale, hjemstavn, tierra natal, родная "
                "земля. Latin *colere* means both to till and to dwell, which "
                "is the hinge the whole theme turns on; if your language has a "
                "word that does both jobs, it is the right one.",
    },
    "areaBeginnings": {
        "theme": "beginnings",
        "sense": "The first act, the small becoming large, and what a start "
                 "settles.",
        "thirds": [
            "The first act — germination, imbibition, radicle, meristem",
            "Small to large — the acorn, the coco de mer against orchid dust",
            "What a start settles — the Bramley pip, prime and primrose",
        ],
        "why": "The bed a seed is sown in. The plainest of the ten, and every "
               "gardening language has the thing.",
    },
    "areaRenewal": {
        "renameable": True,
        "theme": "renewal",
        "sense": "Cutting so that it grows back, the turning year, and being "
                 "made whole.",
        "thirds": [
            "Cut and come again — coppicing, epicormic buds, the Hiroshima ginkgos",
            "The turning year — If Winter comes, spring as water",
            "Made whole — kintsugi, resurgam, anastasis, convalesce",
        ],
        "why": "Coppicing is cutting a tree to the stool so that it grows back "
               "stronger. That is the first third exactly, and the rest of the "
               "theme by extension.",
        "note": "**Cannot be translated, only renamed — and look for the "
                "*stool* before you give up.** The obvious reach is your "
                "language's forestry word, taillis or Niederwald or "
                "stævningsskov, and that is a step too far: forestry is not "
                "gardening and this is a garden. Ask instead whether you have a "
                "word for the stool itself, the cut base a tree comes again "
                "from. Danish does — stub, giving Stubhaven, where this note "
                "previously offered stævningsskoven and was wrong to. A "
                "gardener who prunes hard knows the thing even where the "
                "woodland practice is unknown. **Where the stool word exists "
                "and will not compound, look at the tradition next door before "
                "you describe.** German has the stool — Stock, as in auf den "
                "Stock setzen — and it is also a storey and a walking stick, so "
                "the name went to Kopfweiden, the pollarded willows that stand "
                "along every northern field: a neighbouring practice that names "
                "the same act. Japanese has 株 and it will not stand alone as a "
                "place, so the name went to ひこばえ, the shoot that comes from "
                "the cut stump. Only if all of that is absent, name "
                "what happens there: cut, and it comes again. A description is "
                "acceptable here where it is not elsewhere, but it is the last "
                "answer rather than the second.",
    },
    "areaTravel": {
        "theme": "travel",
        "sense": "How a seed goes, the road, and the far off.",
        "thirds": [
            "How a seed goes — anemochory, sea beans, the dandelion's vortex",
            "The road — ad ripam, peregrinus, travel and travail",
            "Far off — Fernweh, tramontane, serendipity",
        ],
        "why": "A long walk is a real garden feature: the formal avenue you can "
               "see the end of and still have to walk. The one at Windsor is "
               "three miles.",
        "note": "Not a hike or a ramble. It is the garden's own avenue — grande "
                "allée, Lindenallee, paseo. This area is also the one that is "
                "built: `walkTitle` and `/walk` on the site are this place, so "
                "whatever it is called here is what a visitor walking it will "
                "see.",
    },
    "areaPeace": {
        "theme": "peace",
        "sense": "Quiet as a sound, the words for stopping, and being at ease.",
        "thirds": [
            "Quiet as a sound — psithurism, snow, the anechoic chamber",
            "The words for stopping — pax, serenus, quietus, sabbath",
            "At ease — hygge, sobremesa, shinrin-yoku",
        ],
        "why": "Plain on purpose. It is also the half of the app's own name "
               "that is not *garden*, so whatever your language uses for peace "
               "in that sense is likely to be right here too.",
    },
    "areaKinship": {
        "theme": "kinship",
        "sense": "Things grown together, the words for kin, and two people.",
        "thirds": [
            "Grown together — inosculation, grafting, lichen, mycorrhiza",
            "The words for it — sibb, God-sib, companion, kind and kin",
            "Two people — Donne, Montaigne, Hávamál, ubuntu",
        ],
        "why": "**An orchard is a family, and it names the theme three times "
               "over.** Every tree in it is a graft — two plants made one, "
               "which is the first third by meaning rather than by "
               "association. Every tree in it was *chosen* and put there, as "
               "kin and friends are kept rather than happened upon. And it "
               "bears, over years, which is what the keeping is for. Marcus's "
               "reading, 5 September 2026, and it is why the name was kept "
               "when it was questioned.",
        "note": "An orchard is not a wood. If your language distinguishes "
                "planted fruit trees from trees in general, that distinction is "
                "the whole point of the name.",
    },
    "areaPattern": {
        "renameable": True,
        "theme": "pattern",
        "sense": "The counted, the fitted-together, and order named.",
        "thirds": [
            "Counted — the golden angle, Fibonacci spirals, quincunx",
            "Fitted together — tessellation, decussate leaves, Turing patterns",
            "Order named — cosmos, rhythm, ordo, the anthology",
        ],
        "why": "A knot garden is low hedging laid out in an interlaced "
               "pattern: the theme drawn in box.",
        "note": "**Cannot be translated, only renamed.** A Tudor form. French "
                "reaches for *parterre de broderie*, which is its own tradition "
                "under its own name and is the right answer rather than a "
                "compromise. Use yours — giardino all'italiana, jardín de "
                "arrayanes, chahar bagh. **The tradition may be shared and the "
                "word still not be yours**: the fourfold garden runs from "
                "Andalusia to Delhi, and chahar bagh is Persian, so Arabic "
                "names the same garden الحديقة الرباعية. Where there is none, "
                "name the pattern rather than the hedge.",
    },
    "areaLight": {
        "theme": "light",
        "sense": "The edges of the day, reading the light, and light itself.",
        "thirds": [
            "The edges of the day — gloaming, alpenglow, apricity, gökotta",
            "Reading the light — photoperiodism, heliotropism, the day's eye",
            "Light itself — lux, solstice, phosphorus, the eight minutes",
        ],
        "why": "The one building in a garden that is made of light. Serre, "
               "Gewächshaus, drivhus — every gardening language has it.",
        "note": "The horticultural building, not a conservatory attached to a "
                "house.",
    },
    "areaMeeting": {
        "renameable": True,
        "theme": "meeting",
        "sense": "The moment, two that need each other, and the manners of it.",
        "thirds": [
            "The moment — kairos, clinamen, ichigo ichie",
            "Two that need each other — fig and wasp, yucca moth, Ophrys",
            "The manners of it — xenia, limen, interfulgence",
        ],
        "why": "Two senses in one word: where paths cross, and crossing two "
               "plants to make a third. It is what the app does, and this is "
               "the area the whole thing is named for.",
        "note": "**Cannot be translated, only renamed.** Croisement, cruce, "
                "incrocio and krydsning hold both senses. Japanese, Korean, "
                "Chinese, Arabic, Hebrew, Finnish, Hungarian and Basque have no "
                "single word for both — **keep the meeting.** A word that means "
                "only the horticultural cross is the wrong half; what happens "
                "here is two people. **Choosing is not the only way out of it, "
                "though.** Japanese was on that list and did not have to choose: "
                "出会いの辻 sets 出会い, the meeting, at a 辻, which is where "
                "paths cross. Where no one word holds the two, a short name that "
                "carries them side by side is better than half.",
    },
}


# The three parts of each theme, in the order the endings choose them.
#
# **Keys on the site since 24 September 2026**, when Marcus moved them into the
# catalogue: until then they were English data in `meanings.js`, and the app
# had them keyed from the start as `subtheme.<case>`. The site's key is the
# same case, `subtheme` + its name — one list, two catalogues, and in the app's
# languages the same words in both. `gloss` is what each third holds, for the
# translator; the examples come from `AREAS` below.
PARTS = {
    "waiting": [
        ("heldBack", "Dormancy: a seed or a bud held until its season."),
        ("theLongCount", "Very long waits: seeds that germinated after centuries."),
        ("standingAndWatching", "Patience: keeping watch while it happens."),
    ],
    "ground": [
        ("theSoilItself", "The soil, and what lives in it."),
        ("aPlaceYouAreFrom", "Home ground: belonging to a place."),
        ("aKeptPlace", "A garden as a place enclosed and tended."),
    ],
    "beginnings": [
        ("theFirstAct", "Germination: the first root a seed puts out."),
        ("smallToLarge", "The acorn and the oak: how much grows from how little."),
        ("whatAStartSettles", "What a beginning decides about everything after it."),
    ],
    "renewal": [
        ("cutAndComeAgain", "A plant cut back that grows again — a gardener's phrase in English."),
        ("theTurningYear", "The seasons coming round."),
        ("madeWhole", "Mending and healing: what was broken, made whole."),
    ],
    "travel": [
        ("howASeedGoes", "How seeds are carried, by wind and by water."),
        ("theRoad", "Journeys, and the people who make them."),
        ("farOff", "Distance, and the longing for somewhere else."),
    ],
    "peace": [
        ("quietAsASound", "Quiet as something heard: wind in trees, snow falling."),
        ("theWordsForStopping", "The words people have for rest and ceasing."),
        ("atEase", "Comfort: being at ease, with others and alone."),
    ],
    "kinship": [
        ("grownTogether", "Grafts, lichen, roots and fungi joined into one."),
        ("theWordsForIt", "The words people have for kin and companions."),
        ("twoPeople", "Friendship between two people."),
    ],
    "pattern": [
        ("counted", "Patterns that are numbers: spirals, the golden angle."),
        ("fittedTogether", "Shapes that tile and interlock."),
        ("orderNamed", "The words people have for order."),
    ],
    "light": [
        ("theEdgesOfTheDay", "Dawn and dusk."),
        ("readingTheLight", "How a plant senses light and turns to it."),
        ("lightItself", "Sunlight as a thing in itself."),
    ],
    "meeting": [
        ("theMoment", "The right moment: a meeting that happens when it should."),
        ("twoThatNeedEachOther", "A flower and its pollinator: two that live by each other."),
        ("theMannersOfIt", "Hospitality: how a guest is received."),
    ],
}


# What the names mean: the ten one-line meanings, which the area pages, the
# front page's cards and `/meanings` all set as a headword and a definition, and
# the four strings of `/meanings` itself (the four headings its two tables had
# went with the tables on 24 September), and the thirty part labels.
#
# **The ten are `Headword: definition.`, cut at the first colon** by
# `splitEntry` in `meanings.js` — `:` or the full-width `：` — so a line has one
# colon, straight after the headword. `check.py` holds them to that, and in the
# app's languages to the app's `theme.*` keys, which are the same two halves.
MEANINGS = {
    **{f"meaning{theme.capitalize()}": {
        "seen": "Under the area's drawing on its own page, on the area's "
                "card on the front page, and as the area's entry at "
                "`/meanings` — each time as a dictionary headword and its "
                "definition.",
        **ENTRIES[theme]}
       for theme in ENTRIES},
    **{key: _NOTES[key] for key in [
        "meaningsTitle", "meaningsAbout", "meaningsSecond",
        "meaningsNames"]},
    **{f"subtheme{key[0].upper()}{key[1:]}": {
        "seen": f"The {('first', 'second', 'third')[index]} numbered sense of "
                f"the entry for {theme.capitalize()}: under the definition on "
                "the area's own page, and at `/meanings` with the endings that "
                "choose it and the examples its passages were read into. The "
                f"app's name sheet lists the same label, as `subtheme.{key}`.",
        "must": [gloss],
        "note": "A label, not a sentence: sentence case, no full stop, one "
                "line on a phone. It names one third of the theme, so what "
                "these examples have in common is what it has to cover — "
                + AREAS[f"area{theme.capitalize()}"]["thirds"][index]
                .split(" — ", 1)[1] + ". Those stay in English on the page; the "
                "label is the part to write.",
    } for theme, parts in PARTS.items()
      for index, (key, gloss) in enumerate(parts)},
}



def english():
    """The six, the thirteen and the ten, as `strings.js` has them today."""
    source = SOURCE.read_text()
    body = source[source.index("export const EN"):source.index("export const KEYS")]
    found = {}
    for match in re.finditer(r'^  (\w+):\s*\n?\s*"((?:[^"\\]|\\.)*)",', body, re.M):
        # The escapes are undone and anything outside ASCII is kept as it is.
        # `.encode().decode("unicode_escape")` did the first and broke the
        # second, reading UTF-8 as Latin-1, and it went unnoticed because no
        # English string had a character past ASCII until `privacy6`'s dash.
        found[match.group(1)] = (match.group(2).encode("latin-1", "backslashreplace")
                                 .decode("unicode_escape"))
    return found


# What a reader of each language has corrected, as rules for the next job.
#
# **Written down because a reader's correction is a register, not a fix.** A
# native reader changes one sentence and means every sentence: Marcus, reading
# the Danish of the 24 September commission, corrected *mennesker* in three
# strings, and the next commission in Danish would write it again unless it is
# told. Every mode prints its language's lines, above the vocabulary.
REGISTER = {
    "da": [
        "**People are *folk* or *personer*, never *mennesker*.** Whichever "
        "reads naturally: *To personer rører telefonerne mod hinanden*, *de "
        "folk, man holder fast i*, *de veje som frø og folk tager*. Marcus, "
        "reading the Danish on 24 September 2026.",
    ],
}


def register(code):
    """This language's corrections, printed where the vocabulary is."""
    lines = REGISTER.get(code)
    if not lines:
        return
    print("**What a reader of this language has already corrected.** Rules, "
          "not examples:\n")
    for line in lines:
        print(f"- {line}")
    print()


def settled_words(theirs, source, code, wanted):
    """What this language has already said, printed so the next job agrees.

    Both commissions open with this, because both are constrained by it and
    neither can work it out from the English. `wanted` excludes whichever set is
    being written now — printing a translator their own blank keys as
    *already chosen* would be a lie, and printing them filled in would be
    telling them the answer.
    """
    have = {k: v for k, v in theirs.items()
            if k in wanted and isinstance(v, str) and v.strip()}
    register(code)
    if not have:
        return
    for key, value in have.items():
        print(f"- `{key}`\n    en  {source.get(key, '?')}\n    {code}  {value}")


def prose(catalogue, code, source):
    """The six paragraphs."""
    theirs = catalogue.get("strings", {})
    print(BRIEF.read_text())
    print("=" * 78)
    print(f"\n# {catalogue['language']} — {catalogue['endonym']}  ({code})\n")
    print(f"Write into `Server/strings/{code}.json`.\n")

    # The vocabulary first, because it constrains everything after it.
    print("## The words this language has already chosen\n")
    print("Commissioned and shipping. **The six you are about to write have to")
    print("agree with them.**\n")
    settled_words(theirs, source, code,
                  [k for k in source
                   if k not in CLAIMS and k not in AREAS and k not in PRIVACY])

    print("\n## The six\n")
    for key, claim in CLAIMS.items():
        print(f"### `{key}`\n")
        print(f"> {source[key]}\n")
        print(f"*Where it is seen.* {claim['seen']}\n")
        print("*It must say:*")
        for line in claim["must"]:
            print(f"  - {line}")
        print("\n*It must not:*")
        for line in claim["must not"]:
            print(f"  - {line}")
        if "note" in claim:
            print(f"\n*Note.* {claim['note']}")
        print()


def privacy(catalogue, code, source):
    """The eight strings on /privacy.

    Same brief as the six paragraphs — this is a translation, and the claims
    are the specification — so it prints `BRIEF.md` rather than a third one.
    What it does not share is the group: these arrive on their own.
    """
    theirs = catalogue.get("strings", {})
    print(BRIEF.read_text())
    print("=" * 78)
    print(f"\n# {catalogue['language']} — {catalogue['endonym']}  ({code})")
    print("# The privacy page\n")
    print(f"Write into `Server/strings/{code}.json`.\n")
    print("**Eight strings, and they are the most exact on the site.** A privacy")
    print("notice that overstates is worse than one that explains, so the")
    print("*must not* lines below matter more here than anywhere else — see")
    print("`privacy2` in particular, which is the one a reviewer asks about.\n")

    print("## The words this language has already chosen\n")
    settled_words(theirs, source, code, [k for k in source if k not in PRIVACY])

    print("\n## The eight\n")
    for key, claim in PRIVACY.items():
        print(f"### `{key}`\n")
        print(f"> {source[key]}\n")
        print(f"*Where it is seen.* {claim['seen']}\n")
        print("*It must say:*")
        for line in claim["must"]:
            print(f"  - {line}")
        print("\n*It must not:*")
        for line in claim["must not"]:
            print(f"  - {line}")
        if "note" in claim:
            print(f"\n*Note.* {claim['note']}")
        print()


def areas(catalogue, code, source):
    """The ten area names."""
    theirs = catalogue.get("strings", {})
    print(NAMING.read_text())
    print("=" * 78)
    print(f"\n# {catalogue['language']} — {catalogue['endonym']}  ({code})\n")
    print(f"Write into `Server/strings/{code}.json`.\n")

    print("## The words this language has already chosen\n")
    print("The site's own prose, commissioned and shipping. The ten names have")
    print("to sit beside these — chiefly whatever this language calls a *seed*")
    print("and a *garden*.\n")
    settled_words(theirs, source, code, [k for k in source if k not in AREAS])

    print("\n## The ten\n")
    print("In the order they are walked: the top row of the map left to right,")
    print("then the bottom row. Nothing about the map moves.\n")
    # Derived rather than written down, so the count in NAMING.md has something
    # to be checked against. It went from three to four the first time a
    # language was actually commissioned, and a hand-written number would not
    # have.
    hard = [k for k, a in AREAS.items() if a.get("renameable")]
    print(f"{len(hard)} of them cannot be translated at all, only renamed — "
          f"{', '.join(f'`{k}`' for k in hard)}.")
    print("Each says so under its own *Note*, with what to preserve.\n")
    for key, area in AREAS.items():
        print(f"### `{key}`\n")
        print(f"> {source[key]}\n")
        print(f"*The place.* {area['sense']}\n")
        print("*What the theme holds, in three:*")
        for line in area["thirds"]:
            print(f"  - {line}")
        print(f"\n*What the English name is doing.* {area['why']}")
        if "note" in area:
            print(f"\n*Note.* {area['note']}")
        print()


def main():
    argv = sys.argv[1:]
    mode = (areas if "--areas" in argv
            else privacy if "--privacy" in argv
            else prose)
    rest = [a for a in argv if not a.startswith("--")]
    if len(rest) != 1:
        sys.exit(f"usage: {sys.argv[0]} [--areas|--privacy] <language code>")
    code = rest[0]
    path = CATALOGUES / f"{code}.json"
    if not path.exists():
        sys.exit(f"no catalogue at {path.relative_to(ROOT)}")

    catalogue = json.loads(path.read_text())
    source = english()
    mode(catalogue, code, source)


if __name__ == "__main__":
    main()
