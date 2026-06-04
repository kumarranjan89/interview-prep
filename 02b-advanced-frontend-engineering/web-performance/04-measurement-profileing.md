# Measurement & Profiling

How to measure performance and find the real bottleneck. The discipline that makes optimization data-driven instead of guesswork.

---

## Navigation
[← Core Web Vitals](./core-web-vitals.md) | [Network Optimization →](./network-optimization.md)

---

## The Core Principle: Measure First

```
Without measurement:           With measurement:
  optimize what you THINK        optimize what's ACTUALLY slow
  is slow → often wrong          → targeted, verifiable wins
```

> The most senior performance skill isn't knowing tricks — it's **finding the real bottleneck** with data before touching code.

---

## Lab vs Field (The Two Truths)

```
┌──────────────────────────────┬──────────────────────────────┐
│ LAB (Synthetic)              │ FIELD (Real User Monitoring)  │
├──────────────────────────────┼──────────────────────────────┤
│ Controlled, repeatable test  │ Real users, real conditions   │
│ One device/network profile   │ Full device/network spread    │
│ Great for debugging & CI     │ Ground truth; what Google uses │
│ Lighthouse, WebPageTest,     │ CrUX, web-vitals.js, RUM SaaS │
│ DevTools                     │                               │
│ Can't see real-user variety  │ Can't step-debug a session    │
└──────────────────────────────┴──────────────────────────────┘
```

**You need both.** Field tells you *there's a problem and for whom*; lab lets you *reproduce and fix it*. Optimizing the lab score while field stays poor is the classic trap.

---

## Lab Tools

### 1. Lighthouse
The standard synthetic audit (in Chrome DevTools, CLI, or CI).
```bash
# CLI — scriptable, good for CI
npx lighthouse https://example.com --output=json --output-path=./report.json \
  --throttling-method=simulate --preset=desktop
```
- Scores Performance, plus Accessibility/SEO/Best-Practices.
- Gives **lab** CWV (LCP, CLS, TBT as INP proxy) + opportunities/diagnostics.
- **Caveat:** a single simulated run; vary by run. Use medians, and don't worship the score.

### 2. Chrome DevTools — Performance Panel
The deepest lab tool for *runtime* analysis.
```
Record → interact → stop → analyze:
  - Main thread flame chart (long tasks in red/yellow)
  - Scripting / Rendering / Painting time breakdown
  - Layout shifts, forced reflows, long tasks
  - FPS and interaction latency
```
- **Use for:** diagnosing INP/jank, long tasks, layout thrashing, expensive functions.
- **CPU throttling** (4–6×) + **network throttling** to simulate real devices.

### 3. DevTools — Network Panel
```
- Waterfall: request timing, blocking, dependency chains
- Size (transfer vs uncompressed), cache hits
- Find: waterfalls, render-blocking resources, oversized assets, slow TTFB
```

### 4. DevTools — Coverage & Bundle Tools
```
- Coverage tab: % unused CSS/JS shipped (dead weight)
- source-map-explorer / webpack-bundle-analyzer: what's IN the bundle
```
```bash
# Your repo already supports this:
npm run build:stats     # emits stats.json per project
npm run analyze:mfe1    # visualize bundle composition
```

### 5. WebPageTest
Advanced synthetic testing from real locations/devices.
```
- Real devices & networks, multiple locations
- Filmstrip + video of load, Speed Index
- Connection view, request blocking, A/B compare
- "Opportunities" with waterfall correlation
```
- **Use for:** deep, realistic lab analysis beyond Lighthouse; competitor comparison.

---

## Field Tools (RUM)

### CrUX (Chrome User Experience Report)
Real-world CWV data from opted-in Chrome users — what Google uses for ranking.
```
- Free, aggregated p75 field data per origin/URL
- Access via PageSpeed Insights, CrUX API, BigQuery
- Lagging (28-day rolling) — not real-time
```

### web-vitals.js (DIY RUM)
Google's tiny library to capture real CWV from *your* users and send to your analytics.
```javascript
import { onLCP, onINP, onCLS, onTTFB, onFCP } from 'web-vitals';

function send(metric) {
  // beacon to your analytics endpoint
  navigator.sendBeacon('/rum', JSON.stringify({
    name: metric.name, value: metric.value, id: metric.id,
    rating: metric.rating,           // 'good' | 'needs-improvement' | 'poor'
    page: location.pathname,
  }));
}
onLCP(send); onINP(send); onCLS(send); onTTFB(send); onFCP(send);
```
- **Use for:** your own p75 by route/device/geo, real-time, segmentable. The ground truth you control.

