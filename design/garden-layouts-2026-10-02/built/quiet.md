# The Quiet Garden, built: an asymmetric room

Option A of `RESEARCH.md` §*The Quiet Garden*, as Marcus chose it on 2 October
2026. Built on the layouts foundation (`tools/layouts/`).

## What was built

**The ten became one, five, three and one.** The table is
`tools/layouts/tables/quiet_room.py`, written to `PlaceTable.quietRoom` (Swift)
and `QuietRoomTable` (PHP and the page). Twelve places in fill order:

- **the specimen** by the bench, where it has stood since 21 September
  (group 0, at −1.95, −0.95);
- **a group of five** in the far corner, across the water: what the bench
  looks at (group 1). Two at the back, toward the corner, and three arms;
- **a group of three** along the side to the bench's left, a third of the way
  down it (group 2). One at the back, two arms, a scalene triangle;
- **the echo**, one plant alone across the lawn from the five (group 3);
- **the pool's two places** (group 4), along its length.

The groups ride in the old corners' numbers, so a slot is still `corner` and
`index` in the store, on the wire and in the replant: `five` is what `second`
was, `three` what `third` was, `echo` what `fourth` was. A group's places are
blue noise in a blob at the hedge's foot, listed nearest the corner first,
then farthest-first, and tagged back or arm.

**The rule** (`QuietGarden.Room.place`, ported to `QuietGarden::place`):

1. **Own colour**: the five, the three, then the echo, which shows the five's
   colour.
2. **A group nobody has planted**: the five, then the three. The echo is never
   opened on its own; it waits for the five's colour.
3. **A colour near its own**: a group whose colour is a tone of it, and the
   echo if the plant's colour is a tone of the five's.
4. A new room, opened by the specimen.

"Nothing stands in front of something shorter" is asked by stand rather than
by index: every back of a group is at least as tall as every arm, and the
five's two backs are free of each other, as are its arms. The cut stays 1.08.
A lily still goes to the pool and nowhere else. The live garden never sends
this area one, so the pool stays empty there.

**The pool** sits off the middle toward the bench: 2.1 m long and 1.2 m wide
(2.04 m²; the pool in the middle was 2.2 m across each way), longer across
the bench's line of sight than along it.
Its bay on the bench's side is where **three stepping stones** from the seat
arrive. The stones are new drawing: low flat ovals in `quietgarden.js`, page
only, with no structure in the app.

**Every room is turned and mirrored by its number**, eight ways (plot 0 is the
table as drawn). The bench is always in a corner, looking across the water at
the five; the three falls on either hand.

**The service sends the turned spot** (`QuietGarden::spotOn` in `RoomStore`).
`check_quiet_garden.php` compares each row's variant and spot with the
Swift's, exactly, and measures every dry plant against the pool as its room
lays it.

**The page** rebuilds the ground for each plot before its plants grow. It
draws:

- the pool from the table's outline, turned, with a bank, and the lawn walked
  round it (`floorAround`);
- the stones, and the bench turned with the room.

A mown stripe now stops at the water's own edge, in 6 cm pieces under the
pool's 10 cm lip; before, 13 cm pieces stopped at the lip and left a stepped
band of bare turf round the pool.

**The workbench draws only the area's own plants** (`pg_room_arrive`),
plumes and poppies, as the harness and the Cold Frame's workbench do. Before,
every crossing came, and the pool held lilies the live garden never sends.

| Measured on the table | |
|---|---|
| Nearest two of the five | 0.61 m (0.85 m in the old groups of three) |
| Nearest two of the three | 0.60 m |
| Nearest dry place to the water | 0.87 m before the nudge, 0.73 m after it at 500 |
| A plant's nudge | 0.13 m, unchanged |

## The fill, against the baseline

`layouts-harness --area quiet --against tools/layouts/baseline.json`:

| Arrivals | Plots | Places held | Held | Settled plots | Held in settled | Empty in settled |
|---|---|---|---|---|---|---|
| 10 | 2 | 11 of 20 | 55.0% | 0 | — | — |
| 100 | 11 | 101 of 110 | 91.8% | 9 | 98.9% (97.8%) | 1 (2) |
| 1,000 | 101 | 1001 of 1010 | 99.1% | 99 | 99.5% (99.7%) | 5 (3) |

**Plots and places held are the baseline's.** At 100 the settled rooms fill
better. **At 1,000 they hold two places fewer, 99.5% against 99.7%.** All five
empty places are backs of the five.

The five has two backs where a group of three had one, so it needs two tall
plants of its colour or a tone of it. The cut, 1.08, is the 67th centile of
all crossings, set for one back in three. Here three of the eight group places
are backs, and the area's own plants are plumes and poppies.

**The fix, offered and not applied:** cut at **1.04**, the 67th centile of
this area's own thousand, as the Cold Frame measures its cut on its own plants.
On the same stream that gives **100.0% in settled rooms at 100 and at 1,000,
with none empty**, and plots and places held unchanged. It changes a settled
number, so it is Marcus's call. It would mean re-recording the vectors.

**At ten arrivals room 0 holds six plants, not ten.** A room now has two
groups a colour can open, not three, so a third colour opens room 1 sooner;
room 1 holds five. Both counts are composed: room 0 has the specimen, three of
the five and two of the three. From a hundred arrivals on the rooms are the
baseline's in number.

## Renders

From `/dev/quiet` on a local server, headless, cropped to the plot. The
befores were drawn with the old layout on the area's own plants, so the same
plants stand in both:

- `quiet-before-10.jpg`, `quiet-after-10.jpg`: room 0 after ten arrivals;
- `quiet-before-full.jpg`, `quiet-after-full.jpg`: room 3 of 500, full;
- `quiet-before-three.jpg`, `quiet-after-three.jpg`: rooms 4, 5 and 6, laid
  identically before and three ways after.

## What a replant needs

**The Quiet Garden needs the replant.** Capacities are unchanged: ten on the
ground and two in the pool. But the rule changed, so plot assignment does too.
Replaying the 500 vector arrivals keeps the plot of 298 and the slot of 113.

The service works out each plant's position when it serves it, so a deploy
alone re-lays every room, but from stored slots chosen for groups of three:

- corner 1's three would stand in three of the five's places;
- corner 3's three would all stand on the echo's one place.

`tools/replant` needs nothing new: the slot's fields are still `corner` and
`index`, and the store has no new column.

## Left open

- **The cut**, above.
- **The echo is the five's own colour in 20 of 43 rooms** at 500, a tone of it
  in the rest. A tone can reach the echo before a plant of the five's own
  colour does. Keeping the echo for its own colour longer would cost fill.
- **In some turns the bench is in the near corner** with its back to the
  reader, behind the low hedge. That is the eight ways working.
- The stepping stones are drawn on the page only; the app has no structure for
  them.

## After Marcus's answers, 2 October 2026

**The cut is 1.04 m**, in `QuietGarden.backFrom` and `QuietGarden::BACK_FROM`,
the vectors re-recorded. On the harness's stream the settled rooms hold
**100.0% at 100 and at 1,000, none empty**, with 101 rooms and 99.1% held at
1,000, the baseline's. Re-recording moved 282 of the 500 vector rows' slots and
165 of their plots; the 500 now take 43 rooms (44 at 1.08), every one full. The
echo is the five's own colour in 22 of 43 rooms (20 at 1.08). Render:
`quiet-after2-full.jpg`, room 3 of 500.
