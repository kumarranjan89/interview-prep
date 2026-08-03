# Node.js Event Loop (libuv Phases)

## Scope of This Topic

Builds directly on `event-loop.md` (browser model) and `js-runtime.md` — this is the **Node-specific** implementation via libuv, which is phase-based, not a flat microtask/macrotask split like the browser. If the browser event loop notes are fresh, the delta to focus on here is the **phase structure** and **`process.nextTick`**.

## The Six Phases

```
   ┌───────────────────────────┐
┌─▶│           timers          │  ← setTimeout / setInterval callbacks due
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
│  │     pending callbacks      │  ← deferred I/O callbacks (some system errors)
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
│  │        idle, prepare       │  ← internal use only
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
│  │            poll            │  ← retrieve new I/O events, execute I/O callbacks (MOST work happens here)
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
│  │            check           │  ← setImmediate callbacks
│  └─────────────┬─────────────┘
│  ┌─────────────▼─────────────┐
└──┤       close callbacks      │  ← e.g. socket.on('close', ...)
   └───────────────────────────┘
```

Each phase has its own FIFO callback queue. The loop cycles through all six phases, then repeats — as long as there's pending work (timers, I/O, etc.) keeping the process alive.

## Microtasks: `process.nextTick` vs Promises

Node has **two** microtask-like queues, and they are not equal priority — this is the single most commonly mis-answered Node interview question:

```
process.nextTick queue   ← HIGHEST priority, Node-specific, not in any spec
      |
Promise microtask queue  ← standard ECMAScript microtasks (.then/.catch/.finally)
```

**Both queues drain completely between every phase transition** — not just once per full loop — and `nextTick` always drains first, including any new `nextTick` calls added during its own drain (meaning a `nextTick`-recursion can starve the Promise queue and the entire rest of the event loop).

```js
console.log('start');

setTimeout(() => console.log('timeout'), 0);
setImmediate(() => console.log('immediate'));

process.nextTick(() => console.log('nextTick'));
Promise.resolve().then(() => console.log('promise'));

console.log('end');

// Output: start, end, nextTick, promise, timeout, immediate
// (timeout vs immediate order at top-level is non-deterministic — see below)
```

## `setTimeout` vs `setImmediate` — The Classic Gotcha

**At the top level of a script**, ordering between `setTimeout(fn, 0)` and `setImmediate(fn)` is **not guaranteed** — depends on process startup performance (how long it takes to enter the event loop and reach the timers phase versus the check phase).

**Inside an I/O callback**, ordering *is* guaranteed — `setImmediate` always wins:

```js
const fs = require('fs');

fs.readFile(__filename, () => {
  setTimeout(() => console.log('timeout'), 0);
  setImmediate(() => console.log('immediate'));
});
// Always: immediate, timeout
```

Why: the I/O callback runs during the **poll** phase. After poll comes **check** (`setImmediate` fires here immediately), while **timers** is a full loop cycle away (loop must wrap back around). This is a genuinely common "explain this Node quirk" interview question.

## Why the "Poll" Phase Matters Most

Poll is where Node spends most of its time in a typical server — it does two things:

1. Calculates how long it should block/poll for I/O events
2. Processes events in its queue (executing I/O-related callbacks)

If the poll queue isn't empty, callbacks execute synchronously until the queue drains or a system-dependent hard limit is hit. If empty, and there are `setImmediate` callbacks scheduled, the loop moves straight to **check** instead of waiting/blocking in poll.

## Starving the Loop (real production incidents, not just trivia)

```js
// process.nextTick recursion — starves EVERYTHING: I/O, timers, Promises
function recurse() {
  process.nextTick(recurse);
}
recurse();
// Server becomes completely unresponsive — no requests processed, ever
```

This has caused real production outages — a well-intentioned `nextTick`-based retry/polling pattern that never yields is a total event-loop lockup, worse than a slow synchronous function because it never even *starts* other work.

## Mental Model Summary

- Node's loop is **phase-based** (timers → pending → poll → check → close), not a flat browser-style queue.
- `process.nextTick` > Promise microtasks > next phase's macrotasks, in priority, drained fully between every phase.
- `setImmediate` vs `setTimeout(fn, 0)` is only deterministic **inside an I/O callback** (immediate wins there) — non-deterministic at top level.
- Poll phase is where most real work happens in a typical Node server (I/O callback execution).

## Fullstack Angle — What You'd Actually Debug

- **Server occasionally "hangs" under specific request patterns** → check for `process.nextTick` or recursive Promise chains without any yielding — a very real, hard-to-spot cause of total unresponsiveness, not a GC pause or slow query.
- **File-read-triggered logic timing feels inconsistent between environments** → confirm whether you're relying on `setTimeout` vs `setImmediate` ordering at the top level (non-deterministic) vs inside an I/O callback (deterministic) — a common source of "works on my machine" timing bugs.

## Architect Angle — What You'd Actually Decide

- **Health check / heartbeat design**: avoid `process.nextTick`-based polling loops in shared services — prefer `setImmediate` or a proper timer with actual delay, since `nextTick` starvation risk scales with service criticality (a starved event loop means the health check itself stops responding, masking the real outage).
- **Observability**: event loop lag (time between expected and actual timer fire) is a first-class metric to monitor in production Node services — a growing lag number is often the earliest signal of a starvation or CPU-bound-task problem, before requests visibly start failing.
- **I/O-heavy service design**: understanding that poll phase dominates typical execution reinforces why Node fits I/O-bound service boundaries well in a microservices architecture — CPU-bound boundaries should be pushed to different services/languages rather than fought within Node's model.

## Interview Q&A Rapid Fire

**Q: What are the phases of Node's event loop, in order?**
timers → pending callbacks → idle/prepare (internal) → poll → check → close callbacks — cycling continuously while there's pending work.

**Q: What's the priority order between `process.nextTick` and Promise microtasks?**
`process.nextTick` queue drains first and completely (including any nextTick calls added during its own drain), then the Promise microtask queue drains — both happen between every phase transition, not just once per loop.

**Q: Why is `setImmediate` vs `setTimeout(fn, 0)` ordering only reliable inside an I/O callback?**
Because an I/O callback executes during the poll phase, and check (where setImmediate fires) is the very next phase — timers is a full loop cycle away. At the top level, before entering the loop, which phase gets reached first depends on process startup timing, so it's non-deterministic.

**Q: What's the danger of recursive `process.nextTick` calls?**
Since the nextTick queue must fully drain — including newly added callbacks — before the loop can proceed to the next phase, an unbounded recursive nextTick chain never lets the loop advance, completely starving all I/O, timers, and even Promise callbacks — a total event-loop lockup.