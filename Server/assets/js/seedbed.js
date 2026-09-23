// A plot of the Seedbed, drawn the way the app draws a plot: a floating slab of
// ground seen in true isometric, a bed of fine tilth over it, six shallow drills
// raked across it, a wooden label at the head of each, and the plants standing
// along the drills in the order they were sown.
//
// **It is a nursery bed, so the page shows one plot.** The Long Walk draws three
// end to end because a walk is a length you look down. A bed is not: it is a
// rectangle you stand at the end of and read across, and two of them end to end
// read as one bed with a seam in it.
//
// **A drill has to read as a line, and that is the whole drawing.** The rule
// already does its half — `Seedbed.Planting.nudge` is the only nudge in the
// garden that differs by direction, 0.035 m across a drill against 0.06 m along
// it, because a line survives being uneven along its length and not across it.
// This file does the other half: the soil is darker in the bottom of each drill
// and paler on the crest between two, so there is a line under the plants
// whether the drill holds eight of them or one.
//
// **The tilth is the Knot's gravel problem again, at a finer grain.** A square
// lattice of flat-toned faces draws a tiled floor however small the cells are,
// because the grid is the only thing in the picture that repeats exactly. So the
// lattice is jittered before anything is drawn and the diagonal each cell splits
// on turns with the same noise, and the tone is per face rather than per corner
// — soil is crumbs, not a surface. See `knot.js` §The ground, where that was
// found out. What differs here is the contrast: a chipping catches the light and
// a crumb of earth does not, so the spread of tones is half the gravel's.
//
// The rule that decides where each plant stands is SeedCore's `Seedbed`, through
// the module — this file draws the ground and the labels and puts each plant on
// the spot the service gives it. The plot's own numbers come from
// `pg_seedbed_plan` rather than being written down again here.

import { decode, takeResult } from './plant.js';
import { COLOUR, RIM_DEPTH, SIDE, hash, readOutline, readStructure } from './longwalk.js';

// Seeds for this area's dressing, so a bed is the same shape on every visit.
// Its own, not the walk's, the room's, the crossing's, the orchard's or the
// knot's: six areas drawing from one seed would be six plots with the same
// wandering edge, which is the sort of thing an eye catches without being able
// to say why.
const SEEDBED = { ground: 8837, floor: 29, crumb: 47, drift: 101, furrow: 211, label: 977 };

/// The wood a row label is cut from, and it is not the bench's.
///
/// **A label stands almost edge-on to this sun and gets nothing from it.**
/// `Organic.rowLabel` leans its tongue back 22° so it catches the sky, which it
/// does — but the sky here is a third of the light and the sun is the rest, so
/// the face comes out at about a third of what the ground beside it is getting.
/// `COLOUR.timber` was picked for a bench seen broadside in full light; at that
/// value a label is a black tongue on brown soil.
///
/// So it is cut from paler stock — weathered deal rather than oak — which is
/// what a nursery label is anyway. It leaves the tongue a shade darker than the
/// soil, which is true of any upright plate at midday, and the stake's west face
/// a shade brighter, which is the highlight that says the thing is made of wood.
const LABEL_WOOD = [0.72, 0.65, 0.54];

export function plan(e) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_seedbed_plan())));
}

// MARK: - The ground

