# Web Workers — Concepts

## 1. The Core Problem It Solves

JavaScript on the main thread is single-threaded. One call stack. If you run a
heavy computation (parsing a huge JSON, image processing, sorting a huge array,
crypto hashing), it blocks:

- UI rendering (no repaint, no reflow)
- User input (clicks, scrolls freeze)
- Event loop (timers, promises, everything queued behind it)

This is why a 2-second `for` loop makes a webpage "freeze." The browser isn't
crashing — the main thread's call stack is just busy and nothing else can run
until it's empty.

**Web Workers give you a second thread.** Actual OS-level thread, separate
memory space, separate event loop, separate call stack. Your heavy work runs
there, main thread stays free to paint frames and respond to clicks.

**Interview one-liner:** "Web Workers let you run JS off the main thread to
avoid blocking UI rendering and user interaction during CPU-heavy work."

---

## 2. Mental Model: Two Isolated Islands Talking by Postcards

This is the model that removes 90% of confusion about workers.

```
┌─────────────────────┐          ┌─────────────────────┐
│    MAIN THREAD       │          │   WORKER THREAD      │
│                       │          │                       │
│  - DOM access         │  postMessage(data)  │  - No DOM access     │
│  - window object      │ ───────────────────► │  - No window        │
│  - Your app code      │                       │  - Own global scope  │
│                       │ ◄─────────────────── │    (self)            │
│  onmessage             │  postMessage(result) │  - Own event loop    │
└─────────────────────┘          └─────────────────────┘
```

Key idea: **these are two separate JS runtimes.** Not two functions in the
same program. Not shared variables. They cannot see each other's memory.
The ONLY way they talk is by sending messages back and forth — like two
people on separate islands sending postcards. You cannot hand someone on
the other island your actual notebook; you can only write a copy of what's
in it and mail that copy.

This maps directly to how data is transferred (see structured clone below).

**Why no DOM access matters:** DOM is not thread-safe. If two threads could
touch the DOM at once, you'd get race conditions in rendering. So browsers
made a hard rule: workers get zero DOM access. No `document`, no
`window`, no `localStorage` (only `IndexedDB` is available, since it's
already designed to be accessed asynchronously and safely).

---

## 3. Types of Workers (know the difference, common interview trap)

| Type | Scope | Use case |
|---|---|---|
| **Dedicated Worker** | One-to-one with the page that created it | 99% of use cases — offload one heavy task |
| **Shared Worker** | Shared across multiple tabs/windows of same origin | Sync state across tabs, shared cache, single DB connection |
| **Service Worker** | Not tied to a page at all; sits between app and network | Offline caching, push notifications, PWA — **not for CPU offloading**, it's an event-driven proxy |

**Interview trap:** People confuse Service Workers with Web Workers. Service
Worker is NOT for parallel computation — it's a network proxy/lifecycle
worker for offline support and caching. If someone asks "what's the
difference," lead with: **purpose**. Dedicated/Shared Workers = parallel
compute. Service Worker = network interception + lifecycle events.

This repo focuses on **Dedicated Workers** (the general "Web Worker" API).

---

## 4. Basic API — Creating and Talking to a Worker

**main.js (main thread):**
```js
// Create the worker — points to a separate JS file
const worker = new Worker('worker.js');

// Send data to the worker
worker.postMessage({ command: 'start', payload: [1, 2, 3, 4, 5] });

// Listen for messages coming back
worker.onmessage = (event) => {
  console.log('Result from worker:', event.data);
};

worker.onerror = (err) => {
  console.error('Worker crashed:', err.message, err.filename, err.lineno);
};

// Kill it when done
worker.terminate();
```

**worker.js (runs in worker thread):**
```js
// 'self' is the global scope here — equivalent to 'window' on main thread
self.onmessage = (event) => {
  const { command, payload } = event.data;

  if (command === 'start') {
    const result = payload.map(n => n * n); // pretend this is heavy
    self.postMessage(result);
  }
};
```

Note the symmetry: both sides use `postMessage` to send, and
`onmessage` to receive. This symmetry is intentional — a worker script
is written *as if* it's the main thread of its own tiny program.

