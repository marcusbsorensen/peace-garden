# Seeds on the wind

*Can a phone hand the app to a phone that does not have it?*

The honest answer is in two halves.

**No, an app cannot fly from one iPhone to another.** There is no API for it and
no way around it. iOS installs apps from the App Store, from TestFlight (which is
itself an App Store app), from an MDM profile in a managed organisation, or —
in the EU only — from an approved alternative marketplace. Ad hoc distribution
needs each device's identifier baked into a provisioning profile in advance;
enterprise certificates are for an organisation's own staff and get revoked when
used to hand software to the public. Nothing in that list is "two strangers touch
phones in a park."

**But the seed can fly, and the receiving phone can grow it without ever opening
the App Store.** That is what this document is about, and it is most of what you
were describing anyway. A seed is 32 bytes. It travels in a link.

## What is built

`PollenLink` packs a seed, a nonce, a name and a birthday into a URL:

```
https://peacegarden.app/s#1.o.Ku7e0d-lNwWEMUuv…AAECAwQ….1700000000.TWFyY3Vz.…
```

The payload sits in the URL's **fragment** — the part after `#`. Fragments are
never sent to servers. If someone opens the link on a phone with no app, the
page they land on learns nothing about the seed; only the device does.

That link can travel by any means a person can think of:

- **A code on screen.** One phone shows a QR code, the other points its camera
  at it. Works on any iPhone, with nothing installed, no account, no network.
- **AirDrop**, from the share sheet — the closest thing to the gesture you
  described, and the natural one when two phones are already touching.
- **A message, an email, a printed card, a sticker on a lamp post.** A seed does
  not care how it got there.

### The offer and the reply

A meeting needs both seeds. When one person has no app, only one seed is in the
room, so it takes two passes:

```
  Marcus                                        a phone with no app
  |                                                       |
  |-- offer: my seed, my nonce ------------ QR / AirDrop ->|
  |                                                        |
  |                     draws a seed of its own            |
  |                     crosses the two, grows the plant   |
  |                                                        |
  |<----------------- reply: their seed, their nonce, ------|
  |                          my nonce echoed back,
  |                          the plant's checksum
  |
  |  grows the identical plant
```

The reply **echoes the offer's nonce back**. That is what makes it
self-contained: Marcus does not have to have kept a record of an offer he made
three weeks ago, or work out which of several a reply belongs to. Everything
needed is in the link.

The reply also carries the checksum of the plant the receiver grew. If the two
phones would end up with different plants, Marcus's phone refuses rather than
quietly growing a different one — the same guarantee the face-to-face exchange
gets from its confirm step.

Until the reply comes back, the plant exists only on the phone it landed on. A
seed carried on the wind does not report home.

## What an App Clip adds

An **App Clip** is a small piece of your app that Apple hosts and iOS downloads
on demand. Point a camera at a QR code, and a card slides up from the bottom of
the screen; tap it, and the clip is running seconds later. The person never
opens the App Store, never signs in, never chooses to install anything.

For this app that is very nearly the whole idea: the clip mints a seed, crosses
it with the one in the link, grows the plant, shows it turning on black, and
offers the reply code to send back. If they later install the full app, the
clip's data carries over through a shared app group, so the plant they grew is
already in their garden.

**What it costs to set up**, none of which can be done from here:

1. A domain you control — `peacegarden.app`, registered for this.
2. The `apple-app-site-association` file in `Server/` served from
   `https://peacegarden.app/.well-known/`, listing both the app and the clip.
   The rules iOS enforces, and how to check it, are in `Server/README.md`.
3. An App Clip target in the project, and an App Clip Experience registered in
   App Store Connect against the URL prefix.
4. Staying under Apple's App Clip size limit. It is small — in the low tens of
   megabytes uncompressed, and Apple has raised it over the years, so check the
   current figure. This app is mostly procedural geometry with no asset library,
   which is a good position to be in.
5. Being on the App Store. **This is the catch.** The clip is distributed *by*
   the App Store even though the person never visits it. "Without involving the
   App Store" is true for the person receiving the seed. It is not true for you
   as the publisher.

Before any of that exists, the same links still work — they just need the full
app installed to open. During development, TestFlight covers it.

## Why not NFC

The same reason the face-to-face exchange does not use it: an iPhone app cannot
open an NFC link to another iPhone. Core NFC reads and writes *tags*, and the
tap-to-share gestures in iOS are system features with no API. See
[EXCHANGE-PROTOCOL.md](EXCHANGE-PROTOCOL.md).

Writing a seed to a physical NFC sticker *is* possible, and is a lovely idea for
a fixed place — a sticker in a café, a tag on a bench, a seed that anyone who
passes can pick up. That is a phase 2 conversation, because a seed anyone can
take is a different social object from a seed handed to one person.

## What this costs in trust

The face-to-face exchange has a property this does not: both people were there.
A link can be forwarded, screenshotted, posted publicly. Anyone who has it can
grow a plant from that seed.

That is not a security failure — a seed is a public identity, like handing
someone a business card, and nothing about a person can be recovered from it.
But it does mean a link is a weaker claim about a meeting than a tap is. If the
peace garden ever shows how a plant came to be, it should be able to say which
of the two it was.
