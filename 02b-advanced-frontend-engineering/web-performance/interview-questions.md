# ⚡ Web Performance — Interview Questions (Architect / 15+ YOE)

Consolidated performance question bank, calibrated to **architect-level** interviews. Focus: methodology, trade-offs, root-cause diagnosis, and governance — not just isolated tips.

> **At your level, interviewers probe:** Can you diagnose methodically? Do you know *why* each lever works? Can you make trade-offs and govern performance across teams and time?

---

## Navigation
[← Budgets & Governance](./budgets-governance.md) | [Performance README](./README.md)

---

## How to Answer (Architect Bar)
- **Lead with methodology** — "measure → isolate → optimize → verify," never random tips.
- **Explain the mechanism** — tie each fix to the rendering path / main thread / network.
- **Quantify** — know the thresholds (LCP 2.5s, INP 200ms, CLS 0.1, ~170KB JS).
- **Trade-offs** — every optimization has a cost; show you weigh them.
- **Govern** — mention budgets, CI, and RUM so wins don't regress.
- **Evidence** — reference a real diagnosis or platform decision.

---

## SECTION A — Methodology & Strategy (Most Important)

### A1. "The app feels slow." Walk me through your approach.
**Answer:** I never guess; I follow measure → isolate → optimize → verify → prevent. I reproduce under realistic conditions — throttled mid-tier mobile, cold cache — and gather both field data (RUM/CrUX) to see which vital is poor and for whom, and lab data (Lighthouse/WebPageTest/DevTools) to debug. I isolate the dimension: loading (LCP), interactivity (INP), or visual stability (CLS), since each points to different levers. Then I profile with the right tool — network waterfall for LCP, the Performance flame chart for INP and long tasks, the layout-shift view for CLS — to find the actual bottleneck. I apply a targeted fix, re-measure in lab to confirm and watch field over the following weeks, and finally add a budget or CI gate so it can't silently come back. The discipline of data-driven, verified optimization is what matters.

### A2. How do you make the business case for performance investment?
**Answer:** I tie it to outcomes the business already values: performance directly affects conversion and revenue (even small delays measurably reduce conversions), bounce and retention, SEO since Core Web Vitals are a ranking signal, and reach — fast experiences expand the addressable market to users on low-end devices and slow networks, which is most users globally. There's also a cost dimension: smaller payloads reduce bandwidth and CDN spend. I frame performance as a feature with measurable ROI and back proposals with our own RUM data showing where we lose users today and the projected impact, so it competes for prioritization on equal footing with features.

### A3. How do you balance performance against developer velocity and features?
**Answer:** I make performance a managed constraint rather than an absolute or an afterthought. Budgets quantify the acceptable spend (bundle size, key metrics) so teams can move fast within guardrails without re-litigating performance on every PR. I shift the decision left — heavy dependencies and rendering strategies are evaluated at RFC time — so we make deliberate trade-offs early instead of expensive fixes later. I provide fast-by-default tooling (a performance-optimized design system, CI templates, SSR setup) so the fast path is also the easy path, minimizing the velocity tax. And I prioritize by impact using RUM, focusing effort where it moves real users. The goal is sustainable velocity: fast product, fast development, neither sacrificed wholesale.

### A4. What are the most common causes of poor performance you've seen?
**Answer:** A handful recur. Oversized JavaScript bundles from no code-splitting and heavyweight dependencies, which hurt both load and INP. Unoptimized images — wrong format, no responsive sizing, and the classic lazy-loaded hero that tanks LCP. Render-blocking resources, especially large CSS and synchronous scripts in the head. Request waterfalls from chained client-side fetches. Main-thread congestion from long tasks and excessive framework re-renders, causing poor INP. Layout shift from images and ads without reserved space and from font swaps. No CDN for a global audience, inflating TTFB. And the meta-cause: no measurement, no budgets, and no monitoring, so performance silently rots. Most real wins come from code-splitting, image optimization, and main-thread discipline, then locking them in with governance.

---

## SECTION B — Metrics & Diagnosis

### B1. What are the Core Web Vitals and what drives each?
**Answer:** Three, each mapping to a user-experience dimension at p75 of real users. LCP (Largest Contentful Paint, ≤2.5s) measures loading — when the largest element renders — driven by TTFB, render-blocking CSS/JS, the LCP image's load, and client-render delay. INP (Interaction to Next Paint, ≤200ms) measures interactivity — input to next paint across the page lifecycle, replacing FID — driven by long tasks, heavy handlers, and excessive re-renders. CLS (Cumulative Layout Shift, ≤0.1) measures visual stability — unexpected movement — driven by media without dimensions, un-reserved ads/embeds, and font swaps. They're a Google ranking signal, and knowing each vital's drivers lets me map a failing metric directly to its fix.

