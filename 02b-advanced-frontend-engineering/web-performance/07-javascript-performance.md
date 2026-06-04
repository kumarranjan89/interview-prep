# JavaScript Performance

The most expensive resource on modern apps. Not because of download — because of parse, compile, and execution on the main thread.

---

## Navigation
[← Asset Optimization](./asset-optimization.md) | [Runtime & Rendering →](./runtime-rendering.md)

---

## Why JavaScript Is the Bottleneck

```
1 MB image:  download + decode (often off main thread)
1 MB JS:     download + PARSE + COMPILE + EXECUTE on the main thread
             → blocks rendering AND interactivity (INP/TBT)
```

> "Byte for byte, JavaScript is the most expensive resource on the web." On low-end phones, executing a large bundle can take **seconds** — the device, not the network, is the limit.

**The goal:** ship less JavaScript, ship it later, and run it less.

---

## The JS Cost Model

```
Download  → network time (compression helps)
Parse     → browser reads the JS into an AST
Compile   → JS engine compiles to bytecode/machine code
Execute   → actually running it (the most variable cost)
```
- Parse/compile scale with bundle **size**; execution scales with **what the code does**.
- All happen on the **main thread** → directly hurt TBT (lab) and INP (field).
- **Less code is the most reliable win** — every byte not shipped is free.

---

## 1. Code Splitting (Ship Only What's Needed Now)

Instead of one giant bundle, split into chunks loaded on demand.

```
❌ One bundle:  [everything].js  → user downloads/parses ALL upfront
✅ Split:       [main].js + [route-a].js + [route-b].js (lazy)
                → load route-a only when visiting route A
```

### Route-Based Splitting (biggest win)
```typescript
// Angular: lazy-loaded routes (each becomes its own chunk)
const routes: Routes = [
  { path: 'dashboard', loadChildren: () =>
      import('./dashboard/dashboard.module').then(m => m.DashboardModule) },
];
```
```tsx
// React: lazy + Suspense
const Dashboard = lazy(() => import('./Dashboard'));
<Suspense fallback={<Skeleton />}><Dashboard /></Suspense>
```

### Component-Level Splitting
```
Defer heavy, non-critical components: modals, charts, editors, maps
→ import() them on interaction or when needed
```
```tsx
// Load a heavy chart only when the user opens that tab
const Chart = lazy(() => import('./HeavyChart'));
```

---

## 2. Tree Shaking (Drop Dead Code)

Bundlers remove unused exports — but only if code is **tree-shakeable**.

```
✅ ES modules (import/export) → statically analyzable → shakeable
❌ CommonJS (require) → harder to shake
```

### Import Only What You Use
```javascript
// ❌ Pulls the whole library (if not tree-shakeable)
import _ from 'lodash';
_.debounce(fn, 200);

// ✅ Import the specific function
import debounce from 'lodash/debounce';
// or use lodash-es (ES modules, tree-shakeable)
import { debounce } from 'lodash-es';
```

### Enablers
```
- Use ES module builds of libraries
- "sideEffects": false in package.json (tells bundler it's safe to drop)
- Avoid importing entire icon/util libraries; import individual items
- Prefer smaller alternatives (date-fns/dayjs over moment)
```

---

## 3. Lazy Loading & Dynamic Imports

```javascript
// Load on demand — e.g., a feature behind a user action
button.addEventListener('click', async () => {
  const { exportToPdf } = await import('./pdf-export');  // separate chunk
  exportToPdf(data);
});
```
- Defer anything not needed for the initial view.
- Pair with **prefetch** (idle/hover) so the chunk is ready before the click feels slow.

---

## 4. Reduce Dependency Weight

```
- Audit with the bundle analyzer (your repo: build:stats → analyze:mfe1)
- Replace heavyweights:
    moment (~70KB) → date-fns / dayjs (~2-7KB)
    lodash (full)  → lodash-es / individual / native
- Question every dependency — could a few lines replace it?
- Watch for duplicate deps (multiple versions) → dedupe
- Avoid large polyfills for browsers you don't support
```

> **Architect note:** dependency discipline is a governance issue — a single careless `import` can add hundreds of KB. Bundle budgets in CI catch this.

---

## 5. Minification & Modern Output

```
- Minify (Terser/esbuild) — removes whitespace, shortens names
- Ship modern syntax (ES2017+) to modern browsers (smaller, faster)
  → differential serving / module-nomodule, or target modern baseline
- Avoid over-transpiling: don't down-level to ES5 for browsers that
  don't need it (adds size + slows execution)
```

