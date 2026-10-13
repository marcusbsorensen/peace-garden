// Shared by the population driver, the adversary, the races and the load
// test: one HTTP client, the database and the service's own CLI tools, and
// the arithmetic for latencies.
//
// **Local only.** Every request goes to PGMT_BASE, which must be loopback. The
// live site's releases are public and permanent, so this refuses to start
// rather than send one request anywhere else.

import http from 'node:http';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

export const HERE = path.dirname(fileURLToPath(import.meta.url));
export const ROOT = path.resolve(HERE, '../../..');
export const BASE = process.env.PGMT_BASE || 'http://127.0.0.1:8811';
const base = new URL(BASE);
if (!['127.0.0.1', 'localhost', '[::1]'].includes(base.hostname)) {
    console.error(`refusing: ${BASE} is not this machine. The population test runs against a local copy only.`);
    process.exit(2);
}

const agent = new http.Agent({ keepAlive: true, maxSockets: 1024 });

/**
 * One request. `addr` is the address the simulated phone would have
 * (X-Sim-Addr, which the local nginx hands PHP as REMOTE_ADDR); `db` picks a
 * test database (X-Sim-Db). `raw` sends a body exactly as given.
 */
export function request(method, route, { body, raw, addr, db, timeoutMs = 60000, headers = {} } = {}) {
    return new Promise((resolve) => {
        const payload = raw !== undefined ? raw : body !== undefined ? JSON.stringify(body) : undefined;
        const h = { ...headers };
        if (payload !== undefined) {
            h['content-type'] ??= 'application/json';
            h['content-length'] = Buffer.byteLength(payload);
        }
        if (addr) h['x-sim-addr'] = addr;
        if (db) h['x-sim-db'] = db;
        const started = performance.now();
        const req = http.request({ host: base.hostname.replace(/[[\]]/g, ''), port: base.port || 80, method,
                                   path: route, headers: h, agent, timeout: timeoutMs }, (res) => {
            const chunks = [];
            res.on('data', (c) => chunks.push(c));
            res.on('end', () => {
                const text = Buffer.concat(chunks).toString('utf8');
                let json = null;
                try { json = JSON.parse(text); } catch { /* not JSON */ }
                resolve({ status: res.statusCode, json, text, bytes: Buffer.byteLength(text),
                          ms: performance.now() - started, headers: res.headers });
            });
        });
        req.on('timeout', () => req.destroy(new Error('timeout')));
        req.on('error', (error) => resolve({ status: 0, json: null, text: String(error.message), bytes: 0,
                                             ms: performance.now() - started, error: error.message }));
        if (payload !== undefined) req.write(payload);
        req.end();
    });
}

export const get = (route, opts) => request('GET', route, opts);
export const post = (route, body, opts = {}) => request('POST', route, { ...opts, body });

/** SQL as root inside the MariaDB container; rows as arrays of strings. */
export function sql(query, db = 'pgmt_main') {
    const out = execFileSync('docker', ['exec', '-i', 'pg-mt-pop-db', 'mariadb', '-uroot', '-proot-local-only',
                                        '-N', '-B', db], { input: query, maxBuffer: 1 << 28 }).toString('utf8');
    return out.split('\n').filter((line) => line.length).map((line) => line.split('\t'));
}

/** One of the service's own commands (curate.php, sweep.php), on a test database. */
export function serviceCommand(script, args = [], db = 'pgmt_main') {
    try {
        const out = execFileSync('php', [path.join(ROOT, 'Server/.api', script), ...args],
                                 { env: { ...process.env, PGMT_DB: db }, stdio: ['ignore', 'pipe', 'pipe'] });
        return { code: 0, out: out.toString('utf8') };
    } catch (error) {
        return { code: error.status ?? 1, out: String(error.stdout ?? '') + String(error.stderr ?? '') };
    }
}

