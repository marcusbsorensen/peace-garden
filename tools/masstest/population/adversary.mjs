// The adversarial cases, each one request or a short sequence with the answer
// the service should give.
//
//   node adversary.mjs POOL.jsonl OUT_DIR [--db main] [--from 0]
//
// Uses true crosses from a pool plan popgen made apart from the population, so
// nothing here disturbs a gardener's plant. Writes OUT_DIR/adversary.json (every
// case, wanted and got), OUT_DIR/forged_adversary.json (seeds that must never
// stand anywhere, for check.php) and OUT_DIR/extra_genuine_adversary.json (the
// true crosses it planted or released, so the verifier does not count them as
// strangers).

import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { request, post, get, serviceCommand, readPlan, arrival, inventedCross, randomHex,
         AREA_ROUTES } from './lib.mjs';

const argv = process.argv.slice(2);
const option = (name, fallback) => { const i = argv.indexOf(`--${name}`); return i >= 0 ? argv[i + 1] : fallback; };
const [poolFile, outDir] = argv;
const DB = `pgmt_${option('db', 'main')}`;
let cursor = Number(option('from', 0));
const { meetings } = readPlan(poolFile);
const nextMeeting = () => meetings[cursor++];

const cases = [];
const forged = [];
const genuine = [];
let addresses = 0;
const fresh = () => `172.16.${(++addresses >> 8) & 255}.${addresses & 255}`;

async function expect(name, promise, want, check) {
    const res = await promise;
    let ok = want.includes(res.status);
    let why = '';
    if (ok && check) {
        why = check(res) || '';
        ok = !why;
    }
    cases.push({ name, want, got: res.status, ok, why: why || undefined, body: ok ? undefined : res.text.slice(0, 240) });
    return res;
}
const send = (route, body, addr = fresh()) => post(route, body, { addr, db: DB });
const raw = (route, text, addr = fresh(), headers = {}) => request('POST', route, { raw: text, addr, db: DB, headers });
const tokens = (m, g) => (g === 'a' ? { ours: m.tokenA, theirs: m.tokenB } : { ours: m.tokenB, theirs: m.tokenA });
const releaseBody = (m, extra = {}) => ({ seed: m.seed, parents: m.parents, encounter: m.encounter, ...extra });
const offerBody = (m, g = 'a') => ({ to: tokens(m, g).theirs, from: tokens(m, g).ours, plant: arrival(m) });

// MARK: - Forged crosses and wrong meetings

{
    const m = nextMeeting();
    const other = nextMeeting();
    const bogus = randomHex(32);
    forged.push(bogus);
    await expect('release: a seed that is not the cross', send('/api/wild/release', releaseBody(m, { seed: bogus })), [422]);
    await expect('offer: a seed that is not the cross', send('/api/walk/offer', { ...offerBody(m), plant: { ...arrival(m), seed: bogus } }), [422]);
    await expect('release: the right seed, the wrong meeting', send('/api/wild/release', releaseBody(m, { encounter: other.encounter })), [422]);
    await expect('offer: the right seed, the wrong meeting', send('/api/walk/offer', { ...offerBody(m), plant: { ...arrival(m), encounter: other.encounter } }), [422]);
    await expect('release: one parent swapped for a stranger\'s', send('/api/wild/release', releaseBody(m, { parents: [m.parents[0], other.parents[1]] })), [422]);
    await expect('release: three parents', send('/api/wild/release', releaseBody(m, { parents: [...m.parents, other.parents[0]] })), [400]);
    await expect('release: upper-case hex', send('/api/wild/release', releaseBody(m, { seed: m.seed.toUpperCase() })), [400]);
    await expect('offer: from and to the same token', send('/api/walk/offer', { to: m.tokenA, from: m.tokenA, plant: arrival(m) }), [400]);
    forged.push(m.seed.toUpperCase());

    // **An invented lineage**: parents nobody holds and a meeting that never
    // happened, crossed by the caller. The service's one check passes, by design
    // (a token carries consent, not authenticity); only the rate limit slows it.
    const pa = randomHex(32), pb = randomHex(32), enc = randomHex(32);
    const invented = await inventedCross(pa, pb, enc);
    await expect('release: an invented lineage (accepted by design)', send('/api/wild/release', { seed: invented, parents: [pa, pb], encounter: enc }), [201]);
    genuine.push(invented);
    // **A plant crossed with itself**: both parents the same seed. The app's
    // exchange aborts this ("same seed"); the service took it until 14 October
    // 2026 and refuses it with 422 since.
    const self = await inventedCross(pa, pa, enc);
    const selfRes = await send('/api/wild/release', { seed: self, parents: [pa, pa], encounter: enc });
    cases.push({ name: 'release: a plant crossed with itself (the app never makes one)', want: [422, 400], got: selfRes.status,
                 ok: [400, 422].includes(selfRes.status), body: selfRes.text.slice(0, 200) });
    if (selfRes.status === 201) genuine.push(self);
}

