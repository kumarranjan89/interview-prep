# Runtime & Rendering Performance

Keeping the app smooth *after* it loads — responsiveness, 60fps, and no memory leaks. This is where INP and jank live.

---

## Navigation
[← JavaScript Performance](./javascript-performance.md) | [Framework Performance →](./framework-performance.md)

---

## Loading vs Runtime Performance

```
Loading performance:   how fast the page APPEARS      (LCP, FCP)
Runtime performance:   how smooth it FEELS while used (INP, FPS, jank)
```

Previous files made loading fast. This file keeps it **smooth during interaction** — the second half of performance that JS-heavy apps often neglect.

---

## The 60fps Budget

```
60fps = 1 frame every 16.7ms
  → ALL work (JS + style + layout + paint + composite) must fit in ~16ms
  → exceed it → dropped frames → visible jank/stutter

120fps displays: ~8ms budget (even tighter)
```

> Every frame is a deadline. The main thread must finish its work in time, every time, or the user sees jank.

---

## The Main Thread Is Shared

```
ONE main thread runs: JS execution + style + layout + paint + input handling
  → a long JS task blocks input, animation, EVERYTHING
```

This is why **long tasks** are the enemy of runtime performance.

---

## 1. Long Tasks (The #1 INP Killer)

```
Long task = any main-thread task > 50ms
  → during it, the browser can't respond to input → poor INP
```

### Break Up Long Tasks
```javascript
// ❌ One long task blocks the thread for 500ms
function processAll(items) { items.forEach(heavyWork); }

// ✅ Chunk it, yielding to the event loop between chunks
async function processAll(items) {
  for (let i = 0; i < items.length; i++) {
    heavyWork(items[i]);
    if (i % 100 === 0) await yieldToMain();   // let input/render happen
  }
}
const yieldToMain = () =>
  'scheduler' in window && 'yield' in scheduler
    ? scheduler.yield()                        // modern API
    : new Promise(r => setTimeout(r));         // fallback
```

### Schedule by Priority
```javascript
requestIdleCallback(cb)      // run during idle time (non-urgent)
requestAnimationFrame(cb)    // run right before next paint (visual updates)
scheduler.postTask(cb, { priority: 'background' }) // explicit priorities
// React: startTransition(() => setState(...))  // mark non-urgent updates
```

---

## 2. Web Workers (Off the Main Thread)

Move heavy computation off the main thread entirely.

```
Main thread (UI)  ⇄ postMessage ⇄  Worker thread (heavy compute)
  → UI stays responsive while the worker crunches
```
```javascript
// main.js
const worker = new Worker('/worker.js');
worker.postMessage({ data });
worker.onmessage = (e) => render(e.data);   // result, UI never blocked

// worker.js
onmessage = (e) => {
  const result = expensiveComputation(e.data);  // off main thread
  postMessage(result);
};
```
**Use for:** parsing/transforming large data, image/video processing, crypto, search indexing, anything CPU-heavy. (Partytown runs third-party JS in a worker.)

---

## 3. Reflow & Repaint (Recap + Runtime Focus)

```
Reflow (layout): recompute geometry — EXPENSIVE, can cascade
Repaint:         redraw pixels — less expensive than reflow
Composite:       GPU layer combine — cheapest (transform/opacity)
```

### Animate Cheap Properties Only
```css
/* ✅ Compositor-only: 60fps, off main thread */
.x { transform: translateX(100px); opacity: .5; transition: transform .3s; }

/* ❌ Triggers layout + paint every frame → jank */
.x { left: 100px; width: 200px; }
```

### Avoid Layout Thrashing
```javascript
// ❌ Read→write→read→write forces sync reflow each iteration
els.forEach(el => { el.style.height = el.offsetHeight + 10 + 'px'; });

// ✅ Batch: read all, then write all
const hs = els.map(el => el.offsetHeight);
els.forEach((el, i) => el.style.height = hs[i] + 10 + 'px');
```

