# Framework Performance — Angular & React

Framework-specific optimization. The general principles still apply — here's how they map to change detection, reactivity, and rendering in your stack.

---

## Navigation
[← Runtime & Rendering](./runtime-rendering.md) | [Budgets & Governance →](./budgets-governance.md)

---

## Why Framework-Specific Matters

```
General rule:            "minimize work on the main thread"
Framework translation:   "minimize unnecessary change detection / re-renders"
```

Frameworks add an abstraction (change detection, the virtual DOM, reactivity) whose **overhead is the dominant runtime cost** in most SPAs. Knowing your framework's model lets you cut that overhead precisely.

---

## PART 1 — ANGULAR (Your Stack)

### How Change Detection Works
```
Zone.js patches async APIs (events, timers, XHR/fetch, promises)
  → after any async event, Angular runs change detection
  → walks the component tree checking bindings for changes
  → Default strategy checks the WHOLE tree every time
```
The cost: with many components, checking everything on every event is wasteful.

### 1. OnPush Change Detection (Biggest Lever)
```typescript
@Component({
  selector: 'app-row',
  changeDetection: ChangeDetectionStrategy.OnPush,  // check only when needed
  template: `...`,
})
export class RowComponent {}
```
OnPush only re-checks a component when:
```
- An @Input reference changes (immutable updates!)
- An event fires from the component
- An observable bound with | async emits
- You manually markForCheck()
```
> **Architect note:** OnPush + **immutable data** is the foundation of Angular performance. Standardize it for new components.

### 2. trackBy on *ngFor (Avoid DOM Churn)
```typescript
@for (item of items; track item.id) {  // modern (Angular 17+)
  <app-row [item]="item" />
}
```
```html
<!-- classic syntax -->
<app-row *ngFor="let item of items; trackBy: trackById" [item]="item" />
```
```typescript
trackById = (_: number, item: Item) => item.id;
```
Without `trackBy`, changing the array re-creates **all** DOM nodes; with it, Angular reuses unchanged rows.

### 3. Signals (Modern Reactivity)
```typescript
count = signal(0);
double = computed(() => this.count() * 2);   // recomputes only when count changes
increment() { this.count.update(v => v + 1); }
```
- Fine-grained reactivity → Angular updates **only what actually changed**, not the whole tree.
- Path toward **zoneless** change detection (drop Zone.js overhead entirely).
- Prefer signals for new state; combine with OnPush.

### 4. Zoneless Change Detection (The Future)
```typescript
// Angular 18+ experimental: remove Zone.js
bootstrapApplication(App, {
  providers: [provideExperimentalZonelessChangeDetection()],
});
```
- No Zone.js → smaller bundle, less overhead, CD driven by signals/events.
- The strategic direction for Angular performance.

### 5. Avoid Common Angular Pitfalls
```
- ❌ Function calls / heavy getters in templates → run every CD cycle
     ✅ Use pure pipes, signals, or precomputed values
- ❌ Subscribing manually without unsubscribe → leaks + extra CD
     ✅ async pipe / takeUntilDestroyed
- ❌ Heavy work inside Angular's zone (e.g., rAF loops)
     ✅ ngZone.runOutsideAngular() for non-UI hot loops
- ❌ Large eager modules → lazy-load routes (loadChildren)
- ❌ Default CD everywhere → OnPush + immutability
```
```typescript
// Run a hot loop outside Angular so it doesn't trigger CD every frame
this.ngZone.runOutsideAngular(() => {
  const loop = () => { doWork(); requestAnimationFrame(loop); };
  requestAnimationFrame(loop);
});
```

### 6. Angular Bundle & Build
```
- Lazy routes (loadChildren) — biggest bundle win
- Standalone components (tree-shakeable, no NgModule overhead)
- Production build: AOT + optimization on by default (ng build)
- Budgets in angular.json (warn/error on bundle size)
- Analyze: your repo's build:stats → analyze:mfe1
- For SSR/prerender: Angular Universal / @angular/ssr (better LCP/SEO)
- For MFE: share @angular/* + rxjs as singletons (see MFE section)
```
```json
// angular.json — enforce bundle budgets in the build
"budgets": [
  { "type": "initial", "maximumWarning": "500kb", "maximumError": "1mb" },
  { "type": "anyComponentStyle", "maximumWarning": "2kb" }
]
```

---

## PART 2 — REACT

### How Rendering Works
```
State/props change → component re-renders → new virtual DOM →
  diff against previous → minimal real DOM updates
  ⚠️ A parent re-render re-renders children by default (even if props same)
```
The cost: unnecessary re-renders cascade down the tree.

