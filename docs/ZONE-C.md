# Zone C

Zone C is the space-garden area in Peace Garden and the exchange of space seeds
that feeds it. What it is and why it is built this way is in
`design/space-seeds-2026-10-16/DESIGN.md`. This page only says where each piece
lives.

## Server

- `Server/.api/Aloft.php` holds the two pools.
- The pending route is in `Server/.api/router.php` (`POST /api/walk/pending`).
- The pools file is `../peacegarden-data/aloft.sqlite`, beside `public_html`.
  Its path is set in `Server/.api/settings.php`.

## App

- `App/PeaceGarden/ZoneC/` holds the store, the exchange, the finder, the
  returns and the slots.
- `ZoneCProductionKey.swift` in that folder is ignored by git. It is made by
  `tools/zonec/make_key.sh` and never committed.

## SeedCore

- `Packages/SeedCore/Sources/SeedCore/ZoneC/` holds the space flora.

## Tools and checks

- `tools/zonec/` holds `make_key.sh`, `check_make_key.sh` and the SQLite
  locking test (`locktest.sh`, `locktest.php`).
- `tools/reference/check_aloft_store.php` checks the pools file.
- `tools/reference/check_aloft.php` checks the route.
- `tools/reference/space_flora_reference.py` is an independent implementation
  of the space flora. `tools/reference/space_flora_vectors.json` holds the
  pinned vectors.
- `.github/workflows/tests.yml` runs these, and fails if a path containing
  `ZoneCProductionKey` is tracked or its ignore rule stops matching.