---

## 4b. Other Ways to Create a Worker (common gotchas)

**Same-origin restriction:** the worker script must be same-origin as the
page. `new Worker('https://other-domain.com/worker.js')` will fail — this
trips people up when using CDN-hosted scripts. Blob and data URLs are the
exception (see below), since they aren't a cross-origin fetch.

**Inline workers via Blob URL** — build a worker from a string at runtime
instead of a separate file. Useful for small dynamic scripts, or when a
bundler doesn't emit a standalone worker file:
```js
const code = `self.onmessage = e => self.postMessage(e.data * 2);`;
const blob = new Blob([code], { type: 'application/javascript' });
const worker = new Worker(URL.createObjectURL(blob));
```

**Module workers** — pass `{ type: 'module' }` to use `import`/`export`
inside the worker instead of the older `importScripts()`:
```js
const worker = new Worker('worker.js', { type: 'module' });
```
```js
// worker.js
import { square } from './math.js';
self.onmessage = e => self.postMessage(square(e.data));
```
**Interview trap:** "classic worker vs module worker" — classic uses global
`importScripts()` calls (synchronous, loads scripts into global scope);
module uses ES module `import` (same semantics as module scripts on the
main thread — strict mode by default, scoped bindings).

**Feature detection** — always guard in production code, since older
environments or restrictive contexts may not expose `Worker`:
```js
if (typeof Worker !== 'undefined') {
  const worker = new Worker('worker.js');
} else {
  // fallback: run the task synchronously on main thread
}
```

**Startup cost** — creating a worker isn't instant. The browser has to fetch
the script, parse it, and spin up a new thread + JS engine instance — this
takes real milliseconds. This is another reason per-request worker creation
is an anti-pattern; it reinforces why a **worker pool** (reuse, don't
recreate) is the standard approach for many small tasks.

---

## 5. Structured Clone Algorithm — the "postcard," not the "notebook"

When you call `postMessage(data)`, the data is **not shared by reference**.
It is **copied** using the Structured Clone Algorithm.

```js
const obj = { count: 0 };
worker.postMessage(obj);
obj.count = 999; // has ZERO effect on what the worker received
```

This is the single most important thing to internalize. There is no shared
memory by default. Every message is a deep copy.

**What structured clone CAN copy:** objects, arrays, Map, Set, Date, RegExp,
Blob, File, ArrayBuffer, and even circular references (something
`JSON.stringify` cannot handle).

**What it CANNOT copy:** functions, DOM nodes, Error objects (partial
support varies), class instances lose their prototype chain (you get a
plain object back, not an instance of your class).

**Interview question you will get asked:** "Why not just use
`JSON.stringify`/`parse` to pass data?" Answer: structured clone is faster
for large data (native browser algorithm, not string serialization), handles
circular references, and preserves types like `Date` and `Map` that JSON
would mangle into strings or plain objects.

---

## 6. Transferable Objects — the exception, and a favorite interview topic

Copying is expensive for large binary data (e.g., a 100MB `ArrayBuffer`).
So the platform gives you an escape hatch: **Transferable Objects.**

```js
const buffer = new ArrayBuffer(1024 * 1024 * 50); // 50MB
worker.postMessage(buffer, [buffer]); // second arg = transfer list
console.log(buffer.byteLength); // 0 — main thread lost ownership!
```

Instead of copying the 50MB, ownership of the memory is **moved** to the
worker. Main thread's reference becomes unusable (`byteLength` becomes 0).
This is a zero-copy operation — extremely fast regardless of data size.

Going back to the island/postcard model from Section 2: structured clone is
mailing a **photocopy** of your notebook page — you keep the original.
Transfer is mailing the **actual page torn out** — you no longer have it.

Transferable types: `ArrayBuffer`, `MessagePort`, `ImageBitmap`,
`OffscreenCanvas`.

**Common interview follow-up:** "When would you use Transferable Objects
over structured clone?" — Answer: large binary data (image pixels, audio
buffers, big typed arrays) where copy cost matters. For small plain
objects, structured clone overhead is negligible; transfer isn't worth
the added complexity (ownership loss) for tiny payloads.