### 1. Memoization (Prevent Unnecessary Re-renders)
```jsx
// React.memo: skip re-render if props are shallow-equal
const Row = React.memo(function Row({ item }) { return <li>{item.name}</li>; });

// useMemo: cache expensive computed values
const sorted = useMemo(() => expensiveSort(items), [items]);

// useCallback: stable function identity (so memo'd children don't re-render)
const onClick = useCallback(() => doThing(id), [id]);
```
> Don't over-memoize — it has its own cost. Memoize hot paths and props passed to memo'd children. (React 19's compiler automates much of this.)

### 2. Stable Keys (Like trackBy)
```jsx
{items.map(item => <Row key={item.id} item={item} />)}  // stable, unique key
// ❌ key={index} → breaks reconciliation on reorder/insert
```

### 3. Concurrent Features (React 18+)
```jsx
// Mark non-urgent updates so urgent input stays responsive
const [isPending, startTransition] = useTransition();
startTransition(() => setFilter(value));   // de-prioritized → better INP

const deferred = useDeferredValue(query);  // defer expensive derived renders
```

### 4. Code Splitting & Suspense
```jsx
const Chart = lazy(() => import('./Chart'));
<Suspense fallback={<Skeleton />}><Chart /></Suspense>
```

### 5. Server Components & SSR (React 19 / Next.js)
```
- React Server Components: render on server, ship ZERO JS for them
  → less client bundle, better LCP/INP
- Streaming SSR: progressive HTML, faster TTFB/LCP
- Partial/selective hydration: hydrate interactive parts only
```

### 6. Avoid Common React Pitfalls
```
- ❌ Creating objects/arrays/functions inline as props → breaks memo
     ✅ useMemo/useCallback for referential stability
- ❌ key={index} for dynamic lists
     ✅ stable unique keys
- ❌ Huge context that changes often → re-renders all consumers
     ✅ split contexts, selectors, or state libraries (Zustand/Jotai)
- ❌ Expensive work in render
     ✅ useMemo, move to effects/workers
- ❌ Not virtualizing long lists
     ✅ react-window / TanStack Virtual
```

---

## Angular vs React — Same Principles, Different Levers

| Goal | Angular | React |
|------|---------|-------|
| Avoid wasted re-checks/renders | OnPush + immutability / signals | React.memo / useMemo / useCallback |
| Efficient lists | `track`/`trackBy` | stable `key` |
| Fine-grained reactivity | Signals | Signals-like libs / RSC / compiler |
| Prioritize urgent work | runOutsideAngular, signals | `startTransition`, `useDeferredValue` |
| Less client JS | lazy routes, zoneless, SSR | code split, RSC, streaming SSR |
| Long lists | CDK Virtual Scroll | react-window |

> The framework changes the *lever name*, not the *principle*: do less work, only when needed, off the critical path.

---

## Mental Models

### Change Detection = A Security Guard's Rounds
Default Angular CD is a guard checking *every* room on every alarm. OnPush gives each room a sensor so the guard only checks rooms that actually changed. Signals go further — the room reports exactly what changed.

### React Re-renders = Ripples in a Pond
A state change drops a stone; ripples spread to all children by default. `memo`/`useMemo`/`useCallback` are breakwaters that stop ripples where nothing actually changed.

### Keys/trackBy = Name Tags
Without name tags, the framework can't tell which list item is which, so it rebuilds them all on any change. Stable IDs let it recognize and reuse the ones that didn't change.

### Signals = A Smart Thermostat
Instead of re-surveying the whole house's temperature on every event (Zone.js), a signal-driven system reacts only to the specific sensor that changed — minimal, precise updates.

---

## Common Mistakes

### Mistake 1 (Angular): Default CD Everywhere
❌ Whole-tree checks on every event
✅ OnPush + immutable data; adopt signals

### Mistake 2 (Angular): Function Calls in Templates
❌ `{{ compute() }}` runs every CD cycle
✅ Pure pipes, signals, or precomputed values

### Mistake 3 (Angular): No trackBy
❌ Re-creates all DOM rows on array change
✅ `track`/`trackBy` by stable id

### Mistake 4 (React): Unstable Props Breaking memo
❌ Inline objects/functions as props
✅ `useMemo`/`useCallback` for stable references

### Mistake 5 (React): index as key
❌ `key={index}` breaks reconciliation on reorder
✅ Stable unique keys

### Mistake 6 (Both): Not Lazy-Loading / Virtualizing
❌ Eager big modules; rendering huge lists
✅ Lazy routes/components; virtualize long lists

### Mistake 7 (Both): Heavy Work in Render/CD Path
❌ Expensive computation on every render/CD
✅ Memoize, precompute, or offload to workers

---

## Interview Questions

### Q1: How does Angular change detection work, and how do you optimize it?
**Answer:** Angular uses Zone.js to patch async APIs — events, timers, XHR/fetch, promises — so that after any async activity it runs change detection, walking the component tree and checking template bindings. With the default strategy it checks the entire tree on every event, which is wasteful in large apps. The primary optimization is the OnPush strategy, which only re-checks a component when an input reference changes, an event fires from it, a bound observable emits via the async pipe, or you call `markForCheck` — so it relies on immutable data updates. I pair OnPush with `trackBy`/`track` on lists to avoid DOM churn, avoid function calls in templates (they run every cycle), use `runOutsideAngular` for hot non-UI loops, and adopt signals for fine-grained reactivity. The strategic direction is signals plus zoneless change detection, which removes Zone.js overhead entirely.

### Q2: What are Angular signals and why do they matter for performance?
**Answer:** Signals are Angular's reactive primitive — a `signal` holds a value, `computed` derives from signals and recomputes only when dependencies change, and `effect` reacts to changes. They matter because they enable fine-grained reactivity: instead of Zone.js triggering a tree-wide change detection pass on every async event, the framework can update precisely the views that depend on the signal that changed. This reduces wasted work dramatically in large apps. Signals are also the foundation for zoneless change detection, where Angular drops Zone.js entirely — yielding a smaller bundle and less runtime overhead, with updates driven by signals and events. For new code I prefer signals for state, combined with OnPush, as the modern high-performance pattern.

### Q3: Why does a React component re-render unnecessarily, and how do you prevent it?
**Answer:** By default, when a component re-renders, React re-renders all of its children regardless of whether their props actually changed, so re-renders cascade down the tree; this is compounded when parents pass newly-created objects, arrays, or functions as props on every render, defeating any child optimization. I prevent unnecessary re-renders with `React.memo` to skip a child when its props are shallow-equal, `useMemo` to cache expensive computed values, and `useCallback` to keep function identities stable so memoized children don't re-render. I also use stable unique keys in lists, split large frequently-changing contexts (or use selector-based state libraries) to avoid re-rendering all consumers, and keep expensive work out of render. I'm careful not to over-memoize, since memoization has its own cost; React 19's compiler automates much of this.

### Q4: What are React's concurrent features and how do they help performance?
**Answer:** React 18's concurrent rendering lets React interrupt and prioritize rendering work instead of doing it all synchronously. `useTransition`/`startTransition` mark state updates as non-urgent, so urgent updates like typing stay responsive while expensive re-renders (filtering a big list) are de-prioritized — directly improving INP. `useDeferredValue` defers re-rendering of expensive derived UI until the browser has capacity, keeping input snappy. Streaming SSR with Suspense sends HTML progressively for faster TTFB and LCP, and selective hydration hydrates interactive parts first. Together these keep the main thread responsive to the user by yielding and prioritizing, which is exactly what good INP requires. The mental model is telling React what's urgent versus what can wait.

### Q5: How would you optimize a slow Angular application?
**Answer:** I'd start by measuring to find whether it's a load or runtime problem, then apply the right levers. For runtime/change detection: convert hot components to OnPush with immutable data, add `trackBy`/`track` to lists, remove function calls and heavy getters from templates, run hot non-UI loops with `runOutsideAngular`, virtualize long lists with CDK Virtual Scroll, and adopt signals (and consider zoneless) for fine-grained updates. For load/bundle: lazy-load routes with `loadChildren`, use standalone components, ensure production AOT builds, analyze the bundle (`build:stats` → `analyze:mfe1`) to remove heavyweight dependencies, enforce budgets in `angular.json`, and add SSR/prerendering for better LCP and SEO. I'd also fix memory leaks via the async pipe or `takeUntilDestroyed`. Throughout, I re-measure to confirm each change and gate regressions with CI budgets.

### Q6: Same performance principles, different frameworks — how do Angular and React compare?
**Answer:** The underlying principle is identical: do less work, only when needed, and off the critical path. The frameworks just expose different levers. To avoid wasted updates, Angular uses OnPush plus immutability or signals, while React uses `React.memo`, `useMemo`, and `useCallback`. For efficient lists, Angular uses `track`/`trackBy` and React uses stable keys. For prioritizing urgent work, Angular offers `runOutsideAngular` and signal-driven updates, React offers `startTransition` and `useDeferredValue`. For shipping less client JS, Angular uses lazy routes, zoneless, and SSR, while React uses code splitting, Server Components, and streaming SSR. Both virtualize long lists. So at architect level I reason in principles — minimize change detection/re-renders, virtualize, split, and offload — and translate them into whichever framework's idioms the team uses.

---

## Key Takeaways

- **Framework overhead (change detection / re-renders) is the dominant runtime cost**
- **Angular:** OnPush + immutability is foundational; add `trackBy`, avoid template function calls
- **Angular's future:** signals + zoneless for fine-grained, low-overhead updates
- **React:** prevent cascading re-renders with `memo`/`useMemo`/`useCallback` + stable keys
- **React concurrency:** `startTransition`/`useDeferredValue` improve INP; RSC ships less JS
- **Both:** lazy-load routes/components, virtualize long lists, offload heavy work
- **Same principles, different levers** — reason in principles, apply framework idioms
- **Enforce bundle budgets** (`angular.json` / CI) and analyze regularly

---

## What's Next?

You can optimize across the whole stack — the final piece is making it **stick** across teams and time:
- **[Budgets & Governance →](./budgets-governance.md)** — performance budgets, CI gates, monitoring, culture

---

[← Runtime & Rendering](./runtime-rendering.md) | [Budgets & Governance →](./budgets-governance.md)
