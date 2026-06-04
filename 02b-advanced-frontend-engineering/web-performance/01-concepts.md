# Web Performance — Concepts & Mental Model

The *why* and *how to think* before any tool or metric. Tool-agnostic foundation for architect-level performance work.

---

## Navigation
[← Performance README](./README.md) | [Rendering Path →](./rendering-path.md)

---

## Why Performance Matters (The Business Case)

At architect level, performance is justified in **business terms**, not vanity scores.

```
Performance is a feature — and a revenue/retention lever:
  - Conversions:  every 100ms can move conversion measurably
  - Bounce:       slower pages → higher abandonment
  - SEO:          Core Web Vitals are a Google ranking signal
  - Reach:        fast sites work on low-end devices & slow networks
  - Cost:         smaller payloads → lower bandwidth/CDN cost
  - Accessibility: performance IS accessibility on constrained devices
```

> **Architect framing:** "We invest in performance because it directly affects conversion, retention, SEO, and our addressable market — especially on the low-end devices most users actually have."

**The empathy gap:** engineers test on fast laptops and fast networks. Real users are on mid-tier phones, throttled networks, and cold caches. Always design for the **p75 user**, not your dev machine.

---

## Perceived vs Actual Performance

The most important concept in performance UX: **what users *feel* matters as much as what the clock says.**

```
Actual performance:    measurable time (ms) for work to complete
Perceived performance: how fast it FEELS to the user
```

You optimize both — but perception often wins for UX:
- **Show progress early** — skeletons, streaming, optimistic UI beat a blank wait.
- **Prioritize what's visible** — above-the-fold first; defer the rest.
- **Instant feedback** — respond to input <100ms so the UI feels alive.
- **Avoid surprise** — layout shifts and jank feel slower than they are.

> A page that renders meaningful content in 1s but *streams* feels faster than one that blocks for 800ms then dumps everything at once.

---

## The Three Performance Dimensions

Every performance problem falls into one of three buckets. Knowing which one you're in tells you which levers to pull.

```
┌──────────────────────────────────────────────────────────────┐
│ 1. LOADING     How fast does content appear?                  │
│                → network, assets, critical path  (LCP, FCP)    │
│                                                                │
│ 2. INTERACTIVITY How fast does it respond to input?           │
│                → JS execution, main thread, long tasks (INP)   │
│                                                                │
│ 3. VISUAL STABILITY Does content jump around?                 │
│                → layout shifts, reserved space    (CLS)        │
└──────────────────────────────────────────────────────────────┘
```

These map directly to the three Core Web Vitals (next files). An architect diagnoses *which dimension* is failing before optimizing.

---

## The Golden Workflow: Measure → Optimize → Verify

The cardinal rule: **never optimize by guessing.**

```
1. MEASURE   establish a baseline with real data (lab + field/RUM)
2. ISOLATE   find the actual bottleneck (don't assume)
3. OPTIMIZE  apply the targeted fix
4. VERIFY    re-measure; confirm improvement, no regressions
5. PREVENT   add a budget/CI gate so it doesn't come back
```

> Premature optimization wastes effort on non-bottlenecks. Data-driven optimization is the difference between senior and junior performance work.

---

## The Critical Resource Mental Model

A page's speed is gated by its **critical path** — the minimum set of resources required to render meaningful content.

```
Fewer critical resources  +  smaller critical bytes  +  shorter dependency chains
                         = faster first render
```

Three levers, always:
- **Reduce the number** of critical requests (bundle wisely, defer non-critical).
- **Reduce the size** of critical bytes (compression, code-splitting, image formats).
- **Reduce the depth** of dependency chains (preload, avoid request waterfalls).

(Deep mechanics in [rendering-path.md](./rendering-path.md).)

---

## The Cost of JavaScript (The Modern Bottleneck)

On modern apps, **JavaScript is usually the most expensive resource** — not because of download, but because of **parse, compile, and execution** on the main thread.

```
1 MB of JS  ≠  1 MB of image
  Image:  download + decode (often off-main-thread)
  JS:     download + parse + compile + EXECUTE on main thread
          → blocks interactivity, drives INP/TBT
```

> "Byte for byte, JavaScript is the most expensive resource on the web." Treat the **JS budget** as your tightest constraint, especially for interactivity.

---

## Performance Budgets (Concept)

A **performance budget** is a quantified limit treated as a build/CI constraint — performance as a contract, not an aspiration.

```
Examples:
  - JS bundle ≤ 170 KB (compressed) on the critical path
  - LCP ≤ 2.5s at p75 on 4G/mid-tier mobile
  - INP ≤ 200ms at p75
  - CLS ≤ 0.1
```

Budgets convert "make it fast" into enforceable numbers, prevent slow regression, and give teams a shared target. (Operationalized in [budgets-governance.md](./budgets-governance.md).)

---

## Lab vs Field (Two Kinds of Truth)

```
LAB (synthetic):   controlled, repeatable test (Lighthouse, WebPageTest)
                   → great for debugging & CI; NOT real users
FIELD (RUM):       real users, real devices/networks (Core Web Vitals)
                   → ground truth; what Google ranks on
```

You need **both**: lab to diagnose and gate, field to know the truth. Optimizing only the lab score while field metrics stay poor is a classic trap. (Details in [measurement-profiling.md](./measurement-profiling.md).)

---

## Mental Models

### Performance = A Budget You Spend
Every feature, library, image, and font spends from a fixed budget (bytes + main-thread time). Architects allocate that budget deliberately, like a financial plan — not first-come-first-served.