export function makeSeedbedGround(place) {
  return function buildSeedbedGround(farSide, span, e, eye) {
    const positions = [], normals = [], colours = [];
    const vertex = (p, n, c) => { positions.push(...p); normals.push(...n); colours.push(...c); };
    const tri = (a, b, c, n, ca, cb = ca, cc = ca) => { vertex(a, n, ca); vertex(b, n, cb); vertex(c, n, cc); };
    const quad = (a, b, c, d, n, ca, cb = ca, cc = cb, cd = ca) => {
      tri(a, b, c, n, ca, cb, cc); tri(a, c, d, n, ca, cc, cd);
    };
    const UP = [0, 1, 0];

    const outline = readOutline(e, SIDE, SIDE, SEEDBED.ground);
    const n = outline.length;
    for (let i = 0; i < n; i++) {
      const a = outline[i], b = outline[(i + 1) % n];
      tri([0, 0, 0], [a[0], 0, a[1]], [b[0], 0, b[1]], UP, COLOUR.tilth);
    }

    // **The crumb.** The Knot's lattice, jittered the same way and split on the
    // diagonal the noise chooses, at a finer cell — this is tilth, which is what
    // a gardener calls soil worked down until a seed can be covered by it.
    const half = SIDE / 2 - 0.06;
    const cell = 0.05;
    const steps = Math.ceil((half * 2) / cell);
    const lattice = [];
    for (let i = 0; i <= steps; i++) {
      const row = [];
      for (let j = 0; j <= steps; j++) {
        const edgeOfSheet = i === 0 || j === 0 || i === steps || j === steps;
        const shift = edgeOfSheet ? 0 : cell * 0.34;
        row.push([
          Math.max(-half, Math.min(half, -half + i * cell + shift * (hash(i * 7919 + j * 104729) - 0.5) * 2)),
          Math.max(-half, Math.min(half, -half + j * cell + shift * (hash(i * 6733 + j * 92831) - 0.5) * 2)),
        ]);
      }
      lattice.push(row);
    }

    // **Where each drill runs, row of lattice by row of lattice.** A drill is
    // straight in the rule — `Slot.spot` puts every place in it on one `x` — and
    // drawn straight it would be the one ruled line in a garden that has none.
    // So the furrow the plants stand in wanders by a few centimetres along its
    // length, which is what a rake leaves and what the eye reads as a line drawn
    // by a hand. The plants do not move: this is the soil, not the placement.
    //
    // Worked out once a lattice row rather than once a face: it is a call into
    // the module apiece, and there are ten thousand faces.
    const zOf = (j) => -half + j * cell;
    const centres = [];
    for (let j = 0; j <= steps; j++) {
      const z = zOf(j);
      centres.push(place.drillX.map((x, d) =>
        x + 0.045 * (e.pg_verge(z * 0.9 + d * 4.3, 1, SEEDBED.furrow) / 0.14)));
    }

    // A slow wander under the crumb, so a bed is damper in one corner and drier
    // in another. Without it, ten thousand crumbs of independent tone average
    // out to one flat brown at arm's length. Separable, so it is two calls a
    // lattice line instead of two a face.
    const driftX = [], driftZ = [];
    for (let i = 0; i <= steps; i++) {
      driftX.push(0.055 * (e.pg_verge(zOf(i) * 0.58, -1, SEEDBED.drift) / 0.14));
      driftZ.push(0.045 * (e.pg_verge(zOf(i) * 0.51, 1, SEEDBED.drift) / 0.14));
    }

    // How the rake left this point: dark in the bottom of a drill, pale on the
    // crest between two, and flat again beyond the ends of them, where nothing
    // is sown and nothing was drawn out.
    const rake = (x, j) => {
      let nearest = Infinity;
      for (const centre of centres[j]) nearest = Math.min(nearest, Math.abs(x - centre));
      const across = Math.min(1, nearest / (place.drillGap / 2));
      // Smoothed, then pulled toward the crest: a drill is a narrow trough with
      // a broad shoulder either side, not a sine wave. Drawn as a sine wave the
      // bed reads as corrugated iron.
      const shape = Math.pow(across * across * (3 - 2 * across), 0.62);
      const past = Math.min(1, Math.max(0, (Math.abs(zOf(j)) - (SIDE / 2 - 0.45)) / 0.3));
      return 1 + (1 - past) * (-0.17 + 0.27 * shape);
    };

    const crumb = (i, j, k, x) =>
      COLOUR.tilth.map((v) => v * (1 + driftX[i] + driftZ[j]) * rake(x, j)
        * (0.91 + 0.18 * hash(i * 131 + j * 37 + k * 7 + SEEDBED.crumb)));
    const up = (p) => [p[0], 0.003, p[1]];
    for (let i = 0; i < steps; i++) {
      for (let j = 0; j < steps; j++) {
        const a = lattice[i][j], b = lattice[i + 1][j], c = lattice[i + 1][j + 1], d = lattice[i][j + 1];
        if (hash(i * 31 + j * 17 + SEEDBED.crumb) < 0.5) {
          tri(up(a), up(b), up(c), UP, crumb(i, j, 0, a[0]));
          tri(up(a), up(c), up(d), UP, crumb(i, j, 1, c[0]));
        } else {
          tri(up(a), up(b), up(d), UP, crumb(i, j, 2, a[0]));
          tri(up(b), up(c), up(d), UP, crumb(i, j, 3, c[0]));
        }
      }
    }

    // MARK: The labels
    //
    // **One at the head of every drill, sown or not.** A bed is drawn out and
    // labelled before anything goes into it, which is what a seedbed is for; and
    // the drawing would otherwise have to be rebuilt every time the reader moved
    // to another plot, because which drills are claimed is a fact about the
    // plants and not about the ground.
    //
    // Nothing is written on them — `Organic.rowLabel` says why: at this scale a
    // word is four pixels tall and fights the plants. What each drill holds is
    // named in the page's text, where it can be read and translated.
    for (let d = 0; d < place.drills; d++) {
      const mesh = readStructure(takeResult(e, e.pg_seedbed_label(0.38, 0.19, SEEDBED.label + d)));
      stand(mesh, [place.drillX[d], 0, place.labelAt], vertex);
    }

    // Its sides hang from the outline down to a floor as rough as a clod's, in
    // the app's strata. The walk's arithmetic, because it is the same slab.
    const strata = [[0, COLOUR.humus], [0.16, COLOUR.earth], [0.58, COLOUR.earth], [1, COLOUR.bedrock]];
    let around = 0;
    const floor = outline.map((p, i) => {
      if (i > 0) around += Math.hypot(p[0] - outline[i - 1][0], p[1] - outline[i - 1][1]);
      return RIM_DEPTH * (1 + 0.22 * (e.pg_verge(around, 1, SEEDBED.floor) / 0.14));
    });
    for (let i = 0; i < n; i++) {
      const j = (i + 1) % n, a = outline[i], b = outline[j];
      const dx = b[0] - a[0], dz = b[1] - a[1], l = Math.hypot(dx, dz);
      const normal = [dz / l, 0, -dx / l];
      for (let k = 0; k < strata.length - 1; k++) {
        const [f0, c0] = strata[k], [f1, c1] = strata[k + 1];
        quad([a[0], -f0 * floor[i], a[1]], [b[0], -f0 * floor[j], b[1]],
             [b[0], -f1 * floor[j], b[1]], [a[0], -f1 * floor[i], a[1]], normal, c0, c0, c1, c1);
      }
    }

    return {
      positions: new Float32Array(positions),
      normals: new Float32Array(normals),
      colours: new Float32Array(colours),
    };
  };
}

