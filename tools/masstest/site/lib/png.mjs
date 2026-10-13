// Enough of PNG to compare two screenshots from Chrome: 8-bit RGB or RGBA,
// not interlaced, which is what `page.screenshot({ type: 'png' })` writes.
import { inflateSync } from 'node:zlib';

export function decode(buffer) {
  let at = 8;
  let width = 0, height = 0, channels = 4;
  const data = [];
  while (at < buffer.length) {
    const length = buffer.readUInt32BE(at);
    const type = buffer.toString('ascii', at + 4, at + 8);
    const body = buffer.subarray(at + 8, at + 8 + length);
    if (type === 'IHDR') {
      width = body.readUInt32BE(0);
      height = body.readUInt32BE(4);
      const colour = body[9];
      channels = colour === 6 ? 4 : colour === 2 ? 3 : colour === 0 ? 1 : 4;
    } else if (type === 'IDAT') data.push(body);
    else if (type === 'IEND') break;
    at += 12 + length;
  }
  const raw = inflateSync(Buffer.concat(data));
  const stride = width * channels;
  const pixels = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y++) {
    const filter = raw[y * (stride + 1)];
    const line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
    const out = pixels.subarray(y * stride, (y + 1) * stride);
    const prev = y ? pixels.subarray((y - 1) * stride, y * stride) : Buffer.alloc(stride);
    for (let x = 0; x < stride; x++) {
      const a = x >= channels ? out[x - channels] : 0;
      const b = prev[x];
      const c = x >= channels ? prev[x - channels] : 0;
      let v = line[x];
      if (filter === 1) v += a;
      else if (filter === 2) v += b;
      else if (filter === 3) v += (a + b) >> 1;
      else if (filter === 4) {
        const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c);
        v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c;
      }
      out[x] = v & 255;
    }
  }
  return { width, height, channels, pixels };
}

/// The share of pixels that differ by more than `threshold` in any channel.
export function difference(one, other, threshold = 8) {
  const a = decode(one), b = decode(other);
  if (a.width !== b.width || a.height !== b.height) return 1;
  let changed = 0;
  const n = a.width * a.height;
  for (let i = 0; i < n; i++) {
    for (let c = 0; c < Math.min(3, a.channels); c++) {
      if (Math.abs(a.pixels[i * a.channels + c] - b.pixels[i * b.channels + c]) > threshold) { changed++; break; }
    }
  }
  return changed / n;
}
