# Core Web Vitals & Performance Metrics

What to measure and what drives each metric. The vocabulary of performance — and Google's ranking signals.

---

## Navigation
[← Rendering Path](./rendering-path.md) | [Measurement & Profiling →](./measurement-profiling.md)

---

## Why Metrics Matter

You can't optimize or communicate performance without a shared, user-centric vocabulary. Metrics turn "feels slow" into a measurable, comparable, rankable number.

```
Old metrics (machine-centric):  onload, DOMContentLoaded
   → didn't reflect what USERS experience

Modern metrics (user-centric):  when did content APPEAR? when could I INTERACT?
   → Core Web Vitals measure real user experience
```

> **Architect note:** Core Web Vitals are a **Google ranking signal** and the industry-standard target. They map exactly to the three performance dimensions: loading, interactivity, visual stability.

---

## The Three Core Web Vitals

```
┌──────────────────────────────────────────────────────────────┐
│ LCP  Largest Contentful Paint  → LOADING                      │
│      "When did the main content appear?"     Good: ≤ 2.5s     │
│                                                                │
│ INP  Interaction to Next Paint → INTERACTIVITY                │
│      "How fast does the UI respond to input?" Good: ≤ 200ms   │
│                                                                │
│ CLS  Cumulative Layout Shift   → VISUAL STABILITY             │
│      "Does content jump around?"             Good: ≤ 0.1      │
└──────────────────────────────────────────────────────────────┘
```

All three are measured at **p75** (75th percentile) of real users — so good scores must hold for the slower three-quarters of visits, not the average.

---

## LCP — Largest Contentful Paint (Loading)

**What:** Time until the **largest visible element** in the viewport is rendered — usually a hero image, a video poster, or a large text block.

```
Good          Needs improvement      Poor
≤ 2.5s        2.5s – 4.0s            > 4.0s
```

### What Drives LCP
1. **Slow TTFB** — server/CDN latency delays everything.
2. **Render-blocking CSS/JS** — delays first paint.
3. **Slow resource load** — the LCP image itself loads late/large.
4. **Client-side rendering delay** — JS must run before content appears.

### How to Improve LCP
```
- Fast TTFB: CDN, edge cache, SSR/streaming, preconnect
- Preload the LCP image with fetchpriority="high"
- Optimize the LCP image: modern format (WebP/AVIF), right size, responsive
- Inline critical CSS; defer non-critical CSS/JS
- Avoid lazy-loading the LCP image (don't defer what's above the fold)
- Prefer SSR/SSG for content-heavy pages
```

```html
<!-- Prioritize the hero/LCP image -->
<link rel="preload" as="image" href="/hero.avif" fetchpriority="high" />
<img src="/hero.avif" fetchpriority="high" alt="..." width="1200" height="600" />
```

> **Common trap:** lazy-loading the hero image. Lazy-load below-the-fold images only; the LCP element should load eagerly with high priority.

---

## INP — Interaction to Next Paint (Interactivity)

**What:** Measures **responsiveness** across the whole page lifecycle — the latency from a user interaction (click, tap, key) to the **next frame painted**, reported near the worst interaction. Replaced **FID** in March 2024.

```
Good          Needs improvement      Poor
≤ 200ms       200ms – 500ms          > 500ms
```

### INP = the full interaction latency
```
Input delay      →  Processing time     →  Presentation delay
(main thread      (your event handler     (style/layout/paint
 busy?)            running)                to next frame)
```

### What Drives Poor INP
1. **Long tasks** blocking the main thread (heavy JS).
2. **Expensive event handlers** doing too much synchronously.
3. **Large/complex DOM** making style/layout slow.
4. **Excessive re-renders** in frameworks.

### How to Improve INP
```
- Break up long tasks; yield to the main thread (scheduler.yield)
- Move heavy work to web workers (off main thread)
- Debounce/throttle expensive handlers
- Defer non-urgent work (requestIdleCallback, startTransition in React)
- Reduce DOM size/complexity; virtualize long lists
- Optimize framework re-renders (OnPush/memo)
- Show immediate visual feedback, then do work
```

```javascript
// Respond immediately, defer the heavy work so the frame can paint
button.addEventListener('click', () => {
  showSpinner();                 // instant feedback (paints next frame)
  requestIdleCallback(() => doExpensiveWork());  // non-urgent work later
});
```

> INP is often the **hardest** vital for JS-heavy SPAs — it's about main-thread discipline, not just load time.

---

## CLS — Cumulative Layout Shift (Visual Stability)

**What:** Measures **unexpected layout shifts** — content jumping as the page loads. Score = impact fraction × distance fraction, summed over session windows.