### Perceived Performance = A Good Waiter
A great waiter acknowledges you instantly, brings water, and tells you the kitchen is busy — you wait the same time but feel cared for. Skeletons, streaming, and instant feedback are that waiter.

### The Critical Path = The Shortest Bridge
Only the planks needed to cross *now* matter for first render. Everything else can be built after the user is already walking. Minimize, shrink, and shorten the critical bridge.

### JavaScript = Carry-On, Not Checked Luggage
Every KB of JS is carried by the main thread through parse/compile/execute. Unlike images (checked luggage, processed elsewhere), JS slows the passenger directly. Pack light.

---

## Common Mistakes (Architectural)

### Mistake 1: Optimizing Without Measuring
❌ Guessing at bottlenecks → wasted effort
✅ Measure → isolate → optimize → verify

### Mistake 2: Testing Only on Dev Hardware
❌ Fast laptop + fast network hides real UX
✅ Test throttled mid-tier mobile; design for p75 users

### Mistake 3: Chasing the Lighthouse Score Only
❌ Lab score 100 while field LCP is poor
✅ Optimize field/RUM data; use lab to diagnose

### Mistake 4: Treating Performance as a Phase
❌ "We'll optimize before launch"
✅ Performance is a design constraint with budgets from day one

### Mistake 5: Ignoring the JS Cost Model
❌ Counting only download size, not execution
✅ Budget parse/compile/execute; ship less JS

### Mistake 6: Optimizing Actual, Ignoring Perceived
❌ Fast number, blank screen then a dump
✅ Stream/skeleton; prioritize visible content and instant feedback

---

## Interview Questions

### Q1: How do you make the business case for investing in performance?
**Answer:** I tie it to outcomes the business already cares about: performance directly affects conversion and revenue (even small delays measurably reduce conversions), bounce and retention, SEO (Core Web Vitals are a ranking signal), and reach — fast experiences expand the addressable market to users on low-end devices and slow networks, which is most users globally. There's also a cost angle: smaller payloads reduce bandwidth and CDN spend. I frame performance not as a technical nicety but as a feature with measurable ROI, and I back proposals with field data (RUM) showing where we lose users today and the projected impact of improvement.

### Q2: What's the difference between perceived and actual performance, and why does it matter?
**Answer:** Actual performance is the measurable time for work to complete; perceived performance is how fast it *feels* to the user. They diverge often — a page that streams meaningful content progressively can feel faster than one that blocks briefly then renders everything at once. It matters because UX and conversion track perception, not just the clock. So beyond reducing real time, I optimize perception: show skeletons and stream content, prioritize above-the-fold rendering, give input feedback within ~100ms, and eliminate layout shifts that make a page feel janky and slow. The best results optimize both dimensions, but perception is frequently the higher-leverage lever for user-facing UX.

### Q3: Walk me through how you'd approach a "the app feels slow" report.
**Answer:** I refuse to guess and follow measure → isolate → optimize → verify. First I reproduce with realistic conditions — throttled mid-tier mobile, cold cache — and gather both lab data (Lighthouse/DevTools) and field data (RUM) to see whether the problem is loading, interactivity, or visual stability, since each points to different levers. I isolate the bottleneck with profiling (network waterfall, flame charts, long tasks) rather than assuming. Then I apply the targeted fix — network, assets, JS, runtime, or framework — re-measure to confirm real improvement without regressions, and finally add a budget or CI gate so it can't silently come back. The discipline of data-driven, verified optimization is the key.

### Q4: Why is JavaScript considered the most expensive resource?
**Answer:** Because its cost isn't just download — it's parse, compile, and execution on the main thread, which is also where the browser handles user input and rendering. A megabyte of JavaScript is far more costly than a megabyte of image: the image largely downloads and decodes off the critical interactivity path, while JavaScript blocks the main thread and directly drives metrics like INP and Total Blocking Time. On low-end devices the execution cost is dramatically higher. That's why I treat the JS budget as the tightest constraint — shipping less JavaScript, code-splitting, deferring non-critical scripts, and moving heavy work off the main thread (web workers) usually yields the biggest interactivity wins.

### Q5: Lab vs field data — why do you need both?
**Answer:** Lab (synthetic) data from tools like Lighthouse or WebPageTest is controlled and repeatable, which makes it ideal for debugging specific issues and gating changes in CI — but it's a single simulated environment, not your real users. Field data (Real User Monitoring / Core Web Vitals) captures actual devices, networks, and usage patterns at percentiles like p75, which is the ground truth and what Google ranks on. A classic trap is polishing the lab score to 100 while field metrics stay poor because real users differ from the test profile. I use lab to diagnose and prevent regressions, and field to know the truth and prioritize what actually hurts users.

---

## Key Takeaways

- **Performance is a business metric** — conversion, retention, SEO, reach, cost
- **Design for the p75 user**, not your dev machine (the empathy gap)
- **Perceived performance matters** as much as actual — stream, skeleton, give feedback
- **Three dimensions:** loading (LCP), interactivity (INP), visual stability (CLS)
- **Always measure → isolate → optimize → verify → prevent**
- **The critical path** governs first render — reduce number, size, and depth
- **JavaScript is the most expensive resource** — budget parse/compile/execute
- **Use budgets** to make performance an enforceable contract
- **Need both lab and field data** — diagnose with lab, know truth with RUM

---

## What's Next?

Now that you have the mental model, learn **how the browser actually renders** so you can connect each optimization to a mechanism:
- **[Rendering Path →](./rendering-path.md)** — critical rendering path, DOM/CSSOM, the event loop

---

[← Performance README](./README.md) | [Rendering Path →](./rendering-path.md)
