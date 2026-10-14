// Load: closed-loop clients at 10, 50 and 200 at once, reading and then
// writing, against the population's database.
//
//   node load.mjs POOL.jsonl OUT_DIR [--db main] [--from 2000] [--seconds 20] [--levels 10,50,200] [--tag tmpfs] [--kinds read,write]
//
// Reads are what a visitor's browser asks: a tile of the Wild Fields, the
// field's counts, an area's plot count or one of its plots. Writes are what
// phones send: a release of a fresh true cross, or an offer of one, each from
// a phone of its own (so the rate limit is not what is measured).
//
// Writes OUT_DIR/load-<tag>.json: per level and kind, throughput, p50/p95/p99,
// error counts by status, and the statements that took the most time.

import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { request, sql, sqlAsync, summarise, readPlan, arrival, AREA_ROUTES } from './lib.mjs';

const argv = process.argv.slice(2);
const option = (name, fallback) => { const i = argv.indexOf(`--${name}`); return i >= 0 ? argv[i + 1] : fallback; };
const [poolFile, outDir] = argv;
const DB = `pgmt_${option('db', 'main')}`;
const SECONDS = Number(option('seconds', 20));
const LEVELS = option('levels', '10,50,200').split(',').map(Number);
const TAG = option('tag', 'tmpfs');
let cursor = Number(option('from', 2000));
const { meetings } = readPlan(poolFile);
const used = [];
let addresses = 0;
const fresh = () => `100.${64 + ((++addresses >> 16) & 63)}.${(addresses >> 8) & 255}.${addresses & 255}`;

// The plots each area has now, so reads ask for plots that exist.
const plots = {};
for (const [area, route] of Object.entries(AREA_ROUTES)) {
    const res = await request('GET', `/api/${route}`, { db: DB });
    plots[area] = res.json?.plots ?? 1;
}
const areas = Object.keys(AREA_ROUTES);

function readRoute() {
    const roll = Math.random();
    if (roll < 0.5) return `/api/wild/tile/${Math.floor(Math.random() * 8)}/${Math.floor(Math.random() * 8)}`;
    if (roll < 0.6) return '/api/wild';
    const area = areas[Math.floor(Math.random() * areas.length)];
    if (roll < 0.7) return `/api/${AREA_ROUTES[area]}`;
    return `/api/${AREA_ROUTES[area]}/plot/${Math.floor(Math.random() * plots[area])}`;
}

function writeRequest() {
    const m = meetings[cursor++];
    if (!m) return null;
    used.push(m.seed);
    if (Math.random() < 0.5) {
        return ['/api/wild/release', { seed: m.seed, parents: m.parents, encounter: m.encounter, token: m.tokenA, theirs: m.tokenB,
                                       shown: { name: 'Load test', month: '2026-10' } }];
    }
    return ['/api/walk/offer', { to: m.tokenB, from: m.tokenA, plant: arrival(m) }];
}

// InnoDB's own count of deadlocks it broke, server-wide (14 October 2026), so
// a phase can say how many it caused whether or not the service retried them.
const deadlocks = () => Number(sql("SHOW GLOBAL STATUS LIKE 'Innodb_deadlocks'", DB)[0]?.[1] ?? 0);