```html
<!-- module/nomodule: modern browsers get smaller modern code -->
<script type="module" src="/app.modern.js"></script>
<script nomodule src="/app.legacy.js"></script>
```

---

## 6. The Hydration Cost (SSR/SSR Frameworks)

```
SSR sends HTML (fast first paint), then JS "hydrates" it to add interactivity
  → hydration re-runs framework work on the client = main-thread cost
  → big apps: fast LCP but poor INP until hydration completes
```

**Modern mitigations:**
```
- Partial / progressive hydration: hydrate only interactive parts
- Islands architecture (Astro): static HTML + small interactive islands
- React Server Components: components that never ship JS to the client
- Resumability (Qwik): skip hydration, resume server state
- Selective/lazy hydration on visibility/interaction
```

> **Architect note:** for content sites, shipping **zero/minimal JS** (islands/RSC) often beats a full SPA on both LCP and INP.

---

## 7. Keep Execution Cheap

```
- Avoid large synchronous work at startup → defer/break up (see runtime file)
- Don't eagerly initialize everything; init on demand
- Remove dead feature flags, unused code paths
- Be wary of expensive module-level side effects at import time
```

---

## Mapping JS Problems → Levers

```
Big initial bundle     → route-based code splitting
Unused code shipped    → tree shaking, purge, import specifics
Heavy dependency       → lighter alternative, individual imports
Feature loads upfront  → lazy import on demand + prefetch
Slow on old-browser JS → modern output (module/nomodule), less transpiling
Fast LCP, poor INP     → reduce hydration (islands/RSC/partial)
Duplicate libraries    → dedupe, share singletons (esp. MFE)
```

---

## Mental Models

### JavaScript = Carry-On Luggage
Every KB is carried by the main thread through parse/compile/execute — unlike images (checked luggage handled elsewhere). Pack only what you need for *this* leg of the trip; ship the rest separately (code-split) or leave it home (tree-shake).

### Code Splitting = Ordering Courses, Not the Whole Menu
You don't cook the entire menu when a guest sits down. You serve the appetizer (initial route) now and prepare other courses (routes) only when ordered. Faster to first bite.

### Tree Shaking = Editing Out Unused Scenes
A good editor cuts every scene that doesn't make the final film. Tree shaking removes exports nobody imports — but only if the code is written so the editor can *see* what's unused (ES modules).

### Hydration = Re-Building Furniture That Already Looks Assembled
SSR ships a photo of assembled furniture (HTML) so it *looks* ready, but the client still has to actually build it (hydrate) before you can use it. Islands/RSC only build the pieces you'll actually touch.

---

## Common Mistakes

### Mistake 1: One Giant Bundle
❌ Ship everything upfront → slow parse/execute, poor TTI/INP
✅ Route-based code splitting; lazy-load non-critical

### Mistake 2: Importing Whole Libraries
❌ `import _ from 'lodash'` for one function
✅ Import specifics / tree-shakeable builds (lodash-es, date-fns)

### Mistake 3: Heavyweight Dependencies
❌ moment.js, full lodash, big UI kits for one widget
✅ Lighter alternatives; question every dependency

### Mistake 4: Over-Transpiling
❌ Down-leveling to ES5 for modern users → bigger, slower
✅ Modern output (module/nomodule), modern baseline target

### Mistake 5: Not Analyzing the Bundle
❌ Blind to what's inside → silent bloat
✅ Regular bundle analysis (`build:stats` → `analyze:mfe1`) + CI budgets

### Mistake 6: Ignoring Hydration Cost
❌ Great LCP but janky INP from heavy hydration
✅ Partial hydration, islands, RSC, resumability

### Mistake 7: Eager Loading Everything
❌ Loading modals/charts/editors no one opened yet
✅ Dynamic `import()` on demand + prefetch

---

## Interview Questions

### Q1: Why is JavaScript the most expensive resource, and how do you reduce its cost?
**Answer:** Its cost isn't just download — it's parse, compile, and execution on the main thread, the same thread that handles rendering and user input, so heavy JS directly worsens TBT and INP. And unlike an image, which largely decodes off the critical path, a megabyte of JavaScript must be processed by the engine, with execution cost much higher on low-end devices. I reduce it primarily by shipping less: route-based code splitting so users only download the current view, tree shaking and specific imports to drop dead code, replacing heavyweight dependencies with lighter ones, and lazy-loading non-critical features on demand. I ship modern syntax to modern browsers to avoid transpilation bloat, minify, analyze the bundle against CI size budgets, and for SSR apps reduce hydration cost with partial hydration, islands, or server components. Less code, later, run less.