### B2. Lab vs field data — why both?
**Answer:** Lab data (Lighthouse, WebPageTest, DevTools) is a controlled, repeatable test on one device/network profile — ideal for debugging and CI gating, but not representative of all users. Field data / RUM (CrUX, web-vitals.js) captures real users across the full device/network spread at p75 — the ground truth and what Google ranks on, but you can't step-debug a session. A classic trap is polishing the lab score to 100 while field metrics stay poor because real users differ from the test profile. I use lab to reproduce and fix and to prevent regressions in CI, and field to know the truth and prioritize. Both feed back into budgets.

### B3. How would you set up RUM for Core Web Vitals?
**Answer:** I'd use Google's web-vitals.js to capture LCP, INP, CLS, plus TTFB and FCP from real users and beacon them with `navigator.sendBeacon` so reporting doesn't block the page. I'd attach dimensions — route, device, connection, country, app version — to segment p75 and find which cohorts hurt. On the backend I aggregate to p75/p95 per route, build dashboards, and alert on threshold breaches and deploy-correlated regressions. I'd also pull CrUX for a zero-instrumentation baseline, or use a managed platform (SpeedCurve, Sentry, Datadog) instead of the DIY pipeline. The goal is continuous, segmentable, real-time truth that drives prioritization and catches regressions early.

### B4. INP replaced FID — what changed and why does it matter?
**Answer:** FID only measured the input delay of the first interaction, ignoring processing time, presentation delay, and all subsequent interactions, so it was easy to pass while the app still felt sluggish. INP measures the full latency — input delay plus handler processing plus paint — across all interactions during the page's life, reporting near the worst one. It's a far more honest responsiveness measure, especially for JS-heavy SPAs. It matters because passing INP demands real main-thread discipline: breaking up long tasks, offloading to web workers, reducing re-renders, and yielding to the event loop — not just getting the first interaction in quickly.

---

## SECTION C — Loading Optimization

### C1. How would you optimize a slow LCP?
**Answer:** First identify which LCP driver dominates. For slow TTFB: CDN, edge caching, SSR/streaming, and preconnect. For render-blocking resources: inline critical CSS and defer non-critical CSS/JS. For the LCP image itself: serve a modern format (AVIF/WebP) at the right responsive size, preload it with `fetchpriority="high"`, and never lazy-load it — deferring the hero is a common self-inflicted regression. For client-render delay on content pages: prefer SSR/SSG so the main content is in the initial HTML. Then I re-measure in lab and validate on field RUM, since LCP is best judged on real users.

### C2. Design a caching strategy for a web app's assets.
**Answer:** Separate immutable, content-hashed static assets from changing HTML. Hashed assets (`app.a1b2c3.js`) get `Cache-Control: public, max-age=31536000, immutable` so browsers and CDNs cache them forever and never revalidate — and because the hash changes with content, there's no staleness; a new build references a new URL. HTML gets short or no-cache (often `no-cache` with revalidation, or short `s-maxage` at the CDN with `stale-while-revalidate`) so users always pick up the latest asset map quickly. I add ETags for conditional revalidation and serve everything via CDN with appropriate `s-maxage`. This gives aggressive caching with instant deployability.

### C3. How did HTTP/2-3 change frontend loading best practices?
**Answer:** HTTP/1.1's ~6-connection limit and head-of-line blocking led to hacks like giant bundles, image sprites, and domain sharding. HTTP/2 added multiplexing — many requests over one connection — plus header compression and prioritization, making many small files efficient and those hacks counterproductive. HTTP/3 over QUIC/UDP removes TCP-level head-of-line blocking so packet loss doesn't stall all streams, with faster connection setup that especially helps mobile. So best practice flipped: prefer fine-grained, independently cacheable chunks (pairs with route-based code-splitting) over one big bundle, and drop concatenation/sharding. This improves cache hit rates and parallel download.

### C4. How do you handle the cost of third-party scripts?
**Answer:** Third parties are a leading real-world performance problem — they can render-block, hog the main thread, open extra connections, and fail unpredictably. I never let them block rendering (async/defer), apply the facade pattern for heavy embeds (a lightweight placeholder that loads the real widget on interaction, like a video thumbnail), self-host where licensing allows to cut connections and gain cache control, and consider Partytown to run them in a web worker off the main thread. I govern them with a budget, audit and remove unused tags, and add Subresource Integrity for safety. The principle is to contain their cost and keep them off the critical path.

---

## SECTION D — JavaScript & Runtime

### D1. Why is JavaScript the most expensive resource, and how do you reduce its cost?
**Answer:** Its cost isn't just download — it's parse, compile, and execution on the main thread, which also handles rendering and input, so heavy JS directly worsens TBT and INP, with execution far costlier on low-end devices. I reduce it by shipping less: route-based code splitting so users only load the current view, tree shaking and specific imports to drop dead code, replacing heavyweight dependencies with lighter ones, and lazy-loading non-critical features. I ship modern syntax to modern browsers to avoid transpilation bloat, minify, analyze the bundle against CI budgets, and for SSR apps cut hydration cost with partial hydration, islands, or server components. Less code, later, run less.

