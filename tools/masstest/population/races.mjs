// Things that happen at the same moment: a phone retrying, two phones acting at
// once, a burst of new callers. Each race is run many times on its own fresh
// database, and the outcome of every run is counted.
//
//   node races.mjs POOL.jsonl OUT_DIR [--from 300]
//
// Uses database pgmt_race (stack.sh db race makes it empty). Writes
// OUT_DIR/races.json.

import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { post, sql, readPlan, arrival, AREA_TABLES } from './lib.mjs';

const argv = process.argv.slice(2);
const option = (name, fallback) => { const i = argv.indexOf(`--${name}`); return i >= 0 ? argv[i + 1] : fallback; };
const [poolFile, outDir] = argv;
const DB = 'pgmt_race';
let cursor = Number(option('from', 300));
const { meetings } = readPlan(poolFile);
const nextMeeting = (area) => {
    while (area && meetings[cursor].area !== area) cursor++;
    return meetings[cursor++];
};
let addresses = 0;
const fresh = () => `198.18.${(++addresses >> 8) & 255}.${addresses & 255}`;
const send = (route, body) => post(route, body, { addr: fresh(), db: DB });
const offerBody = (m) => ({ to: m.tokenB, from: m.tokenA, plant: arrival(m) });
const standing = (m) => {
    const rows = sql(`SELECT hidden FROM ${AREA_TABLES[m.area]} WHERE seed = '${m.seed}'`, DB);
    return rows.length ? (rows[0][0] === '0' ? 'standing' : 'hidden') : 'absent';
};
const offerState = async (m) => (await send('/api/walk/pending', { tokens: [m.tokenA] })).json?.offers?.[0]?.state ?? 'none';
const tally = (list) => list.reduce((t, k) => ({ ...t, [k]: (t[k] ?? 0) + 1 }), {});
const results = {};

// R1. One release, sent twenty times at once.
{
    const outcomes = [];
    for (let trial = 0; trial < 20; trial++) {
        const m = nextMeeting();
        const body = { seed: m.seed, parents: m.parents, encounter: m.encounter, token: m.tokenA, theirs: m.tokenB };
        const answers = await Promise.all(Array.from({ length: 20 }, () => send('/api/wild/release', body)));
        const rows = sql(`SELECT COUNT(*) FROM wild_fields WHERE seed = '${m.seed}'`, DB)[0][0];
        const created = answers.filter((a) => a.status === 201).length;
        outcomes.push(`${created} created, ${answers.filter((a) => a.status === 200).length} told, `
                      + `${answers.filter((a) => a.status >= 500).length} failed, ${rows} row`);
    }
    results.R1_release_twenty_at_once = tally(outcomes);
}

// R2. Yes, sent twice (or three times) at once: a phone retrying after a slow answer.
for (const copies of [2, 3]) {
    const outcomes = [];
    for (let trial = 0; trial < 30; trial++) {
        const m = nextMeeting();
        const offered = await send('/api/walk/offer', offerBody(m));
        if (offered.status !== 201) { outcomes.push(`offer ${offered.status}`); continue; }
        const yes = { seed: m.seed, to: m.tokenB, yes: true };
        const answers = await Promise.all(Array.from({ length: copies }, () => send('/api/walk/answer', yes)));
        const planted = answers.filter((a) => a.json?.planting).length;
        outcomes.push(`offer ${await offerState(m)}, planting ${standing(m)}, ${planted} answers said planted`
                      + (answers.some((a) => a.status >= 500) ? ', a 500' : ''));
    }
    results[`R2_yes_${copies}_at_once`] = tally(outcomes);
}

// R3. Yes from one phone and a withdrawal from the other, at once.
{
    const outcomes = [];
    for (let trial = 0; trial < 30; trial++) {
        const m = nextMeeting();
        if ((await send('/api/walk/offer', offerBody(m))).status !== 201) continue;
        await Promise.all([send('/api/walk/answer', { seed: m.seed, to: m.tokenB, yes: true }),
                           send('/api/walk/withdraw', { seed: m.seed, token: m.tokenA })]);
        outcomes.push(`offer ${await offerState(m)}, planting ${standing(m)}`);
    }
    results.R3_yes_and_withdraw_at_once = tally(outcomes);
}

