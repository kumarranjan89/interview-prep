# The Critical Rendering Path & Browser Internals

How the browser turns bytes into pixels — and where the time goes. This is the mechanism behind every loading optimization.

---

## Navigation
[← Concepts](./concepts.md) | [Core Web Vitals →](./core-web-vitals.md)

---

## Why This Matters

Every loading optimization (preload, code-split, critical CSS, defer) is just **manipulating the critical rendering path**. If you understand the pipeline, you can reason about *any* optimization from first principles instead of memorizing tips.

---

## The Big Picture: URL → Pixels

```
1. NAVIGATION    DNS → TCP → TLS → HTTP request
        ↓
2. RESPONSE      server/CDN returns HTML (TTFB measured here)
        ↓
3. PARSE HTML    build the DOM (incrementally, as bytes arrive)
        ↓
4. PARSE CSS     build the CSSOM (render-blocking)
        ↓
5. JAVASCRIPT    download/parse/compile/execute (can block parsing)
        ↓
6. RENDER TREE   DOM + CSSOM → only visible nodes + styles
        ↓
7. LAYOUT        compute geometry (position & size) — "reflow"
        ↓
8. PAINT         fill pixels (text, colors, images) — "repaint"
        ↓
9. COMPOSITE     combine layers on the GPU → screen
```

---

## Stage 1–2: Navigation & Response (TTFB)

Before a single byte of HTML, the browser does:
```
DNS lookup → TCP handshake → TLS handshake → HTTP request → server processing → first byte
```
- **TTFB (Time To First Byte)** captures all of this + server time.
- **Levers:** CDN (shorten distance), DNS prefetch, `preconnect` (warm up DNS+TCP+TLS early), HTTP/2-3 (multiplexing, faster handshakes), edge caching, faster server/SSR.

```html
<!-- Warm up a critical third-party origin early -->
<link rel="preconnect" href="https://api.example.com" crossorigin />
<link rel="dns-prefetch" href="https://api.example.com" />
```

---

## Stage 3: Building the DOM

The browser parses HTML into the **DOM tree**, incrementally as bytes arrive (it can start before the full document downloads).

```
<html><body><h1>Hi</h1><p>Text</p></body></html>
        ↓ parsed into
Document → html → body → [h1 → "Hi", p → "Text"]
```

- HTML parsing is **streamed** and fast — but it can be **interrupted by synchronous scripts** (see Stage 5).
- Bigger/deeper DOM → more memory and slower style/layout. **Keep the DOM small and shallow.**

---

## Stage 4: Building the CSSOM (Render-Blocking)

CSS is parsed into the **CSSOM**. Critically:

```
CSS is RENDER-BLOCKING:
  The browser will NOT paint until the CSSOM is ready
  (to avoid a flash of unstyled content / wrong styles).
```

- All CSS in `<head>` blocks first render. **Minimize and inline critical CSS; defer the rest.**
- **Levers:** critical CSS inlined, non-critical CSS loaded async, remove unused CSS, avoid huge stylesheets and `@import` chains.

```html
<!-- Inline critical CSS; load the rest non-blocking -->
<style>/* above-the-fold critical CSS here */</style>
<link rel="preload" href="/full.css" as="style" onload="this.rel='stylesheet'" />
```

---

## Stage 5: JavaScript — The Parser Blocker

This is where most loading problems live.

```
A plain <script> is PARSER-BLOCKING:
  HTML parsing STOPS → script downloads → executes → parsing resumes.
  Worse: scripts wait for in-progress CSSOM (JS may read styles).
```

### `async` vs `defer` (must-know)
```
<script>          parse HTML ──■ download+exec script ──► resume   (blocks)
<script async>    parse HTML ───────────► (exec ASAP, unordered, can interrupt)
<script defer>    parse HTML ───────────► exec after DOM, IN ORDER  (best default)
```