async function phase(kind, level) {
    sql('TRUNCATE performance_schema.events_statements_summary_by_digest', DB);
    const deadlocksBefore = deadlocks();
    const latencies = [];
    const statuses = {};
    const byRoute = {};
    const deadline = performance.now() + SECONDS * 1000;
    let done = 0;
    async function client() {
        while (performance.now() < deadline) {
            let method = 'GET', route, body;
            if (kind === 'read') route = readRoute();
            else {
                const next = writeRequest();
                if (!next) return;
                method = 'POST';
                [route, body] = next;
            }
            const res = await request(method, route, { body, addr: kind === 'write' ? fresh() : undefined, db: DB, timeoutMs: 65000 });
            latencies.push(res.ms);
            statuses[res.status] = (statuses[res.status] ?? 0) + 1;
            const key = route.replace(/\/\d+/g, '/n');
            (byRoute[key] ??= []).push(res.ms);
            done++;
        }
    }
    // What the database's threads are doing, sampled twice a second while the
    // clients run: a state of "Waiting for table metadata lock" is one request
    // queued behind another's DDL.
    const states = {};
    let sampling = true;
    const sampler = (async () => {
        while (sampling) {
            const rows = await sqlAsync(`SELECT IFNULL(NULLIF(state, ''), command), LEFT(REPLACE(IFNULL(info, ''), '\n', ' '), 60)
                                         FROM information_schema.processlist
                                         WHERE db = '${DB}' AND command <> 'Sleep' AND id <> CONNECTION_ID()`, DB);
            for (const [state, info] of rows) {
                const key = state === 'Waiting for table metadata lock' ? `${state}: ${(info ?? '').replace(/\s+/g, ' ').slice(0, 48)}` : state;
                states[key] = (states[key] ?? 0) + 1;
            }
            await new Promise((resolve) => setTimeout(resolve, 500));
        }
    })();
    const t0 = performance.now();
    await Promise.all(Array.from({ length: level }, client));
    sampling = false;
    await sampler;
    const seconds = (performance.now() - t0) / 1000;
    const deadlocked = deadlocks() - deadlocksBefore;
    const samples = Object.values(states).reduce((n, c) => n + c, 0);
    const metadataWaits = Object.entries(states).filter(([k]) => k.startsWith('Waiting for table metadata lock'))
        .reduce((n, [, c]) => n + c, 0);
    const ok = Object.entries(statuses).filter(([s]) => s >= 200 && s < 300).reduce((n, [, c]) => n + c, 0);
    const top = sql(`SELECT COUNT_STAR, ROUND(SUM_TIMER_WAIT/1e9), ROUND(AVG_TIMER_WAIT/1e6), LEFT(DIGEST_TEXT, 90)
                     FROM performance_schema.events_statements_summary_by_digest WHERE SCHEMA_NAME = '${DB}'
                     ORDER BY SUM_TIMER_WAIT DESC LIMIT 6`, DB)
        .map(([n, ms, avgUs, text]) => ({ n: Number(n), totalMs: Number(ms), avgUs: Number(avgUs), text }));
    const result = { kind, level, seconds: Math.round(seconds * 10) / 10, requests: done,
                     perSecond: Math.round((done / seconds) * 10) / 10, ...summarise(latencies),
                     errorShare: Math.round(((done - ok) / Math.max(1, done)) * 1000) / 10, statuses,
                     routes: Object.fromEntries(Object.entries(byRoute).map(([r, l]) => [r, summarise(l)])), top,
                     threadStates: states, deadlocks: deadlocked,
                     metadataLockShare: samples ? Math.round((metadataWaits / samples) * 1000) / 10 : 0 };
    console.log(JSON.stringify({ kind, level, perSecond: result.perSecond, p50: result.p50, p95: result.p95, p99: result.p99,
                                 errorShare: result.errorShare, statuses, deadlocks: deadlocked,
                                 metadataLockShare: result.metadataLockShare }));
    return result;
}

const KINDS = option('kinds', 'read,write').split(',');
const results = [];
for (const kind of KINDS) for (const level of LEVELS) results.push(await phase(kind, level));
const size = sql(`SELECT ROUND(SUM(data_length + index_length) / 1048576, 1) FROM information_schema.tables WHERE table_schema = '${DB}'`, DB)[0][0];
writeFileSync(path.join(outDir, `load-${TAG}.json`), JSON.stringify({ db: DB, tag: TAG, seconds: SECONDS, plots, databaseMB: Number(size), results }, null, 1));
writeFileSync(path.join(outDir, `extra_genuine_load_${TAG}.json`), JSON.stringify(used));
console.error(`cursor ${cursor}, database ${size} MB`);
