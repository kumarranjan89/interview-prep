# Event Loop

## Core Definition

The event loop is the mechanism that lets single-threaded JavaScript handle async operations without blocking. It's **not part of the JS engine** — it's provided by the **host environment** (browser or Node/libuv). The engine just executes code and maintains the call stack + job queue; the host decides when to feed work back into the engine.

## The Four Pieces

1. **Call Stack** — where synchronous execution happens, one frame at a time, LIFO.
2. **Web APIs / Node APIs** — `setTimeout`, DOM events, `fetch`, `fs` — these are **not** JS, they're provided by the host, running outside the single JS thread (browser uses separate threads internally, Node uses libuv's thread pool for some I/O).
3. **Callback / Macrotask Queue** — where completed async work (timer fired, I/O done) gets queued, FIFO.
4. **Microtask Queue** — separate, **higher-priority** queue for Promise callbacks; see [Promises notes](./promises.md).

## The Actual Algorithm

```
while (true) {
  1. Run the call stack to completion (execute one task fully)
  2. Drain the ENTIRE microtask queue (including microtasks queued during this drain)
  3. (Browser only) Possibly repaint / run rAF callbacks
  4. Pull ONE task from the macrotask queue, push to call stack, go to step 1
}
```

**Key detail people get wrong:** step 2 doesn't run "one microtask" — it drains until the queue is **completely empty**, even if new microtasks keep getting added during the drain. Only then does the loop move to a single macrotask.

```js
console.log('start');

setTimeout(() => console.log('timeout'), 0);

Promise.resolve().then(() => {
  console.log('promise 1');
  Promise.resolve().then(() => console.log('promise 2')); // queued during drain
});

console.log('end');
// start, end, promise 1, promise 2, timeout
```

## Why the Call Stack Must Be Empty First

Async callbacks (from either queue) **never** preempt running synchronous code — JS is single-threaded, so a long synchronous block starves *everything*, timers included.

```js
setTimeout(() => console.log('fires late'), 0);
const start = Date.now();
while (Date.now() - start < 3000) {} // blocks for 3s — nothing else can run
console.log('sync done');
// sync done (after 3s), THEN fires late — the timeout was ready at 0ms but had to wait
```

`setTimeout(fn, 0)` means "run as soon as the call stack is empty and it's this task's turn" — not "run in 0ms." This is a very common interview trick question.

## Node.js Specifics (libuv phases)

Node's event loop isn't a single queue — it's **phases**, each with its own FIFO queue, cycled in order:

1. **timers** — `setTimeout`/`setInterval` callbacks
2. **pending callbacks** — deferred I/O callbacks
3. **poll** — retrieve new I/O events, execute I/O callbacks
4. **check** — `setImmediate` callbacks
5. **close callbacks** — e.g. `socket.on('close')`

Microtasks (`process.nextTick` — even higher priority than Promise microtasks — and Promise callbacks) drain **between every phase transition**, not just once per full loop.

**Classic Node interview question:** `setTimeout(fn, 0)` vs `setImmediate(fn)` — order is **not guaranteed** at the top level (depends on process startup timing), but **inside an I/O callback**, `setImmediate` always fires before `setTimeout`, because you're already in/after the poll phase and check comes next, while timers is a full loop away.

## Starvation Risks (real production concern, not trivia)

- **Microtask starvation of macrotasks**: recursive `.then()` chains or `process.nextTick` recursion can block timers/I/O indefinitely — the loop never reaches step 4 above.
- **Long synchronous tasks block everything**: heavy synchronous computation (JSON.parse on huge payload, tight loops, sync crypto) freezes the UI in browsers and stalls all requests in a single Node process. Fix: chunk work, move to Web Worker / Node worker_threads, or use async-friendly APIs.

## Mental Model Summary

- Engine executes; **host schedules**. Event loop lives in the host layer (HTML spec / libuv), not in V8 itself.
- Priority order per tick: **synchronous code → all microtasks (fully drained, spec-guaranteed) → one macrotask → repeat.**
- `setTimeout(fn, 0)` is a *minimum* delay + "get in line," not an immediate guarantee.
- Node's loop is phase-based, not a flat queue — this is *why* `setImmediate` vs `setTimeout` ordering differs from browser mental models.

## Interview Q&A Rapid Fire

**Q: Is the event loop part of JavaScript the language?**
No — it's not in the ECMAScript spec. It's defined by the host (WHATWG HTML spec for browsers, libuv for Node). The engine only guarantees the Job Queue (microtasks) per ECMAScript.

**Q: Why do Promise callbacks run before `setTimeout(fn, 0)` even when the timeout is scheduled first?**
Because microtasks are drained completely before the loop pulls a single macrotask — priority is structural, not about scheduling order.

**Q: What's `process.nextTick` and how is it different from a Promise microtask in Node?**
It has its own queue with **even higher priority** than the Promise microtask queue — it's drained first, and recursively (fully), before Promise microtasks get a turn. Overusing it can starve Promises entirely, a Node-specific footgun.

**Q: Can you block the event loop, and what happens if you do?**
Yes — any long synchronous operation blocks the single thread, meaning no timers, no I/O callbacks, no rendering (browser) can happen until the stack clears. This is why CPU-heavy work should be chunked, deferred, or offloaded to workers.