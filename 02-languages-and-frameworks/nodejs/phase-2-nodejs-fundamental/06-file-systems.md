# File System (fs)

## Scope of This Topic

Node's `fs` module is the practical, everyday application of everything already covered — non-blocking I/O, the thread pool, streams, buffers. This topic is about the API surface and its footguns, not new mechanics.

## Three API Styles

```js
const fs = require('fs');
const fsPromises = require('fs/promises');

fs.readFile('f.txt', (err, data) => {});      // callback — async, non-blocking
fs.readFileSync('f.txt');                      // sync — BLOCKING, avoid in request paths
await fsPromises.readFile('f.txt');             // Promise-based — async, non-blocking, preferred in modern code
```

**Rule of thumb:** `fs/promises` for application code (works cleanly with `async`/`await`), raw callback API only when interfacing with older code, `*Sync` methods reserved for CLI scripts/startup-time config loading — never inside a request handler (see `non-blocking-io.md` for why).

## Common Operations

```js
await fsPromises.readFile('f.txt', 'utf8');           // read (encoding = string result, else Buffer)
await fsPromises.writeFile('f.txt', 'content');        // write (overwrites)
await fsPromises.appendFile('log.txt', 'new line\n');  // append
await fsPromises.unlink('f.txt');                      // delete file
await fsPromises.mkdir('dir', { recursive: true });    // create dir (recursive = create parents too)
await fsPromises.readdir('dir');                       // list directory contents
await fsPromises.stat('f.txt');                        // metadata: size, mtime, isDirectory(), etc.
await fsPromises.rename('old.txt', 'new.txt');          // move/rename
```

## Streaming Large Files (ties directly to `streams.md`)

```js
// Reading/writing large files — never fs.readFile for genuinely large files
const readStream = fs.createReadStream('huge.log');
const writeStream = fs.createWriteStream('huge-copy.log');
readStream.pipe(writeStream);
```

## `fs.watch` — File Change Detection

```js
fs.watch('config.json', (eventType, filename) => {
  console.log(eventType, filename); // 'change' or 'rename'
});
```

**Genuine gotcha:** `fs.watch` behavior is **platform-inconsistent** — event firing frequency, filename reliability, and even whether renames are detected differs between Linux (inotify), macOS (FSEvents), and Windows (ReadDirectoryChangesW). Production file-watching (e.g. hot-reload tooling) typically uses a library like `chokidar` that normalizes these differences rather than raw `fs.watch`.

## File Descriptors and Resource Leaks

Every open file consumes an OS-level file descriptor — a finite resource (`ulimit -n` on Unix, often 1024 default per process). Streams and `fs.open` calls that aren't properly closed on error leak descriptors, eventually causing `EMFILE: too many open files` errors under load — a real, recurring production incident class, especially with unclosed streams in error paths.

```js
// Leak risk — if writeStream errors, readStream is never explicitly closed unless using pipeline()
fs.createReadStream('a.txt').pipe(fs.createWriteStream('b.txt'));

// Safer — pipeline() guarantees cleanup of ALL streams in the chain on error
const { pipeline } = require('stream/promises');
await pipeline(fs.createReadStream('a.txt'), fs.createWriteStream('b.txt'));
```

## Path Safety — A Real Security Concern

Never build file paths directly from user input without validation — classic path traversal vulnerability:

```js
// VULNERABLE — user could pass '../../etc/passwd'
app.get('/files/:name', (req, res) => {
  res.sendFile(`/uploads/${req.params.name}`);
});

// SAFER — resolve and verify the result stays within the intended directory
const path = require('path');
const safePath = path.join('/uploads', path.basename(req.params.name)); // strips directory components
```

## Mental Model Summary

- Three API styles exist (callback, sync, Promise) — `fs/promises` is the modern default, `*Sync` is reserved for startup/CLI code, never request paths.
- Large file operations should use streams, not `readFile`/`writeFile`, to avoid loading entire files into memory.
- File descriptors are a finite OS resource — unclosed streams/handles on error paths are a real leak source; prefer `pipeline()` for automatic cleanup.
- User-supplied filenames/paths must be sanitized (`path.basename`, path containment checks) to prevent path traversal.

## Fullstack Angle — What You'd Actually Debug

- **`EMFILE: too many open files` under load** → file descriptor leak, usually unclosed streams in error paths — audit for raw `pipe()` without error handlers, migrate to `pipeline()`.
- **File-watch-based hot reload behaving inconsistently across dev machines** → raw `fs.watch` platform inconsistency — switch to `chokidar` or similar.
- **Directory traversal in a security scan/pentest report** → unsanitized user input building file paths — apply `path.basename` + containment check pattern.

## Architect Angle — What You'd Actually Decide

- **File descriptor limits as a capacity planning input**: `ulimit -n` and expected concurrent file operations should be part of a service's documented resource model, alongside memory/CPU — genuinely overlooked in most capacity reviews.
- **User-upload storage strategy**: direct filesystem writes from user input are a security surface — favor a dedicated upload service/library with built-in path sanitization and, ideally, object storage (S3-style) over direct local filesystem access for anything user-facing at scale.
- **Config loading pattern**: `*Sync` fs calls are architecturally acceptable (even preferred, for simplicity) at process startup (loading config before the server starts accepting requests) — the "never use Sync" rule applies to request-handling code paths, not initialization code, worth stating explicitly in team guidelines to avoid over-correction.

## Interview Q&A Rapid Fire

**Q: When is it acceptable to use `fs.readFileSync`?**
At process startup / CLI script context, before the event loop is handling concurrent requests — never inside a request handler, where it would block all other in-flight requests.

**Q: Why prefer `pipeline()` over manually chaining `fs.createReadStream().pipe()`?**
`pipeline()` guarantees all streams in the chain are properly destroyed/cleaned up if any one errors, preventing file descriptor leaks; raw `pipe()` requires manually attaching error listeners to every stream to achieve the same safety.

**Q: What's a path traversal vulnerability and how do you prevent it in Node?**
Building a file path directly from unsanitized user input (e.g. `../../etc/passwd`) to escape the intended directory. Prevent with `path.basename()` to strip directory components from user input, and/or verifying the resolved path stays within the intended base directory.

**Q: Why might `fs.watch` behave differently across a team's dev machines?**
Its underlying implementation is platform-specific (inotify on Linux, FSEvents on macOS, ReadDirectoryChangesW on Windows) with different event granularity and reliability guarantees — production tooling typically uses a normalizing library like `chokidar` instead of relying on raw `fs.watch` behavior.