# Zone C: the English wording

Package W1, 17 October 2026. This is the exact English to read before any translation. Voice: British English, short sentences, each thing said as what it is and does. Settings text is a plain label and one short line; the reasoning sits on the privacy page and in About.

Nothing here is translated yet. `privacy7` and `privacy11` are already in `Server/assets/js/strings.js`. The rest is a draft, and the app's Swift is not touched by W1 (A5 writes it).

## 1. `privacy7`: the asking

*Lives in:* `Server/assets/js/strings.js`, shown on `/privacy` (`Server/.pages/privacy`), sixth paragraph.

**Old**

> With alerts on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings.

**New**

> With news from the garden on, each time the app starts it asks the web garden about your shared plants, by sending the random numbers from your meetings. It asks whether or not you have met anyone. Each request also sends up one random-looking value and one random-looking reply, and the answer brings back a handful of each.

Note: "With news from the garden on" names the relabelled switch in section 3 by what it does, and replaces "With alerts on".

## 2. `privacy11`: what the pools keep

*Lives in:* `Server/assets/js/strings.js`, shown on `/privacy` straight after `privacy7`. New. It names Autonaut once, plainly.

> The web garden keeps the random-looking values it receives in two pools, one of 64-byte values and one of 104-byte values. Each is kept alone, with no time, address or order. A value stays until newer ones push it out. The pools are in no backup. A reply opens only on the phone that sent its seed. Seeds from Autonaut travel this way too. To the web garden, every value is random numbers.

## 3. The switch: label and note (draft)

*Lives in:* the app's Settings, the row now labelled "Alert me when a joint seed is shared" (`Views/SettingsView.swift`, written by A5; translated by T1). The stored key `sharing.invitations.v1` stays, so no one's choice moves.

**Old**

> Alert me when a joint seed is shared
> A plant you both share goes to the web garden without your username.

**Draft**

> Ask the garden for news when it opens
> The app asks the web garden each time it starts.

Other lines for the note, if that one is wrong:

- "News about your shared plants arrives when the app starts."
- "Each time the app starts, it asks the web garden what is new."

I keep the first draft: it says when and to whom, and `privacy7` says the rest. The old note's line about the username moves to the privacy page, where `privacy6` already says no name goes with a shared plant.

## 4. The About paragraph (draft)

*Lives in:* the app's About sheet, Privacy section, after the paragraph on a logged place (`Views/AboutView.swift`, written by A5; translated by T1). Set in the same quiet type as the others.

> Each time the app starts, it asks the web garden for news. The request carries two random-looking values, and the answer brings back a handful of each. Seeds that reach you from Autonaut, and the plants they grow, are kept with your garden in your phone's backups.

## 5. Optional: the Zone C row (draft)

*Lives in:* Settings, a second row shown only while Autonaut is on the phone, off by default (DESIGN.md §7 item 16; A5). Turning it on is the consent. A5's brief does not give its wording, so this is offered for you to change.

> Zone C
> Seeds can pass between this app and Autonaut.

## 6. Where each string lives

| String | File | Seen | Written by | Translated by |
|---|---|---|---|---|
| `privacy7` | `Server/assets/js/strings.js` | `/privacy` | W1 (done) | W2 |
| `privacy11` | `Server/assets/js/strings.js` | `/privacy` | W1 (done) | W2 |
| Switch label and note | `SettingsView.swift` | Settings | A5 | T1 |
| About paragraph | `AboutView.swift` | About | A5 | T1 |
| Zone C row | `SettingsView.swift` | Settings | A5 | T1 |