---

## 7. What Workers Do NOT Have Access To

Memorize this list — it comes up as a rapid-fire interview question.

**No access to:**
- `window` object
- DOM (`document`, elements, etc.)
- `localStorage` / `sessionStorage` (synchronous, and tied to main thread)
- Parent's variables/functions directly (only via postMessage)

**Access to (via `self`):**
- `fetch` — yes, workers can make network calls
- `setTimeout` / `setInterval`
- `IndexedDB` — the only persistent storage available in workers
- `WebSocket`
- `importScripts()` — synchronously load other JS files into the worker (classic workers only; module workers use `import`)
- Its own `console` (logs still show in devtools)
- Crypto, WebAssembly, most computation-related APIs

**Why this list matters conceptually:** workers are designed for
**computation and networking**, not for UI. Anything UI-related is
main-thread-only by design.

---

## 8. Error Handling

```js
// main.js
worker.onerror = (event) => {
  console.log(event.message, event.filename, event.lineno);
  event.preventDefault(); // stop it from also bubbling to window.onerror
};

worker.onmessageerror = (event) => {
  // fires if a message FAILS to deserialize (structured clone failure)
  console.log('Could not deserialize message', event);
};
```

Uncaught errors inside a worker do not crash the main thread — they fire
`onerror` on the worker object. This is one of the safety benefits: a
buggy worker can't take down your whole app.

---

## 9. Termination and Lifecycle

```js
worker.terminate();     // from main thread — kills immediately, no cleanup callback
self.close();            // from inside worker — worker can kill itself
```

There is no graceful shutdown event by default (no `onclose`). If you need
cleanup, you build your own protocol: send a `{ command: 'shutdown' }`
message, let the worker do cleanup, have it `postMessage({done:true})`,
then main thread calls `terminate()`.

**Memory note:** Workers are not free. Each one is a real OS thread with its
own JS engine instance — memory overhead is nontrivial (megabytes each).
Don't spin up a worker per small task; use a **worker pool** for many small
jobs (see practices.md).

---

## 10. Where Workers Fit in the Event Loop (deep interview territory)

Common misconception: "workers make JS multi-threaded, so now the event
loop has multiple threads." Wrong — each worker gets its **own, completely
separate** event loop, call stack, and microtask/macrotask queue. JS's
single-threaded-per-context rule is preserved; what you get is *multiple
independent single-threaded contexts*, not one shared multi-threaded one.

```
Main thread's event loop  →  own callbacks, promises, DOM events
Worker's event loop        →  own callbacks, promises (never interleaves
                               with main thread's call stack)
```

The two loops only touch at the `postMessage` boundary, which is queued as
a task on the receiving side — always async, never a blocking call.

**Good interview answer:** "A Web Worker doesn't break JavaScript's
single-threaded execution model — it gives you a second, independent
single-threaded environment. Communication is always asynchronous message
passing, never a direct synchronous call."

---

## 11. SharedArrayBuffer — true shared memory (advanced, mention if asked)

Regular `postMessage` copies data. But `SharedArrayBuffer` is the one
exception where actual memory IS shared between main thread and worker(s) —
both can read/write the same underlying buffer.

```js
const sab = new SharedArrayBuffer(1024);
worker.postMessage(sab); // NOT in transfer list — SAB is inherently shared, no need to transfer
```

Because multiple threads can now write to the same memory simultaneously,
you get real race conditions — so this comes paired with
`Atomics` (`Atomics.add`, `Atomics.wait`, `Atomics.notify`) for safe
concurrent access, similar to mutexes/locks in traditional multithreaded
languages.

**Why it's disabled/gated:** After Spectre (2018 CPU side-channel
vulnerability), browsers restricted `SharedArrayBuffer` to require specific
HTTP headers (`Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy`)
because shared memory + high-resolution timers = a side-channel attack
vector for reading other processes' memory.

**Interview flavor:** if asked "is there real shared memory in JS
threading," this is your answer — most work is copy-based, but
`SharedArrayBuffer` + `Atomics` is the true shared-memory, lock-based
concurrency primitive, gated behind security headers.

---

