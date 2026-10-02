// The browser turns, mirrors and varies a plot as SeedCore does.
//
//   node tools/reference/check_plot_variant.mjs
//
// `Server/assets/js/variant.js` is a port of SeedCore's `PlotVariant`, for the
// page drawing a plot's ground the way its plants were placed: a ride, a pond,
// a bench, turned as the places were, here and in the neighbours seen through
// the gateways. `PlotVariantVectorTests` writes down what the Swift deals and
// draws; this deals and draws the same in JavaScript and fails on any
// difference. Nothing here has a tolerance: a variant is integers, and a turned
// place is the same two numbers with their signs changed.

import { readFile } from 'node:fs/promises';
import { plotVariant, areaSalt, applyVariant, undoVariant } from '../../Server/assets/js/variant.js';

const vectors = JSON.parse(await readFile(new URL('plot_variant_vectors.json', import.meta.url), 'utf8'));

let checks = 0;
const failures = [];
const fail = (line) => { if (failures.length < 8) failures.push(line); };

for (const [area, salt] of Object.entries(vectors.salts)) {
  checks++;
  if (areaSalt(area) !== salt) fail(`${area} salts to ${areaSalt(area)} here and ${salt} in SeedCore`);
}

for (const row of vectors.dealt) {
  const space = { turns: row.turns, mirror: row.mirror, nudges: row.nudges };
  row.plots.forEach(([turn, mirror, nudge], plot) => {
    checks++;
    const got = plotVariant(plot, row.area, space);
    if (got.turn !== turn || got.mirror !== (mirror === 1) || got.nudge !== nudge) {
      fail(`plot ${plot} of ${row.area} in ${JSON.stringify(space)}: SeedCore deals [${turn} ${mirror} ${nudge}], `
        + `the page [${got.turn} ${got.mirror ? 1 : 0} ${got.nudge}]`);
    }
  });
}

for (const row of vectors.spots) {
  const variant = { turn: row.turn, mirror: row.mirror, nudge: 0 };
  const [x, z] = applyVariant(variant, row.from[0], row.from[1]);
  checks++;
  if (x !== row.to[0] || z !== row.to[1]) {
    fail(`turn ${row.turn}${row.mirror ? ', mirrored,' : ''} takes ${row.from} to ${row.to} in SeedCore and ${[x, z]} here`);
  }
  const [bx, bz] = undoVariant(variant, x, z);
  checks++;
  if (bx !== row.from[0] || bz !== row.from[1]) fail(`turn ${row.turn}${row.mirror ? ', mirrored,' : ''} does not undo to ${row.from}`);
}

if (failures.length) {
  console.error("The browser and SeedCore disagree about how a plot varies:");
  for (const line of failures) console.error(`  ${line}`);
  console.error('\nRecord the Swift with PEACE_GARDEN_RECORD_VECTORS=1 swift test --filter PlotVariantVectorTests,'
    + '\nor fix Server/assets/js/variant.js to match it.');
  process.exit(1);
}

console.log(`The page deals ${vectors.dealt.length} spaces of ${vectors.dealt[0].plots.length} plots `
  + `and draws ${vectors.spots.length} places as the Swift does: ${checks} checks.`);
