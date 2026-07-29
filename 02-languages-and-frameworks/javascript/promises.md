# Promises

## Core Model

A Promise is a state machine, not a value container. Three states — `pending`, `fulfilled`, `rejected` — and once settled (fulfilled/rejected), it's **immutable forever**. This immutability is the entire point: it's what makes `.then()` chains composable and safe to hand around, unlike callbacks which can be invoked multiple times or never.

```js
const p = new Promise((resolve, reject) => {
  // executor runs SYNCHRONOUSLY, immediately
  resolve(42);
});
```

**Interview trap:** the executor function runs synchronously the moment `new Promise()` is called. Only the `.then()` callbacks are deferred to the microtask queue.

```js
console.log('1');
new Promise((res) => { console.log('2'); res(); }).then(() => console.log('3'));
console.log('4');
// 1, 2, 4, 3
```

## Microtask Queue vs Macrotask Queue

This is the #1 asked concept at senior level.

- Promise callbacks (`.then`, `.catch`, `.finally`, `queueMicrotask`) → **microtask queue**
- `setTimeout`, `setInterval`, I/O → **macrotask queue**
- After each macrotask, the event loop **drains the entire microtask queue** before rendering or picking the next macrotask.

```js
setTimeout(() => console.log('macro'), 0);
Promise.resolve().then(() => console.log('micro'));
console.log('sync');
// sync, micro, macro
```

If you chain `.then()` recursively without yielding, you can **starve the macrotask queue** (rendering, I/O never happens) — a real production footgun, not just trivia.

## Chaining and Error Propagation

`.then(onFulfilled, onRejected)` always returns a **new** Promise. Whatever the handler returns gets auto-wrapped:
- Return a plain value → next promise resolves with it.
- Return a thenable/Promise → chain "adopts" its state (this is the flattening behavior, aka no promise-of-a-promise nesting).
- Throw → next promise rejects.

Errors propagate down the chain like a synchronous `try/catch` — skip to the nearest `.catch`/rejection handler, ignoring intermediate `.then`s.

```js
fetchUser()
  .then(parseUser)     // if this throws, skips straight to .catch
  .then(saveUser)
  .catch(handleError)  // catches ANY rejection upstream
  .finally(() => cleanup()); // runs regardless, doesn't alter the resolved value
```

**Gotcha:** `.catch()` after `.finally()` — `.finally()` doesn't consume the rejection, it just observes and re-throws it downstream unless you throw inside `.finally` itself.

## Combinators — know the failure semantics cold

| Method | Resolves when | Rejects when | Use case |
|---|---|---|---|
| `Promise.all` | all fulfill | **any one** rejects (fails fast) | all-or-nothing batch |
| `Promise.allSettled` | always, once all settle | never | need every result regardless of failure |
| `Promise.race` | first to settle (fulfill or reject) | first to settle | timeout patterns |
| `Promise.any` | first to fulfill | all reject (`AggregateError`) | first success wins, tolerate failures |

Classic interview implementation ask: **implement `Promise.all` from scratch**.

```js
function promiseAll(promises) {
  return new Promise((resolve, reject) => {
    const results = [];
    let completed = 0;
    if (promises.length === 0) return resolve([]);
    promises.forEach((p, i) => {
      Promise.resolve(p).then((val) => {
        results[i] = val;          // preserve order, not completion order
        if (++completed === promises.length) resolve(results);
      }, reject);                   // first rejection short-circuits
    });
  });
}
```

Common timeout pattern using `race`:

```js
const withTimeout = (promise, ms) =>
  Promise.race([
    promise,
    new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms)),
  ]);
```

## async/await — sugar, not a new mechanism

`async function` always returns a Promise. `await` pauses execution and unwraps the resolved value — but it's still built on `.then()` under the hood, meaning it's still microtask-driven, not magically synchronous.

```js
async function f() {
  console.log('a');
  await null;          // yields to microtask queue even with a non-promise
  console.log('b');
}
f();
console.log('c');
// a, c, b
```

**Sequential vs parallel — the #1 real-world bug:**

```js
// BAD: sequential, 3x slower — each await blocks the next
const a = await fetchA();
const b = await fetchB();
const c = await fetchC();

// GOOD: fire concurrently, await together
const [a, b, c] = await Promise.all([fetchA(), fetchB(), fetchC()]);
```

Error handling: `try/catch` around `await` is equivalent to `.catch()`. In loops, prefer `try/catch` per-iteration if one failure shouldn't abort the rest — otherwise a single `await` throw exits the whole function.

## Unhandled Rejections

A rejected promise with no `.catch` triggers `unhandledrejection` (browser) / `unhandledRejection` (Node). In Node, as of modern LTS, this **crashes the process by default** — not just a warning. Worth mentioning in interviews as a production reliability concern, especially with fire-and-forget async calls (`doSomethingAsync()` without `await` or `.catch`).

## Mental Model Summary

- Promise = eventual value + guaranteed single settlement + microtask scheduling.
- `.then` chain = monadic flatMap — flattening avoids callback pyramid AND avoids promise-of-promise nesting.
- `async/await` = syntactic sugar over `.then`, doesn't change the concurrency model, only readability.
- Concurrency bugs in interviews almost always trace back to accidental sequential `await`s or misunderstanding `all` vs `allSettled` failure semantics.

## Interview Q&A Rapid Fire

**Q: Is a Promise cancellable?**
No, natively. Cancellation is simulated via `AbortController`/`AbortSignal` passed into the async operation itself (e.g. `fetch(url, { signal })`); the Promise itself still settles once, you just choose to ignore the result.

**Q: What happens if you resolve a promise twice?**
Second (and all further) `resolve`/`reject` calls are silently no-ops. First settlement wins.

**Q: Difference between `.then(f).catch(g)` and `.then(f, g)`?**
`.then(f, g)` — `g` only catches rejections from the *original* promise, not errors thrown inside `f`. `.then(f).catch(g)` — `g` catches errors from `f` too. Chained `.catch` is almost always what you want.

**Q: Why does `for...of` with `await` work but `forEach` with `await` doesn't wait?**
`forEach` ignores the return value of its callback entirely — an async callback's returned promise is discarded, so `forEach` doesn't await anything and moves on synchronously. `for...of` respects `await` because it's just normal statement execution inside the loop body.