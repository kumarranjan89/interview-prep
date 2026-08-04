# Timers

## Scope of This Topic

`setTimeout`/`setInterval`/`setImmediate` are host APIs (not part of JS itself — see `js-runtime.md`), implemented via libuv's **timers phase** and **check phase** respectively (see `node-event-loop.md` for the phase mechanics). This topic is about correct usage patterns and the gotchas that show up in real code.

## The Three Timer APIs

```js
setTimeout(() => console.log('once, after delay'), 1000);
setInterval(() => console.log('repeats every interval'), 1000);
setImmediate(() => console.log('runs in check phase, after current poll cycle'));
```

`setImmediate` is Node-specific (no browser equivalent) — designed to run a callback right after the current poll phase completes, useful for "do this after I/O, but don't wait an arbitrary timer delay."

## Delay Is a Minimum, Not a Guarantee

```js
setTimeout(() => console.log('fires'), 100);
// Actually fires when: (a) 100ms has elapsed AND (b) the event loop reaches the timers phase AND (c) the call stack is empty
```

If the main thread is busy (synchronous work, or a full microtask queue draining), the timer callback waits — `setTimeout(fn, 0)` genuinely means "as soon as possible after the stack clears," not "immediately." This directly connects to the event-loop starvation topic already covered.

## Clearing Timers — Avoiding Leaks

```js
const timeoutId = setTimeout(doSomething, 5000);
clearTimeout(timeoutId); // cancel before it fires

const intervalId = setInterval(poll, 1000);
clearInterval(intervalId); // MUST clear, or it runs forever, keeping the process alive
```

**Real leak pattern:** an uncleared `setInterval` inside a function/class instance that gets discarded (e.g. a request-scoped object, a component instance) keeps a reference to its closure alive indefinitely — both a memory leak and, in a request-handling context, an ever-growing pile of duplicate intervals running the same logic repeatedly.

## `unref()` — Letting the Process Exit Naturally

By default, a pending timer keeps the Node process alive (the event loop has "work" to do). `unref()` opts a timer out of that behavior:

```js
const timer = setTimeout(() => console.log('background task'), 60000);
timer.unref(); // process can exit even if this timer hasn't fired yet — useful for non-critical background timers
```

Useful for things like periodic non-essential telemetry pings that shouldn't prevent a script/CLI tool from exiting naturally when its actual work is done.

## `setInterval` Drift — A Real Correctness Issue

`setInterval` schedules the *next* call relative to when the *previous* call was scheduled, not when it actually finished executing — if the callback itself takes meaningful time, or the event loop is briefly busy, intervals can drift or even overlap.

```js
// If doWork() sometimes takes >1000ms, calls can pile up / overlap unexpectedly
setInterval(doWork, 1000);

// Safer pattern for guaranteed non-overlapping execution — recursive setTimeout
function scheduleNext() {
  setTimeout(() => {
    doWork();
    scheduleNext(); // only schedules the NEXT run after THIS one completes
  }, 1000);
}
scheduleNext();
```

This recursive-`setTimeout` pattern is the standard fix for polling loops, cron-like periodic jobs, or retry logic where overlapping executions would cause real bugs (e.g. two overlapping DB polls double-processing the same rows).

## Mental Model Summary

- `setTimeout`/`setInterval`/`setImmediate` are host APIs backed by libuv's timers/check phases — delay is a minimum, gated by the call stack being empty and the loop reaching the right phase.
- Always clear intervals/timeouts that are no longer needed — an uncleared `setInterval` is a common, easy-to-miss leak and duplicate-execution source.
- `unref()` lets a pending timer avoid keeping the process alive — useful for background/non-critical scheduled work.
- `setInterval` doesn't wait for slow callbacks to finish before scheduling the next tick — recursive `setTimeout` is the correct pattern when non-overlapping execution matters.

## Fullstack Angle — What You'd Actually Debug

- **A background poll/interval seems to run more often than configured, or overlaps itself under load** → classic `setInterval` drift/overlap with a slow callback — switch to recursive `setTimeout`.
- **Memory/CPU usage grows the longer a long-running process runs** → check for uncleared intervals accumulating (e.g. created per-request or per-connection without a corresponding `clearInterval` on cleanup).
- **CLI tool/script hangs and won't exit even though "the work is done"** → an un-`unref()`'d timer (or uncleared interval) is keeping the event loop alive artificially.

## Architect Angle — What You'd Actually Decide

- **Polling vs event-driven design**: any `setInterval`-based polling pattern (checking a queue, DB table, external API) is worth reconsidering against an event-driven alternative (webhooks, pub/sub, message queue) at scale — polling has an inherent latency/efficiency trade-off that compounds across many service instances.
- **Standardize the recursive-`setTimeout` pattern** for any team-wide polling/retry utility rather than letting each service reinvent `setInterval`-based polling with its own drift/overlap bugs — a good candidate for a shared internal utility library.
- **Timer cleanup as part of service lifecycle management**: services with background timers should have those cleanup calls (`clearInterval`) wired into the same graceful shutdown path covered in `process.md` — an easy thing to miss when only `SIGTERM` handling for server connections is considered.

## Interview Q&A Rapid Fire

**Q: Does `setTimeout(fn, 100)` guarantee the callback runs at exactly 100ms?**
No — 100ms is a minimum delay. The callback only runs once that time has elapsed AND the event loop reaches the timers phase AND the call stack is empty; a busy main thread or full microtask queue can delay it further.

**Q: Why is `setInterval` risky for tasks whose duration might exceed the interval?**
`setInterval` schedules subsequent calls based on the original interval, not the completion time of the previous callback — a slow callback can cause overlapping executions. Recursive `setTimeout` (scheduling the next call only after the current one finishes) avoids this.

**Q: What does `timer.unref()` do and when would you use it?**
It excludes that timer from keeping the Node process alive — useful for background/non-essential scheduled work (e.g. periodic telemetry) in scripts or CLI tools that should be able to exit naturally once their primary work completes, even if such a timer is still pending.

**Q: What's a common memory/resource leak pattern involving timers?**
An uncleared `setInterval` whose enclosing object/scope is discarded but the interval keeps running — the closure (and anything it references) stays alive indefinitely, and in request-scoped code this can create an ever-growing number of duplicate running intervals over time.