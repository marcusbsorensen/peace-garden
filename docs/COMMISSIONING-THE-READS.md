# Getting the forty-one languages read

Everything on peacegarden.app has been translated by machine and named by a
namer. **One language has been read by somebody who speaks it.** This is how the
other forty-one get read: where to find the readers, what it costs, and what to
send them.

The packets are already written. `out/review/INDEX.md` lists forty-three, one
per language, each the whole of `docs/REVIEWING-A-LANGUAGE.md` plus that
language's six live links. They are sendable as they stand.

## What is actually being bought

Fifteen minutes of judgement from one native speaker per language, against six
screens. Not proofreading — `check.py` already does the mechanical half, and
grammar is the thing machine translation gets right. What cannot be automated is
the three questions in §2 of the guide: is it true, does it sound like a person,
would you send it to a friend.

**The ten area names are the part nobody has ever seen.** The prose has at least
been through a brief that specifies what each sentence must mean. The names were
chosen by a namer working from a description of a garden, and forty of the
forty-one sets are guesses that survived a checker.

## What is where

| | |
| --- | --- |
| **42 languages** | with prose, names and a passage bank — every one but Greenlandic |
| **1 confirmed** | Danish, all ten names, by Marcus |
| **41 to place** | Danish needs only its prose; the other forty need everything |
| **Greenlandic** | has neither prose nor names and shows English throughout. It needs a *namer* before it needs a reader — see `tools/strings/commission.py --areas kl` |

## Where the readers come from

**Not Mechanical Turk.** It pays per task, which rewards speed over judgement;
its text work is widely routed through machine translation or an LLM, which
would mean paying to have machine translation checked by machine translation on
a brief whose first line is *you are the part that cannot be automated*; and its
pool is thin to absent for a third of this list.

**Prolific for the bulk.** It prescreens on first language rather than
self-report, pays hourly, and is built for free-text answers rather than
piecework. Set one study per language, or one study with a language prescreen
and a per-participant packet link.

- **Sample size 1 per language.** This is not a survey. A second reader is worth
  buying only where the first one disagrees with the brief.
- **Time estimate 15 minutes**, and pay it honestly — the guide says fifteen and
  a short-changed reader does the five-minute version.
- **Screen on first language, not fluency.** The whole question is what a
  sentence sounds like to somebody who grew up in it.
- **Check the current fee and minimum hourly rate when you post.** Both have
  moved before and neither is worth quoting here.

**The small languages will not fill on any panel.** Welsh, Irish, Basque,
Galician, Maltese, Icelandic, Albanian, Macedonian, Kalaallisut — for these, one
translator on ProZ or a small agency for a single fifteen-minute read is likely
cheaper than the panel batches that fail to recruit, and much faster than
waiting. Ask for a read, not a translation, and send the packet unchanged.

**And ask around first.** Forty-one is a lot of studies to run for a job where
one good reader per language is the whole requirement, and several of these are
languages somebody you know speaks. A friend who reads Dutch is worth more than
a stranger who is being paid to hurry.

## What to send

The packet, and nothing else. It opens by explaining the app in two sentences
and it ends by saying how to send comments back. Adding a covering note that
explains the app again is how a fifteen-minute job becomes a twenty-five-minute
one.

If you want one line above it:

> This is a website in forty-two languages, translated by machine. Yours has
> never been read by anybody who speaks it. Fifteen minutes, and the questions
> are in the note — say "this is fine" wherever it is fine, which is genuinely
> useful to know.

## What comes back, and what to do with it

Three kinds, and they are different jobs:

- **A sentence that says the wrong thing.** The most valuable, and the reason
  §3 lists what each sentence has to mean. Fix the catalogue and redeploy.
- **An area name a gardener would not use.** Fix `Server/strings/<code>.json`,
  run `check.py`, and **write down why in the commit** — four of the five
  corrections `NAMING.md` carries came out of exactly this.
- **A passage that is wrong or wrongly attributed.** A different job, and it
  belongs to whoever holds the banks rather than to this pass.

**Record it in the catalogue.** A read language carries a `read` note beside
`language` and `endonym` — who, when, and what they actually read, since a
reader may cover the names and not the prose:

```json
"read": { "by": "Ingrid", "on": "2026-09-14", "what": "all six screens" },
```

`check.py` counts them and prints the number on every run, under everything
else, because it is the one line in that output a machine cannot improve:

```
1 of 42 have been read by somebody who speaks the language.
```
