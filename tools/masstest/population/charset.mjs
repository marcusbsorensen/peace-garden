// What a database's default character set does to a name.
//
//   node charset.mjs POOL.jsonl OUT_DIR [--from 1200]
//
// The service's CREATE TABLEs name no character set, so its tables take the
// database's default, whatever the host made it. This makes three databases —
// utf8mb4, utf8mb3 and latin1 — and releases plants with names into each: an
// Arabic name, an emoji, a plain one. For each it records the answer, and
// whether a plant answered 500 is standing in the field anyway.

import { writeFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { post, sql, readPlan, HERE } from './lib.mjs';

const argv = process.argv.slice(2);
const option = (name, fallback) => { const i = argv.indexOf(`--${name}`); return i >= 0 ? argv[i + 1] : fallback; };
const [poolFile, outDir] = argv;
let cursor = Number(option('from', 1200));
const { meetings } = readPlan(poolFile);
let addresses = 0;
const fresh = () => `198.51.100.${++addresses}`;

const results = {};
for (const charset of ['utf8mb4', 'utf8mb3', 'latin1']) {
    const suffix = `cs_${charset}`;
    execFileSync(path.join(HERE, 'stack.sh'), ['db', suffix, charset]);
    const db = `pgmt_${suffix}`;
    const rows = [];
    for (const name of ['Anna', 'مريم', 'Rose 🌹', 'Zoë']) {
        const m = meetings[cursor++];
        const body = { seed: m.seed, parents: m.parents, encounter: m.encounter, token: m.tokenA, theirs: m.tokenB,
                       shown: { name, month: '2026-10' } };
        const first = await post('/api/wild/release', body, { addr: fresh(), db });
        const standing = sql(`SELECT COUNT(*) FROM wild_fields WHERE seed = '${m.seed}' AND hidden = 0`, db)[0][0] === '1';
        const again = await post('/api/wild/release', body, { addr: fresh(), db });
        const stored = sql(`SELECT IFNULL(name_a, '(none)') FROM wild_names WHERE seed = '${m.seed}'`, db)[0]?.[0] ?? '(no row)';
        rows.push({ name, first: first.status, standingAfterFirst: standing, retry: again.status, stored });
    }
    results[charset] = rows;
}
writeFileSync(path.join(outDir, 'charset.json'), JSON.stringify(results, null, 1));
console.log(JSON.stringify(results, null, 1));
