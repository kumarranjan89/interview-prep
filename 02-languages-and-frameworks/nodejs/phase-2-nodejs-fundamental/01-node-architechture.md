# Node.js Architecture

## Scope of This Topic

Node.js isn't "JavaScript on the server" in a naive sense — it's V8 (the engine) wrapped in a **C++ runtime layer** built on **libuv**, giving JS access to non-blocking I/O, the file system, networking, and threading that pure JS/V8 has no concept of. This builds directly on the Engine vs Runtime distinction already covered — Node is simply a different **runtime** wrapped around the same engine.

```
[ Your JS Code ]
      |
      v
[ Node.js Bindings ]     ← C++ APIs exposing fs, net, crypto, etc. to JS
      |
      v
[ V8 Engine ]             ← parses/executes JS (same engine as Chrome)
      |
      v
[ libuv ]                 ← event loop, thread pool, async I/O abstraction over the OS
      |
      v
[ Operating System ]      ← epoll (Linux) / kqueue (macOS) / IOCP (Windows)
```

## The Four Core Pieces

1. **V8** — executes JS, provides the call stack, heap, GC, JIT (already covered in `js-engine.md`)
2. **libuv** — C library providing the event loop, thread pool, and cross-platform async I/O
3. **Node bindings (C++)** — glue layer exposing OS-level capabilities (`fs`, `net`, `crypto`, `dns`) to JS
4. **Node.js core modules** — the JS-facing API surface (`require('fs')`, `require('http')`, etc.) built on top of the bindings

## Single-Threaded, But Not Single-Threaded

The classic misleading soundbite: "Node is single-threaded." More precisely — **your JS code runs on one thread**, but Node/libuv uses real OS-level parallelism underneath for I/O:

```
Your JS (single thread)
      |
      | offloads I/O to...
      v
libuv Thread Pool (default: 4 threads)  ← fs operations, DNS lookup (dns.lookup), some crypto
      |
OS-level async I/O (epoll/kqueue/IOCP)  ← network sockets — no thread pool needed, OS handles it natively
```

**Network I/O** (HTTP requests, TCP sockets) doesn't need the thread pool at all — the OS kernel provides async socket notifications natively (epoll on Linux), and libuv just listens for those events.

**File I/O and some crypto/DNS operations** *do* use the thread pool, because most OS filesystem APIs are blocking by nature — libuv fakes async behavior by running the blocking call on a worker thread and notifying the event loop when it completes.

## Why This Architecture Exists

Traditional server models (one thread — or one process — per request, e.g. classic Apache/PHP) don't scale well under high concurrency: each idle connection still holds a thread, consuming memory even while doing nothing (most of a request's lifetime is spent waiting on I/O, not computing).

Node's model: **one thread handles many concurrent connections**, because it's never blocked waiting — it registers a callback and moves to the next thing. This makes Node very efficient for I/O-heavy, low-compute workloads (APIs, real-time apps) and comparatively weak for CPU-heavy workloads (image processing, heavy computation) where a single thread becomes a bottleneck.

## Process, Module, and Global Objects

```js
process.argv       // command-line arguments
process.env        // environment variables
process.platform    // 'linux', 'darwin', 'win32'
process.exit(code)  // terminate process
process.on('uncaughtException', handler); // last-resort error catch — not a substitute for proper handling

global.setTimeout   // Node's global scope equivalent of browser's `window`
```

**Module wrapper:** every CommonJS file is secretly wrapped by Node before execution:

```js
(function(exports, require, module, __filename, __dirname) {
  // your file's actual code goes here
});
```

This is *why* `require`, `module.exports`, `__dirname`, `__filename` are available without importing anything — they're injected as function parameters, not real globals. (Also why they're missing in native ESM — no wrapper function providing them there.)

## Mental Model Summary

- Node = V8 (engine) + libuv (event loop, thread pool, async I/O) + C++ bindings exposing OS capabilities to JS.
- "Single-threaded" refers only to JS execution — I/O parallelism happens via the OS (network) or a thread pool (file system, some crypto/DNS), invisible to your JS code.
- This architecture optimizes for high-concurrency, I/O-bound workloads — not CPU-bound ones, which is the direct reason Worker Threads/child processes/clustering exist (covered in later phases).

## Fullstack Angle — What You'd Actually Debug

- **API feels slow under load, CPU usage looks low** → likely I/O-bound bottleneck (DB round-trip, external API latency) — Node's model should handle this well; if it doesn't, check for accidentally blocking calls (sync `fs` methods, tight synchronous loops) on the single JS thread.
- **A `crypto.pbkdf2` or heavy `fs` batch job slows down unrelated requests** → thread pool exhaustion (default 4 threads) — concurrent heavy operations queue behind each other; increasing `UV_THREADPOOL_SIZE` or offloading to worker threads/a separate service is the actual fix, not "add more compute."

## Architect Angle — What You'd Actually Decide

- **Workload fit assessment**: Node is a strong default for I/O-heavy services (APIs, gateways, real-time) but a poor fit for CPU-heavy workloads (video/image processing, heavy data transforms) unless offloaded to worker threads or a separate service in another stack — this is a genuine architecture decision point, not a Node limitation to work around blindly.
- **Horizontal scaling implication**: since one Node process effectively uses one core for JS execution, scaling *up* (more cores on one machine) requires clustering (`cluster` module / PM2) or running multiple container replicas behind a load balancer — vertical scaling alone doesn't help past one core for CPU-bound JS work.
- **Thread pool sizing**: `UV_THREADPOOL_SIZE` is a real production tuning lever for fs/crypto/DNS-heavy services — worth documenting as an explicit config decision rather than leaving at the default of 4.

## Interview Q&A Rapid Fire

**Q: Is Node.js truly single-threaded?**
Your JS code executes on a single thread (one call stack), but Node/libuv uses OS-level async I/O for networking and a thread pool (default 4 threads) for filesystem/some crypto/DNS operations — so the runtime as a whole is not single-threaded, only your JS execution is.

**Q: What is libuv and what does it provide?**
A C library giving Node its event loop, a thread pool for blocking-by-nature operations, and a cross-platform abstraction over OS-level async I/O (epoll/kqueue/IOCP) — V8 itself has no concept of any of this.

**Q: Why is Node good for I/O-bound apps but bad for CPU-bound ones?**
Because the single JS thread is never blocked waiting on I/O (it delegates and continues), efficiently handling many concurrent I/O-waiting connections — but a CPU-heavy synchronous task occupies that one thread fully, blocking all other requests until it completes, since there's no automatic parallelism for pure computation.

**Q: What's actually happening when you call `require('module')`?**
Node wraps the target file in a function `(exports, require, module, __filename, __dirname) => {...}`, executes it synchronously, reading from disk via the host's `fs` layer, and caches the result by resolved path — subsequent `require` calls for the same path return the cached `module.exports` instead of re-executing.