/// A label, stood at the head of its drill, with the grain that keeps a single
/// colour from reading as plastic.
///
/// It needs no axis swap where the Knot's `lay` does: `pg_seedbed_label` returns
/// a label already facing the way a row label faces, out of the end of the bed
/// the drill fills from.
///
/// The grain is read off where a vertex is in the world rather than where it is
/// in its own label, so that six labels cut from the same mesh are not six
/// identical pieces of wood.
function stand(mesh, at, vertex) {
  for (let t = 0; t < mesh.indices.length; t += 3) {
    for (const k of [0, 1, 2]) {
      const v = mesh.indices[t + k];
      const p = [mesh.positions[v * 3] + at[0],
                 mesh.positions[v * 3 + 1] + at[1],
                 mesh.positions[v * 3 + 2] + at[2]];
      const n = [mesh.normals[v * 3], mesh.normals[v * 3 + 1], mesh.normals[v * 3 + 2]];
      const tone = 0.88 + 0.24 * hash(Math.round(p[0] * 53) * 131 + Math.round(p[2] * 47) + Math.round(p[1] * 71));
      vertex(p, n, LABEL_WOOD.map((c) => c * tone));
    }
  }
}

// MARK: - Reading a bed

/// Which drill a plant is standing in, from where it stands.
///
/// **The wire says where, not which.** `SeedbedStore::planting` sends a seed, its
/// parents and a spot, the same five fields every area sends, and the drill is
/// recovered from the spot rather than added to it — the nudge across a drill is
/// 0.035 m against a 0.74 m gap between drills, so the nearest is never in
/// doubt. Asked of `pg_seedbed_plan`'s own positions, so this cannot come to
/// disagree with the rule about where a drill runs.
export function drillAt(place, x) {
  let best = 0;
  for (let d = 1; d < place.drillX.length; d++) {
    if (Math.abs(x - place.drillX[d]) < Math.abs(x - place.drillX[best])) best = d;
  }
  return best;
}