## 11b. Multiple Instances, Worker-to-Worker Talk, and Nested Workers

**Multiple instances:** you can create as many `new Worker()` instances as
you want — each is a fully independent thread with its own memory, never
sharing state with any other worker unless you explicitly wire up
communication. This is the basis of the **worker pool** pattern (see
practices.md): spawn `navigator.hardwareConcurrency` workers, queue tasks,
assign to whichever worker is free.

```js
const POOL_SIZE = navigator.hardwareConcurrency || 4;
const pool = Array.from({ length: POOL_SIZE }, () => new Worker('worker.js'));
```

Going past the CPU core count rarely helps for CPU-bound work — the OS just
time-slices more threads across the same cores, adding scheduling overhead
instead of real parallelism.

**Worker-to-worker direct communication:** by default, two workers can only
talk *through* the main thread (relay). But you can connect them directly
using `MessageChannel`, which creates a pair of linked ports:

```js
const channel = new MessageChannel();
worker1.postMessage({ port: channel.port1 }, [channel.port1]);
worker2.postMessage({ port: channel.port2 }, [channel.port2]);
```
Each worker now holds one end of a private pipe and can `postMessage`
directly to the other, without main thread relaying every message.
**Interview question:** "Can two workers talk without going through the
main thread?" — yes, via `MessageChannel`/`MessagePort`.

**Nested workers:** a worker can spawn its own child worker
(`new Worker(...)` called from inside worker.js) in most modern browsers.
Rarely used in practice, but worth knowing it's structurally possible —
useful for hierarchical task decomposition in very heavy pipelines.

---

## 12. Quick Comparison Table (for rapid recall before interviews)

| Concept | Main Thread ↔ Worker |
|---|---|
| Data passing | Copied via Structured Clone (default) |
| Large binary data | Transferred via Transferable Objects (zero-copy, ownership moves) |
| True shared memory | `SharedArrayBuffer` + `Atomics` (gated by COOP/COEP headers) |
| DOM access | None in worker |
| Event loop | Fully separate per thread, never shared |
| Error isolation | Worker errors don't crash main thread |
| Storage available in worker | IndexedDB only (no localStorage) |
| Network | `fetch`, `WebSocket` both available in worker |

---

## 13. One-Paragraph Summary (say this if asked "explain web workers" cold)

"A Web Worker runs JavaScript on a separate OS thread with its own event
loop and global scope, so heavy computation doesn't block the main
thread's rendering and input handling. It has no DOM access — communication
happens only through asynchronous message passing. By default, data is
deep-copied via the Structured Clone Algorithm; for large binary data you
can use Transferable Objects to move ownership with zero copy instead. True
shared memory across threads is possible only via SharedArrayBuffer paired
with Atomics, and is gated behind security headers because of Spectre-era
side-channel risks."

---
---

# Web Workers — Practices

Real, reusable patterns. These are the ones that actually come up in
production code and in "design this" interview rounds.

## P1. Worker Pool with Task Queue (the pattern you'll reuse most)

Problem: you have many small-to-medium tasks (e.g., resize 500 images) and
don't want to spawn 500 workers, or block waiting for one worker to finish
each task serially.

Solution: fixed pool of workers + a task queue + a dispatcher that assigns
the next queued task to whichever worker frees up.

