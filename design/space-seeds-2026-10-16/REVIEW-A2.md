# Review of A2: Zone C cryptography

Reviewed 17 October 2026, against `origin/claude/zonec-a2` at `d69ab55`. The diff under review is `git diff origin/claude/space-seeds-design...origin/claude/zonec-a2`, which covers seven files. I checked it against DESIGN.md §3.5, §4 and §5, and against BUILD-PLAN.md A2 and risk 1. I read the code and did not build it. No Swift toolchain is available here. The checks I could make outside Xcode were run in Python, using the system `cryptography` library and a hand-written RFC 9180 key schedule.

## Verdict

**I found nothing serious.** The construction is sound and it matches the spec:

- the mark is HMAC-SHA256 truncated to 16 bytes, with its own domain, and it is compared in constant time;
- real slots and padding are built from the same kinds of parts;
- HPKE runs in base mode with the right suite and the right info string, and returns exactly 104 bytes;
- opening fails closed;
- the production K cannot be committed through any ordinary path;
- no secret reaches a log or an error message.

The findings below are a test that is likely to flake, one privacy gap between Debug and Release builds that becomes real once A3 lands, and some test and tooling gaps worth closing before A3 and A4 build on this code.

## Findings, most severe first

### 1. Medium: the timing test is likely to flake under load
`App/PeaceGardenTests/ZoneCCryptoTests.swift:454`

**Scenario.** The best pass takes about 90 ms against a bound of 100 ms, which leaves about 10% headroom. Taking the best of five passes protects against a single interrupted pass, but not against load that lasts the whole half-second the test runs. That kind of load comes from a parallel `xcodebuild test` with several simulator clones, Spotlight or a build running on the same Mac, or thermal throttling on a laptop. Under it, all five passes come in above 100 ms and the test goes red although the code has not changed. The figure is also measured on a Mac simulator. Phones at the iOS 17 floor (A12) are likely to be 1.5 to 3 times slower. So DESIGN.md:328's "a few tens of milliseconds" is already wrong on the machine that is fastest.

**Fix.** The test exists to catch a regression of an order of magnitude, such as a key generation per row or work done on the main thread. It does not need to hold the code to 100 ms.
- Assert `best < 300` in this test.
- Track the real figure with `measure(metrics: [XCTClockMetric()])` and a stored baseline, or behind an environment variable that only the scratch simulator run sets.
- Change DESIGN.md:328 to "about 100 ms on a Mac, a few hundred on the oldest supported phone, off the main thread". A4 must then keep the opening loop off the main actor.

### 2. Low to medium: Debug builds sign with a public K but talk to the production server
`App/PeaceGarden/ZoneC/ZoneCKey.swift:16-20, 36-46`; `App/PeaceGarden/WebGarden/PlotService.swift:30`

**Scenario.** `PlotService.origin` is `https://peacegarden.app` whatever the build configuration. Once A3 sends the `aloft` slot, a Debug build from Xcode that carries a seed from `out/` puts a row into the production pool, and that row is marked with the test K. The test K is published in this public repository. Anyone who holds a copy of the pool can then pick out exactly those rows without taking any app apart: 20i, a breach, a subpoena, or a server changed to log. Combined with the access logs or with snapshots (§4.5), that ties the developer's own address to sending space seeds. That is a weaker crowd than a Release seed gets, where K at least has to be extracted from the binary. The comment at `ZoneCKey.swift:18-20` presents the Debug/Release split as only a benefit. It does keep test seeds from being found as real seeds. But it makes the rows more recognisable, not less.

**Do the two kinds of build need to recognise each other?** No. TestFlight and App Store builds are Release builds, so they all share the production K, and that is the only compatibility that matters. A Debug phone will never find a real seed, and Release phones pass over its seeds. Returns do not depend on K, so a return from a Release finder to a Debug sender would still open. That combination cannot arise, though, because no Release phone finds a Debug seed.

**Fix (in A3, recorded here so it is not lost).** In a Debug build that talks to the production origin, send only padding in `aloft`: never a real seed from `out/`. Alternatively, point Debug builds at a staging origin. Also correct the comment at `ZoneCKey.swift:16-20` so that it names the cost as well as the benefit.

### 3. Low: no value made outside the app pins the info string's layout or the 56-byte payload inside HPKE
`App/PeaceGarden/ZoneC/ZoneCReturn.swift:136-138`; tests at `ZoneCCryptoTests.swift:281-334`

**Scenario.** Every return test seals and opens with the same `info(for:)`. Suppose someone reorders it to `spaceSeed ‖ domain`, or appends a separator. Every test still passes, but returns sealed by the old build and the new build stop opening for each other, so finds go silently unreported. The RFC A.2.1 vector does pin the suite, the key schedule and the AEAD. It does not pin Zone C's own framing. The mark has Python-made vectors (`:61-72`); the return has none.