### Q2: Explain code splitting and where you'd apply it.
**Answer:** Code splitting breaks a single large bundle into smaller chunks loaded on demand instead of all upfront, so the initial download, parse, and execute cost drops. The biggest win is route-based splitting — each route becomes its own lazily-loaded chunk (Angular `loadChildren`, React `lazy` + `Suspense`) so visiting the dashboard doesn't load the settings code. I also split at the component level for heavy, non-critical UI like charts, rich editors, maps, or modals, importing them dynamically when the user actually opens them. And I split vendor or rarely-changing code so it caches well. To avoid a delay when a chunk is first needed, I pair splitting with prefetching on idle or link hover so the chunk arrives before the interaction. The principle is to load only what the current view needs.

### Q3: What is tree shaking and what can prevent it from working?
**Answer:** Tree shaking is dead-code elimination — the bundler statically analyzes ES module imports/exports and drops exports nobody uses. It depends on static analyzability, so several things break it: using CommonJS (`require`) instead of ES modules, importing an entire library namespace when the library isn't tree-shakeable (`import _ from 'lodash'`), and modules with side effects that the bundler can't safely remove. To enable it I use ES module builds (e.g., `lodash-es`, `date-fns`), import specific functions rather than whole libraries, mark packages with `"sideEffects": false` when accurate so the bundler knows it's safe to drop unused modules, and avoid side-effectful imports. I verify the result with a bundle analyzer to confirm unused code actually dropped.

### Q4: How do you decide which dependencies to include in a large app?
**Answer:** I treat every dependency as a long-term cost — to bundle size, security surface, and maintenance — not a free convenience. Before adding one I check its size and tree-shakeability (e.g., with bundlephobia or our analyzer), whether a lighter alternative exists (date-fns/dayjs over moment, native APIs over lodash), and whether a few lines of our own code could replace it. I prefer ES-module, well-maintained libraries, avoid pulling a large kit for a single widget, and watch for duplicate versions to dedupe. At the architecture level I enforce this with CI bundle budgets so a careless import that adds hundreds of KB fails the build, and I periodically audit the dependency tree. Dependency discipline is one of the highest-leverage performance governance practices.

### Q5: What is hydration and why can it hurt INP?
**Answer:** Hydration is the process where a server-rendered page, which arrives as static HTML for a fast first paint, gets its JavaScript downloaded and executed on the client to attach event listeners and make it interactive. The problem is that hydration re-runs framework work on the main thread across the page, so you can have a great LCP — content is visible early — but poor INP, because until hydration finishes the page can't respond to input, and on large apps that's a lot of blocking main-thread work. Mitigations reduce or defer that work: partial/progressive hydration to hydrate only interactive regions, islands architecture (static HTML with small interactive islands), React Server Components that ship no client JS for non-interactive parts, lazy/selective hydration on visibility or interaction, and resumability (Qwik) which skips hydration entirely. For content-heavy sites, minimizing client JS often wins on both LCP and INP.

### Q6: How would you reduce a 2MB initial JavaScript bundle?
**Answer:** First I'd measure with the bundle analyzer (`build:stats` then `analyze:mfe1`) and the Coverage tab to see what's actually shipped and used. Then, in order of impact: route-based code splitting so the initial load only contains the current view, moving everything else to lazy chunks; tree shaking and specific imports to drop dead code; replacing heavyweight dependencies (moment, full lodash, large UI kits) with lighter alternatives; lazy-loading heavy non-critical components on interaction; deduplicating multiple versions of the same library; and ensuring modern output rather than over-transpiling to ES5. If it's an SSR app, I'd cut hydration cost with partial hydration or server components. After each change I re-measure, and I'd add a CI bundle-size budget so it can't regress back to 2MB. The single biggest lever is usually code splitting plus removing a few oversized dependencies.

---

## Key Takeaways

- **JS is the most expensive resource** — parse/compile/execute on the main thread
- **Ship less, later, run less** — the most reliable wins
- **Route-based code splitting** is usually the biggest single win
- **Tree shaking** needs ES modules + specific imports + `sideEffects: false`
- **Lazy-load** heavy/non-critical features on demand + prefetch
- **Audit dependencies** — replace heavyweights, dedupe, enforce CI budgets
- **Ship modern output** — don't over-transpile for browsers you don't support
- **Hydration hurts INP** — use partial hydration, islands, RSC, resumability

---

## What's Next?

You've minimized the JS you ship — now make the JS that *does* run stay smooth at runtime:
- **[Runtime & Rendering →](./runtime-rendering.md)** — reflow/repaint, long tasks/INP, virtualization, workers

---

[← Asset Optimization](./asset-optimization.md) | [Runtime & Rendering →](./runtime-rendering.md)