### Isolate with CSS containment
```css
/* Tell the browser this subtree's layout/paint is independent */
.card { contain: content; }          /* limits reflow/repaint scope */
.offscreen { content-visibility: auto; }  /* skip rendering offscreen content */
```
> `content-visibility: auto` can dramatically cut rendering work for long pages by skipping offscreen subtrees until needed.

---

## 4. List Virtualization (Render Only What's Visible)

Rendering thousands of DOM nodes destroys performance (memory, layout, scroll jank).

```
❌ 10,000 rows → 10,000 DOM nodes → slow layout, huge memory
✅ Virtualize → render ~20 visible rows + recycle on scroll
```
```
- React: react-window, react-virtuoso, TanStack Virtual
- Angular: CDK Virtual Scroll (<cdk-virtual-scroll-viewport>)
```
```html
<!-- Angular CDK virtual scroll: only visible items in the DOM -->
<cdk-virtual-scroll-viewport itemSize="50" class="viewport">
  <div *cdkVirtualFor="let item of items">{{ item.name }}</div>
</cdk-virtual-scroll-viewport>
```

> **Rule:** any list that can grow unbounded (feeds, tables, search results) must be virtualized.

---

## 5. Debounce & Throttle (Limit Work Frequency)

```
Debounce: run AFTER activity stops (e.g., search input → wait 300ms)
Throttle: run at most every N ms (e.g., scroll/resize → every 100ms)
```
```javascript
const debounce = (fn, ms) => { let t; return (...a) => {
  clearTimeout(t); t = setTimeout(() => fn(...a), ms); }; };

const throttle = (fn, ms) => { let last = 0; return (...a) => {
  const now = Date.now(); if (now - last >= ms) { last = now; fn(...a); } }; };

searchInput.addEventListener('input', debounce(onSearch, 300));
window.addEventListener('scroll', throttle(onScroll, 100));
```

### Prefer Passive Listeners & IntersectionObserver
```javascript
// Passive: tells browser you won't preventDefault → smoother scroll
window.addEventListener('scroll', onScroll, { passive: true });

// IntersectionObserver instead of scroll math (lazy-load, infinite scroll)
const io = new IntersectionObserver(entries => {/* ... */});
io.observe(sentinel);
```

---

## 6. Memory Management & Leaks

Leaks cause growing memory → GC pauses → jank → crashes (especially long-lived SPAs).

### Common Leak Sources
```
- Event listeners not removed on teardown
- Timers/intervals not cleared
- RxJS subscriptions not unsubscribed (Angular!)
- Detached DOM nodes still referenced
- Closures capturing large objects
- Global caches that grow unbounded
```

### Fixes
```typescript
// Angular: unsubscribe (takeUntilDestroyed / async pipe / ngOnDestroy)
private destroy$ = new Subject<void>();
this.data$.pipe(takeUntil(this.destroy$)).subscribe(...);
ngOnDestroy() { this.destroy$.next(); this.destroy$.complete(); }
```
```javascript
// Always clean up
const id = setInterval(tick, 1000);
// ...later
clearInterval(id);
element.removeEventListener('click', handler);
```
- **Detect:** DevTools Memory panel → heap snapshots, allocation timeline; watch for detached nodes and growing heap across interactions.

---

## 7. Rendering Optimization (Framework-Agnostic)

```
- Minimize DOM size/depth (faster style/layout)
- Avoid forced synchronous layout in hot paths
- Batch DOM updates (DocumentFragment, framework batching)
- Use CSS containment + content-visibility for large pages
- Keep animations on transform/opacity
- Don't run expensive work in scroll/resize/mousemove handlers
```
(Framework-specific change detection in [framework-performance.md](./framework-performance.md).)

---

## Mapping Runtime Problems → Levers

