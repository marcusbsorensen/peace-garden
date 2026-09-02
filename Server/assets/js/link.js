// A seed in a link, read on the web.
//
// The payload rides in the URL's **fragment**, which is not in the request
// line, not in `Referer`, and not in a log. That is the whole reason it lives
// there, and it is the one property this page exists to keep: nothing here ever
// puts a field of it into a query string, an image URL, or a fetch.
//
// The honest sentence is the narrow one, and it should stay that shape: the
// page they land on learns nothing *about the seed*. The request still happens,
// so the origin sees an IP address, a time and a user agent, because that is
// what serving a file is.
//
// **This is a port**, of `PollenLink` in `Packages/SeedCore`. It reads the wire
// format and computes the six-byte checksum, and it does no derivation: no
// genome, no geometry, no crossing. That line is where docs/WEBSITE.md draws it
// — a hand-maintained port of the *geometry* is the one option that is off the
// table however convenient it looks, and a port of a small, stable, pinned
// piece of the format is the one it says is cheap to gate.
//
// SEAM: nothing gates this yet. `PollenLinkTests.testFragmentMatchesReference`
// pins a fragment and `tools/reference/derivation_reference.py` writes the same
// one; `PINNED` below is that exact vector, and a CI step that parses it here
// is what would keep this file honest. Adding that step is a job in the app's
// repository, which this pass does not touch.

const DOMAIN = "peacegarden.link.v1";
const NONCE_BYTES = 16;
const SEED_BYTES = 32;
const FIELD_COUNT = 10;

/// The vector `PollenLinkTests` and `tools/reference/` both agree on. Kept here
/// so the gate described above has something to run against.
export const PINNED =
  "1.o.Ku7e0d-lNwWEMUuvt60W5NfNA4L-0el_yvIjjCHISDM" +
  ".AAECAwQFBgcICQoLDA0ODw.1700000000.TWFyY3Vz" +
  ".QXVyZWxpYSBub2N0dXJuYQ...Ztri7XhK";

export class LinkError extends Error {
  constructor(reason, version) {
    super(reason);
    this.reason = reason; // "notASeed" | "newerVersion" | "damaged"
    this.version = version;
  }
}

function decode(field) {
  const padded = field.replace(/-/g, "+").replace(/_/g, "/");
  const binary = atob(padded + "=".repeat((4 - (padded.length % 4)) % 4));
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function text(bytes) {
  return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
}

/// `seedDigest(domain, part)`, from `Determinism/Digest.swift`: the domain, a
/// zero byte, then each part's length big-endian followed by the part. Six
/// bytes of it is plenty to catch a link a messaging app has wrapped or
/// truncated, which is the only failure it needs to catch. It is not a
/// signature and cannot prove who sent anything.
async function checksum(body) {
  const part = new TextEncoder().encode(body);
  const domain = new TextEncoder().encode(DOMAIN);
  const buffer = new Uint8Array(domain.length + 1 + 4 + part.length);
  buffer.set(domain, 0);
  buffer[domain.length] = 0;
  new DataView(buffer.buffer).setUint32(domain.length + 1, part.length, false);
  buffer.set(part, domain.length + 5);

  const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", buffer));
  let binary = "";
  for (const byte of digest.slice(0, 6)) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/// Reads a fragment. Throws a `LinkError` and never a bare string.
///
/// The field count is fixed and unused fields are empty, so a truncated link
/// fails to parse rather than parsing as something else.
export async function parse(fragment) {
  const raw = String(fragment || "").replace(/^#/, "");
  if (!raw) throw new LinkError("notASeed");

  const fields = raw.split(".");
  if (fields.length !== FIELD_COUNT) throw new LinkError("notASeed");

  const version = Number.parseInt(fields[0], 10);
  if (!Number.isInteger(version)) throw new LinkError("notASeed");
  if (version !== 1) throw new LinkError("newerVersion", version);

  const body = fields.slice(0, 9).join(".");
  // A browser without `crypto.subtle` — which means an insecure context —
  // reads the link rather than refusing it. The checksum catches mangling, and
  // being unable to run it is not evidence of mangling.
  if (globalThis.crypto && crypto.subtle) {
    if ((await checksum(body)) !== fields[9]) throw new LinkError("damaged");
  }

  try {
    const kind = fields[1];
    if (kind !== "o" && kind !== "r") throw new LinkError("damaged");

    const seed = decode(fields[2]);
    const nonce = decode(fields[3]);
    if (seed.length !== SEED_BYTES || nonce.length !== NONCE_BYTES) {
      throw new LinkError("damaged");
    }

    const seconds = Number(fields[4]);
    if (!Number.isFinite(seconds)) throw new LinkError("damaged");

    const link = {
      version,
      kind,
      seed,
      nonce,
      birth: new Date(seconds * 1000),
      displayName: text(decode(fields[5])),
      plantName: text(decode(fields[6])),
      echo: fields[7] ? decode(fields[7]) : null,
      check: fields[8] ? decode(fields[8]) : null,
    };

    // A reply without both is unusable: the sender could not reach the same
    // plant, and could not tell that they had not.
    if (kind === "r" && (!link.echo || !link.check)) throw new LinkError("damaged");
    return link;
  } catch (error) {
    if (error instanceof LinkError) throw error;
    throw new LinkError("damaged");
  }
}
