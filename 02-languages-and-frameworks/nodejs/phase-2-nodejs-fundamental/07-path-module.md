# Path Module

## Scope of This Topic

`path` handles filesystem path manipulation **correctly across operating systems** — the entire reason it exists is that string-concatenating paths yourself breaks on Windows (`\` separator) vs POSIX (`/` separator).

## Core Methods

```js
const path = require('path');

path.join('/uploads', 'images', 'photo.jpg');
// '/uploads/images/photo.jpg' (POSIX) or '\uploads\images\photo.jpg' (Windows)
// Normalizes separators for the current OS — this is the whole point

path.resolve('uploads', 'photo.jpg');
// Absolute path, resolved against process.cwd() (current working directory)
// '/home/ranjan/project/uploads/photo.jpg'

path.basename('/uploads/photo.jpg');        // 'photo.jpg'
path.basename('/uploads/photo.jpg', '.jpg'); // 'photo' — strip extension too

path.dirname('/uploads/photo.jpg');          // '/uploads'
path.extname('/uploads/photo.jpg');          // '.jpg'

path.parse('/uploads/photo.jpg');
// { root: '/', dir: '/uploads', base: 'photo.jpg', ext: '.jpg', name: 'photo' }
```

## `join` vs `resolve` — The Distinction That Actually Matters

```js
path.join('/a', '../b');      // '/b' — treats segments as relative to each other, normalizes '..'
path.resolve('/a', '../b');   // '/b' — same result here, but...

path.join('a', 'b');          // 'a/b' — relative path, NOT resolved against cwd
path.resolve('a', 'b');       // '/current/working/dir/a/b' — always absolute
```

`join` just concatenates and normalizes segments (handles `..`/`.`/extra slashes) without caring whether the result is absolute. `resolve` always returns an absolute path, working right-to-left until an absolute segment is found (or falling back to `process.cwd()`).

**Interview-relevant nuance:** `path.resolve()` processes arguments **right to left**, stopping once it hits an absolute path:

```js
path.resolve('/foo', '/bar', 'baz'); // '/bar/baz' — '/bar' is absolute, so '/foo' is discarded entirely
```

## `__dirname` / `__filename` vs `process.cwd()`

A very common source of confusion — these are **not the same thing**:

```js
// __dirname: directory of the CURRENT FILE (fixed, based on file location)
// process.cwd(): directory the Node process was LAUNCHED FROM (can be anywhere)

// If you run `node /home/ranjan/project/src/index.js` from `/home/ranjan`:
console.log(__dirname);      // /home/ranjan/project/src
console.log(process.cwd());  // /home/ranjan
```

**Practical rule:** use `__dirname` (or `import.meta.url`-derived equivalent in ESM) for locating files **relative to your own source code** (config files, templates shipped with the package) — using `process.cwd()` for this breaks the moment someone runs your script from a different directory.

## Security Relevance — Path Sanitization (ties to `file-system.md`)

```js
const safeName = path.basename(userInput); // strips any directory traversal attempt
const safePath = path.join(UPLOAD_DIR, safeName);

// Extra safety: verify resolved path is actually still inside the intended directory
if (!path.resolve(safePath).startsWith(path.resolve(UPLOAD_DIR))) {
  throw new Error('Invalid path');
}
```

## Mental Model Summary

- `path` exists specifically to avoid hand-rolled, OS-specific path string bugs — always use it over manual string concatenation for file paths.
- `join` normalizes/concatenates segments without guaranteeing an absolute result; `resolve` always produces an absolute path, processed right-to-left.
- `__dirname` = where the file lives (stable); `process.cwd()` = where the process was launched from (can vary) — don't confuse them for locating a package's own files.
- `path.basename` is a key building block for sanitizing user-supplied filenames before touching the filesystem.

## Fullstack Angle — What You'd Actually Debug

- **"Works on my machine" file-not-found errors, especially cross-platform (Windows teammate, Linux CI)** → manual string concatenation with hardcoded `/` or `\` instead of `path.join`.
- **Config/template file not found when script run from a different directory** → using `process.cwd()`-relative paths instead of `__dirname`-relative paths for files that ship alongside the source code.

## Architect Angle — What You'd Actually Decide

- **Cross-platform CI/dev parity**: enforcing `path.join`/`path.resolve` usage (vs string concatenation) via lint rule is a small but real reliability investment for teams with mixed OS environments (Windows dev machines, Linux CI/prod).
- **Config resolution strategy**: standardizing whether config paths are resolved relative to `__dirname` (package-relative, portable) or an explicit environment variable (deployment-configurable) is a real architectural decision for how a service's file dependencies are located across environments (local, Docker, various cloud deployments).

## Interview Q&A Rapid Fire

**Q: What's the actual difference between `path.join` and `path.resolve`?**
`path.join` concatenates and normalizes path segments without guaranteeing the result is absolute. `path.resolve` always returns an absolute path, processing segments right-to-left until it hits one that's already absolute (or falling back to `process.cwd()`).

**Q: What's the difference between `__dirname` and `process.cwd()`?**
`__dirname` is the directory containing the currently executing file — fixed based on file location. `process.cwd()` is the directory the Node process was launched from — can be any directory, depending on how/where the script was invoked.

**Q: Why is `path.join` important for cross-platform code?**
It normalizes path separators for the current OS (`/` on POSIX, `\` on Windows) automatically — manual string concatenation with a hardcoded separator breaks on the other platform.