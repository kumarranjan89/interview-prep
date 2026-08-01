# JavaScript Runtime

## Scope of This Topic

**Runtime = Engine + Host Environment.** The engine (previous topic) only executes JS. The runtime is the full package that makes a JS program actually *do* something useful — network calls, timers, DOM manipulation, file I/O — none of which the engine itself understands.

```
JS Runtime (e.g. Chrome, Node.js)
  |
  |-- JS Engine (V8)
  |     |-- Call Stack, Memory Heap, Parser, JIT, GC
  |
  |-- Host APIs                ← NOT part of the engine
  |     |-- Browser: DOM, fetch, setTimeout, localStorage, MutationObserver
  |     |-- Node: fs, http, process, Buffer, worker_threads
  |
  |-- Callback / Macrotask Queue
  |-- Microtask Queue
  |-- Event Loop               ← also NOT part of the engine — host-owned
```

**Interview framing:** the same V8 engine binary runs inside both Chrome and Node — the *engine* code is identical. What differs is entirely the runtime: Chrome injects `document`/`window`, Node injects `require`/`fs`/`process`. This single fact is the cleanest way to prove you understand the boundary.

## Why setTimeout "belongs" to the runtime, not the engine

```js
setTimeout(() => console.log('hi'), 1000);
```

V8 sees `setTimeout` called, hands off the callback + delay to the **host**, and immediately continues executing the next line. The host (browser thread / libuv timer wheel) is responsible for:
- Tracking real wall-clock time
- Pushing the callback into the macrotask queue once the delay elapses
- Nothing here touches the JS heap or call stack until the callback actually fires

This is the same pattern for `fetch`, DOM events, `fs.readFile` — **host does the waiting/I/O, engine only runs the callback once handed back.**

## Two Concrete Runtimes — Compare and Contrast

| | Browser Runtime | Node.js Runtime |
|---|---|---|
| Engine | V8 (Chrome/Edge), SpiderMonkey (Firefox), JSC (Safari) | V8 |
| Host APIs | DOM, `fetch`, `setTimeout`, `localStorage`, `MutationObserver` | `fs`, `http`, `process`, `Buffer`, `worker_threads` |
| Event loop spec | WHATWG HTML spec | libuv |
| Module system | ESM (native `import`), also bundler-driven | CommonJS (`require`) natively, ESM supported |
| Globals | `window`, `document` | `global`, `process`, `__dirname` |
| Threading model | Main thread + browser-internal threads (networking, GPU) + Web Workers | Single JS thread + libuv thread pool for some I/O |

## Node's Host Layer — libuv

Node doesn't use the HTML spec's event loop — it uses **libuv**, a C library providing an event loop with **phases**, not a flat queue:

```
timers → pending callbacks → poll → check → close callbacks
```

- **timers**: `setTimeout`/`setInterval` due callbacks
- **poll**: retrieve new I/O events, run their callbacks (this is where most work happens)
- **check**: `setImmediate` callbacks
- Microtasks (`process.nextTick` — Node-only, higher priority than Promise microtasks — and Promise `.then`) drain **between every phase transition**, not once per full loop

**Classic gotcha:** `setImmediate` vs `setTimeout(fn, 0)` ordering is non-deterministic at the top level of a script, but **deterministic inside an I/O callback** — `setImmediate` always wins there, because you're already past the poll phase and check comes next, while timers is a full loop away.

## Threading — What's Actually Parallel

JS execution itself is always single-threaded (one call stack). But the **runtime** uses real OS-level parallelism for I/O so the JS thread never blocks waiting:

- **Browser**: networking, disk cache, GPU compositing all happen off the JS thread in the browser's own process/thread architecture
- **Node/libuv**: uses a thread pool (default size 4) for operations that don't have native async OS support — `fs` file operations, DNS lookups (`dns.lookup`), some crypto. Network sockets themselves use OS-level async I/O (epoll/kqueue/IOCP), no thread pool needed.

**Why this matters:** `fs.readFile` "feels async" because Node offloads it to the thread pool, not because there's engine-level magic. `crypto.pbkdf2` (CPU-heavy) also uses the thread pool — which is why 4+ concurrent heavy crypto calls can start queuing and blocking each other, a real production surprise.

## Module Loading — A Runtime-Level Case Study

Module loading is a good worked example of the engine/host split, since it's a common point of confusion:

- **CommonJS (`require`)** — pure Node/host convention (not in ECMAScript spec at all). Synchronous: reads the file via `fs`, wraps it, executes immediately, caches the result by resolved path.
- **ESM (`import`)** — the module **record** and static binding rules *are* specified in ECMAScript (engine-level), but **fetching** the module (resolving a specifier, reading a file, or a network request in the browser) is host-level — same "host does I/O, engine does linking/evaluation" pattern as any other async host API.

```js
// CommonJS — synchronous, host reads file immediately
const fs = require('fs');

// ESM — import graph resolved/fetched by host, then linked/evaluated by engine
import fs from 'fs';
```

**Practical gotchas that come from this split:** `__dirname`/`__filename` don't exist in native ESM (no CommonJS wrapper function providing them); circular `require` returns a partial (possibly empty) `module.exports`, while circular ESM imports use live bindings that can resolve correctly once evaluation completes.

## Mental Model Summary

- Engine = pure execution. Runtime = engine + everything that lets JS talk to the outside world.
- The event loop, timers, DOM, file system, network — **none of it is in ECMAScript**. It's defined by whichever host you're running in (HTML spec or libuv).
- Same engine, different runtime, different globals/APIs — this is *why* "isomorphic" JS code (shared between browser and Node) has to carefully avoid runtime-specific globals.

## Interview Q&A Rapid Fire

**Q: Is `setTimeout` part of JavaScript the language?**
No — it's not in ECMAScript at all. It's a host API, defined by the HTML spec in browsers and implemented via libuv in Node.

**Q: Why does the same V8 engine behave differently in Chrome vs Node?**
Because the engine only executes code — all the globals and APIs (`window`/`document` vs `process`/`require`) come from the host layer wrapped around the engine, not the engine itself.

**Q: What is libuv and why does Node need it?**
A C library providing Node's event loop, thread pool, and async I/O abstraction over the OS. V8 has no concept of an event loop on its own — Node supplies one via libuv, structured as phases rather than a single flat queue like browsers.

**Q: Give an example of something that looks async but is actually using a thread pool under the hood.**
`fs.readFile` and `crypto.pbkdf2` in Node — both offloaded to libuv's thread pool (default 4 threads), which is why a burst of concurrent calls to these can start serializing/queuing rather than running with unlimited parallelism.