| Attribute | Downloads | Executes | Order | Use for |
|-----------|-----------|----------|-------|---------|
| (none) | blocks parser | immediately | — | avoid in `<head>` |
| `async` | parallel | ASAP, may interrupt | not guaranteed | independent scripts (analytics) |
| `defer` | parallel | after parse | preserved | **app scripts (default choice)** |
| `type=module` | parallel | deferred by default | preserved | modern bundles |

> **Rule of thumb:** non-critical scripts should be `defer` (or `async` if truly independent). Never put render-critical synchronous scripts in `<head>`.

---

## Stage 6: The Render Tree

```
DOM (all nodes) + CSSOM (all styles) → RENDER TREE (visible nodes only)
```
- Excludes non-visual nodes (`<head>`, `<script>`) and `display:none` elements.
- `visibility:hidden` stays in the tree (occupies space); `display:none` does not.

---

## Stage 7: Layout (Reflow)

The browser computes **geometry** — exact position and size of every render-tree node.

```
"How big is this box, and where does it go?"
→ depends on viewport, box model, flex/grid, content
```

- Triggered by: initial render, DOM changes, size changes, reading layout properties (`offsetHeight`, `getBoundingClientRect`), window resize.
- **Reflow is expensive** and can cascade (a parent change reflows children).
- **Layout thrashing** = repeatedly reading then writing layout in a loop → many forced synchronous reflows. (Deep dive in [runtime-rendering.md](./runtime-rendering.md).)

```javascript
// ❌ Layout thrash: read → write → read → write (forces reflow each loop)
for (const el of items) { el.style.width = el.offsetWidth + 10 + 'px'; }

// ✅ Batch reads, then writes
const widths = items.map(el => el.offsetWidth);   // read phase
items.forEach((el, i) => el.style.width = widths[i] + 10 + 'px'); // write phase
```

---

## Stage 8–9: Paint & Composite

```
PAINT:     fill pixels — text, colors, borders, shadows, images
COMPOSITE: combine painted layers on the GPU and draw to screen
```

- Some changes only need **compositing** (cheap, GPU): `transform` and `opacity`.
- Other changes force **layout + paint** (expensive): `width`, `top`, `left`, `margin`.

```
✅ Animate with transform/opacity → compositor only (60fps, off main thread)
❌ Animate with top/left/width   → reflow + repaint every frame (janky)
```

```css
/* Smooth: GPU-composited */
.move { transform: translateX(100px); transition: transform .3s; }
/* hint the browser to promote to its own layer when beneficial */
.will-animate { will-change: transform; }
```

---

## The Event Loop (Why the Main Thread Matters)

JavaScript, layout, paint, and user input **all share one main thread.** Long JS tasks block everything.

```
Call stack runs JS → empties → microtasks (Promises) → render (if needed) → next task
                                                          ↑
            A "long task" (>50ms) here blocks input handling → poor INP
```

- **Long tasks** (>50ms) delay input response → bad **INP**/responsiveness.
- **Levers:** break up long tasks (chunking, `scheduler.yield`), move heavy work to **web workers**, debounce/throttle, avoid synchronous reflows.

```javascript
// Yield to the browser so input can be handled between chunks
async function processBig(items) {
  for (let i = 0; i < items.length; i++) {
    doWork(items[i]);
    if (i % 50 === 0) await new Promise(r => setTimeout(r)); // yield
  }
}
```

---

## Request Waterfalls (The Hidden Latency Killer)

A **dependency chain** of requests serializes latency:
```
❌ HTML → JS → (JS fetches) config → (then) data → render
   each arrow = a full round trip (waterfall)

✅ Preload/parallelize: start critical fetches early, flatten the chain
```
- **Levers:** `preload` critical resources, inline critical data, avoid client-side fetch chains, use SSR/streaming to send data with HTML, HTTP/2 multiplexing.

```html
<!-- Start fetching a critical resource immediately, in parallel -->
<link rel="preload" href="/app.js" as="script" />
<link rel="preload" href="/hero.webp" as="image" fetchpriority="high" />
```

---

## Resource Hints (The Toolkit)

