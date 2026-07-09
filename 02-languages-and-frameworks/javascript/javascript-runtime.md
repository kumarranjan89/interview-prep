# JavaScript Runtime — Interview Notes

> Mental model first, mechanics second. Written for a senior dev prepping FAANG/product-company interviews — assumes you already know JS, this fills gaps + sharpens the "explain it on a whiteboard" version.

---

## 1. Overview — The One Mental Model

JS itself is just a **language spec** (ECMAScript). It has no I/O, no timers, no DOM. The **runtime** is everything wrapped around the engine that makes JS actually do things — talk to network, wait, schedule, render.

**The one-liner to say in an interview:**
> "JS is single-threaded and synchronous by itself. The runtime (browser or Node) gives it async superpowers via Web/Node APIs, queues, and an event loop that keeps the single thread from blocking."

Think of it as **4 layers working together**:

```
┌─────────────────────────────────────────────┐
│              JS ENGINE (V8 etc.)             │
│   Call Stack  +  Memory Heap  +  Compiler    │
└───────────────┬───────────────────────────────┘
                │
┌───────────────┴───────────────────────────────┐
│         RUNTIME APIs (Browser / Node)          │
│  Web APIs (DOM, fetch, setTimeout) OR          │
│  Node APIs (fs, libuv thread pool)             │
└───────────────┬───────────────────────────────┘
                │
┌───────────────┴───────────────────────────────┐
│      CALLBACK QUEUES (Macro + Micro)           │
└───────────────┬───────────────────────────────┘
                │
┌───────────────┴───────────────────────────────┐
│               EVENT LOOP                       │
│   (pushes queued callbacks back to stack       │
│    only when stack is empty)                   │
└─────────────────────────────────────────────────┘
```

**Golden rule interviewers want to hear:** *"Call stack must be empty before the event loop pushes anything from any queue."*

---

## 2. Components at a Glance

| # | Component | What it does | Owned by |
|---|---|---|---|
| 1 | **JS Engine** (Parser, AST, Interpreter, JIT Compiler) | Parses & executes JS | V8 / SpiderMonkey / JSC |
| 2 | **Memory Heap** | Stores objects, closures, allocations | Engine |
| 3 | **Call Stack** | Tracks execution contexts (sync execution) | Engine |
| 4 | **Garbage Collector** | Frees unreachable memory | Engine |
| 5 | **Web APIs / Node APIs** | DOM, `fetch`, `setTimeout`, `fs`, timers | Browser / libuv (Node) |
| 6 | **Macrotask Queue (Task Queue)** | Holds `setTimeout`, I/O, UI events callbacks | Runtime |
| 7 | **Microtask Queue** | Holds Promise `.then`, `queueMicrotask`, `MutationObserver` | Runtime |
| 8 | **Event Loop** | Orchestrator — decides what runs next | Runtime |
| 9 | **Render Queue** (browser only) | Paint/layout, `requestAnimationFrame` | Browser |
| 10 | **libuv Event Loop Phases** (Node only) | timers → pending → poll → check → close | Node |

Each of these is expanded step by step below.

---

## 3. Deep Dive — Component by Component

### 3.1 JS Engine (V8 as reference)

**Pipeline:**
```
Source Code → Tokenizer → Parser → AST → Ignition (Interpreter, bytecode)
           → Profiler watches "hot" code → TurboFan (JIT compiler, optimized machine code)
           → Deoptimization if assumptions break (e.g., hidden class changes)
```

- **Ignition**: interpreter, generates bytecode fast, no upfront compile delay.
- **TurboFan**: optimizing JIT compiler — kicks in for "hot" (frequently run) functions, compiles to optimized machine code using assumptions (e.g., "this object always has shape `{x, y}`").
- **Deoptimization (bailout)**: if a hot function later gets called with a differently-shaped object, TurboFan throws away the optimized code and falls back to Ignition. **This is why monomorphic functions (consistent argument shapes) are faster** — classic V8 interview gotcha.
- **Hidden Classes**: V8 creates internal "shapes" for objects. Adding properties in different order to similar objects creates different hidden classes → deopt risk.