/// The six drills of a plot: what claimed each one, and how many of its eight
/// places are sown.
///
/// `entries` are `{ drill, kind }` in the order they arrived, which is the order
/// a drill fills in. **A drill is claimed by the first plant sown in it**, so the
/// kind is read off that plant and off nothing else — the same reading the rule
/// makes, rather than a second claim kept beside it.
///
/// All six are returned, claimed or not. A bed is drawn out before it is sown
/// and mostly stands part-sown afterwards, and an unclaimed drill left out of
/// the list would make a bed of one row look like a full one.
export function readDrills(place, entries) {
  const drills = place.drillX.map((x, drill) => ({ drill, x, sown: 0, kind: null }));
  for (const entry of entries) {
    const here = drills[entry.drill];
    if (!here) continue;
    if (here.sown === 0) here.kind = entry.kind ?? null;
    here.sown += 1;
  }
  return drills;
}

// MARK: - Growing a plot

// **Letting go of the thread** between plants, the way the other five do:
// forty-eight is the most this area holds, and the module still builds a mesh a
// plant, so a page that cannot answer a finger while it does is a page that
// looks broken.
const SLICE = 16;
const breathe = () => new Promise((resume) => setTimeout(resume, 0));

// Grows one plot from the plot service. A planting with no parents was minted
// rather than crossed — the ambassador at the head of the first drill — and
// grows from its seed alone.
//
// **It hands back the plantings where the other five hand back a count.** This
// is the one area whose page has something to say about each drill, and the
// plantings are where the drills are: a second fetch to read them would be the
// same answer asked for twice.
export async function growSeedbedFromService(e, stage, plot, report) {
  stage.clear();
  const { plantings } = await (await fetch(`/api/seedbed/plot/${plot}`)).json();
  let since = performance.now();
  for (const [i, p] of plantings.entries()) {
    const lineage = p.parents ?? [];
    const words = new TextEncoder().encode(
      lineage.length === 2 ? [p.seed, ...lineage, p.encounter].join(' ') : p.seed,
    );
    const pointer = e.pg_alloc(words.length);
    new Uint8Array(e.memory.buffer, pointer, words.length).set(words);
    const length = lineage.length === 2
      ? e.pg_grow_hybrid(pointer, words.length)
      : e.pg_grow(pointer, words.length);
    e.pg_free(pointer);
    if (length === 0) continue;
    stage.add(p.spot[0], p.spot[1], decode(takeResult(e, length)));
    if (performance.now() - since > SLICE) {
      report(`Growing: ${i + 1} of ${plantings.length}`);
      stage.draw();
      await breathe();
      since = performance.now();
    }
  }
  stage.draw();
  return plantings;
}

// The workbench's version: a Seedbed the module invents, for judging the
// template before anybody has sown anything in it.
export async function plantVisitors(e, total, report) {
  let arrived = 0;
  let since = performance.now();
  while (arrived < total) {
    e.pg_seedbed_arrive();
    arrived += 1;
    if (performance.now() - since > SLICE) {
      report(`Sowing by the rule: ${arrived} of ${total} arrived`);
      await breathe();
      since = performance.now();
    }
  }
  return e.pg_seedbed_plots();
}

export async function growInvented(e, stage, plot, report) {
  stage.clear();
  const count = e.pg_seedbed_count(plot);
  let since = performance.now();
  for (let i = 0; i < count; i++) {
    const length = e.pg_seedbed_grow(plot, i);
    const buffer = takeResult(e, length);
    const spot = new Float32Array(buffer.slice(0, 8));
    stage.add(spot[0], spot[1], decode(buffer.slice(8)));
    if (performance.now() - since > SLICE) {
      report(`Growing: ${i + 1} of ${count}`);
      stage.draw();
      await breathe();
      since = performance.now();
    }
  }
  stage.draw();
  return count;
}

export function describeSeedbed(e, plot) {
  return JSON.parse(new TextDecoder().decode(takeResult(e, e.pg_seedbed_describe(plot))));
}