```
Good          Needs improvement      Poor
≤ 0.1         0.1 – 0.25             > 0.25
```

### What Causes CLS
1. **Images/videos without dimensions** → content reflows when they load.
2. **Ads/embeds/iframes** without reserved space.
3. **Web fonts** causing FOUT/FOIT and re-layout (size swap).
4. **Dynamically injected content** above existing content.
5. **Animations** that trigger layout instead of transform.

### How to Improve CLS
```
- ALWAYS set width/height (or aspect-ratio) on images/video
- Reserve space for ads/embeds/dynamic content (min-height)
- Use font-display: optional/swap + size-adjust to minimize font shift
- Insert new content below the fold or without pushing existing content
- Use transform for animations (doesn't affect layout)
- Preload fonts to reduce swap timing
```

```html
<!-- Reserve space so the image can't shift layout -->
<img src="/photo.webp" width="800" height="450" alt="..." />
```
```css
/* Modern: reserve aspect ratio even with fluid width */
img { aspect-ratio: 16 / 9; width: 100%; height: auto; }
```

---

## Supporting (Diagnostic) Metrics

Not "Core" vitals, but essential for diagnosis:

| Metric | Meaning | Good | Diagnoses |
|--------|---------|------|-----------|
| **TTFB** | Time To First Byte | < 800ms | server/CDN/network latency |
| **FCP** | First Contentful Paint (first any content) | < 1.8s | early render blocking |
| **TBT** | Total Blocking Time (lab proxy for INP) | < 200ms | main-thread blocking |
| **FID** | First Input Delay (deprecated, replaced by INP) | < 100ms | legacy interactivity |
| **TTI** | Time To Interactive | — | when page is reliably usable |
| **Speed Index** | how quickly content visually fills | — | perceived load speed |

```
Relationships:
  TTFB ──► FCP ──► LCP        (loading chain)
  TBT (lab)  ≈  INP (field)   (interactivity)
```

> **TBT vs INP:** TBT is the **lab** proxy you optimize in CI; INP is the **field** truth from real users. Improving TBT usually improves INP.

---

## Mapping Metrics → Dimensions → Levers

```
LCP  (loading)        → TTFB, critical CSS, preload LCP image, SSR
INP  (interactivity)  → break long tasks, workers, fewer re-renders
CLS  (visual stab.)   → set dimensions, reserve space, font strategy
TTFB (diagnostic)     → CDN, edge cache, faster server
FCP  (diagnostic)     → unblock first paint (CSS/JS)
```

An architect reads the failing vital, maps it to a dimension, and pulls the corresponding lever — no guessing.

---

## Mental Models

### LCP = "When does the headline appear?"
Users judge load speed by when the *main* thing shows up, not when the page technically finishes. LCP captures that moment — optimize the single largest above-the-fold element.

### INP = "Is the app listening to me?"
Every tap should produce a visible response fast. INP measures whether the main thread is too busy to acknowledge the user. It's a discipline of *not hogging the thread*.

### CLS = "Don't move the button as I click it"
Layout shift is the page pulling the rug out — you go to tap and the content jumps. Reserve space for everything so nothing moves unexpectedly.

### p75 = "Good enough for the slower 3 in 4"
Averages hide pain. Optimizing for p75 means the experience holds up for most real users, including those on weaker devices and networks.

---

## Common Mistakes

### Mistake 1: Lazy-Loading the LCP Image
❌ `loading="lazy"` on the hero → delays LCP
✅ Eager-load + preload + `fetchpriority="high"` for the LCP element

### Mistake 2: Optimizing Averages, Not p75
❌ "Average LCP is 2s" while p75 is 5s
✅ Track and target p75 (and p95) — that's what users feel and Google ranks

### Mistake 3: Images/Embeds Without Dimensions
❌ Missing width/height → CLS as they load
✅ Always set dimensions or `aspect-ratio`; reserve space for embeds

### Mistake 4: Treating FID as Current
❌ Optimizing FID — it's deprecated
✅ INP replaced FID (March 2024); target INP

### Mistake 5: Ignoring INP in SPAs
❌ Great LCP but janky interactions from heavy JS
✅ Main-thread discipline: break tasks, workers, fewer re-renders

### Mistake 6: Only Looking at Lab Scores
❌ Lighthouse 100 but poor field CWV
✅ Use lab (TBT) to diagnose; validate with field (INP) RUM

---

## Interview Questions

