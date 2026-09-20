// The real sky, in a browser, behind the Long Walk.
//
// **A port, and held to its original.** Every number here comes from
// `Packages/SeedCore/Sources/SeedCore/Sky/Sky.swift` and
// `App/PeaceGarden/Rendering/StarField.swift`, and
// `tools/reference/check_sky.mjs` holds this file to vectors the Swift
// produced — the same arrangement `check_long_walk.php` has with the placing
// rule. A second sky that could drift from the first would be two skies, and
// the point of this one is that somebody walking the garden in a browser and
// somebody holding the app are under the same stars.
//
// **Both halves of it.** The plot floats: there is no ground under it, so the
// whole celestial sphere is drawn, and the half below the horizon is not a
// leftover. Those are the stars somebody on the other side of the world is
// looking up at while this person looks down at them.
//
// **It asks for nothing.** Where the browser is comes from its time zone,
// which it was keeping before this page loaded. See `docs/PLACE.md`.

// MARK: The sky's own clock

/** Greenwich mean sidereal time, in degrees. The IAU series, minus the terms
 *  too small to reach a pixel. */
export function greenwichSiderealTime(date) {
  const julian = date.getTime() / 86400000 + 2440587.5;
  const since2000 = julian - 2451545.0;
  const centuries = since2000 / 36525;
  return wrapped(
    280.46061837 + 360.98564736629 * since2000 + 0.000387933 * centuries * centuries
  );
}

export function siderealTime(date, longitude) {
  return wrapped(greenwichSiderealTime(date) + longitude);
}

// MARK: Where a star stands

/** Altitude in degrees above the horizon — **negative below it, and kept** —
 *  and azimuth in degrees clockwise from north, as a compass reads. */
export function horizon(rightAscension, declination, sidereal, latitude) {
  const hourAngle = radians(wrapped(sidereal - rightAscension));
  const dec = radians(declination);
  const lat = radians(latitude);

  const sinAltitude = Math.sin(dec) * Math.sin(lat) + Math.cos(dec) * Math.cos(lat) * Math.cos(hourAngle);
  const altitude = Math.asin(Math.max(-1, Math.min(1, sinAltitude)));

  const azimuth = Math.atan2(
    -Math.cos(dec) * Math.sin(hourAngle),
    Math.sin(dec) * Math.cos(lat) - Math.cos(dec) * Math.sin(lat) * Math.cos(hourAngle)
  );
  return { altitude: degrees(altitude), azimuth: wrapped(degrees(azimuth)) };
}

/** Towards the equator: south from the north, north from the south. That is
 *  where the sun, the moon and every planet pass. */
export function facing(latitude) {
  return latitude < 0 ? 0 : 180;
}

export function offset(from, to) {
  let difference = wrapped(to - from);
  if (difference > 180) difference -= 360;
  return difference;
}

function wrapped(deg) {
  const turn = deg % 360;
  return turn < 0 ? turn + 360 : turn;
}

const radians = (deg) => (deg * Math.PI) / 180;
const degrees = (rad) => (rad * 180) / Math.PI;

// MARK: The catalogue

const MAGIC = 'PGSKY1';

/** The Yale Bright Star Catalogue as `tools/sky/pack.py` wrote it: six bytes a
 *  star, brightest first. */
export function decodeCatalogue(buffer) {
  const bytes = new Uint8Array(buffer);
  if (bytes.length < 10) throw new Error('not a catalogue');
  for (let i = 0; i < MAGIC.length; i++) {
    if (bytes[i] !== MAGIC.charCodeAt(i)) throw new Error('not a catalogue');
  }
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const count = view.getUint32(6, true);
  if (bytes.length < 10 + count * 6) throw new Error('the catalogue is cut short');

  const stars = new Array(count);
  for (let index = 0; index < count; index++) {
    const at = 10 + index * 6;
    stars[index] = {
      rightAscension: (view.getUint16(at, true) / 65536) * 360,
      declination: (view.getInt16(at + 2, true) / 32767) * 90,
      magnitude: bytes[at + 4] / 16 - 2,
      colourIndex: view.getInt8(at + 5) / 50,
    };
  }
  return stars;
}

// MARK: Where the browser is

/** How faint a star has to be before it is left out: a dark country sky. */
export const FAINTEST = 6.0;

/** How much of the sky is across the page — a little over half a turn, so the
 *  sky spills past both edges rather than ending at them. Altitude is not
 *  scaled to match: all hundred and eighty degrees from zenith to nadir are
 *  always on screen. */
export const FIELD_OF_VIEW = 220.0;

/** Where somebody keeping this time is, from the zone table and nothing else.
 *
 *  The fallback is the equator, with a longitude from the zone's **standard**
 *  offset — fifteen degrees to the hour. Using the offset in force would swing
 *  the sky by fifteen degrees every spring, and daylight saving is a fact about
 *  clocks rather than about where anybody is. */
export function placeOf(zones, zone, date = new Date()) {
  const known = zones[zone];
  if (known) return { latitude: known[0], longitude: known[1] };

  const year = date.getUTCFullYear();
  const january = new Date(Date.UTC(year, 0, 1)).getTimezoneOffset();
  const july = new Date(Date.UTC(year, 6, 1)).getTimezoneOffset();
  // getTimezoneOffset is minutes *behind* UTC, so daylight saving lowers it and
  // the larger of the two is standard time.
  const standard = Math.max(january, july);
  return { latitude: 0, longitude: -standard / 4 };
}