**Interview Q&A:**
- *"Why is `for (let i of arr)` sometimes slower than `for (let i=0...)`?"* → iterator protocol overhead, though V8 has optimized this a lot in recent versions — mention it's engine/version dependent, not gospel.
- *"What causes deoptimization?"* → polymorphic shapes, `try/catch` (older engines), `arguments` object misuse, changing types of a variable.

---

### 3.2 Call Stack & Execution Context

- **Execution Context (EC)** = the environment in which code runs. Created for: Global, Function call, `eval`.
- Each EC has: **Variable Environment**, **Lexical Environment**, **`this` binding**.
- **Call Stack** = LIFO stack of ECs. Push on function call, pop on return.
- **Stack Overflow** = call stack exceeds limit (deep/infinite recursion).

**Two-phase creation of an EC (imp for hoisting Qs):**
1. **Creation phase**: hoist `var` (set to `undefined`), hoist function declarations (fully), create `let`/`const` bindings in **Temporal Dead Zone (TDZ)** — not yet initialized.
2. **Execution phase**: code runs line by line, assignments happen.

**Interview Q&A:**
- *"Why does `console.log(x); var x = 5;` print `undefined` but `let` version throws?"* → `var` hoisted + initialized to `undefined`; `let`/`const` hoisted but stay in TDZ until declaration line.
- *"Stack overflow vs memory leak — different things?"* → Yes: stack overflow = call stack limit hit (sync recursion), memory leak = heap keeps growing due to unreachable-but-referenced objects.

---

### 3.3 Memory Heap & Garbage Collection

- **Heap** = unstructured memory region for objects, closures, arrays.
- **Stack** = primitives + references (fixed size, fast).

**GC Algorithm (V8): Generational, Mark-and-Sweep based**
- **Young Generation (Scavenger / Minor GC)**: new objects, most die young ("infant mortality" hypothesis) → cheap, frequent collection.
- **Old Generation (Major GC / Mark-Sweep-Compact)**: objects that survive multiple young GC cycles get "promoted" here. Collected less often, more expensive.
- **Mark-and-Sweep**: mark all reachable objects from roots (global object, call stack) → sweep (free) unmarked ones.
- **Incremental & Concurrent marking**: modern V8 does GC work in small chunks alongside execution to avoid long "stop-the-world" pauses (reduces jank).

**Common memory leak sources (interview favorite):**
1. Global variables (accidental, no `use strict`).
2. Forgotten timers/intervals holding closures (`setInterval` never cleared).
3. Detached DOM nodes still referenced in JS variables.
4. Closures unintentionally capturing large objects.
5. Event listeners not removed.
6. Caches/Maps growing unbounded without eviction (use `WeakMap`/`WeakRef` here).

**Interview Q&A:**
- *"`WeakMap` vs `Map` for caching?"* → `WeakMap` keys are weakly held — don't prevent GC, ideal for caching data tied to object lifecycle (e.g., DOM node metadata) without leaking.

---

### 3.4 Lexical Environment, Scope Chain & Closures

- **Lexical scoping**: scope is determined by *where code is written*, not where it's called.
- **Scope Chain**: each EC has a reference to its outer lexical environment → chain used to resolve variables.
- **Closure**: a function + its lexically-enclosing scope's variables, retained even after outer function returns. Practically: **the scope chain isn't garbage collected if a closure still references it.**

**Interview Q&A:**
- *Classic loop closure bug*: `for (var i=0...) setTimeout(() => console.log(i))` prints `3,3,3` (var is function-scoped, shared) vs `let` prints `0,1,2` (block-scoped, new binding per iteration).
- *"Does every function create a closure?"* → Technically every function has access to its lexical scope, but we call it a "closure" meaningfully when it's *returned/escapes* and still uses outer variables after outer function finished.
- *Module pattern / private state via closures* — still asked in senior interviews for "how did we do encapsulation before classes/private fields."

---

### 3.5 Web APIs (Browser) vs Node APIs

These are **not part of the JS engine** — provided by the host environment.