// MARK: - Tokens: replayed, stolen, swapped

{
    const m = nextMeeting();
    genuine.push(m.seed);
    const first = await expect('offer: a true cross, first time', send('/api/walk/offer', offerBody(m)), [201]);
    await expect('offer: the same request replayed', send('/api/walk/offer', offerBody(m)), [200],
                 (r) => (r.json?.offer?.state === 'offered' ? '' : 'not the same offer'));
    await expect('offer: the other phone offering the same child', send('/api/walk/offer', offerBody(m, 'b')), [200]);
    await expect('offer: the same plant with two invented tokens', send('/api/walk/offer', { to: randomHex(16), from: randomHex(16), plant: arrival(m) }), [409],
                 (r) => (JSON.stringify(r.json).includes(m.tokenA) ? 'leaked a token' : ''));
    await expect('offer: the real recipient, an invented sender', send('/api/walk/offer', { to: m.tokenB, from: randomHex(16), plant: arrival(m) }), [409]);
    await expect('answer: the offerer answering their own offer', send('/api/walk/answer', { seed: m.seed, to: m.tokenA, yes: true }), [404]);
    await expect('answer: an invented token', send('/api/walk/answer', { seed: m.seed, to: randomHex(16), yes: true }), [404]);
    await expect('withdraw: an invented token', send('/api/walk/withdraw', { seed: m.seed, token: randomHex(16) }), [404]);
    const yes = await expect('answer: yes, by the right token', send('/api/walk/answer', { seed: m.seed, to: m.tokenB, yes: true }), [200],
                             (r) => (r.json?.planting ? '' : 'nothing planted'));
    await expect('answer: yes, replayed', send('/api/walk/answer', { seed: m.seed, to: m.tokenB, yes: true }), [200],
                 (r) => (r.json?.offer?.state === 'accepted' && r.json.planting === null ? '' : 'replay changed something'));
    // Now its seed, parents and meeting are public.
    const route = AREA_ROUTES[m.area];
    const plot = yes.json?.planting?.plot ?? 0;
    const page = await get(`/api/${route}/plot/${plot}`, { db: DB });
    const shown = page.json?.plantings?.find((p) => p.seed === m.seed);
    cases.push({ name: 'the accepted plant is public with its meeting', want: ['present'], got: shown ? 'present' : 'absent', ok: !!shown });
    const stolen = nextMeeting();
    await expect('release: a stranger, no token, a published plant', send('/api/wild/release', releaseBody(m)), [403]);
    await expect('release: a stranger with a token stolen from another meeting', send('/api/wild/release', releaseBody(m, { token: stolen.tokenA, theirs: stolen.tokenB })), [403]);
    await expect('offer: a stranger re-offering a published plant', send('/api/walk/offer', { to: stolen.tokenA, from: stolen.tokenB, plant: arrival(m) }), [409]);
    await expect('withdraw: by the recipient', send('/api/walk/withdraw', { seed: m.seed, token: m.tokenB }), [200],
                 (r) => (r.json?.offer?.state === 'withdrawn' ? '' : 'not withdrawn'));
    const after = await get(`/api/${route}/plot/${plot}`, { db: DB });
    cases.push({ name: 'a withdrawn planting leaves its plot', want: ['absent'], ok: !after.json?.plantings?.some((p) => p.seed === m.seed),
                 got: after.json?.plantings?.some((p) => p.seed === m.seed) ? 'present' : 'absent' });
    await expect('offer: the withdrawn plant again, by the same pair', send('/api/walk/offer', offerBody(m)), [200],
                 (r) => (r.json?.offer?.state === 'withdrawn' ? '' : `came back as ${r.json?.offer?.state}`));
    await expect('offer: the withdrawn plant again, by strangers', send('/api/walk/offer', { to: randomHex(16), from: randomHex(16), plant: arrival(m) }), [409]);
    await expect('release: the withdrawn plant, by a stranger', send('/api/wild/release', releaseBody(m, { token: randomHex(16) })), [403]);
    await expect('release: the withdrawn plant, by one of the two', send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenB })), [201]);
    void first;
}

