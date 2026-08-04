# Streams

## Scope of This Topic

Streams are Node's answer to processing data **without loading it entirely into memory** — chunks flow through incrementally instead of waiting for the whole thing to be available. This is the mechanism that makes Node genuinely good at handling large files, video, and network data efficiently, directly leveraging the non-blocking I/O model already covered.

```
Source ──chunk──▶ chunk ──chunk──▶ chunk ──chunk──▶ Destination
  (file, network request, etc.)                       (file, response, another stream)
```

## Why Streams Exist — The Problem They Solve

```js
// WITHOUT streams — entire file loaded into memory before anything happens
const fs = require('fs');
fs.readFile('huge-video.mp4', (err, data) => {
  response.end(data); // memory usage = full file size, and client waits for the ENTIRE read first
});

// WITH streams — chunks flow as they're read, memory usage stays flat
const readStream = fs.createReadStream('huge-video.mp4');
readStream.pipe(response); // client starts receiving data almost immediately
```

For a 2GB file, the non-streaming version needs ~2GB of RAM and the client waits for the full read to complete before any bytes arrive. The streaming version uses a small, constant buffer (a few chunks at a time) regardless of file size.

## Four Stream Types

| Type | Purpose | Examples |
|---|---|---|
| **Readable** | Source of data, read from | `fs.createReadStream`, HTTP request (server-side) |
| **Writable** | Destination for data, written to | `fs.createWriteStream`, HTTP response |
| **Duplex** | Both readable and writable, independent | TCP sockets |
| **Transform** | Duplex that modifies data as it passes through | `zlib.createGzip()`, encryption streams |

```js
const { Transform } = require('stream');

const upperCaseTransform = new Transform({
  transform(chunk, encoding, callback) {
    this.push(chunk.toString().toUpperCase());
    callback(); // signals "done with this chunk, ready for the next"
  }
});
```

## `pipe()` — The Core Composition Primitive

```js
fs.createReadStream('input.txt')
  .pipe(zlib.createGzip())          // Transform — compress
  .pipe(fs.createWriteStream('input.txt.gz')); // Writable — save
```

`pipe()` does three things automatically that manual chunk-handling wouldn't give you for free:
1. Moves data from readable to writable as it arrives
2. **Handles backpressure** (see below) — pauses the source if the destination can't keep up
3. Propagates `end`/`finish` events, closing the destination when the source is exhausted

## Backpressure — The Concept That Actually Matters

If a writable destination is slower than the readable source producing data, unbounded buffering would eventually exhaust memory. Streams solve this with an explicit signal:

```js
const canContinue = writableStream.write(chunk);
if (!canContinue) {
  // internal buffer is full — STOP writing more until 'drain' fires
  readableStream.pause();
}
writableStream.once('drain', () => {
  readableStream.resume(); // buffer emptied, safe to continue
});
```

`pipe()` handles this automatically — this is precisely why `pipe()` (or the modern `stream/promises` `pipeline()`) is strongly preferred over manually listening to `data` events and calling `write()` yourself, which silently skips backpressure handling and can blow up memory under a slow destination.

## Modern Pattern: `pipeline()` (preferred over raw `pipe()`)

```js
const { pipeline } = require('stream/promises');

async function compressFile() {
  await pipeline(
    fs.createReadStream('input.txt'),
    zlib.createGzip(),
    fs.createWriteStream('input.txt.gz')
  );
  // errors from ANY stream in the chain are caught here — raw pipe() requires manual error listeners on each stream
}
```

`pipeline()` also guarantees proper cleanup (destroying all streams) if any stream in the chain errors — a common source of file-descriptor leaks when using bare `pipe()` chains without individual error handlers.

## Object Mode

By default, streams work with `Buffer`/string chunks. **Object mode** allows streams to emit/accept arbitrary JS objects instead — useful for processing pipelines that aren't raw bytes (e.g. a CSV-parsing stream emitting row objects).

```js
const { Transform } = require('stream');

const parseCSVRow = new Transform({
  objectMode: true,
  transform(line, encoding, callback) {
    this.push({ parsed: line.toString().split(',') });
    callback();
  }
});
```

## Mental Model Summary

- Streams process data incrementally in chunks, keeping memory usage flat regardless of total data size.
- Four types: Readable (source), Writable (sink), Duplex (both), Transform (duplex that modifies data in-flight).
- `pipe()`/`pipeline()` handle backpressure automatically — manual chunk handling (`data` + `write()`) does not, and risks unbounded memory growth under a slow consumer.
- `pipeline()` is the modern preferred API — proper error propagation and cleanup across the whole chain, unlike raw `pipe()`.

## Fullstack Angle — What You'd Actually Debug

- **Large file upload/download causing memory spikes or OOM crashes** → likely reading the entire file into a `Buffer` (`fs.readFile`) instead of streaming (`fs.createReadStream` + `pipe`/`pipeline`) — classic fix for a classic bug.
- **File processing pipeline silently losing data or leaving open file descriptors on error** → missing error handlers on individual streams in a `pipe()` chain — migrate to `pipeline()` from `stream/promises` for automatic cleanup and single-point error handling.
- **Slow downstream consumer (e.g. slow client connection) causing server memory growth** → backpressure not being respected, usually from manually calling `.write()` in a `data` event handler without checking its boolean return value or using `pipe()`.

## Architect Angle — What You'd Actually Decide

- **Streaming as a default for large-payload endpoints**: file uploads/downloads, video/audio serving, and large export/report generation should be designed stream-first from the start — retrofitting streaming into a buffer-everything design later is a much bigger rework.
- **Backpressure-aware architecture at scale**: when composing services (e.g. proxying a large response from one service to another), the streaming approach naturally propagates backpressure across the whole chain — a genuine reliability property worth calling out in architecture reviews for data-heavy services.
- **Standardizing on `pipeline()` over raw `pipe()`** as a team-wide convention/lint rule — the error-handling and cleanup guarantees are significant enough to be a default, not a case-by-case choice.

## Interview Q&A Rapid Fire

**Q: Why use streams instead of just reading a whole file into memory?**
Streams process data in bounded-size chunks, so memory usage stays roughly constant regardless of total data size — critical for large files/video where loading everything into memory first would be slow (waits for full read) and potentially exhaust available memory.

**Q: What is backpressure and how does `pipe()` handle it?**
Backpressure is the situation where a writable destination can't consume data as fast as a readable source produces it. `pipe()` automatically pauses the readable source when the writable's internal buffer fills (`write()` returns `false`) and resumes it on the `drain` event — preventing unbounded memory growth.

**Q: What's the difference between `pipe()` and `pipeline()`, and why does it matter?**
`pipeline()` (from `stream/promises`) wraps multiple piped streams with unified error handling and guaranteed cleanup/destruction of all streams if any one errors. Raw `pipe()` requires manually attaching `error` listeners to every stream in the chain, and a missed one can leak file descriptors or silently drop errors.

**Q: What are the four stream types in Node?**
Readable (data source), Writable (data destination), Duplex (independently readable and writable, e.g. TCP sockets), and Transform (a Duplex stream that modifies data as it passes through, e.g. gzip compression).