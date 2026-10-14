// How the cost of one request grows with the garden: an area filled to each
// step by offers answered yes, and the Wild Fields filled by releases, with
// the latency of the next requests measured at every step.
//
//   node scale.mjs PLAN.jsonl OUT_DIR [--area beginnings] [--steps 250,1000,2000,3000] [--wild 1000,4000,10000]
//
// Its own database, pgmt_scale (made empty here), so the true crosses of the
// population's plan can be used again without meeting the population.

import { writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { post, get, sql, pool, summarise, readPlan, arrival, AREA_ROUTES, AREA_TABLES, HERE } from './lib.mjs';

const argv = process.argv.slice(2);
const option = (name, fallback) => { const i = argv.indexOf(`--${name}`); return i >= 0 ? argv[i + 1] : fallback; };
const [planFile, outDir] = argv;
const AREA = option('area', 'beginnings');
const STEPS = option('steps', '250,1000,2000,3000').split(',').map(Number);
const WILD = option('wild', '1000,4000,10000').split(',').map(Number);
const DB = 'pgmt_scale';
execFileSync(path.join(HERE, 'stack.sh'), ['db', 'scale']);
const { meetings } = readPlan(planFile);
const forArea = meetings.filter((m) => m.area === AREA);
const forWild = meetings.filter((m) => m.area !== AREA);
let addresses = 0;
const fresh = () => `100.${64 + ((++addresses >> 16) & 63)}.${(addresses >> 8) & 255}.${addresses & 255}`;
const send = (route, body) => post(route, body, { addr: fresh(), db: DB });
const route = AREA_ROUTES[AREA];
const table = AREA_TABLES[AREA];

async function accept(list) {
    await pool(list.map((m) => () => send('/api/walk/offer', { to: m.tokenB, from: m.tokenA, plant: arrival(m) })), 8);
    return pool(list.map((m) => () => send('/api/walk/answer', { seed: m.seed, to: m.tokenB, yes: true })), 4);
}

const area = [];
let used = 0;
for (const step of STEPS) {
    if (used < step) {
        await accept(forArea.slice(used, step));
        used = step;
    }
    // The next twenty arrivals, one at a time, timed.
    sql('TRUNCATE performance_schema.events_statements_summary_by_digest', DB);
    const timed = [];
    for (const m of forArea.slice(used, used + 20)) {
        await send('/api/walk/offer', { to: m.tokenB, from: m.tokenA, plant: arrival(m) });
        timed.push((await send('/api/walk/answer', { seed: m.seed, to: m.tokenB, yes: true })).ms);
    }
    used += 20;
    const scan = sql(`SELECT COUNT_STAR, SUM_ROWS_EXAMINED, ROUND(AVG_TIMER_WAIT/1e6) FROM performance_schema.events_statements_summary_by_digest
                      WHERE SCHEMA_NAME = '${DB}' AND DIGEST_TEXT LIKE 'SELECT * FROM \`${table}\` ORDER BY%'`, DB)[0] ?? [];
    const plots = (await get(`/api/${route}`, { db: DB })).json?.plots ?? 1;
    const reads = [];
    const counts = [];
    for (let i = 0; i < 20; i++) {
        reads.push((await get(`/api/${route}/plot/${plots - 1}`, { db: DB })).ms);
        counts.push((await get(`/api/${route}`, { db: DB })).ms);
    }
    const rows = Number(sql(`SELECT COUNT(*) FROM ${table}`, DB)[0][0]);
    const row = { plantings: rows, plots, answerYes: summarise(timed), plotRead: summarise(reads), countRead: summarise(counts),
                  rowsReadPerArrival: scan.length ? Math.round(Number(scan[1]) / Number(scan[0])) : null,
                  arrivalScanUs: scan.length ? Number(scan[2]) : null };
    area.push(row);
    console.log(JSON.stringify(row));
}

const wild = [];
let released = 0;
for (const step of WILD) {
    if (released < step) {
        await pool(forWild.slice(released, step).map((m) => () => send('/api/wild/release',
            { seed: m.seed, parents: m.parents, encounter: m.encounter, token: m.tokenA, theirs: m.tokenB,
              shown: { name: 'Gardener', month: '2026-10' } })), 16);
        released = step;
    }
    const counts = [];
    const tiles = [];
    let bytes = 0;
    for (let i = 0; i < 20; i++) {
        counts.push((await get('/api/wild', { db: DB })).ms);
        const t = await get(`/api/wild/tile/${i % 8}/${(i * 3) % 8}`, { db: DB });
        tiles.push(t.ms);
        bytes = Math.max(bytes, t.bytes);
    }
    const rows = Number(sql('SELECT COUNT(*) FROM wild_fields', DB)[0][0]);
    const row = { released: rows, fieldCount: summarise(counts), tile: summarise(tiles), tileBytesMax: bytes,
                  bytesPerPlanting: Math.round(bytes / Math.max(1, rows / 64)) };
    wild.push(row);
    console.log(JSON.stringify(row));
}

writeFileSync(path.join(outDir, 'scale.json'), JSON.stringify({ area: AREA, table, areaSteps: area, wildSteps: wild }, null, 1));