```
Poor INP / unresponsive   → break long tasks, yield, web workers
Janky animation           → transform/opacity only, avoid layout props
Layout thrashing          → batch reads then writes
Slow long list/scroll     → virtualization (CDK/react-window)
Expensive input handlers  → debounce/throttle, passive listeners
Slow offscreen content    → content-visibility: auto, contain
Growing memory/crashes    → fix leaks (unsubscribe, clear timers/listeners)
Heavy computation         → move to a web worker
```

---

## Mental Models

### Every Frame = A 16ms Deadline
Runtime performance is hitting a deadline 60 times a second. Any work that overruns the budget drops a frame, and dropped frames are the stutter users feel. Keep per-frame work tiny.

### The Main Thread = A Single Lane Road
JS, layout, paint, and input all drive on one lane. A broken-down truck (long task) blocks everyone behind it. Either keep vehicles small (chunk work) or build a second road (worker).

### Virtualization = A Window, Not a Wall
You don't build a 10,000-brick wall to show what fits in one window. Render only what's in view and recycle nodes as the user scrolls — constant cost regardless of list size.

### Memory Leaks = A Slow Drip
Each un-cleaned listener or subscription is a drip. One is harmless; thousands over a long session flood the boat (heap), forcing bailing (GC pauses) and eventually sinking (crash). Always close the tap on teardown.

---

## Common Mistakes

### Mistake 1: Long Tasks Blocking Input
❌ Big synchronous loops → frozen UI, poor INP
✅ Chunk and yield (`scheduler.yield`); offload to workers

### Mistake 2: Animating Layout Properties
❌ Animating `left/top/width/height` → reflow per frame
✅ Animate `transform`/`opacity` (compositor only)

### Mistake 3: Rendering Huge Lists
❌ Thousands of DOM nodes → memory + scroll jank
✅ Virtualize (CDK Virtual Scroll, react-window)

### Mistake 4: Heavy Work in Scroll/Resize Handlers
❌ Layout reads + expensive work on every event
✅ Throttle/debounce, passive listeners, IntersectionObserver

### Mistake 5: Layout Thrashing
❌ Interleaved read/write of layout in loops
✅ Batch reads then writes; rAF for visual updates

### Mistake 6: Memory Leaks in SPAs
❌ Unremoved listeners, uncleared timers, un-unsubscribed observables
✅ Clean up on teardown (takeUntilDestroyed, clearInterval, removeEventListener)

### Mistake 7: CPU-Heavy Work on Main Thread
❌ Parsing/processing big data on the UI thread
✅ Web workers for heavy computation

---

## Interview Questions

### Q1: What causes poor INP and how do you fix it at runtime?
**Answer:** Poor INP comes from main-thread congestion: long tasks (over 50ms) that block the thread so it can't process input and paint the response, expensive event handlers doing too much synchronously, excessive framework re-renders, and a large or complex DOM that makes style and layout slow. At runtime I fix it by breaking long tasks into smaller chunks that yield to the event loop (`scheduler.yield` or a setTimeout fallback) so input can be handled between chunks, moving heavy computation off the main thread into web workers, debouncing or throttling expensive handlers, deferring non-urgent updates (`requestIdleCallback`, React `startTransition`), and giving immediate visual feedback before doing work so the interaction feels instant. I also reduce DOM complexity and unnecessary re-renders. The core principle is keeping the main thread free to respond.

### Q2: How do you achieve smooth 60fps animations?
**Answer:** The frame budget at 60fps is about 16ms, so all work for a frame must fit within it. The key is animating only compositor-friendly properties — `transform` and `opacity` — which the browser can handle on the GPU compositor, off the main thread, without triggering layout or paint each frame. Animating layout-affecting properties like `left`, `top`, `width`, or `margin` forces reflow and repaint every frame and causes jank. I use `will-change` sparingly to hint layer promotion for elements about to animate, drive animations with CSS transitions/animations or the Web Animations API rather than per-frame JS where possible, and keep any JS in `requestAnimationFrame` callbacks tiny. I also avoid layout thrashing and offload heavy work so the main thread isn't busy during the animation.