| Browser (Web APIs) | Node.js (via libuv + bindings) |
|---|---|
| `setTimeout`/`setInterval` | `setTimeout`/`setInterval` (same API, different queue impl) |
| `fetch`, `XMLHttpRequest` | `http`, `fs`, `net` modules |
| DOM events | `EventEmitter`, streams |
| `requestAnimationFrame` | — (no rendering in Node) |
| Geolocation, Storage APIs | `process`, `child_process` |

**Key point:** async functions like `setTimeout` don't "run" in the JS engine — they're handed off to the browser/Node, which handles timing/I/O in a separate thread/mechanism, and only the **callback** comes back into JS via a queue.

---

### 3.6 Macrotask Queue vs Microtask Queue

This is the **#1 asked runtime topic** in senior interviews.

| | Macrotask (Task) Queue | Microtask Queue |
|---|---|---|
| Examples | `setTimeout`, `setInterval`, I/O, UI rendering, `setImmediate` (Node) | `Promise.then/catch/finally`, `queueMicrotask`, `MutationObserver`, `async/await` (resumption) |
| Priority | Lower | **Higher — always drained fully before next macrotask** |
| When run | One macrotask per event loop tick | ALL pending microtasks run before moving on, even if new ones get added during draining |

**Execution order rule (memorize this):**
```
1. Run current synchronous script (this is itself a macrotask)
2. Drain ENTIRE microtask queue (even newly added ones)
3. (Browser) Maybe render/paint
4. Take ONE macrotask from queue, run it
5. Go back to step 2
```

**Classic interview trap:**
```js
console.log('1');
setTimeout(() => console.log('2'), 0);
Promise.resolve().then(() => console.log('3'));
console.log('4');
// Output: 1, 4, 3, 2
```
Explain: sync code runs first (1, 4) → microtask queue drained (3) → then macrotask (2).

**Interview Q&A:**
- *"Can a microtask starve macrotasks?"* → Yes — if a `.then` callback keeps chaining more microtasks infinitely, the event loop never gets to macrotasks/rendering → page freeze. Real footgun in production.
- *"Where does `async/await` fit?"* → `await` pauses the async function and schedules the continuation as a **microtask** once the awaited promise settles. Under the hood it's sugar over `.then()`.

---

### 3.7 The Event Loop (Orchestrator)

**Definition to say out loud:**
> "The event loop is a continuously running process that checks: is the call stack empty? If yes, first drain all microtasks, then pull the next macrotask from the queue and push it onto the call stack."

- Single-threaded — only one thing executes at a time on the main thread.
- Doesn't block on I/O — delegates to Web APIs/libuv, picks up the result later via queue.
- This is what makes JS **concurrent (not parallel)** on a single thread.

**Concurrency vs Parallelism (senior-level distinction they probe):**
- Concurrency = handling multiple tasks by interleaving (what JS does via event loop).
- Parallelism = tasks literally running at the same time on multiple cores (Web Workers, Node `worker_threads`, `child_process` — true parallelism in JS ecosystem).

---

### 3.8 Node.js Event Loop — Deeper (libuv Phases)

Node's loop is more granular than the browser's simple macro/micro model. **libuv** runs these phases in order, each tick:

```
   ┌───────────────────────┐
┌─>│        timers         │  setTimeout, setInterval callbacks
│  ├───────────────────────┤
│  │   pending callbacks    │  I/O callbacks deferred from previous cycle
│  ├───────────────────────┤
│  │    idle, prepare       │  internal use
│  ├───────────────────────┤
│  │         poll           │  retrieve new I/O events, execute I/O callbacks
│  ├───────────────────────┤
│  │        check           │  setImmediate() callbacks
│  ├───────────────────────┤
│  │   close callbacks      │  socket.on('close', ...)
│  └───────────────────────┘
└──────────── loop repeats ─┘
```