### D2. Explain code splitting and tree shaking.
**Answer:** Code splitting breaks one large bundle into chunks loaded on demand, so initial download/parse/execute drops. The biggest win is route-based splitting — each route is a lazy chunk (Angular `loadChildren`, React `lazy` + `Suspense`) — plus component-level splitting for heavy non-critical UI like charts and editors, paired with prefetching so the chunk is ready before it's needed. Tree shaking is dead-code elimination: the bundler statically analyzes ES module imports/exports and drops unused ones. It needs ES modules (not CommonJS), specific imports rather than whole-library namespaces, and accurate `"sideEffects": false` so the bundler can safely remove unused modules. I verify both with a bundle analyzer.

### D3. What causes poor INP and how do you fix it?
**Answer:** Main-thread congestion: long tasks (>50ms) that block input and paint, expensive synchronous event handlers, excessive framework re-renders, and a large/complex DOM. I fix it by breaking long tasks into chunks that yield to the event loop (`scheduler.yield` or a setTimeout fallback), moving heavy computation to web workers, debouncing/throttling handlers, deferring non-urgent updates (`requestIdleCallback`, React `startTransition`), reducing DOM complexity and unnecessary re-renders, and giving immediate visual feedback before doing work. The core principle is keeping the main thread free to respond to the user.

### D4. How do you render a list of 10,000 items performantly?
**Answer:** Virtualize it — render only the ~20 items visible in the viewport plus a small buffer, recycling DOM nodes as the user scrolls, so memory and layout cost stay roughly constant regardless of list size. In Angular I'd use CDK Virtual Scroll (`cdk-virtual-scroll-viewport` with `*cdkVirtualFor`); in React, react-window or TanStack Virtual. I pair it with stable keys/trackBy to avoid re-renders, consistent item sizing for accurate scrolling, and incremental data loading via IntersectionObserver. Any unbounded list — feeds, tables, search results — should be virtualized by default.

### D5. How do you achieve smooth 60fps animations and avoid jank?
**Answer:** The frame budget is ~16ms, so all per-frame work must fit. I animate only compositor-friendly properties — `transform` and `opacity` — which run on the GPU off the main thread without triggering layout or paint each frame; animating `left/top/width/margin` forces reflow and repaint and causes jank. I use `will-change` sparingly to hint layer promotion, prefer CSS transitions/animations or the Web Animations API over per-frame JS, avoid layout thrashing by batching reads then writes, and keep the main thread free during animation by offloading heavy work. For long pages, `content-visibility: auto` skips offscreen rendering.

---

## SECTION E — Framework (Angular Focus)

### E1. How does Angular change detection work and how do you optimize it?
**Answer:** Zone.js patches async APIs so Angular runs change detection after any async event, walking the tree and checking bindings; the default strategy checks the whole tree every time, which is wasteful at scale. The main lever is OnPush, which re-checks a component only when an input reference changes, an event fires from it, a bound observable emits via the async pipe, or `markForCheck` is called — so it relies on immutable updates. I add `trackBy`/`track` to lists, avoid function calls in templates (they run every cycle), use `runOutsideAngular` for hot non-UI loops, and adopt signals for fine-grained reactivity. The strategic direction is signals plus zoneless change detection, removing Zone.js overhead entirely.

### E2. What are Angular signals and why do they matter?
**Answer:** Signals are Angular's reactive primitive — `signal` holds a value, `computed` derives and recomputes only when dependencies change, `effect` reacts to changes. They enable fine-grained reactivity: instead of Zone.js triggering tree-wide change detection on every async event, Angular updates precisely the views depending on the changed signal, cutting wasted work in large apps. They're also the foundation for zoneless change detection, which drops Zone.js for a smaller bundle and less runtime overhead. For new code I prefer signals for state combined with OnPush as the modern high-performance pattern.

### E3. How would you optimize a slow Angular app, end to end?
**Answer:** Measure first to separate load from runtime issues. Runtime/change detection: OnPush with immutable data, `trackBy`/`track` on lists, remove template function calls and heavy getters, `runOutsideAngular` for hot loops, CDK Virtual Scroll for long lists, and signals (and consider zoneless) for fine-grained updates. Load/bundle: lazy routes via `loadChildren`, standalone components, production AOT, bundle analysis (`build:stats` → `analyze:mfe1`) to remove heavyweight deps, budgets in `angular.json`, and SSR/prerendering for LCP and SEO. Fix memory leaks with the async pipe or `takeUntilDestroyed`. Re-measure after each change and gate regressions with CI budgets.