// MARK: - Released twice, hidden, and back

{
    const m = nextMeeting();
    genuine.push(m.seed);
    const shown = { name: 'Robert\'); DROP TABLE wild_fields;--', place: '1\' OR \'1\'=\'1', month: '2026-10' };
    const one = await expect('release: with names, SQL-shaped', send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenB, shown })), [201]);
    await expect('release: the same gardener again', send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenB, shown })), [200],
                 (r) => (JSON.stringify(r.json?.planting?.spot) === JSON.stringify(one.json?.planting?.spot) ? '' : 'moved'));
    await expect('release: the other gardener\'s copy', send('/api/wild/release', releaseBody(m, { token: m.tokenB, theirs: m.tokenA, shown: { name: 'مريم', place: shown.place } })), [200],
                 (r) => (r.json?.beside?.released === false ? '' : 'not answered as the other side'));
    const tile = one.json?.planting?.spot ? [Math.floor(one.json.planting.spot[0] / 8), Math.floor(one.json.planting.spot[1] / 8)] : [0, 0];
    const listed = await get(`/api/wild/tile/${tile[0]}/${tile[1]}`, { db: DB });
    const row = listed.json?.plantings?.find((p) => p.seed === m.seed);
    cases.push({ name: 'SQL-shaped and RTL names come back exactly, place shown once both agree', want: ['exact'],
                 got: row?.shown ? JSON.stringify(row.shown) : 'none',
                 ok: !!row && JSON.stringify(row.shown?.names) === JSON.stringify([shown.name, 'مريم'].sort()) && row.shown?.place === shown.place });
    await expect('wild answer: a stranger', send('/api/wild/answer', { seed: m.seed, token: randomHex(16), shown: { name: 'x' } }), [404]);
    const hide = serviceCommand('curate.php', ['hide', m.seed.slice(0, 10)], DB);
    cases.push({ name: 'curate.php hide', want: ['Hidden'], got: hide.out.split('\n')[0], ok: hide.out.startsWith('Hidden') });
    const gone = await get(`/api/wild/tile/${tile[0]}/${tile[1]}`, { db: DB });
    cases.push({ name: 'a hidden plant is in no tile', want: ['absent'], ok: !gone.json?.plantings?.some((p) => p.seed === m.seed),
                 got: gone.json?.plantings?.some((p) => p.seed === m.seed) ? 'present' : 'absent' });
    await expect('release: a hidden plant, by its releaser', send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenB })), [410]);
    await expect('release: a hidden plant, no token', send('/api/wild/release', releaseBody(m)), [410]);
    await expect('offer: a hidden plant', send('/api/walk/offer', offerBody(m)), [410]);
    const pend = await send('/api/walk/pending', { tokens: [m.tokenA] });
    cases.push({ name: 'pending still tells the releaser about a hidden plant (README says so)', want: ['told'],
                 got: pend.json?.wild?.length ? 'told' : 'silent', ok: !!pend.json?.wild?.length });
    const unhide = serviceCommand('curate.php', ['unhide', m.seed], DB);
    cases.push({ name: 'curate.php unhide', want: ['Standing again'], got: unhide.out.split('\n')[0], ok: unhide.out.startsWith('Standing again') });
    await expect('release: after unhide, answered as standing', send('/api/wild/release', releaseBody(m)), [200]);
    const short = serviceCommand('curate.php', ['hide', m.seed.slice(0, 5)], DB);
    cases.push({ name: 'curate.php refuses fewer than six characters', want: [2], got: short.code, ok: short.code === 2 });
}