**Fix.** Add one pinned vector that the Swift test opens. I made one in Python with a hand-written RFC 9180 key schedule. My implementation also opens both RFC A.2.1 ciphertexts, so the key schedule checks out. The vector uses these inputs:
- **recipient private key:** SHA-256(`peacegarden.zonec.test-seed-key.v1`)
- **ephemeral private key:** SHA-256(`peacegarden.zonec.test-ephemeral.v1`)
- **space seed:** `000102030405060708090a0b0c0d0e0f939fc180ccde6a689d4782f1d286460b`, which is `r` followed by its test-K mark from `:63`
- **info:** `peacegarden.zonec.back.v1 ‖ space seed`
- **payload:** `0x11`×32 ‖ `0x22`×16 ‖ `0x33`×8
- **no associated data**

The expected sealed 104 bytes are:

```
b92453afc2b9a737652487217cfedcf522e4675314e137c8cf040b70aa18ec703d8e3bffb6e68de987748cc0c4f53686bdca2ef8751a75f919dc770ac81fb4d2cf84a9d5328217f32d85616cb190434713f2130c7f6c490ed0cff1f87c4f24bd2460b60ebd2ba9c2
```

In Swift, derive the recipient key from its label with `SHA256.hash`, then assert that `ZoneCReturn.open(sealed, with: skR, spaceSeed: seed) == payload`. Those are test keys derived from public labels. Neither is production material.

### 4. Low: only one weak public key is tested
`App/PeaceGardenTests/ZoneCCryptoTests.swift:364-370`; `App/PeaceGarden/ZoneC/ZoneCSlots.swift:98`; `ZoneCReturn.swift:90-106`

**Scenario.** `splitSeedSlot` accepts any 32 bytes as a seed key, because CryptoKit does not validate X25519 points. The test shows that sealing to the all-zero key throws. It does not show why. CryptoKit might reject an all-zero input, or it might reject the all-zero shared secret that RFC 9180 §7.1.4 and RFC 7748 §6.1 call for. Only the second check also covers the other weak (low-order) public keys, the encodings with the top bit set, and the non-canonical encodings u = p and u = p + 1. Suppose a forged row carries one of those and a finder's seal succeeds. The shared secret is then fixed and known to everyone, so the finder's own seed in Zone C could be read by anyone who holds the pool. In practice an attacker who holds K can use a key of their own just as well, so the extra exposure is small. But the guarantee the comment at `:361-363` claims is untested beyond a single value.

**Fix.** Loop the test over the libsodium and RFC 7748 blocklist:
- 0 and 1;
- the two points of order 8 (`e0eb7a7c…b800` and `5f9c95bc…1157`);
- p − 1, p and p + 1;
- each of the above with byte 31's top bit set.

Assert that sealing to each one throws. If any of them seals, add an explicit all-zero check of the shared secret in `seal`. HPKE in CryptoKit does not expose the shared secret, so that check would mean validating the point before sealing. Also note for A4: seal the return *before* planting the cross or writing to `in/`, so that a key that is refused really does leave the seed "not found".

### 5. Low: the test and the comment show only the top bit, not that a key lies on the curve
`App/PeaceGarden/ZoneC/ZoneCSlots.swift:20-25`; `ZoneCCryptoTests.swift:223-246`

**Scenario.** The design is right: both slots build every key half from a real `Curve25519.KeyAgreement.PrivateKey`. CryptoKit clamps those keys and always encodes them canonically below p. Both the real return's `enc` and the server's padding (`sodium_crypto_scalarmult_base`, BUILD-PLAN:27) are made the same way, so the distributions match. The other parts match too: `r ‖ mark` against 32 random bytes, and ChaCha20-Poly1305 output against 72 random bytes. The rationale in the code, though, names only the top bit. A stronger distinguisher exists. A real key's u lies on the curve, so u³ + 486662u² + u is a square mod p. About half of all random field elements fail that test, so a few rows sort a pool with near certainty even after the top bit is cleared. Suppose a later change, or a server or Autonaut implementation, follows this comment rather than DESIGN.md:192 and "fixes" the padding by clearing the top bit of random bytes. The test at `:227` would still pass, and the padding would then be distinguishable from real rows.