### Q3: What is layout thrashing and how do you prevent it?
**Answer:** Layout thrashing is forcing repeated synchronous reflows by interleaving reads of layout properties (like `offsetHeight`, `getBoundingClientRect`, `scrollTop`) with writes that invalidate layout, usually in a loop. Each read after a write makes the browser recompute layout immediately, turning one reflow into many and tanking performance. I prevent it by batching: perform all layout reads first, then all writes, so the browser reflows once. I schedule DOM writes in `requestAnimationFrame`, use patterns or libraries like FastDOM that enforce read/write separation, and cache layout values instead of re-reading them in a loop. The principle is never to make the browser recompute layout in the middle of a mutation sequence.

### Q4: How do you render a list of 10,000 items performantly?
**Answer:** I virtualize it — render only the items currently visible in the viewport plus a small buffer, and recycle DOM nodes as the user scrolls, so the DOM holds maybe twenty nodes instead of ten thousand. This keeps memory, layout, and scroll cost roughly constant regardless of list size. In Angular I'd use the CDK Virtual Scroll (`cdk-virtual-scroll-viewport` with `*cdkVirtualFor`); in React, react-window, TanStack Virtual, or react-virtuoso. I pair it with stable keys/trackBy to avoid unnecessary re-renders, fixed or measured item sizes for accurate scrolling, and pagination or infinite scroll via IntersectionObserver to fetch data incrementally. Any list that can grow unbounded — feeds, tables, search results — should be virtualized by default.

### Q5: When and how would you use a web worker?
**Answer:** I use a web worker when there's CPU-heavy work that would otherwise block the main thread and harm responsiveness — parsing or transforming large datasets, image or video processing, encryption, building a client-side search index, or running expensive computations. The worker runs on a separate thread, communicating with the main thread via `postMessage` and `onmessage`, so the UI stays responsive while it crunches. I keep the message payloads efficient (transferables like ArrayBuffers to avoid copying, or libraries like Comlink for ergonomics), and I treat the worker as pure computation since it has no DOM access. A related pattern is Partytown, which runs third-party scripts in a worker to keep them off the main thread. The trade-off is added complexity and serialization cost, so I reserve workers for genuinely heavy work.

### Q6: What causes memory leaks in SPAs and how do you find and fix them?
**Answer:** Long-lived SPAs leak when references outlive their components: event listeners not removed on teardown, timers or intervals not cleared, RxJS subscriptions not unsubscribed (a classic in Angular), detached DOM nodes still referenced, closures capturing large objects, and caches that grow unbounded. Over a long session this grows the heap, causing GC pauses, jank, and eventually crashes. I fix it with disciplined cleanup — in Angular, `takeUntilDestroyed` or the async pipe instead of manual subscriptions, and clearing timers/listeners in `ngOnDestroy`; in general, `removeEventListener` and `clearInterval` on teardown, and bounded caches (LRU). To find leaks I use the DevTools Memory panel: take heap snapshots before and after repeating an interaction and look for steadily growing retained objects and detached DOM nodes, and use the allocation timeline to trace what's accumulating.

---

## Key Takeaways

- **Runtime performance = smoothness** (INP, 60fps), distinct from loading speed
- **Every frame is a ~16ms deadline** — keep per-frame work tiny
- **Long tasks are the #1 INP killer** — chunk and yield; offload to workers
- **Animate only `transform`/`opacity`**; avoid layout-triggering properties
- **Batch reads then writes** to avoid layout thrashing
- **Virtualize** any unbounded list (CDK Virtual Scroll, react-window)
- **Debounce/throttle** expensive handlers; use passive listeners & IntersectionObserver
- **Prevent memory leaks** — unsubscribe, clear timers/listeners; detect with heap snapshots

---

## What's Next?

You can keep vanilla runtime smooth — now apply it to your framework's specifics:
- **[Framework Performance →](./framework-performance.md)** — Angular (OnPush, signals, zoneless) & React

---

[← JavaScript Performance](./javascript-performance.md) | [Framework Performance →](./framework-performance.md)