// MARK: - Malformed and oversized

{
    const m = nextMeeting();
    const r = '/api/wild/release';
    await expect('body: not JSON', raw(r, '{"seed": '), [400]);
    await expect('body: a JSON array', raw(r, '[1,2,3]'), [400]);
    await expect('body: a JSON string', raw(r, '"seed"'), [400]);
    await expect('body: empty', raw(r, ''), [400]);
    await expect('body: nested 600 deep', raw(r, '['.repeat(600) + ']'.repeat(600)), [400]);
    await expect('body: invalid UTF-8', raw(r, Buffer.from([0x7b, 0x22, 0xff, 0xfe, 0x22, 0x3a, 0x31, 0x7d])), [400]);
    await expect('body: a lone surrogate in a name', raw(r, JSON.stringify(releaseBody(m, { token: m.tokenA, theirs: m.tokenB })).replace(/}$/, ',"shown":{"name":"\\ud800"}}')), [400]);
    await expect('body: 9 KB, cut at 8 KB by readBody', raw(r, JSON.stringify({ ...releaseBody(m), pad: 'x'.repeat(9000) })), [400]);
    const big = await raw(r, JSON.stringify({ ...releaseBody(m), pad: 'x'.repeat(2_000_000) }));
    cases.push({ name: 'body: 2 MB (nginx default limit is 1 MB)', want: [413, 400], got: big.status, ok: [400, 413].includes(big.status) });
    const huge = await raw(r, JSON.stringify({ ...releaseBody(m), pad: 'x'.repeat(900_000) }));
    cases.push({ name: 'body: 900 KB (under nginx\'s limit; PHP reads 8 KB)', want: [400], got: huge.status, ok: huge.status === 400 });
    const o = '/api/walk/offer';
    const plant = arrival(m);
    await expect('offer: height as a string', send(o, { ...offerBody(m), plant: { ...plant, height: '1.0' } }), [400]);
    await expect('offer: height 1e309', raw(o, JSON.stringify(offerBody(m)).replace(/"height":[0-9.e-]+/, '"height":1e309')), [400]);
    await expect('offer: family 7', send(o, { ...offerBody(m), plant: { ...plant, family: 7 } }), [400]);
    await expect('offer: family 3.0', raw(o, JSON.stringify(offerBody(m)).replace(/"family":\d+/, '"family":3.0')), [400]);
    await expect('offer: hue exactly 1', send(o, { ...offerBody(m), plant: { ...plant, hue: 1 } }), [400]);
    await expect('offer: kind with a capital', send(o, { ...offerBody(m), plant: { ...plant, kind: 'Noctiflora' } }), [400]);
    await expect('offer: kind of 65 letters', send(o, { ...offerBody(m), plant: { ...plant, kind: 'a'.repeat(65) } }), [400]);
    await expect('offer: kind with an accent', send(o, { ...offerBody(m), plant: { ...plant, kind: 'café' } }), [400]);
    await expect('offer: an area that does not exist', send(o, { ...offerBody(m), plant: { ...plant, area: 'moon' } }), [400]);
    await expect('offer: area as an array', send(o, { ...offerBody(m), plant: { ...plant, area: ['travel'] } }), [400]);
    await expect('offer: kind as a number', send(o, { ...offerBody(m), plant: { ...plant, kind: 5 } }), [400]);
    await expect('release: token as a number', send(r, releaseBody(m, { token: 12345 })), [400]);
    await expect('release: shown as a string', send(r, releaseBody(m, { token: m.tokenA, theirs: m.tokenB, shown: 'Anna' })), [400]);
    await expect('release: name as a number', send(r, releaseBody(m, { token: m.tokenA, theirs: m.tokenB, shown: { name: 42 } })), [400]);
    await expect('pending: 129 tokens', send('/api/walk/pending', { tokens: Array.from({ length: 129 }, () => randomHex(16)) }), [400]);
    await expect('pending: 128 tokens', send('/api/walk/pending', { tokens: Array.from({ length: 128 }, () => randomHex(16)) }), [200]);
    await expect('pending: tokens as an object', send('/api/walk/pending', { tokens: { a: randomHex(16) } }), [200, 400]);
    await expect('pending: a token that is a fingerprint', send('/api/walk/pending', { tokens: ['h' + randomHex(16).slice(1)] }), [400]);
    await expect('GET on a write route', get('/api/wild/release', { db: DB }), [404]);
    await expect('tile 8 (one past the edge)', get('/api/wild/tile/8/0', { db: DB }), [404]);
    await expect('tile 08', get('/api/wild/tile/08/01', { db: DB }), [404]);
    await expect('plot 999999 of the walk', get('/api/walk/plot/999999', { db: DB }), [200]);
    await expect('the service file itself', get('/.api/router.php'), [403]);
    await expect('config.php', get('/.api/config.php'), [403]);
}