- **Microtasks (`process.nextTick` and Promise `.then`) run BETWEEN every phase**, not just once per loop. `process.nextTick` queue is drained even before the Promise microtask queue (Node-specific priority: `nextTick` > Promise microtasks > next phase).
- **`setImmediate` vs `setTimeout(fn, 0)`**: order is **not guaranteed** if called from the main module, but inside an I/O callback, `setImmediate` always fires before `setTimeout` (because you're already past the poll phase, check phase is next).
- **Thread pool (libuv)**: default 4 threads, used for `fs`, `dns.lookup`, `crypto` (pbkdf2, etc.), `zlib` — these are genuinely offloaded to OS threads, unlike network I/O which uses OS-level async (epoll/kqueue/IOCP) and doesn't need the thread pool.

**Interview Q&A:**
- *"Is Node single-threaded?"* → Nuanced answer: **the JS execution is single-threaded**, but Node itself uses a thread pool (libuv) for certain blocking operations (file I/O, crypto) under the hood. Good answers show this nuance.
- *"`process.nextTick` vs `setImmediate`?"* → `nextTick` runs before Promise microtasks, before moving to next phase — highest priority, can starve I/O if abused recursively. `setImmediate` runs in the check phase, after I/O.

---

### 3.9 Browser Rendering & `requestAnimationFrame`

- Browser tries to render at **60fps (~16.6ms/frame)**.
- Rendering (recalculate style → layout → paint → composite) happens **after microtasks drain, before the next macrotask**, roughly once per event loop iteration if a repaint is needed.
- `requestAnimationFrame(cb)` schedules `cb` to run right before the next repaint — use for animations, not `setTimeout` (avoids jank/tearing).
- Long-running sync JS or microtask chains **block rendering** → jank. This is why heavy computation should be chunked or moved to a Web Worker.

---

### 3.10 `this` Binding (Execution Context Type)

Quick reference table — always comes up:

| Call style | `this` value |
|---|---|
| Regular function call | `undefined` (strict mode) / global object (sloppy) |
| Method call `obj.fn()` | `obj` |
| Arrow function | Lexical — inherits `this` from enclosing scope (no own `this`) |
| `new Fn()` | Newly created object |
| `.call/.apply/.bind` | Explicitly set object |
| Class method | Instance (unless destructured — then lost, classic bug) |
| Event handler (DOM) | The element the listener is attached to (unless arrow fn) |

**Interview trap:** destructuring a class method (`const { method } = obj`) loses `this` binding — must `bind` or use arrow class fields (`method = () => {}`).

---

## 4. Rapid-Fire Interview Answers (Cheat Sheet)

| Question | One-line senior answer |
|---|---|
| Is JS single-threaded? | JS execution: yes. Runtime (Node/libuv, browser): uses threads under the hood for I/O. |
| Sync vs async? | Sync = blocks call stack. Async = delegated to runtime, callback re-enters via queue when stack is empty. |
| Micro vs macro task priority | All microtasks drain fully before the next macrotask runs. |
| What is event loop's job | Bridge between call stack and queues; only acts when stack is empty. |
| Why can Promise chains freeze UI | Microtask queue must fully drain before render/macrotask — infinite `.then()` chaining starves everything else. |
| `var` vs `let` hoisting | Both hoisted; `var` initialized `undefined`, `let`/`const` stay in TDZ until declared. |
| Memory leak, most common cause in SPA | Detached DOM nodes / uncleared listeners / timers holding closures. |
| Node thread pool used for what | `fs`, `crypto` (some), `zlib`, `dns.lookup` — CPU/blocking-ish ops; network I/O uses OS async, not the pool. |
| How does `async/await` map to microtasks | Each `await` resumption = a microtask scheduled when the awaited promise settles. |

---

## 5. Suggested Follow-up Deep Dives (if time permits before interviews)

- V8 hidden classes & inline caching (for "how does JS achieve near-native speed" type Qs).
- `Atomics`/`SharedArrayBuffer` + Web Workers (true parallelism story).
- Node `Worker Threads` vs `Cluster` vs `child_process` — when to use which.
- Backpressure in Node Streams (if asked about high-throughput I/O design).

---

*File: `01-foundations/javascript-runtime.md` — part of interview prep repo.*