# Browser Internals & Rendering Flow

## Scope of This Topic

Where the runtime (previous topic) actually pays off visually — how the browser turns HTML/CSS/JS into pixels on screen, and precisely where JS execution intersects that pipeline. Browser-specific; doesn't apply to Node.

## The Critical Rendering Path

```
HTML  ──parse──▶  DOM Tree
CSS   ──parse──▶  CSSOM Tree
                       |
                       v
              DOM + CSSOM ──▶ Render Tree
                                   |
                                   v
                               Layout (Reflow)
                                   |
                                   v
                                 Paint
                                   |
                                   v
                              Composite  ──▶  Pixels on screen
```

- **DOM Tree**: structural representation of HTML elements
- **CSSOM Tree**: computed style rules, built in parallel with DOM parsing
- **Render Tree**: DOM + CSSOM merged, **excludes** `display: none` elements (but includes `visibility: hidden` — it still takes up space)
- **Layout (Reflow)**: computes exact position/size of every element (geometry)
- **Paint**: fills in pixels — colors, borders, shadows, text — onto layers
- **Composite**: layers combined by the GPU in the correct stacking order into the final frame

## Why `<script>` Blocks Parsing

By default, encountering a `<script>` tag **halts HTML parsing** — the browser must fetch (if external) and execute it before continuing, because the script might use `document.write()` or otherwise mutate the DOM being parsed.

```html
<!-- Parsing blocks here until script downloads AND executes -->
<script src="app.js"></script>

<!-- defer: downloads in parallel, executes after parsing completes, in order -->
<script src="app.js" defer></script>

<!-- async: downloads in parallel, executes immediately when ready (may interrupt parsing), no order guarantee -->
<script src="analytics.js" async></script>
```

**Practical rule:** `defer` for anything that needs the DOM or must run in a specific order (most app code); `async` for independent scripts (analytics, ads) that don't touch the DOM and don't care about execution order relative to other scripts.

## Reflow vs Repaint vs Composite — Cost Ordering

Not all visual updates are equally expensive — this is the actual answer to "why is my animation janky":

| Operation | Triggers | Cost |
|---|---|---|
| **Layout/Reflow** | Changing geometry — `width`, `height`, `top`, `left`, adding/removing DOM nodes | Most expensive — cascades to affected subtree/siblings |
| **Paint** | Changing visual style without geometry change — `color`, `background`, `box-shadow` | Medium |
| **Composite only** | `transform`, `opacity` | Cheapest — handled entirely on GPU compositor thread, skips layout AND paint |

**This is why `transform`/`opacity` are the go-to properties for smooth animations** — they can be composited without touching the main thread's layout/paint work at all.

## Layout Thrashing (a real, frequently-asked perf bug)

Reading a layout property (`offsetHeight`, `getBoundingClientRect()`, etc.) right after writing one forces the browser to **synchronously** recalculate layout, instead of batching it — because the read demands an up-to-date answer.

```js
// BAD — forces synchronous layout recalculation on every iteration
elements.forEach(el => {
  el.style.width = box.offsetWidth + 'px'; // write, then...
  console.log(el.offsetHeight);             // ...read — forces sync layout each time
});

// GOOD — batch all reads first, then all writes
const heights = elements.map(el => el.offsetHeight); // all reads together
elements.forEach((el, i) => { el.style.width = heights[i] + 'px'; }); // all writes together
```

## Where JS Timing Meets Rendering

The browser's rendering steps happen at specific points **relative to the event loop**, not just "whenever":

```
Task (e.g. event handler) runs
      |
      v
Microtask queue fully drained
      |
      v
If it's time to render (~ every frame, ~16.6ms @ 60fps):
      |
      v
requestAnimationFrame callbacks run  ← BEFORE next paint
      |
      v
Style → Layout → Paint → Composite
      |
      v
requestIdleCallback callbacks run (if time remains before next task)
```

- **`requestAnimationFrame` (rAF)**: schedule work to run right before the next repaint — the correct place for visual/animation updates, never `setTimeout` (which isn't synced to the display refresh).
- **`requestIdleCallback` (rIC)**: schedule low-priority work for browser idle time between frames — good for analytics batching, non-urgent prefetching. Not guaranteed to run soon (or at all) under heavy load.

```js
function animate() {
  el.style.transform = `translateX(${x++}px)`;
  requestAnimationFrame(animate); // synced to display refresh, not a fixed delay
}
requestAnimationFrame(animate);
```

## Long Tasks & Main Thread Blocking

Any task occupying the main thread for **>50ms** is classified a "long task" — it delays input response, animation, and layout, and is the direct driver of the **INP (Interaction to Next Paint)** Core Web Vital.

```js
// Blocks the main thread for the full duration — no rendering, no input handling possible
function heavySync() {
  const start = Date.now();
  while (Date.now() - start < 500) {} // 500ms freeze
}
```

**Fixes:** break work into chunks yielding back to the event loop (`setTimeout(fn, 0)` between chunks, or `scheduler.yield()`/`isInputPending()` in modern browsers), or move to a **Web Worker** for CPU-heavy work that doesn't need DOM access (workers run on a separate thread with their own heap, communicate only via `postMessage`/structured clone — no shared memory by default).

## Mental Model Summary

- Rendering path: **HTML+CSS → DOM+CSSOM → Render Tree → Layout → Paint → Composite.**
- Cost order: **Layout > Paint > Composite-only** — prefer `transform`/`opacity` for anything animated.
- `<script>` blocks parsing by default; use `defer`/`async` deliberately.
- Reading layout properties right after writing forces synchronous layout (thrashing) — batch reads, then writes.
- `requestAnimationFrame` is the correct scheduling primitive for visual updates, synced to actual display refresh — `setTimeout` is not.
- Anything over ~50ms on the main thread is a "long task" and directly hurts responsiveness (INP); offload or chunk it.

## Interview Q&A Rapid Fire

**Q: Why are `transform`/`opacity` preferred for animations over `top`/`left`/`width`?**
`top`/`left`/`width` trigger layout (geometry recalculation) which cascades and is expensive; `transform`/`opacity` can be handled entirely by the GPU compositor, skipping layout and paint — the cheapest possible visual update path.

**Q: What's the difference between `defer` and `async` on a script tag?**
Both download in parallel without blocking parsing. `defer` executes after parsing completes, in document order. `async` executes as soon as it's downloaded, which may interrupt parsing, with no ordering guarantee relative to other scripts.

**Q: What causes layout thrashing and how do you avoid it?**
Interleaving DOM reads (`offsetHeight`, `getBoundingClientRect`) with DOM writes in a loop forces synchronous layout recalculation on every iteration instead of one batched calculation. Fix: read everything first, then write everything.

**Q: Why use `requestAnimationFrame` instead of `setTimeout` for animations?**
`rAF` callbacks are scheduled to run right before the next actual repaint, synced to the display's refresh rate — `setTimeout` has no awareness of paint timing and can cause dropped or misaligned frames.

**Q: What's a "long task" and why does it matter?**
Any main-thread task running longer than ~50ms, during which no input handling, layout, or paint can happen — directly drives the INP Core Web Vital. Fixed by chunking work or offloading to a Web Worker.