| Hint | What it does | Use for |
|------|--------------|---------|
| `dns-prefetch` | resolve DNS early | cross-origin domains you'll use |
| `preconnect` | DNS + TCP + TLS early | critical third-party origins |
| `preload` | fetch a resource now, high priority | critical late-discovered resources |
| `prefetch` | fetch for a *future* navigation, low priority | next likely page |
| `fetchpriority` | bump/lower a resource's priority | LCP image high, below-fold low |
| `modulepreload` | preload ES modules | module bundles |

> Use deliberately — over-preloading contends for bandwidth and can *hurt*.

---

## Mapping Stages → Optimizations (The Payoff)

```
TTFB slow?        → CDN, preconnect, HTTP/2-3, faster server/SSR, edge cache
First paint slow? → inline critical CSS, defer non-critical CSS/JS
Parser blocked?   → defer/async scripts, remove sync scripts from <head>
LCP slow?         → preload LCP image (fetchpriority=high), prioritize hero
Waterfalls?       → preload, flatten fetch chains, SSR/stream data
Jank/low FPS?     → animate transform/opacity, avoid layout thrash
Poor INP?         → break long tasks, web workers, debounce
```

---

## Mental Models

### The Rendering Pipeline = An Assembly Line
Bytes enter, pixels exit. A jam at any station (render-blocking CSS, a parser-blocking script, a long task) stalls everything downstream. Optimization = keeping every station fed and unblocked.

### CSS = Render-Blocking Gatekeeper
The browser refuses to paint until it knows the styles, to avoid showing the wrong thing. So critical CSS must be tiny and immediate; everything else waits outside the gate.

### The Main Thread = A Single Cashier
One cashier handles JS, layout, paint, *and* customer questions (input). A customer with a huge order (long task) makes everyone behind them wait. Keep orders small or open another lane (worker).

### transform/opacity = The Express Lane
These changes skip layout and paint and go straight to the GPU compositor. Animating anything else makes the browser redo expensive earlier stations every frame.

---

## Common Mistakes

### Mistake 1: Render-Blocking Scripts in `<head>`
❌ Synchronous `<script>` stalls HTML parsing and first paint
✅ `defer` (default) or `async` for independent scripts

### Mistake 2: Shipping All CSS as Render-Blocking
❌ One huge blocking stylesheet delays first paint
✅ Inline critical CSS; load the rest async; purge unused

### Mistake 3: Animating Layout Properties
❌ Animating `top/left/width` → reflow+repaint per frame → jank
✅ Animate `transform`/`opacity` (compositor only)

### Mistake 4: Layout Thrashing
❌ Interleaved reads/writes of layout in loops → forced reflows
✅ Batch reads then writes; use `requestAnimationFrame`

### Mistake 5: Request Waterfalls
❌ HTML→JS→fetch→fetch chains serialize latency
✅ Preload critical resources; flatten chains; SSR/stream data

### Mistake 6: Long Tasks on the Main Thread
❌ One big JS task blocks input → poor INP
✅ Chunk work, yield, or offload to web workers

---

## Interview Questions

### Q1: Walk me through what happens from entering a URL to seeing the page.
**Answer:** First the navigation phase: DNS resolution, TCP handshake, TLS negotiation, then the HTTP request — all captured by TTFB along with server processing. The server/CDN returns HTML, which the browser parses incrementally into the DOM. CSS is parsed into the CSSOM and is render-blocking, so the browser won't paint until it's ready. JavaScript can block parsing if synchronous. The browser combines DOM and CSSOM into the render tree (visible nodes only), runs layout to compute geometry (reflow), paints pixels, and composites layers on the GPU to the screen. Then the framework bootstraps, hydrates if SSR, fetches data, and becomes interactive. At each stage there's a lever — CDN/preconnect for TTFB, critical CSS and script deferral for first paint, preload for LCP, and keeping the main thread free for interactivity.