### Q1: What are the Core Web Vitals and what does each measure?
**Answer:** There are three, each mapping to a user-experience dimension. LCP (Largest Contentful Paint) measures loading — the time until the largest visible element, usually the hero image or main text, renders; good is ≤2.5s. INP (Interaction to Next Paint) measures interactivity — the latency from a user interaction to the next painted frame across the page lifecycle, reported near the worst interaction; good is ≤200ms. It replaced FID in March 2024. CLS (Cumulative Layout Shift) measures visual stability — how much content unexpectedly shifts as the page loads; good is ≤0.1. All are measured at the p75 of real users, and they're a Google ranking signal, which is why they're the industry-standard targets.

### Q2: What drives a poor LCP and how would you fix it?
**Answer:** LCP is driven by four things: slow TTFB from server/CDN latency, render-blocking CSS or JS delaying first paint, the LCP resource itself loading slowly (large or late-discovered image), and client-side rendering delay where JS must run before content appears. To fix it I'd speed up TTFB with a CDN, edge caching, and SSR/streaming plus preconnect; preload the LCP image with `fetchpriority="high"` and serve it in a modern format at the right responsive size; inline critical CSS and defer the rest; and crucially never lazy-load the hero image, since deferring the LCP element is a common self-inflicted regression. For content-heavy pages I'd prefer SSR/SSG so the main content is in the initial HTML.

### Q3: INP replaced FID — what's the difference and why does it matter?
**Answer:** FID (First Input Delay) only measured the *input delay* of the *first* interaction — essentially how long before the browser could start processing it — so it ignored processing time, presentation delay, and every interaction after the first. It was easy to pass while the app still felt sluggish. INP (Interaction to Next Paint) measures the full latency — input delay plus handler processing plus the time to paint the next frame — across all interactions during the page's life, reporting close to the worst one. This makes it a far more honest measure of responsiveness, especially for JS-heavy SPAs. It matters because passing INP requires real main-thread discipline: breaking up long tasks, offloading to workers, and reducing re-renders, not just getting the first interaction in quickly.

### Q4: What causes layout shift (CLS) and how do you prevent it?
**Answer:** CLS comes from content moving unexpectedly: images, videos, ads, or iframes without reserved dimensions so surrounding content reflows when they load; web fonts swapping and changing text size; dynamically injected content (banners, notifications) pushing existing content down; and animating layout-affecting properties. I prevent it by always setting explicit width/height or `aspect-ratio` on media so space is reserved, giving ads/embeds a reserved min-height, using a font strategy (`font-display` plus `size-adjust`/`preload`) to minimize swap shift, inserting dynamic content without displacing what the user is looking at, and animating with `transform` rather than properties that trigger layout. The principle is to reserve space for everything up front so nothing jumps.

### Q5: Why are Core Web Vitals measured at p75, and why does that matter?
**Answer:** Core Web Vitals use the 75th percentile of real-user data, meaning 75% of visits must meet the threshold. This matters because averages and medians hide the pain of slower sessions — a good average can coexist with a terrible experience for a large minority on weak devices or networks. Targeting p75 (and watching p95) forces you to optimize for the realistic spread of your users, including the low-end devices that dominate globally, rather than your fast dev machine. It aligns engineering effort with how Google evaluates the site and with the experience most users actually get, closing the "works on my machine" empathy gap.

### Q6: What's the difference between TBT and INP, and how do they relate?
**Answer:** TBT (Total Blocking Time) is a lab metric: the total time the main thread was blocked by long tasks (over 50ms) between First Contentful Paint and Time To Interactive, measured in a synthetic tool like Lighthouse. INP is a field metric capturing real users' interaction-to-paint latency. They're correlated because both stem from main-thread congestion — a high TBT in the lab usually predicts poor INP in the field. I use TBT as the controllable proxy I can debug and gate in CI, and INP as the ground truth from RUM. Reducing main-thread work — code-splitting, breaking long tasks, web workers, fewer re-renders — improves both.

---

## Key Takeaways

- **Three Core Web Vitals:** LCP (loading ≤2.5s), INP (interactivity ≤200ms), CLS (stability ≤0.1)
- **Measured at p75** of real users — optimize for the slower majority
- **LCP drivers:** TTFB, render-blocking resources, slow LCP image, CSR delay
- **INP** replaced FID; it's about **main-thread discipline** for the whole lifecycle
- **CLS:** set dimensions, reserve space, manage fonts, animate with transform
- **TTFB/FCP/TBT** are key diagnostics; **TBT (lab) ≈ INP (field)**
- **Never lazy-load the LCP image**; eager-load with high priority
- **Map vital → dimension → lever** to optimize without guessing

---

## What's Next?

You know *what* to measure. Now learn *how* to measure it and find bottlenecks:
- **[Measurement & Profiling →](./measurement-profiling.md)** — Lighthouse, DevTools, WebPageTest, RUM

---

[← Rendering Path](./rendering-path.md) | [Measurement & Profiling →](./measurement-profiling.md)