### RUM Platforms
SpeedCurve, Sentry Performance, Datadog RUM, New Relic, Vercel Analytics — managed RUM with dashboards, alerting, and per-route/device attribution.

---

## PageSpeed Insights (Lab + Field Together)
```
PSI = Lighthouse (lab) + CrUX (field) in one report
  - Field CWV (if the page has enough CrUX data) at the top
  - Lab Lighthouse run + opportunities below
```
Great first stop: see real-user status *and* diagnostics side by side.

---

## A Methodical Debugging Workflow

```
1. FIELD CHECK   CrUX/RUM: which vital is poor, on which pages/devices?
2. REPRODUCE     PSI/Lighthouse/WebPageTest with realistic throttling
3. ISOLATE       which DIMENSION? loading (LCP) / interactivity (INP) / CLS
4. PROFILE       the right tool:
                   LCP → Network waterfall + Lighthouse opportunities
                   INP → DevTools Performance flame chart (long tasks)
                   CLS → DevTools Performance "Layout Shift" + Experience
5. FIX           apply the targeted lever (network/assets/JS/runtime/framework)
6. VERIFY        re-measure lab; confirm; watch field over following weeks
7. PREVENT       add a CI budget / Lighthouse-CI gate (see governance)
```

> Always throttle CPU (4–6×) and network — an unthrottled desktop hides the problems your users actually hit.

---

## Reading a Flame Chart (INP/Jank)
```
Wide bars  = long-running functions (the expensive ones)
Red corner = "long task" (>50ms) — blocks input
Tall stack = deep call chains
Look for:  forced reflows (purple), recalc style, big scripting blocks
```
- Find the widest bars → that's where your main-thread time goes.
- Long tasks are the #1 INP culprit — break them up or offload to workers.

---

## Reading a Network Waterfall (LCP/Loading)
```
- Long first bar / late first byte → TTFB problem (server/CDN)
- Staircase pattern → request waterfall (dependency chains) → preload/flatten
- Render-blocking resources before first paint → defer/inline
- The LCP resource starting late → preload it, raise fetchpriority
- Big transfer sizes → compress, resize, modern formats
```

---

## Mental Models

### Measurement = A Doctor's Diagnosis
You don't prescribe surgery on a hunch. Field data is the symptom report ("LCP is poor on mobile"), profiling is the scan that locates the cause, and only then do you treat. Treating without diagnosis is malpractice.

### Lab = Microscope, Field = Census
The lab microscope lets you examine one specimen in detail and reproduce findings. The field census tells you what's actually happening across the whole population. You need the microscope to fix and the census to prioritize.

### Throttling = Walking in Users' Shoes
Your dev machine is a sports car. Most users drive economy cars on traffic-filled roads. CPU/network throttling puts you in their seat so you feel what they feel.

### The Flame Chart = A Time Budget Receipt
It itemizes exactly where each millisecond of main-thread time was spent. The widest line items are where the money (time) went — start cutting there.

---

## Common Mistakes

### Mistake 1: Optimizing Without Field Data
❌ Guessing or only running Lighthouse → fixing non-problems
✅ Start from RUM/CrUX: know which vital, which users, which pages

### Mistake 2: Testing Unthrottled
❌ Fast desktop hides real-device pain
✅ CPU 4–6× + network throttling to mimic p75 users

### Mistake 3: Worshipping the Lighthouse Score
❌ Chasing 100 in lab while field CWV is poor
✅ Lab to diagnose; field to judge; optimize the real users

### Mistake 4: One Lighthouse Run as Truth
❌ Single run varies run-to-run
✅ Take medians of multiple runs; use CI trends

### Mistake 5: No Continuous Monitoring
❌ One-time audit → silent regression later
✅ Ongoing RUM + CI budgets (catch regressions early)

### Mistake 6: Profiling the Wrong Dimension
❌ Staring at the network panel for an INP problem
✅ Match tool to dimension: waterfall for LCP, flame chart for INP

---

## Interview Questions

### Q1: How do you approach diagnosing a performance problem?
**Answer:** I work from data, not hunches, following a measure → isolate → optimize → verify loop. I start in the field with CrUX or our RUM to learn which vital is failing, for which pages, devices, and geographies — that tells me the dimension (loading, interactivity, or stability) and who's affected. Then I reproduce it in a lab tool (PageSpeed Insights, Lighthouse, or WebPageTest) with realistic CPU and network throttling. I profile with the right tool for the dimension: a network waterfall for LCP, the DevTools Performance flame chart for INP and long tasks, and the layout-shift view for CLS. I apply a targeted fix, re-measure in lab to confirm, watch field data over the following weeks to validate on real users, and add a CI budget so the regression can't return.