// MARK: - Names: unicode, RTL, emoji, limits

{
    const tryName = async (label, name, want) => {
        const m = nextMeeting();
        const res = await expect(`name: ${label}`, send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenB, shown: { name } })), want);
        if (res.status === 201) genuine.push(m.seed);
        return res;
    };
    await tryName('Arabic', 'مريم', [201]);
    await tryName('Hebrew', 'דניאל', [201]);
    await tryName('emoji without a joiner', 'Rose 🌹', [201]);
    await tryName('48 emoji (48 code points)', '🌿'.repeat(48), [201]);
    await tryName('49 code points', 'a'.repeat(49), [400]);
    await tryName('combining marks: 24 letters, 48 code points', 'é'.repeat(24), [201]);
    await tryName('right-to-left override U+202E', 'abc‮def', [400]);
    await tryName('emoji with a zero-width joiner (the app strips it first)', '🧑‍🌾', [400]);
    await tryName('Persian with ZWNJ (the app strips it first)', 'می‌خواهم', [400]);
    await tryName('a NUL byte', 'a\u0000b', [400]);
    await tryName('only spaces', '     ', [400]);
    await tryName('HTML', '<img src=x onerror=alert(1)>', [201]);
    await tryName('no-break spaces round it (PHP trims ASCII only)', ' Anna ', [201]);
    const m = nextMeeting();
    await expect('month: 2026-13', send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenB, shown: { month: '2026-13' } })), [400]);
    await expect('shown without theirs', send('/api/wild/release', releaseBody(m, { token: m.tokenA, shown: { name: 'x' } })), [400]);
    await expect('theirs equal to token', send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenA })), [400]);
}

// MARK: - The rate limit