**Fix.** Extend the comment: "a public key is canonical (below 2²⁵⁵ − 19, so the top bit is clear), lies on the curve rather than its twist, and is in the prime-order subgroup; only a real key has all three." In the test, add a curve-membership check (Euler's criterion mod p) to the existing control. Random bytes with the top bit cleared fail it about half the time, and padding never does. This needs a small 256-bit modular exponentiation helper in the test target. If that is too much, pin the property in S1's PHP test instead, using sodium.

### 6. Low: `make_key.sh` skips its ignore check when git fails, and nothing in CI guards against a tracked key
`tools/zonec/make_key.sh:36-42`; `.gitignore:55`

**Scenario.** The guard refuses only when `git check-ignore` exits with 1. If `git` is missing (exit 127), or the checkout is a tarball or a worktree that git cannot read (exit 128), the script goes on and writes K inside the repository tree unchecked. Separately, nothing stops K from reaching the public repository if a later `.gitignore` edit drops line 55, or if someone runs `git add -f`. GitHub's secret scanning does not recognise a Swift byte array.

**Fix.**
- In the script, when `$out` resolves to a path under `$root`, require exit status 0 and refuse on anything else.
- Add one step to `tests.yml` that fails if `git ls-files | grep -q ZoneCProductionKey`.
- Optionally, add a step that fails if `git check-ignore App/PeaceGarden/ZoneC/ZoneCProductionKey.swift` stops matching.

The rest of the script is careful and correct:
- It uses `umask 077` and writes to a temporary file beside the target, which line 55's `*` also ignores.
- K never appears on a command line: it is held in a shell variable and passed through a builtin `printf` into a pipe.
- It refuses to overwrite an existing key.
- It never prints K.
- It wraps the output in `#if !DEBUG`.

A Release build without the file fails at `ZoneCKey.swift:52` with an unresolved `ZoneCProductionKey`, as intended. That is by code reading, since I could not build here. CI runs only on Linux and builds no Release, so the requirement does not break CI. `project.yml:30` takes `App/PeaceGarden` as a folder, so the file is compiled once `xcodegen generate` has run. One related operational note: `git clean -fdx` deletes the file, so the copy kept outside the repository, which the script asks for, is the real safeguard.

## Points checked and found correct

- **Mark** (`ZoneCMark.swift`):
  - It computes the first 16 bytes of HMAC-SHA256(K, `peacegarden.zonec.mark.v1` ‖ r). The domain is fixed and `r` is a fixed 16 bytes, so the input cannot be ambiguous without a length prefix.
  - K is used for nothing else.
  - The comparison ORs the XOR of every byte over all 16 and has no early exit.
  - Wrong lengths are refused before any HMAC is computed.
  - I re-derived the test K (SHA-256 of `peacegarden.zonec.test-key.v1`) and all three mark vectors in Python. All of them match.
- **Slots** (`ZoneCSlots.swift`):
  - `aloft` is 64 bytes, as `r ‖ mark ‖ pk` or as 32 random bytes ‖ pk. `back` is 104 bytes, as `enc ‖ ct ‖ tag` or as pk ‖ 72 random bytes. Each part has the same length and the same distribution as its counterpart; see finding 5 for why that is true and the test is narrower.
  - Hex out is lowercase. Hex in is strict: exact length, lowercase only, no sign.
  - The random source is `SystemRandomNumberGenerator`, which is a CSPRNG, and its output is held to the exact count asked for.
  - One dependency lies outside A2: `r` must be 16 uniform bytes from a CSPRNG in Autonaut. A UUID's version and variant bits would mark every real seed.
- **HPKE** (`ZoneCReturn.swift`):
  - Base mode, `Curve25519_SHA256_ChachaPoly`, and info = `peacegarden.zonec.back.v1 ‖ space seed` (fixed lengths), with no associated data.
  - A fresh `Sender` is made per seal, so every seal has a fresh ephemeral key and sequence number 0.
  - The output is the 32-byte `enc` followed by the ciphertext, 56 + 16 bytes. CryptoKit's `seal` returns the ciphertext and tag only and adds no nonce or header. My independent Python seal of a 56-byte payload also gives exactly 104 bytes.
  - The runtime check at `:104` enforces 104 bytes.
- **Opening:**
  - Every failure is `try?` → nil, with no distinction between padding, wrong key, wrong seed, damage or wrong length.
  - `Payload(bytes:)` refuses anything that is not 56 bytes.
  - The tests cover a wrong key, a different seed, all 256 single-bit flips of the seed, every byte of the sealed row, and 300 paddings.
- **RFC vector:** the test uses RFC 9180 A.2.1, which is the right one: DHKEM(X25519, HKDF-SHA256), HKDF-SHA256, ChaCha20-Poly1305, base mode. I checked `skRm`, `pkRm`, `enc`, `info` and both ciphertexts with their "Count-0" and "Count-1" associated data in Python, and both open to "Beauty is truth, truth beauty". The vector checks only the opening direction, since CryptoKit cannot seal with a chosen ephemeral key. Finding 3 adds a vector in the app's own format.
- **Secrets in logs and errors:**
  - `SealError` carries no data.
  - The `precondition` messages report only counts.
  - The test prints only timings.
  - `Data`'s description prints a byte count, not the contents, so `Payload` is safe if it is ever interpolated into a string.
  - Nothing prints K, a private key, a seed or a payload.
- **Branch state, not a finding:** the two-dot diff in the task shows DESIGN.md decision 16 and the A5 consent-switch text being removed. That is only because `claude/zonec-a2` branched before `01c2a07`. The three-dot diff touches no document, and a normal merge keeps decision 16.

---
_Review only; no code changed._
