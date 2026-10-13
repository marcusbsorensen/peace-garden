// The population run: thousands of gardeners living in the garden for months.
//
//   node driver.mjs PLAN.jsonl OUT_DIR [--db main] [--width 32] [--days N]
//
// The plan (popgen) says who met whom and what grew; this decides, with its own
// seeded dice, what each pair then does with the plant, and does it over HTTP
// the way PlotService does: offer it to its area, answer yes or no or never,
// withdraw it, release it to the Wild Fields with or without names, release
// the other copy, answer what stands beside it, and ask `pending` now and then.
// The curator hides a few released plants each day with curate.php, and cron's
// sweep.php runs once a simulated day.
//
// **Time.** The service reads time() and has no clock to wind. A simulated day
// passes by editing the local database: every offer's times move a day into
// the past, and the rate-limit windows are dropped, as a day ends them. So an
// offer nobody answers reaches thirty days old on day 30 of its life and is
// lapsed by the next offer, pending or sweep — the service's own code does it.
//
// **Addresses.** Each gardener's phone has its own address (X-Sim-Addr), except
// on festival days, when one town's gardeners are all on the venue's Wi-Fi.
//
// Every request's answer is checked against what the service should say, and
// every surprise is written down. OUT_DIR gets events.jsonl (the surprises),
// state.json (what the driver believes stands where) and stats.json.