**worker.js** (generic — runs whatever task it's told to):
```js
self.onmessage = (e) => {
  const { taskId, fn, args } = e.data;
  try {
    // fn is passed as a string, since functions can't cross postMessage
    const result = new Function('return (' + fn + ')')(...args);
    self.postMessage({ taskId, status: 'success', result });
  } catch (err) {
    self.postMessage({ taskId, status: 'error', error: err.message });
  }
};
```

**worker-pool.js** (main thread):
```js
class WorkerPool {
  constructor(workerScript, poolSize = navigator.hardwareConcurrency || 4) {
    this.workers = Array.from({ length: poolSize }, () => ({
      instance: new Worker(workerScript),
      busy: false,
    }));
    this.queue = [];
    this.taskId = 0;
    this.callbacks = new Map();

    this.workers.forEach((w) => {
      w.instance.onmessage = (e) => {
        const { taskId, status, result, error } = e.data;
        const cb = this.callbacks.get(taskId);
        if (cb) {
          status === 'success' ? cb.resolve(result) : cb.reject(new Error(error));
          this.callbacks.delete(taskId);
        }
        w.busy = false;
        this._dispatch(); // free worker, try next queued task
      };
    });
  }

  run(fn, args = []) {
    return new Promise((resolve, reject) => {
      const taskId = this.taskId++;
      this.callbacks.set(taskId, { resolve, reject });
      this.queue.push({ taskId, fn, args });
      this._dispatch();
    });
  }

  _dispatch() {
    if (this.queue.length === 0) return;
    const freeWorker = this.workers.find((w) => !w.busy);
    if (!freeWorker) return; // all busy, wait for onmessage to trigger dispatch again

    const task = this.queue.shift();
    freeWorker.busy = true;
    freeWorker.instance.postMessage({
      taskId: task.taskId,
      fn: task.fn.toString(),
      args: task.args,
    });
  }

  terminate() {
    this.workers.forEach((w) => w.instance.terminate());
  }
}
```

**Usage:**
```js
const pool = new WorkerPool('worker.js', 4);

const heavySquare = (n) => {
  let result = 0;
  for (let i = 0; i < n; i++) result += i * i; // pretend heavy
  return result;
};

const results = await Promise.all(
  [1e7, 2e7, 3e7, 4e7].map((n) => pool.run(heavySquare, [n]))
);
console.log(results);
```

**Why this matters for interviews:** this is a real design-a-system
question — "how would you parallelize N independent CPU-bound tasks across
a fixed number of workers?" The answer is always: pool + queue + dispatch
on completion. Same shape as a thread pool in any language.

**Caveat you should state out loud:** passing `fn` as a stringified
function only works for pure, self-contained functions (no closures over
outer variables, since only the string crosses the boundary). For real
apps, it's cleaner to define named task types in worker.js
(`{ type: 'resizeImage', payload }`) rather than shipping arbitrary
function bodies — safer and avoids `new Function` (which is close to
`eval`).

---

## P2. Debouncing Heavy Computation Without Blocking UI

Problem: user types in a search box, each keystroke triggers a heavy
client-side filter/sort over a large dataset. Even with debounce, the
computation itself can still cause a jank frame if it's heavy enough.

Solution: debounce on the main thread (to avoid firing on every keystroke)
+ offload the actual heavy computation to a worker (so even the debounced
call doesn't block the UI thread).

```js
// main.js
const searchWorker = new Worker('search-worker.js');
let latestRequestId = 0;

function debounce(fn, delay) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

const runSearch = debounce((query) => {
  const requestId = ++latestRequestId;
  searchWorker.postMessage({ requestId, query });
}, 300);

searchWorker.onmessage = (e) => {
  const { requestId, results } = e.data;
  if (requestId !== latestRequestId) return; // stale response, user typed more since
  renderResults(results);
};

searchInput.addEventListener('input', (e) => runSearch(e.target.value));
```

**Why the `requestId` check matters:** workers process messages
asynchronously and in the order received, but if the user types fast,
multiple search requests can be in flight. Without a request ID guard, a
slow older response could arrive *after* a newer one and overwrite fresher
results on screen — a classic race condition bug. This `requestId`
pattern is the same idea as aborting stale `fetch` requests with
`AbortController`, just applied to worker messages.

---

## P3. Offloading Image Processing (Transferable Objects in action)

Problem: resizing/filtering a large image on main thread freezes the page.

```js
// main.js
const worker = new Worker('image-worker.js');

async function processImage(file) {
  const bitmap = await createImageBitmap(file);
  // ImageBitmap is transferable — zero-copy handoff
  worker.postMessage({ bitmap }, [bitmap]);
}

worker.onmessage = (e) => {
  const { processedBitmap } = e.data;
  const canvas = document.getElementById('output');
  const ctx = canvas.getContext('bitmaprenderer');
  ctx.transferFromImageBitmap(processedBitmap);
};
```

```js
// image-worker.js
self.onmessage = (e) => {
  const { bitmap } = e.data;
  const canvas = new OffscreenCanvas(bitmap.width, bitmap.height);
  const ctx = canvas.getContext('2d');
  ctx.drawImage(bitmap, 0, 0);

  // pretend heavy pixel manipulation here (grayscale, blur, etc.)
  const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
  for (let i = 0; i < imageData.data.length; i += 4) {
    const gray = (imageData.data[i] + imageData.data[i + 1] + imageData.data[i + 2]) / 3;
    imageData.data[i] = imageData.data[i + 1] = imageData.data[i + 2] = gray;
  }
  ctx.putImageData(imageData, 0, 0);

  const processedBitmap = canvas.transferToImageBitmap();
  self.postMessage({ processedBitmap }, [processedBitmap]);
};
```

**Why this is the textbook Transferable Objects example:** `ImageBitmap`
and `OffscreenCanvas` let you do the *entire* pixel pipeline off the main
thread, including rendering — main thread only receives a finished bitmap
and paints it, zero-copy both directions.

---

## P4. Graceful Shutdown Protocol

Since `terminate()` gives the worker no chance to clean up, build a small
handshake when cleanup matters (closing IndexedDB connections, flushing
buffered data, etc.):

```js
// main.js
function shutdownWorker(worker) {
  return new Promise((resolve) => {
    worker.onmessage = (e) => {
      if (e.data.type === 'shutdown-complete') {
        worker.terminate();
        resolve();
      }
    };
    worker.postMessage({ type: 'shutdown' });
  });
}
```

```js
// worker.js
self.onmessage = (e) => {
  if (e.data.type === 'shutdown') {
    // flush/cleanup here
    self.postMessage({ type: 'shutdown-complete' });
  }
};
```

---

## P5. Practices Checklist (quick self-check before shipping worker code)

- [ ] Pool size capped at `navigator.hardwareConcurrency`, not unbounded
- [ ] Stale responses guarded with a request/task ID, not just assumed in-order
- [ ] Large binary payloads use Transferable Objects, not plain postMessage
- [ ] `onerror` and `onmessageerror` both handled, not just `onmessage`
- [ ] Worker created once and reused (pool), not spun up per request
- [ ] Named task types used instead of stringified functions in production code
- [ ] Feature-detected (`typeof Worker !== 'undefined'`) with a fallback path

---
---

# Web Workers — Problems

Practice problems, ordered easy → hard. Mix of "build this" and "find the
bug" — both show up in interviews. Try each before reading the notes below
the statement.

## Problem 1 — Basic Offload
Write a worker that takes an array of numbers and returns the sum of their
squares, without blocking the main thread. Main thread should log the
result once ready.

*Tests:* basic `postMessage`/`onmessage` symmetry (Section 4).

---

## Problem 2 — Fix the Bug (Shared Reference Assumption)
```js
// main.js
const data = { count: 0 };
worker.postMessage(data);
setTimeout(() => {
  data.count = 42;
  worker.postMessage({ type: 'check' });
}, 100);

// worker.js
let stored;
self.onmessage = (e) => {
  if (e.data.type === 'check') {
    self.postMessage(stored.count); // expecting 42
  } else {
    stored = e.data;
  }
};
```
This logs `0`, not `42`. Why? Fix the code so the worker sees the updated
count, using the correct mental model of how data crosses the boundary.

*Tests:* structured clone understanding (Section 5) — no shared reference,
ever. Correct fix: main thread must send the updated value again via a new
`postMessage`, not mutate a previously-sent object.

---

## Problem 3 — Transferable vs Clone Cost
You need to send a 200MB `ArrayBuffer` from main thread to a worker
repeatedly (e.g., streaming audio buffers every 100ms). Using
`worker.postMessage(buffer)` without a transfer list causes visible jank.
Explain why, and rewrite the call correctly.

*Tests:* Transferable Objects (Section 6) — copying 200MB repeatedly is
expensive; transferring is zero-copy. Also flag the tradeoff: main thread
loses the buffer after transfer, so if it needs to reuse that memory
region, it must allocate a new buffer for the next chunk.

---

## Problem 4 — Design a Worker Pool
Given a function `heavyTask(n)` and an array of 1000 `n` values, design a
system that processes all 1000 using no more than 4 concurrent workers,
without spawning 1000 worker instances and without blocking the main
thread. Return a single `Promise` that resolves with all 1000 results in
original order.

*Tests:* Practices P1 — pool + queue + dispatch pattern. Extra: results
must preserve original order even though task completion order isn't
guaranteed (hint: index the tasks, don't rely on completion order for
placement).

---

## Problem 5 — Fix the Race Condition
```js
// main.js
searchInput.addEventListener('input', (e) => {
  worker.postMessage({ query: e.target.value });
});

worker.onmessage = (e) => {
  renderResults(e.data.results); // sometimes shows results for an OLD query
};
```
User types "a", then quickly "ap", then "app". Occasionally the UI ends up
showing results for "a" even though "app" was the last thing typed. Why,
and how do you fix it without changing the worker at all (main-thread-only
fix)?

*Tests:* Practices P2 — stale response problem. Fix: attach an
incrementing `requestId` on send, ignore any `onmessage` whose `requestId`
isn't the latest one sent.

---

## Problem 6 — Same-Origin Trap
```js
const worker = new Worker('https://cdn.example.com/shared-worker-script.js');
```
This throws a security error in the browser console. Explain why, and give
two different ways to work around it while still using a script hosted on
a CDN.

*Tests:* Section 4b — same-origin restriction. Valid answers: (1) fetch
the script text yourself via `fetch()`, then wrap it in a `Blob` and use
`URL.createObjectURL`, since Blob URLs aren't treated as cross-origin; (2)
if the CDN supports CORS and you control response headers, some browsers
allow cross-origin worker scripts with proper CORS headers — but Blob URL
is the reliable, universally supported fix.

---

## Problem 7 — Event Loop Trick Question
True or false, and explain: "If I have a worker running an infinite loop
by mistake, my main thread's `setTimeout` callbacks will eventually stop
firing too, since JS is single-threaded."

*Tests:* Section 10 — event loop separation. Answer: **False**. The
worker's infinite loop blocks *only its own* event loop and call stack.
Main thread's `setTimeout` callbacks are completely unaffected, since it
has its own independent event loop. This is exactly the point of using a
worker in the first place.

---

## Problem 8 — Worker-to-Worker Without Main Thread
You have `workerA` (fetches data) and `workerB` (processes data). Currently
`workerA` sends data to main thread, which forwards it to `workerB` — an
unnecessary hop. Rewrite so `workerA` sends processed data directly to
`workerB`, with main thread only setting up the initial connection.

*Tests:* Section 11b — `MessageChannel`/`MessagePort`. Main thread creates
the channel and gives one port to each worker (as a transferable), then
steps out of the data path entirely.

---

## Problem 9 — Debugging a Silent Failure
```js
class MyData {
  constructor(value) { this.value = value; }
  double() { return this.value * 2; }
}

const instance = new MyData(21);
worker.postMessage(instance);

// worker.js
self.onmessage = (e) => {
  console.log(e.data.double()); // TypeError: e.data.double is not a function
};
```
Explain exactly why this fails, referencing what structured clone does and
does not preserve. What's the correct way to send this data if the worker
needs `double()` too?

*Tests:* Section 5 — structured clone strips the prototype chain, so
methods don't survive. Correct fix: either send plain data
(`{ value: 21 }`) and reconstruct `new MyData(e.data.value)` inside the
worker (since the class definition itself must exist in both files), or
avoid classes for cross-boundary data entirely and use plain objects +
standalone functions.

---

## Problem 10 — SharedArrayBuffer Reasoning
Two workers both increment a shared counter stored in a
`SharedArrayBuffer` 100,000 times each, using plain array reads/writes
(no `Atomics`). The final value is consistently less than 200,000.
Explain why, and fix it.

*Tests:* Section 11 — race conditions on true shared memory. Answer:
classic read-modify-write race — both threads can read the same value
before either writes back the incremented result, so increments get lost.
Fix: use `Atomics.add(sharedArray, index, 1)` for the increment, which is
guaranteed atomic across threads.