### Q2: Explain `async` vs `defer` and when you'd use each.
**Answer:** Both download the script in parallel without blocking HTML parsing; the difference is execution. `async` executes as soon as it's downloaded, can interrupt parsing, and runs in no guaranteed order — good for independent scripts like analytics that don't depend on the DOM or other scripts. `defer` waits until HTML parsing is complete and executes in document order — ideal for application scripts that need the DOM or have dependencies, which makes it the sensible default. A plain synchronous script blocks the parser entirely and should never sit in the `<head>` for render-critical paths. So: `defer` for app code, `async` for truly independent third-party scripts.

### Q3: Why is CSS render-blocking, and how do you mitigate it?
**Answer:** CSS is render-blocking because the browser won't paint until it has the complete CSSOM — otherwise it would risk showing unstyled or wrongly-styled content (FOUC) and then repainting. So all CSS referenced in the head delays first paint. I mitigate it by inlining the critical, above-the-fold CSS directly in the document so first paint doesn't wait on a network round trip, and loading the rest non-blocking (e.g., preloading and swapping to a stylesheet on load, or media-conditional loading). I also remove unused CSS, avoid `@import` chains that serialize requests, and keep stylesheets lean. The goal is a tiny critical CSS payload available immediately, with everything else deferred.

### Q4: What's the difference between layout, paint, and composite — and why does it matter for animations?
**Answer:** Layout (reflow) computes the geometry — position and size — of elements; paint fills in pixels like text, colors, and shadows; composite combines painted layers on the GPU and draws them to the screen. It matters for animation because the cost differs dramatically: animating properties like `width`, `top`, or `margin` forces layout and paint on every frame, which is expensive and causes jank, while animating `transform` and `opacity` can be handled by the compositor alone on the GPU, off the main thread, achieving smooth 60fps. So for performant animations I stick to transform and opacity, and use `will-change` sparingly to hint layer promotion. Understanding the pipeline tells you which properties are cheap to animate.

### Q5: What is layout thrashing and how do you avoid it?
**Answer:** Layout thrashing is when code repeatedly forces synchronous reflows by interleaving reads of layout properties (like `offsetHeight` or `getBoundingClientRect`) with writes that invalidate layout, typically inside a loop. Each read after a write forces the browser to recompute layout immediately, turning what could be one reflow into many, which tanks performance. I avoid it by batching: do all the layout *reads* first, then all the *writes*, so the browser reflows once. Tools like `requestAnimationFrame` to schedule writes, or libraries like FastDOM, help enforce the read/write separation. The principle is to never make the browser recompute layout in the middle of a mutation loop.

### Q6: How does the event loop relate to performance and INP?
**Answer:** JavaScript execution, layout, paint, and user-input handling all share a single main thread coordinated by the event loop, which runs a task, drains microtasks, optionally renders, then moves to the next task. If a task runs long (over 50ms, a "long task"), it blocks the thread so the browser can't respond to taps or clicks until it finishes — which directly worsens INP (Interaction to Next Paint) and makes the UI feel frozen. To keep interactions snappy I break long tasks into smaller chunks that yield to the event loop (e.g., `await` a macrotask, `scheduler.yield`, or `requestIdleCallback`), move heavy computation to web workers off the main thread, and debounce/throttle expensive handlers. Keeping the main thread free is the core of good responsiveness.

---

## Key Takeaways

- **The critical rendering path is the mechanism** behind every loading optimization
- **TTFB** covers DNS/TCP/TLS/request/server — fix with CDN, preconnect, HTTP/2-3, SSR
- **CSS is render-blocking** — inline critical CSS, defer the rest
- **Sync scripts block the parser** — `defer` app code, `async` independent scripts
- **Layout (reflow) and paint are expensive** — animate `transform`/`opacity` only
- **Avoid layout thrashing** — batch reads then writes
- **One main thread** runs JS + layout + paint + input — long tasks hurt INP
- **Flatten request waterfalls** — preload critical resources, SSR/stream data

---

## What's Next?

You understand the pipeline. Now learn **what to measure** so you know which stage is slow:
- **[Core Web Vitals →](./core-web-vitals.md)** — LCP, INP, CLS and what drives them

---

[← Concepts](./concepts.md) | [Core Web Vitals →](./core-web-vitals.md)