### Q2: What's the difference between lab and field data, and which tools give each?
**Answer:** Lab (synthetic) data comes from a controlled, repeatable test on a single device/network profile — great for debugging and CI gating but not representative of all users. Tools include Lighthouse, Chrome DevTools, and WebPageTest. Field data (Real User Monitoring) comes from actual users across the full spread of devices and networks — it's the ground truth and what Google ranks on, but you can't step-debug a session. Sources include CrUX (Google's aggregated field data), the web-vitals.js library for your own RUM, and platforms like SpeedCurve or Sentry. PageSpeed Insights conveniently shows both. The key is using field data to know there's a real problem and for whom, and lab tools to reproduce and fix it.

### Q3: How would you set up RUM for Core Web Vitals?
**Answer:** I'd use Google's web-vitals.js library to capture LCP, INP, CLS, plus TTFB and FCP from real users, and beacon them to an analytics endpoint with `navigator.sendBeacon` so reporting doesn't block the page. I'd attach useful dimensions — route/path, device type, connection, country, and app version — so I can segment p75 by those and find which cohorts hurt. On the backend I'd aggregate to p75/p95 per route and build dashboards with alerting on threshold breaches and regressions tied to deploys. For zero-instrumentation baseline I'd also pull CrUX. A managed platform (SpeedCurve, Sentry, Datadog) can replace the DIY pipeline. The goal is continuous, segmentable, real-time truth that drives prioritization and catches regressions.

### Q4: How do you read a flame chart to fix an interactivity problem?
**Answer:** I record the interaction in the DevTools Performance panel with CPU throttling, then look at the main-thread track. Wide bars are long-running functions — the expensive work — and tasks flagged as "long tasks" (over 50ms, marked red) are what block input and drive poor INP. Deep stacks show the call chains, and I watch for forced synchronous reflows and style recalculation. I identify the widest/most frequent bars, trace them to the responsible code, and then reduce that work: break long tasks into chunks that yield to the event loop, move heavy computation to a web worker, memoize or cut unnecessary framework re-renders, and ensure the handler gives immediate visual feedback before doing non-urgent work. Then I re-record to confirm the long tasks are gone.

### Q5: Why shouldn't you trust a single Lighthouse score?
**Answer:** A Lighthouse run is a single synthetic measurement that varies run-to-run due to simulated throttling, CPU contention, network variance, and third-party noise, so one number can mislead. It also reflects one device/network profile that may not match your real users, which is why a perfect lab score can coexist with poor field Core Web Vitals. I treat Lighthouse as a diagnostic and regression tool: take the median of multiple runs, use it in CI to catch trends rather than chase an absolute 100, and always validate against field/RUM data, which is the ground truth for actual users and for Google's ranking. Lab guides the fix; field judges success.

### Q6: How do you find what's bloating your JavaScript bundle?
**Answer:** I analyze the bundle composition with a visualizer like webpack-bundle-analyzer or source-map-explorer — in this project that's `npm run build:stats` to emit stats.json followed by `npm run analyze:mfe1` — which shows a treemap of what each module contributes. I look for oversized or duplicated dependencies, libraries imported in full when only a part is needed (missing tree-shaking or deep imports), moment/lodash-style heavyweights, and polyfills shipped to modern browsers. I cross-check with the DevTools Coverage tab to see how much shipped JS/CSS is actually unused. From there I code-split by route, switch to lighter or tree-shakeable alternatives, lazy-load non-critical chunks, and dedupe shared dependencies. Then I re-run the analyzer and check the bundle against a CI size budget.

---

## Key Takeaways

- **Measure before optimizing** — find the real bottleneck with data
- **Need both lab and field** — lab to reproduce/fix, field for truth and priority
- **Lab tools:** Lighthouse, DevTools (Performance/Network/Coverage), WebPageTest
- **Field tools:** CrUX, web-vitals.js (DIY RUM), RUM platforms; PSI shows both
- **Always throttle** CPU and network to mimic p75 users
- **Match tool to dimension:** waterfall for LCP, flame chart for INP, shift view for CLS
- **Use your bundle analyzer** (`build:stats` → `analyze:mfe1`) to find JS bloat
- **Monitor continuously** — RUM + CI budgets catch regressions early

---

## What's Next?

You can measure and locate bottlenecks. Now start optimizing — in page-load order, beginning with the network:
- **[Network Optimization →](./network-optimization.md)** — caching, CDN, compression, HTTP/2-3, hints

---

[← Core Web Vitals](./core-web-vitals.md) | [Network Optimization →](./network-optimization.md)
