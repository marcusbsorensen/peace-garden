// What one request costs, alone: each route asked N times one after another,
// with performance_schema's statement digests counted around the batch.
//
//   node probe.mjs [N] [db-suffix]
//
// Prints, per route, the median latency, and for the whole batch the
// statements MariaDB ran per request and the ten that took the most time.

import { get, sql, summarise } from './lib.mjs';

const N = Number(process.argv[2] ?? 20);
const DB = `pgmt_${process.argv[3] ?? 'main'}`;
const routes = ['/api/garden', '/api/wild', '/api/wild/tile/3/4', '/api/walk', '/api/glasshouse/plot/0',
                '/api/coppice/plot/0', '/api/ground'];

await get('/api/wild', { db: DB });   // warm: opcache, tables made
sql('TRUNCATE performance_schema.events_statements_summary_by_digest', DB);
const result = {};
let storeRequests = 0;
for (const route of routes) {
    const ms = [];
    for (let i = 0; i < N; i++) ms.push((await get(route, { db: DB })).ms);
    result[route] = summarise(ms);
    if (route !== '/api/garden') storeRequests += N;
}
const total = sql(`SELECT SUM(COUNT_STAR), ROUND(SUM(SUM_TIMER_WAIT)/1e9) FROM performance_schema.events_statements_summary_by_digest WHERE SCHEMA_NAME='${DB}'`, DB)[0];
const top = sql(`SELECT COUNT_STAR, ROUND(SUM_TIMER_WAIT/1e9,1), ROUND(AVG_TIMER_WAIT/1e6,0), LEFT(DIGEST_TEXT,70)
                 FROM performance_schema.events_statements_summary_by_digest WHERE SCHEMA_NAME='${DB}'
                 ORDER BY SUM_TIMER_WAIT DESC LIMIT 10`, DB);
console.log(JSON.stringify({
    db: DB, perRoute: result,
    statementsPerRequest: Math.round(Number(total[0]) / storeRequests),
    dbMsPerRequest: Math.round(Number(total[1]) / storeRequests),
    top: top.map(([n, ms, avgUs, text]) => ({ n: Number(n), totalMs: Number(ms), avgUs: Number(avgUs), text })),
}, null, 1));
