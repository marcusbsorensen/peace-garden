// Sows a local copy of the plot service with a garden worth crawling.
//
//   node tools/masstest/site/seed.mjs http://127.0.0.1:8822 35 200
//
// LOCAL ONLY. It plants through `POST /api/walk/plant`, which a copy answers
// only when its `Server/.api/config.php` sets `open_for_planting`, and it
// refuses any base that is not loopback, so it cannot be pointed at the live
// site by accident.
//
// Each plant is a real crossing from the plant module (`pg_lineage`, and the
// Coppice's and Home Ground's lineages for their habits), named by the module
// (`pg_name`) and sent to the area its genus head belongs to, exactly as a
// phone does (`themeOf` in passages.js). The epithet goes as its kind, so the
// Seedbed's drills have something to claim. Areas fill to `perArea` each.
//
// The Wild Fields are sown from the command line through `WildStore`
// (seed-wild.php), as Server/README.md says to, because the release route is
// rate-limited to nine a window. Some plants get names, places and months
// beside them, in several scripts and at the longest the service takes, so the
// labels have something to wrap.
import { writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { engine } from './engine.mjs';
import { syllables, themeOf } from '../../../Server/assets/js/passages.js';

const [base = 'http://127.0.0.1:8822', perAreaArg = '35', wildArg = '200'] = process.argv.slice(2);
const host = new URL(base).hostname;
if (!['127.0.0.1', 'localhost', '::1', '[::1]'].includes(host)) {
  console.error(`seed.mjs plants only into a local copy; ${host} is not one.`);
  process.exit(2);
}
const perArea = Number(perAreaArg);
const wildCount = Number(wildArg);
const g = await engine();

const AREAS = ['beginnings', 'waiting', 'renewal', 'light', 'pattern', 'ground', 'travel', 'meeting', 'kinship', 'peace'];
const filled = Object.fromEntries(AREAS.map((a) => [a, 0]));
const tally = {};
const used = new Set();
let n = 0;
let sent = 0;
while (AREAS.some((a) => filled[a] < perArea) && n < 20000) {
  for (const kind of ['', 'coppice', 'ground']) {
    const lineage = g.lineage(n, kind);
    if (used.has(lineage.seed)) continue;
    used.add(lineage.seed);
    const named = g.name(lineage);
    if (!named) continue;
    const [genus, epithet = ''] = named.name.split(' ');
    const area = themeOf(syllables(genus).head);
    if (filled[area] >= perArea) continue;
    const body = { ...lineage, area, kind: epithet.toLowerCase().replace(/[^a-z]/g, '') };
    const response = await fetch(`${base}/api/walk/plant`, { method: 'POST', body: JSON.stringify(body) });
    tally[response.status] = (tally[response.status] ?? 0) + 1;
    if (response.status >= 400) {
      console.error(`plant ${n}/${kind || 'plain'} to ${area}: ${response.status} ${await response.text()}`);
      if (response.status === 403) process.exit(1);
      continue;
    }
    filled[area] += 1;
    sent += 1;
  }
  n += 1;
}
console.log(`Planted ${sent} into the ten areas: ${JSON.stringify(filled)}; statuses ${JSON.stringify(tally)}.`);

// The Wild Fields: plants the areas do not hold.
const NAMES = ['Marcus', 'Ane-Sofie Kristiansen', 'Ζωή', 'محمد عبد الرحمن', 'שרה', 'Иван', '美咲',
  'Siobhán Ní Bhriain', 'Bartholomew Featherstonehaugh-Cholmondeley Jr.', 'Józef', 'Þórunn', 'Kalaallit Nunaat Inuk'];
const PLACES = ['Margate', 'The long bench by the harbour wall at Broadstairs', 'København', 'القاهرة', 'ירושלים',
  'Reykjavík', '東京', 'Nuuk', 'Gdańsk', 'Ciudad de México, Coyoacán, junto a la fuente'];
const wild = [];
while (wild.length < wildCount && n < 40000) {
  const lineage = g.lineage(n, '');
  n += 1;
  if (used.has(lineage.seed)) continue;
  used.add(lineage.seed);
  const i = wild.length;
  const plant = { seed: lineage.seed, parents: lineage.parents };
  if (i % 3 === 0) {
    plant.shown = {
      a: { name: NAMES[i % NAMES.length], place: PLACES[i % PLACES.length], month: `2026-${String(1 + (i % 9)).padStart(2, '0')}` },
      b: { name: i % 2 ? NAMES[(i + 5) % NAMES.length] : null, place: PLACES[i % PLACES.length], month: `2026-${String(1 + (i % 9)).padStart(2, '0')}` },
    };
  }
  wild.push(plant);
}
const file = join(tmpdir(), `masstest-wild-${process.pid}.json`);
await writeFile(file, JSON.stringify(wild));
try {
  const out = execFileSync('php', [fileURLToPath(new URL('./seed-wild.php', import.meta.url)), file], { encoding: 'utf8' });
  process.stdout.write(out);
} finally {
  await import('node:fs/promises').then((fs) => fs.rm(file, { force: true }));
}