import { writeFileSync, mkdirSync, appendFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { request, post, sql, serviceCommand, pool, summarise, readPlan, rng, addressOf, arrival,
         AREA_TABLES } from './lib.mjs';

const argv = process.argv.slice(2);
const option = (name, fallback) => {
    const i = argv.indexOf(`--${name}`);
    return i >= 0 ? argv[i + 1] : fallback;
};
const [planFile, outDir] = argv;
const DB = `pgmt_${option('db', 'main')}`;
const WIDTH = Number(option('width', 32));
mkdirSync(outDir, { recursive: true });
const eventsFile = path.join(outDir, 'events.jsonl');
writeFileSync(eventsFile, '');

const { gardeners, meetings } = readPlan(planFile);
const lastDay = Number(option('days', meetings.at(-1).day + 1 + 35));
const dice = rng(20261013);
const VENUE = '203.0.113.7';
const festivals = new Map([[45, 3], [90, 7]]);   // day -> town on the venue's Wi-Fi
// Days to stop between requests and check every invariant (check.php), so the
// checks see the garden mid-life and not only at the end.
const checkDays = new Set(option('check-days', '').split(',').filter(Boolean).map(Number));

// MARK: - What happened

const stats = { requests: 0, routes: {}, unexpected: 0, festival: { requests: 0, limited: 0 },
                sweeps: [], curated: 0, clockSeconds: 0, started: new Date().toISOString() };
const latencies = {};

function note(kind, detail) {
    stats.unexpected++;
    appendFileSync(eventsFile, JSON.stringify({ kind, ...detail }) + '\n');
}

/** Sends one request as gardener `g` and checks the status is one of `want`. */
async function ask(g, route, body, want, context = {}) {
    const addr = context.addr ?? currentAddress(g);
    const r = (stats.routes[route] ??= { n: 0, status: {}, retried: 0 });
    const send = async () => {
        const res = await post(route, body, { addr, db: DB });
        stats.requests++;
        r.n++;
        r.status[res.status] = (r.status[res.status] ?? 0) + 1;
        (latencies[route] ??= []).push(res.ms);
        return res;
    };
    let res = await send();
    // A 500 is what a phone shows as "could not answer", and a person taps
    // again. So the driver does, once, after a moment — the first answer is
    // already counted above, and the population carries on as it would.
    if (res.status >= 500 || res.status === 0) {
        r.retried++;
        await new Promise((resolve) => setTimeout(resolve, 150 + Math.random() * 300));
        res = await send();
        if (want.includes(201) && res.status === 200) want = [...want, 200];
    }
    if (addr === VENUE) {
        stats.festival.requests++;
        if (res.status === 429) stats.festival.limited++;
    }
    if (!want.includes(res.status) && !(res.status === 429 && addr === VENUE)) {
        note('unexpected status', { route, status: res.status, want, body: res.text.slice(0, 300),
                                    seed: body?.seed ?? body?.plant?.seed, ...context.detail });
    }
    return res;
}

let today = 0;
const festivalTown = () => festivals.get(today);
const currentAddress = (g) => (festivalTown() !== undefined && gardeners[g].town === festivalTown() ? VENUE : addressOf(g));

// MARK: - What the driver believes

/** Every plant somebody did something public with, by seed. */
const plants = new Map();
/** Each gardener's own tokens, for pending. */
const tokensOf = gardeners.map(() => []);
/** Things to do on a later day: day -> seed -> [() => Promise], run in order per plant. */
const agenda = new Map();
const later = (day, seed, task) => {
    if (day >= lastDay) return;
    const forDay = agenda.get(day) ?? agenda.set(day, new Map()).get(day);
    (forDay.get(seed) ?? forDay.set(seed, []).get(seed)).push(task);
};
const dueToday = () => [...(agenda.get(today) ?? new Map()).values()].map((tasks) => async () => {
    for (const task of tasks) await task();
});

const side = (m, g) => (g === m.a ? { ours: m.tokenA, theirs: m.tokenB } : { ours: m.tokenB, theirs: m.tokenA });
const other = (m, g) => (g === m.a ? m.b : m.a);

function shownFor(g, m) {
    // Each plant's own dice, so a run's choices do not depend on which request finished first.
    const dice = plants.get(m.seed)?.dice ?? rng(parseInt(m.seed.slice(0, 8), 16));
    const choice = { name: dice.chance(0.6), place: dice.chance(0.4), month: dice.chance(0.4) };
    const shown = {};
    if (choice.name) shown.name = gardeners[g].name;
    // Both phones keep the meeting's place as they read it; most agree, some don't.
    if (choice.place) shown.place = dice.chance(0.85) ? gardeners[m.a].place : gardeners[g].place;
    if (choice.month) shown.month = `2026-${String(1 + (m.day % 12)).padStart(2, '0')}`;
    return Object.keys(shown).length ? shown : undefined;
}

// MARK: - The acts

async function offer(m, g) {
    const t = side(m, g);
    const res = await ask(g, '/api/walk/offer', { to: t.theirs, from: t.ours, plant: arrival(m) }, [201]);
    const p = plants.get(m.seed);
    if (res.status === 201 || (res.status === 200 && res.json?.offer?.state === 'offered')) { p.state = 'offered'; p.offeredOn = today; }
    else if (res.status === 429) p.state = 'held';
    return res;
}

async function answer(m, yes) {
    const p = plants.get(m.seed);
    if (p.state !== 'offered') return;
    const recipient = other(m, p.by);
    const res = await ask(recipient, '/api/walk/answer', { seed: m.seed, to: side(m, recipient).ours, yes }, [200]);
    if (res.status !== 200) return;
    const offerState = res.json?.offer?.state;
    if (today - p.offeredOn >= 30) {
        // Lapsed before the answer came: told so, nothing planted.
        if (offerState !== 'withdrawn' || res.json.planting) note('answered after lapse', { seed: m.seed, offerState });
        p.state = 'lapsed';
        return;
    }
    if (yes) {
        if (offerState !== 'accepted' || !res.json.planting) note('yes did not plant', { seed: m.seed, body: res.text.slice(0, 300) });
        p.state = 'accepted';
    } else {
        if (offerState !== 'declined') note('no did not decline', { seed: m.seed, offerState });
        p.state = 'declined';
    }
}

async function withdraw(m, g) {
    const p = plants.get(m.seed);
    if (!['offered', 'accepted'].includes(p.state)) return;
    const res = await ask(g, '/api/walk/withdraw', { seed: m.seed, token: side(m, g).ours }, [200]);
    if (res.status === 200) p.state = res.json?.offer?.state === 'withdrawn' ? 'withdrawn' : p.state;
}

async function release(m, g, { withToken = true, second = false } = {}) {
    const p = plants.get(m.seed);
    const t = side(m, g);
    const body = { seed: m.seed, parents: m.parents, encounter: m.encounter };
    if (withToken) {
        body.token = t.ours;
        body.theirs = t.theirs;
        const shown = shownFor(g, m);
        if (shown) body.shown = shown;
    }
    let want;
    if (p.state === 'hidden') want = [410];
    else if (p.state === 'released') want = [200];
    else if (['offered', 'accepted', 'declined', 'withdrawn', 'lapsed'].includes(p.state)) want = withToken ? [201] : [403];
    else want = [201];
    const res = await ask(g, '/api/wild/release', body, want, { detail: { state: p.state, second } });
    const took = res.status === 201 || (res.status === 200 && res.json?.planting && !['released', 'hidden'].includes(p.state));
    if (took) { p.state = 'released'; p.releasedOn = today; p.named = withToken; }
    return res;
}

async function besideAnswer(m, g) {
    const p = plants.get(m.seed);
    if (p.state !== 'released' || !p.named) return;
    await ask(g, '/api/wild/answer', { seed: m.seed, token: side(m, g).ours, shown: shownFor(g, m) ?? null }, [200]);
}

async function pending(g) {
    const tokens = tokensOf[g];
    for (let i = 0; i < tokens.length; i += 128) {
        const res = await ask(g, '/api/walk/pending', { tokens: tokens.slice(i, i + 128) }, [200]);
        if (res.status === 200 && (!Array.isArray(res.json?.offers) || !Array.isArray(res.json?.wild))) {
            note('pending unreadable', { g, body: res.text.slice(0, 200) });
        }
    }
}

// MARK: - A plant's fate, decided the day it grows

function decide(m) {
    tokensOf[m.a].push(m.tokenA);
    tokensOf[m.b].push(m.tokenB);
    const roll = dice.unit();
    const by = dice.chance(0.5) ? m.a : m.b;
    const p = { seed: m.seed, m, by, state: 'held', area: m.area, dice: rng(parseInt(m.seed.slice(0, 8), 16)) };
    if (roll < 0.30) {
        plants.set(m.seed, p);
        const answerRoll = dice.unit();
        const tasks = [() => offer(m, by)];
        if (answerRoll < 0.55) later(today + 1 + dice.int(10), m.seed, () => answer(m, true));
        else if (answerRoll < 0.70) later(today + 1 + dice.int(5), m.seed, () => answer(m, false));
        else if (answerRoll < 0.73) later(today + 31 + dice.int(4), m.seed, () => answer(m, true));   // too late
        // ...and the rest never answer, and lapse.
        const who = dice.chance(0.5) ? m.a : m.b;
        if (dice.chance(0.05)) later(today + 12 + dice.int(20), m.seed, () => withdraw(m, who));
        if (dice.chance(0.04)) later(today + 3 + dice.int(30), m.seed, () => release(m, who));
        return tasks;
    }
    if (roll < 0.42) {
        plants.set(m.seed, p);
        const withToken = dice.chance(0.75);
        if (dice.chance(0.3)) later(today + 1 + dice.int(6), m.seed, () => release(m, other(m, by), { second: true }));
        if (withToken && dice.chance(0.4)) later(today + 1 + dice.int(8), m.seed, () => besideAnswer(m, other(m, by)));
        return [() => release(m, by, { withToken })];
    }
    return [];
}

// MARK: - The day's housekeeping

function advanceClock() {
    const t0 = performance.now();
    sql('UPDATE walk_offers SET offered_at = offered_at - 86400, answered_at = answered_at - 86400; DELETE FROM rate_limits;', DB);
    stats.clockSeconds += (performance.now() - t0) / 1000;
}

function curateSome() {
    const fresh = [...plants.values()].filter((p) => p.state === 'released' && p.releasedOn === today - 1);
    for (let i = 0; i < Math.min(2, fresh.length); i++) {
        const p = fresh.sort((x, y) => (x.seed < y.seed ? -1 : 1))[dice.int(fresh.length)];
        if (p.state !== 'released') continue;
        const run = serviceCommand('curate.php', ['hide', p.seed], DB);
        if (run.code !== 0 || !run.out.startsWith('Hidden')) note('curate failed', { seed: p.seed, out: run.out.slice(0, 200) });
        else { p.state = 'hidden'; stats.curated++; }
        // A hidden plant cannot come back: released again by either, or offered.
        later(today + 1 + dice.int(5), p.seed, () => release(p.m, p.m.a));
        later(today + 1 + dice.int(5), p.seed, async () => {
            const t = side(p.m, p.m.b);
            await ask(p.m.b, '/api/walk/offer', { to: t.theirs, from: t.ours, plant: arrival(p.m) }, [410]);
        });
    }
}

// MARK: - Run

const byDay = new Map();
for (const m of meetings) (byDay.get(m.day) ?? byDay.set(m.day, []).get(m.day)).push(m);

const started = performance.now();
for (today = 0; today < lastDay; today++) {
    if (today > 0) advanceClock();
    const acts = [];
    for (const m of byDay.get(today) ?? []) acts.push(...decide(m));
    await pool(acts, WIDTH);
    await pool(dueToday(), WIDTH);
    agenda.delete(today);

    // The app opens now and then: everyone with a meeting in the last week,
    // and one in twenty of the rest. At a festival, the whole town, thrice.
    const askers = [];
    for (let g = 0; g < gardeners.length; g++) {
        if (tokensOf[g].length === 0) continue;
        const atFestival = festivalTown() !== undefined && gardeners[g].town === festivalTown();
        const times = atFestival ? 3 : dice.chance(0.05) ? 1 : 0;
        for (let i = 0; i < times; i++) askers.push(() => pending(g));
    }
    await pool(askers, WIDTH);

    const sweep = serviceCommand('sweep.php', [], DB);
    if (sweep.code !== 0) note('sweep failed', { out: sweep.out.slice(0, 200) });
    else if (sweep.out.trim()) stats.sweeps.push({ day: today, said: sweep.out.trim().replace(/^\S+ \S+\s+/, '') });
    curateSome();

    if (checkDays.has(today)) {
        const dir = path.join(outDir, `check-day-${today}`);
        mkdirSync(dir, { recursive: true });
        let said;
        try {
            said = execFileSync('php', [path.join(path.dirname(new URL(import.meta.url).pathname), 'check.php'), dir,
                                        DB.replace(/^pgmt_/, '')]).toString();
        } catch (failed) {
            said = String(failed.stdout ?? failed.message);
        }
        (stats.checks ??= {})[today] = JSON.parse(said.trim().split('\n').at(-1) || '{}');
        console.log(`check on day ${today}: ${said.trim().slice(0, 300)}`);
    }

    if (today % 10 === 0 || today === lastDay - 1) {
        const states = {};
        for (const p of plants.values()) states[p.state] = (states[p.state] ?? 0) + 1;
        console.log(`day ${today}: ${stats.requests} requests, ${stats.unexpected} unexpected, ` +
                    `${((performance.now() - started) / 1000).toFixed(0)}s, ${JSON.stringify(states)}`);
    }
}

stats.seconds = Math.round((performance.now() - started) / 1000);
stats.latency = Object.fromEntries(Object.entries(latencies).map(([route, list]) => [route, summarise(list)]));
stats.states = {};
for (const p of plants.values()) stats.states[p.state] = (stats.states[p.state] ?? 0) + 1;
stats.gardeners = gardeners.length;
stats.meetings = meetings.length;
stats.days = lastDay;
writeFileSync(path.join(outDir, 'stats.json'), JSON.stringify(stats, null, 1));
writeFileSync(path.join(outDir, 'state.json'), JSON.stringify(
    [...plants.values()].map((p) => ({ seed: p.seed, state: p.state, area: p.area, named: p.named ?? false }))));
writeFileSync(path.join(outDir, 'latencies.json'), JSON.stringify(latencies));
console.log(JSON.stringify({ requests: stats.requests, unexpected: stats.unexpected, seconds: stats.seconds,
                             states: stats.states, festival: stats.festival }));