// R4. One phone offers the plant while the other releases it, at once; then
// the offer, if it survived, is answered yes.
{
    const outcomes = [];
    for (let trial = 0; trial < 40; trial++) {
        const m = nextMeeting();
        const [offered, released] = await Promise.all([
            send('/api/walk/offer', offerBody(m)),
            send('/api/wild/release', { seed: m.seed, parents: m.parents, encounter: m.encounter, token: m.tokenB, theirs: m.tokenA }),
        ]);
        const yes = await send('/api/walk/answer', { seed: m.seed, to: m.tokenB, yes: true });
        const wild = sql(`SELECT COUNT(*) FROM wild_fields WHERE seed = '${m.seed}'`, DB)[0][0] === '1';
        outcomes.push(`offer ${offered.status}, release ${released.status}, then yes ${yes.status}: `
                      + `wild ${wild ? 'yes' : 'no'}, area ${standing(m)}`);
    }
    results.R4_offer_and_release_at_once = tally(outcomes);
}

// R5. Fifty different plants accepted into one area at once: the lock has to
// keep them off each other's places.
{
    const area = 'light';
    const batch = [];
    for (let i = 0; i < 50; i++) {
        const m = nextMeeting(area);
        if ((await send('/api/walk/offer', offerBody(m))).status === 201) batch.push(m);
    }
    const t0 = performance.now();
    const answers = await Promise.all(batch.map((m) => send('/api/walk/answer', { seed: m.seed, to: m.tokenB, yes: true })));
    const ms = Math.round(performance.now() - t0);
    const clashes = sql(`SELECT COUNT(*) FROM (SELECT plot, bed, slot_row, slot_index FROM glasshouse
                         GROUP BY plot, bed, slot_row, slot_index HAVING COUNT(*) > 1) c`, DB)[0][0];
    results.R5_fifty_yes_into_the_glasshouse = { statuses: tally(answers.map((a) => a.status)), clashes: Number(clashes),
                                                 ms_for_all: ms, slowest_ms: Math.round(Math.max(...answers.map((a) => a.ms))) };
}

// R6. Both gardeners choose the same place at the same moment: shown or not?
{
    const outcomes = [];
    for (let trial = 0; trial < 30; trial++) {
        const m = nextMeeting();
        await send('/api/wild/release', { seed: m.seed, parents: m.parents, encounter: m.encounter, token: m.tokenA, theirs: m.tokenB });
        const shown = { name: null, place: 'Margate', month: '2026-10' };
        await Promise.all([send('/api/wild/answer', { seed: m.seed, token: m.tokenA, shown: { ...shown, name: 'A' } }),
                           send('/api/wild/answer', { seed: m.seed, token: m.tokenB, shown: { ...shown, name: 'B' } })]);
        const row = sql(`SELECT IFNULL(place, '-'), IFNULL(month, '-') FROM wild_names WHERE seed = '${m.seed}'`, DB)[0];
        outcomes.push(`place ${row[0] === 'Margate' ? 'shown' : 'not shown'}, month ${row[1] === '2026-10' ? 'shown' : 'not shown'}`);
    }
    results.R6_both_choose_the_place_at_once = tally(outcomes);
}

// R7. Forty phones nobody has heard from this hour, asking at once. Each is a
// new rate-limit bucket: SELECT, then UPDATE of no row, then INSERT.
{
    const rounds = [];
    for (let round = 0; round < 15; round++) {
        sql('DELETE FROM rate_limits', DB);
        const answers = await Promise.all(Array.from({ length: 40 }, () => send('/api/walk/pending', { tokens: [] })));
        rounds.push(answers.filter((a) => a.status === 500).length);
    }
    results.R7_forty_new_callers_at_once = { failed_per_round_of_40: rounds,
                                             failed_share: Math.round((rounds.reduce((a, b) => a + b, 0) / (40 * rounds.length)) * 1000) / 10 + '%' };
}

writeFileSync(path.join(outDir, 'races.json'), JSON.stringify(results, null, 1));
console.log(JSON.stringify(results, null, 1));
console.error(`cursor ${cursor}`);
