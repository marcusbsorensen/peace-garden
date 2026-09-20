// The web walk's sky is SeedCore's sky.
//
//   node tools/reference/check_sky.mjs
//
// `tools/wasm/web/sky.js` is a port: a browser cannot run SeedCore, so the
// arithmetic that puts a star on the glass exists twice. A port drifts unless
// something holds it, which is the arrangement `check_long_walk.php` already
// has with the plot service's placing rule. `SkyVectorTests` writes down what
// the Swift sees; this checks the JavaScript sees the same thing, down to the
// last digit a double carries.
//
// **The last block is the one that matters.** It places the real catalogue at a
// fixed instant, from four places on the globe, onto a fixed screen, and holds
// a sample of where the stars landed. A port that decoded the catalogue half a
// byte out, flipped the sky, or rounded a magnitude fails there and nowhere
// else — each of those is invisible in a single trig call and obvious in a
// field of eight thousand stars.

import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import * as sky from '../wasm/web/sky.js';

const here = new URL('.', import.meta.url);
const vectors = JSON.parse(await readFile(new URL('sky_vectors.json', here), 'utf8'));
const catalogue = sky.decodeCatalogue(
  (await readFile(fileURLToPath(new URL('../wasm/web/stars.bin', here)))).buffer
);

let checks = 0;
let worst = { what: 'nothing', by: 0 };
const failures = [];

/** **Where a tolerance is honest and where it is not.**
 *
 *  The vectors carry seventeen significant digits, which is what a double
 *  round-trips in, so anything built out of `+ - * /` has to match to the last
 *  bit and does: a port that is right there is exactly right.
 *
 *  `sin`, `cos`, `asin`, `atan2` and `pow` are a different matter. They are
 *  library functions, and Darwin's libm and V8's are each correct to within
 *  about an ulp of the true value without being correct to the same bit as one
 *  another. Demanding equality of those would be demanding that two C
 *  libraries agree, which is not a property of this code and not one anybody
 *  can fix. So they get a tolerance, and each one is stated in the units of the
 *  thing it measures rather than as a bare epsilon. */
function same(what, got, want, tolerance = 0) {
  checks++;
  if (Number.isNaN(got) && Number.isNaN(want)) return;
  const by = Math.abs(got - want);
  if (by > worst.by) worst = { what, by };
  if (tolerance === 0 ? got === want : by <= tolerance) return;
  failures.push(`${what}\n    Swift: ${want}\n    JS:    ${got}`);
}

function sameTriple(what, got, want, tolerance = 0) {
  for (let i = 0; i < 3; i++) same(`${what}[${i}]`, got[i], want[i], tolerance);
}

/** A billionth of a degree. The catalogue is packed at twenty arcseconds and a
 *  star on screen is about a thousand arcseconds wide, so this is ten million
 *  times finer than anything that could show. */
const ANGLE = 1e-9;

/** A millionth of a pixel, which follows from ANGLE through the mapping. */
const PIXEL = 1e-6;

/** `pow` is the only library call in the radius. */
const POW = 1e-12;

// MARK: The two decisions about how the sky looks

same('faintest', sky.FAINTEST, vectors.faintest);
same('fieldOfView', sky.FIELD_OF_VIEW, vectors.fieldOfView);
same('catalogue count', catalogue.length, vectors.catalogueCount);

// MARK: The sky's own clock

for (const v of vectors.siderealTime) {
  same(
    `sidereal time at ${v.at} for longitude ${v.longitude}`,
    sky.siderealTime(new Date(v.at * 1000), v.longitude),
    v.sidereal
  );
}

// MARK: Where a star stands

for (const v of vectors.horizon) {
  const got = sky.horizon(v.ra, v.dec, v.sidereal, v.latitude);
  const where = `RA ${v.ra} dec ${v.dec} at sidereal ${v.sidereal}, latitude ${v.latitude}`;
  same(`${where} — altitude`, got.altitude, v.altitude, ANGLE);
  same(`${where} — azimuth`, got.azimuth, v.azimuth, ANGLE);
}

// MARK: How a star is drawn

for (const v of vectors.brightness) {
  same(`radius of magnitude ${v.magnitude}`, sky.radiusOfMagnitude(v.magnitude), v.radius, POW);
  // No library call in this one, so it is exact.
  same(`alpha of magnitude ${v.magnitude}`, sky.alphaOfMagnitude(v.magnitude), v.alpha);
}

for (const v of vectors.tint) {
  sameTriple(`tint of B−V ${v.colourIndex}`, sky.tintOfColourIndex(v.colourIndex), v.tint);
}

// MARK: The whole field

for (const field of vectors.field) {
  const place = { latitude: field.latitude, longitude: field.longitude };
  const placed = sky.placeStars(catalogue, { width: field.width, height: field.height },
                                place, new Date(field.at * 1000));
  same(`${field.zone}: how many stars are on the glass`, placed.length, field.drawn);

  // The sample is every `every`-th star of the Swift's own placed list, so the
  // indices line up only when the two lists are the same list.
  field.sample.forEach((want, n) => {
    const got = placed[n * field.every];
    const where = `${field.zone}, star ${want.star}`;
    if (!got) {
      checks++;
      failures.push(`${where} is missing from the JavaScript field`);
      return;
    }
    same(`${where} — x`, got.x, want.x, PIXEL);
    same(`${where} — y`, got.y, want.y, PIXEL);
    same(`${where} — radius`, got.radius, want.radius, POW);
    same(`${where} — alpha`, got.alpha, want.alpha);
    sameTriple(`${where} — tint`, got.tint, want.tint);
  });
}

// MARK: Keeping off the words

// Not in the vectors, because nothing in Swift draws this the same way — the
// app's version is `GardenSky.dimming` and it is held by `StarFieldTests`.
// What both have to be is the same shape: nothing inside, everything well
// away, and no hard edge anywhere.
const words = { x: 100, y: 100, width: 120, height: 30 };
checks++;
if (sky.dimming(150, 110, words) !== 0) failures.push('a star inside the words is not dimmed away');
checks++;
if (sky.dimming(300, 400, words) !== 1) failures.push('a star far from the words is dimmed');
checks++;
if (!(sky.dimming(150, 96, words) > 0 && sky.dimming(150, 96, words) < 1)) {
  failures.push('the edge of the words is hard — that draws a straight line by leaving stars out');
}
checks++;
if (!(sky.dimming(150, 90, words) > sky.dimming(150, 96, words))) {
  failures.push('the fade does not grow with distance');
}

// MARK: The word

if (failures.length === 0) {
  console.log(`The browser's sky is SeedCore's sky: ${checks} checks.`);
  console.log(`  the furthest the two ever drift: ${worst.by.toExponential(2)} — ${worst.what}`);
  process.exit(0);
}
console.error(`The two skies have drifted apart: ${failures.length} of ${checks} checks failed.\n`);
for (const failure of failures.slice(0, 12)) console.error('  ' + failure);
if (failures.length > 12) console.error(`  …and ${failures.length - 12} more.`);
console.error('\nBoth come from the same arithmetic. Fix tools/wasm/web/sky.js to match Sky.swift.');
process.exit(1);
