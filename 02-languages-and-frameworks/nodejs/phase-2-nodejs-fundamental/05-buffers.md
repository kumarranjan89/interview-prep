# Buffers

## Scope of This Topic

`Buffer` is Node's way of handling **raw binary data** directly — something JS had no native mechanism for until `TypedArray`/`ArrayBuffer` arrived in the language itself (Node's `Buffer` predates those and is now built on top of `Uint8Array`). This is the layer underneath Streams (previous topic) — most stream chunks *are* Buffers by default.

## Why Buffers Exist

JS strings are UTF-16 internally and aren't suited for representing arbitrary binary data (image bytes, file contents, network packets, encrypted data) — a string assumes text encoding, binary data doesn't. `Buffer` is a fixed-length, raw memory allocation outside the normal V8 heap (in earlier Node versions) or within it as a `Uint8Array` subclass (modern Node) — either way, purpose-built for byte-level data.

```js
const buf = Buffer.from('hello');
console.log(buf);          // <Buffer 68 65 6c 6c 6f>  — raw byte values, hex
console.log(buf.length);   // 5 — byte length, NOT necessarily character count for non-ASCII text
console.log(buf.toString()); // 'hello' — decode back to string (default utf8)
```

## Creating Buffers

```js
Buffer.from('hello');              // from a string (default utf8 encoding)
Buffer.from('hello', 'utf16le');   // from a string, explicit encoding
Buffer.from([104, 101, 108, 108, 111]); // from an array of byte values
Buffer.alloc(10);                  // 10 zero-filled bytes — SAFE, always initializes memory
Buffer.allocUnsafe(10);            // 10 bytes, NOT initialized — faster, but may contain old memory data
```

**`Buffer.allocUnsafe` is a real security consideration** — the returned memory may contain leftover data from previous allocations (potentially sensitive data from elsewhere in the process). Only use it when you're about to immediately overwrite every byte yourself; `Buffer.alloc` is the safe default.

## Byte Length vs String Length — A Real Bug Source

```js
const str = '日本語'; // 3 characters
console.log(str.length);                    // 3 — JS string length counts UTF-16 code units
console.log(Buffer.byteLength(str, 'utf8'));  // 9 — actual UTF-8 byte length
```

This mismatch matters anywhere you're computing content length for a protocol header (`Content-Length` in HTTP) — using `.length` on a string with multi-byte characters instead of `Buffer.byteLength()` produces a wrong, too-small value, causing truncated response bodies on the client side. A genuinely common production bug with international text.

## Encoding — Converting Between Bytes and Text

```js
const buf = Buffer.from('hello', 'utf8');

buf.toString('utf8');    // 'hello' — default
buf.toString('base64');  // 'aGVsbG8=' — common for embedding binary in JSON/URLs
buf.toString('hex');     // '68656c6c6f' — common for hashes, checksums
```

`base64` and `hex` are the two most common encodings for **transporting binary data through text-only channels** (JSON payloads, URLs) — this is why file uploads via JSON APIs, JWT tokens, and hash digests are so often base64/hex-encoded strings.

## Buffers and Streams — The Connection

By default, `Readable` streams emit `Buffer` chunks (unless in object mode, covered in the Streams notes):

```js
const readStream = fs.createReadStream('file.bin');
readStream.on('data', (chunk) => {
  console.log(Buffer.isBuffer(chunk)); // true
  console.log(chunk.length);            // bytes in this chunk, not a fixed/predictable size
});
```

**Important gotcha:** stream chunk boundaries are **not guaranteed to align with logical data boundaries** — a chunk might cut a UTF-8 multi-byte character in half, or split a JSON object across two chunks. Naively calling `.toString()` on each chunk independently can produce corrupted output for multi-byte text; use `StringDecoder` (Node core module) or buffer the chunks and decode once fully received, when correctness matters.

```js
const { StringDecoder } = require('string_decoder');
const decoder = new StringDecoder('utf8');

readStream.on('data', (chunk) => {
  process.stdout.write(decoder.write(chunk)); // correctly handles multi-byte chars split across chunks
});
```

## Concatenating Buffers Correctly

```js
const chunks = [];
readStream.on('data', (chunk) => chunks.push(chunk));
readStream.on('end', () => {
  const fullBuffer = Buffer.concat(chunks); // single allocation, correct byte-level join
  // NOT chunks.join('') — that coerces each Buffer to a string first, which can corrupt binary data
});
```

## Mental Model Summary

- `Buffer` is Node's raw-byte data type — built on `Uint8Array`, purpose-built for binary data that strings aren't suited for.
- `Buffer.alloc` is always safe (zero-filled); `Buffer.allocUnsafe` is faster but can leak old memory contents — only use when immediately overwriting every byte.
- String `.length` counts UTF-16 code units, not bytes — use `Buffer.byteLength()` for actual byte size, especially for protocol headers.
- Stream chunks are Buffers by default, and chunk boundaries can split multi-byte characters — use `StringDecoder` or buffer-then-decode for correctness with text data.

## Fullstack Angle — What You'd Actually Debug

- **Garbled/corrupted text with non-English content, especially over streamed responses** → chunk boundary splitting a multi-byte UTF-8 character mid-sequence, decoded independently per chunk — fix with `StringDecoder` or decode only after full concatenation.
- **`Content-Length` mismatch errors or truncated response bodies with international text** → using string `.length` instead of `Buffer.byteLength()` when setting the header manually.
- **Slow or memory-spiking binary processing code** → check for repeated `Buffer.concat` calls in a loop (each call reallocates) versus collecting chunks in an array and concatenating once at the end.

## Architect Angle — What You'd Actually Decide

- **Binary data transport strategy**: base64 encoding inflates payload size by ~33% — for large binary payloads (file uploads, images) in high-throughput services, consider multipart/binary transport (raw bytes, `multipart/form-data`) over JSON+base64 wrapping, a real bandwidth/cost decision at scale.
- **Security review point**: `Buffer.allocUnsafe` usage anywhere in a codebase is worth flagging in security-focused code review — uninitialized memory exposure is a genuine (if narrow) vulnerability class, especially in services handling sensitive data.
- **I18n-heavy services**: services handling significant non-ASCII content (multi-language platforms) should have `Buffer.byteLength()` vs string-length correctness as an explicit code-review/lint checkpoint, since the bug class is subtle and easy to miss in review.

## Interview Q&A Rapid Fire

**Q: What is a Buffer and why does Node need it separately from strings?**
A fixed-length raw binary data structure (built on `Uint8Array`) for handling data that isn't text — file contents, network packets, images. JS strings assume a text encoding (UTF-16 internally) and aren't a correct representation for arbitrary binary data.

**Q: What's the difference between `Buffer.alloc` and `Buffer.allocUnsafe`?**
`Buffer.alloc(n)` returns `n` zero-filled bytes — always safe. `Buffer.allocUnsafe(n)` returns `n` bytes without initializing them, which is faster but may contain leftover data from previous memory allocations — only safe if every byte will be immediately overwritten.

**Q: Why might `string.length` give the wrong value for `Content-Length`?**
`.length` on a JS string counts UTF-16 code units, not bytes. Multi-byte UTF-8 characters (most non-ASCII text) have a byte length greater than their character count — use `Buffer.byteLength(str, 'utf8')` for the actual byte size a protocol header needs.

**Q: Why can naively decoding each stream chunk to a string independently corrupt output?**
Stream chunk boundaries don't align with logical/character boundaries — a chunk might end in the middle of a multi-byte UTF-8 sequence. Decoding that partial sequence alone produces garbled characters; `StringDecoder` buffers incomplete sequences across chunk boundaries to decode correctly.