export function thisBrowsersZone() {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || '';
  } catch {
    return '';
  }
}

// MARK: How a star is drawn

/** Brightness is a ratio, not a number of pixels: each magnitude is two and a
 *  half times the light of the next, so this is flattened hard. */
export function radiusOfMagnitude(magnitude) {
  const brightness = Math.max(0, FAINTEST - magnitude);
  return 0.32 + Math.pow(brightness, 1.45) * 0.24;
}

export function alphaOfMagnitude(magnitude) {
  const brightness = Math.max(0, FAINTEST - magnitude);
  return Math.min(1, 0.16 + brightness * 0.16);
}

/** A star's colour from B−V, held well short of what the numbers would give:
 *  starlight at this size is almost white, and a sky of frank blue and orange
 *  dots is a chart of star types rather than a sky. */
export function tintOfColourIndex(index) {
  const warmth = Math.max(-0.4, Math.min(1.9, index));
  if (warmth <= 0) {
    const t = Math.min(1, -warmth / 0.4);
    return [1 - 0.1 * t, 1 - 0.04 * t, 1];
  }
  const t = Math.min(1, warmth / 1.9);
  return [1, 1 - 0.13 * t, 1 - 0.28 * t];
}

/** Every star on the glass, for this moment, this size and this place. */
export function placeStars(catalogue, { width, height }, place, date) {
  const sidereal = siderealTime(date, place.longitude);
  const towards = facing(place.latitude);
  const placed = [];

  for (const star of catalogue) {
    if (star.magnitude > FAINTEST) continue;
    const { altitude, azimuth } = horizon(
      star.rightAscension, star.declination, sidereal, place.latitude
    );
    const across = offset(towards, azimuth);
    if (Math.abs(across) > FIELD_OF_VIEW / 2) continue;

    placed.push({
      x: width * (0.5 + across / FIELD_OF_VIEW),
      // Zenith at the top, nadir at the foot, the horizon across the middle
      // where the plot floats.
      y: height * (0.5 - altitude / 180),
      radius: radiusOfMagnitude(star.magnitude),
      alpha: alphaOfMagnitude(star.magnitude),
      tint: tintOfColourIndex(star.colourIndex),
    });
  }
  return placed;
}

// MARK: Keeping off the words

/** How much of a star survives near a box of words: nothing inside it, all of
 *  it well away, and a gradient between.
 *
 *  **Not a hard edge.** Leaving stars out of a rectangle draws the rectangle —
 *  a straight line made by absence, which is the one thing this garden does not
 *  have. The sun and the moon move aside instead; a constellation cannot, so it
 *  dims. */
export const FADE = 14;

export function dimming(x, y, box) {
  if (!box || box.width <= 0 || box.height <= 0) return 1;
  const left = box.x, top = box.y;
  const right = box.x + box.width, bottom = box.y + box.height;
  if (x < left - FADE || x > right + FADE || y < top - FADE || y > bottom + FADE) return 1;
  if (x >= left && x <= right && y >= top && y <= bottom) return 0;

  const dx = Math.max(left - x, x - right, 0);
  const dy = Math.max(top - y, y - bottom, 0);
  return Math.min(1, Math.hypot(dx, dy) / FADE);
}

// MARK: The sky on the page

/**
 * Draws the field onto a 2-D canvas and keeps it turning.
 *
 * A minute at a time, because the sky turns a quarter of a degree in one and
 * that is a fifth of a pixel. `keepClear` is asked for the boxes the page's own
 * words are in, each in CSS pixels, every time it redraws.
 */
export async function makeSky(canvas, { keepClear = () => [], now = () => new Date() } = {}) {
  const here = new URL('.', import.meta.url);
  const [catalogue, zones] = await Promise.all([
    fetch(new URL('stars.bin', here)).then((r) => r.arrayBuffer()).then(decodeCatalogue),
    fetch(new URL('places.json', here)).then((r) => r.json()),
  ]);

  const context = canvas.getContext('2d');
  let timer = null;

  const draw = () => {
    const ratio = window.devicePixelRatio || 1;
    const width = canvas.clientWidth, height = canvas.clientHeight;
    if (!width || !height) return;
    canvas.width = Math.round(width * ratio);
    canvas.height = Math.round(height * ratio);
    context.setTransform(ratio, 0, 0, ratio, 0, 0);
    context.clearRect(0, 0, width, height);

    const date = now();
    const place = placeOf(zones, thisBrowsersZone(), date);
    const boxes = keepClear();

    for (const star of placeStars(catalogue, { width, height }, place, date)) {
      let alpha = star.alpha;
      for (const box of boxes) {
        alpha *= dimming(star.x, star.y, box);
        if (alpha <= 0.004) break;
      }
      if (alpha <= 0.004) continue;
      const [r, g, b] = star.tint;
      context.fillStyle = `rgb(${Math.round(r * 255)} ${Math.round(g * 255)} ${Math.round(b * 255)} / ${alpha})`;
      context.beginPath();
      context.arc(star.x, star.y, star.radius, 0, Math.PI * 2);
      context.fill();
    }
  };

  draw();
  timer = setInterval(draw, 60000);
  window.addEventListener('resize', draw);

  return { draw, stop: () => { clearInterval(timer); window.removeEventListener('resize', draw); } };
}