// Two counts since 14 October 2026 (Limits.php): one per gardener, by the
// meeting token the request carries (or the plant, for a release without a
// token), at the old allowances; and one per address, CROWD (5) times that,
// shared by everybody behind it. IPv6 is counted by /64.
{
    const PERSONAL = 9;
    const CEILING = 45;
    const releaseFrom = async (addr, extra = {}) => {
        const m = nextMeeting();
        const res = await send('/api/wild/release', releaseBody(m, extra), addr);
        if (res.status === 201) genuine.push(m.seed);
        return res.status;
    };
    const firstRefusal = (statuses) => statuses.indexOf(429);

    // One machine on one address, a different plant each time and no token:
    // every plant passes its own count, and the address's ceiling refuses.
    const one = '192.0.2.10';
    const statuses = [];
    for (let i = 0; i < CEILING + 2; i++) statuses.push(await releaseFrom(one));
    cases.push({ name: `rate limit: one address, ${CEILING + 2} releases`, want: [`${CEILING} then 429`],
                 got: `${statuses.filter((s) => s === 201).length} accepted, first 429 at ${firstRefusal(statuses) + 1}`,
                 ok: statuses.filter((s) => s === 201).length === CEILING && firstRefusal(statuses) === CEILING });

    // One gardener — one token — from a fresh address each time: the
    // per-gardener count refuses, wherever the requests come from.
    const token = randomHex(16);
    const mine = [];
    for (let i = 0; i < PERSONAL + 2; i++) mine.push(await releaseFrom(fresh(), { token }));
    cases.push({ name: `rate limit: one token from ${PERSONAL + 2} addresses`, want: [`${PERSONAL} then 429`],
                 got: `${mine.filter((s) => s === 201).length} accepted, first 429 at ${firstRefusal(mine) + 1}`,
                 ok: mine.filter((s) => s === 201).length === PERSONAL && firstRefusal(mine) === PERSONAL });

    // A workshop: forty gardeners on one router, each releasing their own
    // plant with their own token. Before, the tenth was refused.
    const venue = '203.0.113.50';
    const crowd = [];
    for (let i = 0; i < 40; i++) {
        const m = nextMeeting();
        const res = await send('/api/wild/release', releaseBody(m, { token: m.tokenA, theirs: m.tokenB }), venue);
        if (res.status === 201) genuine.push(m.seed);
        crowd.push(res.status);
    }
    cases.push({ name: 'rate limit: forty gardeners on one address each release a plant', want: ['40 accepted'],
                 got: `${crowd.filter((s) => s === 201).length} accepted`, ok: crowd.every((s) => s === 201) });

    // A festival: a hundred phones on the venue's Wi-Fi each open the app
    // three times. Before, a quarter were refused (finding 6).
    const festival = '203.0.113.51';
    const phones = Array.from({ length: 100 }, () => [randomHex(16), randomHex(16), randomHex(16)]);
    const polls = [];
    for (let round = 0; round < 3; round++) {
        polls.push(...(await Promise.all(phones.map((bag) => send('/api/walk/pending', { tokens: bag }, festival))))
            .map((r) => r.status));
    }
    cases.push({ name: 'rate limit: a hundred phones on one Wi-Fi ask pending three times each', want: ['none refused'],
                 got: `${polls.filter((s) => s === 429).length} of ${polls.length} refused`, ok: polls.every((s) => s === 200) });

    // One phone on IPv6 holds a /64: every address in it is one caller now.
    const v6 = [];
    for (let i = 0; i < CEILING + 2; i++) v6.push(await releaseFrom(`2001:db8:1:2::${(i + 1).toString(16)}`));
    const v6accepted = v6.filter((s) => s === 201).length;
    cases.push({ name: `rate limit: ${CEILING + 2} releases from one IPv6 /64`, want: [`${CEILING} then 429`],
                 got: `${v6accepted} accepted`, ok: v6accepted === CEILING && firstRefusal(v6) === CEILING });
    const apart = [];
    for (let i = 0; i < 10; i++) apart.push(await releaseFrom(`2001:db8:2:${(i + 1).toString(16)}::1`));
    cases.push({ name: 'rate limit: ten /64s are ten callers', want: ['10 accepted'],
                 got: `${apart.filter((s) => s === 201).length} accepted`, ok: apart.every((s) => s === 201) });

    // Malformed requests spend the address's allowance: counted before the
    // body is read, where no token is known yet.
    const two = '192.0.2.11';
    for (let i = 0; i < CEILING; i++) await raw('/api/wild/release', 'not json', two);
    const m = nextMeeting();
    const after = await send('/api/wild/release', releaseBody(m), two);
    cases.push({ name: `rate limit: ${CEILING} malformed releases spend the address's allowance`, want: [429], got: after.status,
                 ok: after.status === 429 });
    const retry = after.headers['retry-after'];
    cases.push({ name: 'rate limit: Retry-After present', want: ['a number'], got: retry ?? 'none', ok: /^\d+$/.test(retry ?? '') });
}

writeFileSync(path.join(outDir, 'adversary.json'), JSON.stringify({ db: DB, cases }, null, 1));
writeFileSync(path.join(outDir, 'forged_adversary.json'), JSON.stringify(forged));
writeFileSync(path.join(outDir, 'extra_genuine_adversary.json'), JSON.stringify(genuine));
const failed = cases.filter((c) => !c.ok);
console.log(JSON.stringify({ cases: cases.length, failed: failed.length, cursor }));
for (const c of failed) console.log('NOT AS WANTED:', JSON.stringify(c));
