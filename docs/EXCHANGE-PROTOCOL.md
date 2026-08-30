# The exchange

Two people, two phones, one plant that neither of them could have grown alone.

This document covers how that works, and — first — why it does not work the way
you would expect.

## Why phones cannot actually exchange over NFC

The natural reading of "touch the tops of the phones together" is NFC. On
iPhone, an app cannot do that.

An iPhone's NFC radio, through Core NFC, reads and writes *tags*. It cannot open
a peer-to-peer link to another iPhone. The tap-to-share gestures people know
from iOS — sharing a contact by holding two phones together, AirDrop's
proximity handoff — are system features built on private frameworks, and there
is no API that lets a third-party app take part in them or imitate them.

So the tap is treated as **a gesture, not a transport**:

| What the tap does | How |
| --- | --- |
| Says "these two phones, deliberately, now" | Both accelerometers feel the knock |
| Carries the seeds between the phones | Multipeer Connectivity, over Bluetooth/Wi-Fi |

The feeling for the two people is the one described: hold the phones together,
tap, and the plants cross. What is underneath is a short-range radio link that
only proceeds once both phones have felt the knock within three seconds of each
other.

**A later refinement.** iPhones with a U1/U2 chip can measure the distance to
another such iPhone to within centimetres, through Nearby Interaction. Adding
that as a second gate — proceed only if the phones are also physically within a
few centimetres — would make a meeting impossible to fake from across a room.
It needs a discovery-token exchange over the link that already exists, so it
slots into the handshake below as one extra message. It is deliberately not in
this phase: it needs specific hardware on both sides and cannot be tested
without two such devices in the same room.

## What crosses the air

Only this, and only after both phones have been tapped:

- the 32-byte seed
- the display name the person chose
- the plant's name, so each phone can name what the other brought
- when the seed was first drawn, so each phone can show the other's plant at the
  right age
- 16 random bytes for this meeting

No account. No contacts. No location. No device identifier. Nothing to a server —
there is no server.

## The handshake

```
  A                                            B
  |-- advertise + browse (_pg-pollen._tcp) ---->|
  |<------------------ connect ---------------->|      encryption: required
  |                                             |
  |  (both people tap their phones together)    |
  |------------------ touch ------------------->|
  |<----------------- touch --------------------|      within 3s on each clock
  |                                             |
  |-- hello(seed, name, plant, birth, nonce) -->|
  |<- hello(seed, name, plant, birth, nonce) ---|
  |                                             |
  |     both compute the same child seed        |
  |                                             |
  |----------- confirm(checksum) -------------->|
  |<---------- confirm(checksum) ---------------|
  |                                             |
  |   checksums match -> the plant is shown     |
```

Either side may send `abort(reason)` at any point. A phone that receives a
message kind it does not recognise — from a future version — aborts rather than
guessing.

### Who invites whom

Both phones advertise and browse at the same time, so both would invite each
other and both connections would drop. Each phone generates a random token for
the session and puts it in its discovery info; the lower token invites, the
other accepts. Exactly one invitation, every time.

### Why the touch is not a timestamp comparison

The two phones have no shared clock, and comparing wall clocks across devices is
a good way to build something that fails at a daylight-saving boundary. Instead,
each phone records two moments *on its own clock*: when it felt its own tap, and
when the other phone's `touch` message arrived. If those are within three
seconds of each other, the tap was mutual. Neither phone ever reads the other's
clock.

## The derivation

Both phones must arrive at the same offspring seed independently. Every step is
domain-separated SHA-256 over length-prefixed inputs:

```
encounterID = H("peacegarden.encounter.v1", min(seedA,seedB), max(seedA,seedB),
                                            min(nonceA,nonceB), max(nonceA,nonceB))
childSeed   = H("peacegarden.cross.v1",     min(seedA,seedB), max(seedA,seedB), encounterID)
checksum    = H("peacegarden.checksum.v1",  childSeed)[0..8]
```

Sorting the seeds and the nonces is what makes this work: neither phone knows or
cares which of them started the exchange, and both compute the identical value.

Both nonces go in, so neither person can steer the result by choosing their own
nonce carefully, and meeting the same person again next week grows a different
plant rather than the same one twice.

The checksum is the safety catch. If the two phones disagree — different
versions, a corrupted message — they find out before either of them saves
anything, and the exchange is abandoned. Two people walking away believing they
have the same plant when they do not is the one failure this protocol will not
tolerate.

### Inheritance

The child seed alone would give a random plant unrelated to either parent. So
each trait is drawn by name, and the child's value for a trait is chosen from:

| | |
| --- | --- |
| 36% | the first parent's value |
| 36% | the second parent's value |
| 22% | a blend of the two |
| 6% | something neither parent had |

The parents are sorted by seed, so "first" and "second" mean the same thing on
both phones. A hybrid reads as descended from both plants — including its name,
which is drawn the same way and so is usually one parent's genus with the
other's epithet.

## Verifying all of this

`Packages/SeedCore/Tests/SeedCoreTests/` holds the derivation vectors, and
`tools/reference/derivation_reference.py` is an independent implementation of
the same spec in another language. The two agree byte for byte; if they ever
stop agreeing, one of them has drifted, and the vectors say which.