---

## SECTION F — Governance & Scale

### F1. What is a performance budget and how do you enforce it?
**Answer:** A quantified, enforced limit that makes "be fast" a contract — metric budgets (LCP ≤2.5s, INP ≤200ms, CLS ≤0.1 at p75), quantity budgets (critical JS ≤~170KB, total weight, request count), or rule budgets (no render-blocking third parties, images must declare dimensions). I set them from real-user data and device targets, per route, starting at baseline and ratcheting tighter. Enforcement is the key: the build must fail when exceeded, so I wire bundle-size checks (Angular budgets, size-limit) and Lighthouse CI metric assertions into every PR. Catching regressions at the PR rather than in production is the single most effective practice.

### F2. How do you prevent performance from degrading across many teams over time?
**Answer:** Treat performance as a property to maintain via a governance loop: baseline, per-route budgets, CI gates that fail regressing PRs, RUM monitoring of real-user p75 with alerts, regression-to-release (and in MFE, per-team/version) attribution, then fix and ratchet. Crucially I pair tooling with culture — shared ownership where teams own their routes' budgets, performance in the Definition of Done, visible dashboards, and a platform team providing fast-by-default components and CI templates. The architect's job is making the fast path the easy path, so good performance is the default rather than a heroic effort.

### F3. How does performance governance change in micro-frontends?
**Answer:** Multiple independently-deployed teams share one page, so one team's regression can degrade the whole experience. Each MFE gets its own budget enforced in its own pipeline, so no team can silently bloat the shared page. RUM is attributed per-MFE and per-version for precise root cause. A shared-dependency policy keeps frameworks as singletons to avoid duplicate copies — a major payload risk. The design system ships as a fast-by-default shared library, and a platform team owns the shared performance paved road (shell, budgets, RUM, CI templates). This preserves team autonomy while protecting the composed app's collective performance.

### F4. Where should performance fit in the development lifecycle?
**Answer:** Shifted left — into design and planning, not just code review or post-release. At RFC/design time I budget new features and heavy dependencies explicitly and choose the rendering strategy (CSR/SSR/SSG/ISR) from requirements. During development, CI gates enforce bundle and metric budgets on every PR. After release, RUM validates real-world impact and feeds back into budgets. Discovering performance cost only at review or in production is too late and expensive; budgeting up front makes performance a deliberate design constraint rather than a cleanup phase.

---

## SECTION G — Scenario / Design Prompts (Practice Out Loud)

Structure: clarify → measure → isolate dimension → apply levers → verify → govern.

- **An e-commerce PDP has poor LCP on mobile in emerging markets** — diagnose and fix (TTFB? image? render-blocking?).
- **A dashboard SPA has great LCP but feels sluggish to click** — INP root-cause and fixes.
- **Bundle has grown to 3MB over two years** — reduction plan + prevention.
- **CLS spikes after a marketing team adds banners/ads** — stabilize without blocking them.
- **Set up a performance program for 10 teams on one platform** — budgets, CI, RUM, culture.
- **Choose a rendering strategy for a content site vs an internal app** — justify CSR/SSR/SSG.

---

## Rapid-Fire (One-Liners)

- **3 Core Web Vitals?** LCP (≤2.5s), INP (≤200ms), CLS (≤0.1), at p75.
- **First step diagnosing?** Measure (field + lab); don't guess.
- **Most expensive resource?** JavaScript (parse/compile/execute).
- **Biggest bundle win?** Route-based code splitting.
- **Never lazy-load?** The LCP/hero image.
- **Animate only?** `transform` and `opacity`.
- **#1 INP killer?** Long tasks on the main thread.
- **Long list?** Virtualize.
- **Cache static assets?** Immutable hashed + forever; HTML short-lived.
- **Prefer chunks over big bundle because?** HTTP/2-3 multiplexing.
- **Angular CD lever?** OnPush + immutability; then signals/zoneless.
- **Keep it fast forever?** Budgets + CI gates + RUM.
- **Lab vs field?** Lab to fix, field for truth.

---

## Self-Check Before the Interview
- [ ] I diagnose with **measure → isolate → optimize → verify**, never guessing
- [ ] I can explain **each Core Web Vital** and its drivers from the rendering path
- [ ] I know the **thresholds and the ~170KB JS** rule of thumb
- [ ] I can optimize **LCP, INP, and CLS** specifically
- [ ] I can explain **code splitting, tree shaking, and hydration cost**
- [ ] I can speak fluently to **Angular CD, OnPush, signals, zoneless**
- [ ] I can design **budgets + CI + RUM governance** across teams
- [ ] I have **a real diagnosis story** with measurable before/after

---

[← Budgets & Governance](./budgets-governance.md) | [Performance README](./README.md)