/** Runs `tasks` (functions returning promises) with at most `width` in flight. */
export async function pool(tasks, width) {
    const results = new Array(tasks.length);
    let next = 0;
    async function worker() {
        while (next < tasks.length) {
            const index = next++;
            results[index] = await tasks[index]();
        }
    }
    await Promise.all(Array.from({ length: Math.min(width, tasks.length) }, worker));
    return results;
}

export function percentile(sorted, p) {
    if (sorted.length === 0) return null;
    const index = Math.min(sorted.length - 1, Math.max(0, Math.ceil((p / 100) * sorted.length) - 1));
    return sorted[index];
}

export function summarise(latencies) {
    const sorted = [...latencies].sort((a, b) => a - b);
    const round = (v) => (v === null ? null : Math.round(v * 10) / 10);
    return { n: sorted.length, p50: round(percentile(sorted, 50)), p95: round(percentile(sorted, 95)),
             p99: round(percentile(sorted, 99)), max: round(sorted[sorted.length - 1] ?? null) };
}

/** The plan popgen wrote: gardeners and meetings. */
export function readPlan(file) {
    const gardeners = [];
    const meetings = [];
    for (const line of readFileSync(file, 'utf8').split('\n')) {
        if (!line) continue;
        const row = JSON.parse(line);
        if (row.kind === 'gardener') gardeners.push(row);
        else meetings.push(row);
    }
    return { gardeners, meetings };
}

/** A deterministic RNG for the driver's choices (mulberry32). */
export function rng(seed) {
    let a = seed >>> 0;
    const next = () => {
        a = (a + 0x6d2b79f5) >>> 0;
        let t = a;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
    return { unit: next, int: (n) => Math.floor(next() * n), pick: (list) => list[Math.floor(next() * list.length)],
             chance: (p) => next() < p };
}

/** An address for gardener `g`: one phone, one address, as the rate limit assumes. */
export const addressOf = (g) => `10.${(g >> 16) & 255}.${(g >> 8) & 255}.${g & 255}`;

/** What the app sends to offer a plant (PlotService.offer: WalkArrival). */
export function arrival(m) {
    const plant = { seed: m.seed, parents: m.parents, encounter: m.encounter, height: m.height,
                    family: m.family, area: m.area, kind: m.kind_, habit: m.habit };
    if (m.hue !== undefined) plant.hue = m.hue;
    return plant;
}

/**
 * The cross, computed here rather than by SeedCore: what somebody inventing a
 * lineage would compute. Only the adversary uses it, to make plants that pass
 * the service's one check without any meeting having happened. Every plant the
 * population grows comes from popgen.
 */
export async function inventedCross(parentA, parentB, encounter) {
    const { createHash } = await import('node:crypto');
    const a = Buffer.from(parentA, 'hex');
    const b = Buffer.from(parentB, 'hex');
    const [low, high] = Buffer.compare(a, b) < 0 ? [a, b] : [b, a];
    const parts = [Buffer.from('peacegarden.cross.v1\0')];
    for (const part of [low, high, Buffer.from(encounter, 'hex')]) {
        const length = Buffer.alloc(4);
        length.writeUInt32BE(part.length);
        parts.push(length, part);
    }
    return createHash('sha256').update(Buffer.concat(parts)).digest('hex');
}

export const randomHex = (bytes) => [...crypto.getRandomValues(new Uint8Array(bytes))]
    .map((b) => b.toString(16).padStart(2, '0')).join('');

export const AREA_TABLES = {
    travel: 'long_walk', peace: 'quiet_garden', meeting: 'crossing', kinship: 'orchard', pattern: 'knot_garden',
    beginnings: 'seedbed', waiting: 'cold_frame', light: 'glasshouse', renewal: 'coppice', ground: 'home_ground',
};
export const AREA_ROUTES = {
    travel: 'walk', peace: 'quiet', meeting: 'cross', kinship: 'orchard', pattern: 'knot',
    beginnings: 'seedbed', waiting: 'frame', light: 'glasshouse', renewal: 'coppice', ground: 'ground',
};
