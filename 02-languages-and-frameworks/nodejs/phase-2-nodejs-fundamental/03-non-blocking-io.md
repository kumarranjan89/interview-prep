# Non-Blocking I/O

## Scope of This Topic

The actual mechanism behind "Node is fast for I/O" — how synchronous-looking async code avoids blocking the single JS thread, and what's really happening at the OS level underneath `fs`, `net`, and friends.

## Blocking vs Non-Blocking, Concretely

**Blocking**: the calling thread halts entirely until the operation completes — nothing else can happen on that thread in the meantime.

```js
const fs = require('fs');

// BLOCKING — thread frozen until file read completes
const data = fs.readFileSync('big-file.txt');
console.log('this line waits for the read above');
```

**Non-blocking**: the call returns immediately; the operation happens in the background (OS-level async I/O or a worker thread), and a callback/Promise resolves later when it completes.

```js
// NON-BLOCKING — thread free immediately, callback fires later
fs.readFile('big-file.txt', (err, data) => {
  console.log('this runs later, when the read finishes');
});
console.log('this line runs immediately, doesn't wait');
```

## What "Non-Blocking" Actually Means at the OS Level

Two genuinely different mechanisms hide behind the same-looking async API, depending on the operation type:

```
Network I/O (sockets, HTTP)
      |
      v
OS kernel async I/O (epoll on Linux, kqueue on macOS, IOCP on Windows)
      |
libuv just registers interest and gets notified — NO thread pool needed
      |
      v
Callback queued on the event loop when OS signals "ready"


File System I/O (most fs calls), some DNS, some crypto
      |
      v
OS filesystem APIs are blocking by nature (no universal native async fs API across platforms)
      |
libuv fakes non-blocking behavior:
  hands the blocking call to a THREAD POOL worker (default 4 threads)
      |
      v
Worker thread blocks on that thread — main JS thread stays free
      |
Callback queued on the event loop when worker finishes
```

**Why the distinction matters**: network-heavy Node services scale very well (near-unlimited concurrent connections limited mainly by memory/file descriptors, not threads). File-system-heavy services have a **hidden concurrency ceiling** — the default 4-thread pool — that network I/O simply doesn't have.

## Demonstrating the Thread Pool Limit

```js
const crypto = require('crypto');

console.time('4 calls');
for (let i = 0; i < 4; i++) {
  crypto.pbkdf2('password', 'salt', 100000, 512, 'sha512', () => {
    console.timeEnd('4 calls'); // all 4 finish around the same time — one per thread
  });
}

console.time('8 calls');
for (let i = 0; i < 8; i++) {
  crypto.pbkdf2('password', 'salt', 100000, 512, 'sha512', () => {
    console.timeEnd('8 calls'); // takes ~2x as long — 4 queue behind the first 4
  });
}
```

Increasing `UV_THREADPOOL_SIZE` (env var, must be set before the process starts) raises this ceiling — a genuine, well-known production tuning lever for fs/crypto/DNS-heavy Node services.

## Callbacks, Promises, and async/await — Same Mechanism, Different Syntax

All three are surface syntax over the identical non-blocking mechanism — none of them change what's happening at the OS/libuv level, only how you write the "what happens after" logic.

```js
// Callback style (original Node convention)
fs.readFile('f.txt', (err, data) => { /* ... */ });

// Promise style (fs.promises / fs/promises)
const fsPromises = require('fs/promises');
fsPromises.readFile('f.txt').then(data => { /* ... */ });

// async/await (sugar over the Promise version)
async function read() {
  const data = await fsPromises.readFile('f.txt');
}
```

## The Danger of Mixing Sync and Async APIs

Node's `fs` module ships **three variants** of most functions — this is a real footgun:

```js
fs.readFile('f.txt', callback);        // async, non-blocking
fs.readFileSync('f.txt');              // sync, BLOCKING
fsPromises.readFile('f.txt');          // async, Promise-based, non-blocking
```

A single accidental `readFileSync` (or any `*Sync` call, or a tight synchronous loop) inside a request handler blocks the **entire process** — every other concurrent request stalls, not just the one that triggered it. This is the single most common way a Node service accidentally loses its main non-blocking advantage.

## Mental Model Summary

- Non-blocking means the calling thread never waits — it registers interest and moves on; the "waiting" happens in the OS kernel (network) or a worker thread (file system/some crypto/DNS).
- Network I/O has no thread pool ceiling — near-unlimited concurrent connections. File I/O does — bounded by `UV_THREADPOOL_SIZE` (default 4).
- Callback/Promise/async-await are three syntaxes over the exact same non-blocking mechanism — none of them is "more async" than another.
- A single synchronous/blocking call in a request path blocks the whole process, not just that request — this is Node's sharpest footgun.

## Fullstack Angle — What You'd Actually Debug

- **All requests slow down together under load, not just one endpoint** → strong signal of an accidental blocking call somewhere (`*Sync` method, heavy synchronous computation, or unbounded synchronous loop) — profile with `--prof` or check for `Sync` suffix usage across the codebase.
- **File-upload-heavy or crypto-heavy endpoints slow down unrelated endpoints under concurrent load** → thread pool exhaustion, not a code bug per se — either raise `UV_THREADPOOL_SIZE`, or move that work to a separate worker/service.

## Architect Angle — What You'd Actually Decide

- **Service boundary design**: file-processing or crypto-heavy workloads (image resizing, PDF generation, password hashing at scale) are strong candidates to split into a separate service or worker pool — protects the thread-pool-bound ceiling of the main API service from unrelated request latency spikes.
- **Never allow `*Sync` methods in request-handling code paths** — worth codifying as an actual lint rule (`eslint-plugin-node`'s `no-sync` or similar) in a team's shared config, not just a code review reminder — this is a systemic risk, not a one-off mistake.
- **Capacity planning**: `UV_THREADPOOL_SIZE` tuning and thread-pool-bound operation inventory (which endpoints touch `fs`/`crypto`/`dns.lookup`) should be part of a service's documented capacity model, since it's a real, distinct bottleneck from CPU or memory limits.

## Interview Q&A Rapid Fire

**Q: What's the actual difference between how network I/O and file I/O achieve "non-blocking" in Node?**
Network I/O uses OS-level async notification (epoll/kqueue/IOCP) — no thread pool involved, the OS itself tells libuv when a socket is ready. File I/O (and some crypto/DNS) has no universal native async OS API, so libuv simulates non-blocking by running the blocking call on a thread pool worker (default 4 threads) and notifying the event loop when that thread finishes.

**Q: Why does calling `fs.readFileSync` inside an HTTP request handler hurt every other concurrent request, not just that one?**
Because it blocks Node's single JS execution thread entirely — no other request handler, timer, or I/O callback can run until that synchronous call returns, regardless of which request triggered it.

**Q: Is async/await "more non-blocking" than callbacks?**
No — identical underlying mechanism (OS async I/O or thread pool). async/await is purely syntactic sugar over Promises, which themselves wrap the same callback-based non-blocking APIs; none of the three changes what happens at the libuv/OS level.

**Q: What's a practical symptom of thread pool exhaustion, and how would you fix it?**
Concurrent fs/crypto/DNS-heavy operations start queuing and completing in batches rather than in parallel, adding latency to unrelated requests sharing the same process. Fix: raise `UV_THREADPOOL_SIZE`, or move the heavy operation to a separate worker thread/service so it doesn't compete with the main service's I/O-bound thread pool usage.