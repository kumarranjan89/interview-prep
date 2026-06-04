# MFE Composition & Routing

How micro-frontends are composed into one app and how routing works across team boundaries.

---

## Navigation
[← Concepts (Architecture)](./concepts.md) | [Shared State →](./shared-state.md)

---

## The Two Big Questions

When you split a UI across teams, you must answer:
1. **Composition** — how do the separate apps become one page?
2. **Routing** — how does navigation work across independently deployed apps?

---

## Composition Strategies

```
┌──────────────────────────────────────────────────────────┐
│ 1. BUILD-TIME    bundle MFEs together at build (npm)       │
│ 2. SERVER-SIDE   compose HTML on the server (SSI/edge)     │
│ 3. CLIENT-SIDE   compose in the browser at runtime         │
│ 4. EDGE-SIDE     compose at the CDN/edge (ESI)             │
└──────────────────────────────────────────────────────────┘
```

### 1. Build-Time Composition
MFEs published as npm packages, installed and built into the host.
```
✅ Simple, type-safe, fast runtime
❌ NOT independent deployment — rebuild host on every MFE change
```
> This is technically "components," not true MFE. Avoid if independent deploy is the goal.

### 2. Server-Side Composition (SSR / SSI)
Server stitches HTML fragments from each MFE before sending to the browser.
```
✅ Great SEO, fast first paint, works without JS
❌ Server complexity, harder client interactivity
```
Tools: Tailor, Podium, Nginx SSI, frameworks with SSR.

### 3. Client-Side Composition (most common)
The host (shell) loads MFEs in the browser at runtime, usually via **Module Federation**.
```
✅ True independent deployment, rich interactivity, team autonomy
❌ Larger JS, runtime coordination, loading states needed
```
> This is what your Angular `app-shell` + `mfe1` setup uses.

### 4. Edge-Side Composition (ESI)
CDN/edge workers assemble fragments close to the user.
```
✅ Performance of SSR + CDN scale
❌ Edge infra complexity, vendor-specific
```

---

## The App Shell Pattern

The dominant client-side architecture (and your project's model):

```
┌─────────────────────────────────────────────────┐
│                  APP SHELL (Host)                │
│  ┌───────────────────────────────────────────┐  │
│  │  Global Header / Nav (owned by shell)     │  │
│  ├───────────────────────────────────────────┤  │
│  │                                           │  │
│  │   <router-outlet> ← MFE mounts here       │  │
│  │   ┌─────────────┐   ┌─────────────────┐   │  │
│  │   │   mfe1      │   │   mfe2          │   │  │
│  │   │ (Team A)    │   │  (Team B)       │   │  │
│  │   └─────────────┘   └─────────────────┘   │  │
│  │                                           │  │
│  ├───────────────────────────────────────────┤  │
│  │  Global Footer (owned by shell)           │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

**Shell responsibilities:**
- Global layout (header, nav, footer)
- Top-level routing → mounts the right MFE
- Cross-cutting concerns: auth, theming, telemetry, error boundaries
- Loading the remotes

**MFE responsibilities:**
- Own their feature area end-to-end
- Internal (child) routing
- Their own state and data fetching

---

## Routing Across Micro-Frontends

The challenge: **one URL bar, multiple independently deployed routers.**

### Two-Level Routing Model
```
Shell router (top-level):
  /dashboard/**  → load mfe1
  /orders/**     → load mfe2
  /settings/**   → load mfe3

MFE router (child-level, inside mfe1):
  /dashboard         → overview
  /dashboard/reports → reports
  /dashboard/:id     → detail
```

The shell routes by **prefix** to the correct MFE; the MFE handles everything under that prefix.

### Angular Example (Shell)
```typescript
const routes: Routes = [
  {
    path: "dashboard",   // prefix owned by mfe1
    loadChildren: () =>
      loadRemoteModule({
        type: "module",
        remoteEntry: "http://localhost:4201/remoteEntry.js",
        exposedModule: "./Dashboard",
      }).then((m) => m.DashboardModule),
  },
  {
    path: "orders",      // prefix owned by mfe2
    loadChildren: () =>
      loadRemoteModule({
        type: "module",
        remoteEntry: "http://localhost:4202/remoteEntry.js",
        exposedModule: "./Orders",
      }).then((m) => m.OrdersModule),
  },
];
```

### Angular Example (MFE child routes)
```typescript
// mfe1 owns everything under /dashboard
const routes: Routes = [
  { path: "", component: OverviewComponent },
  { path: "reports", component: ReportsComponent },
  { path: ":id", component: DetailComponent },
];

@NgModule({
  imports: [RouterModule.forChild(routes)],  // forChild, not forRoot
  exports: [RouterModule],
})
export class DashboardModule {}
```

---

## Routing Pitfalls & Solutions

### Pitfall 1: Multiple Router Instances
With one framework router shared as a **singleton**, the shell and MFEs cooperate on one router. Without singleton sharing, you get competing routers fighting over the URL.
```
✅ Share @angular/router as singleton (Module Federation)
```

### Pitfall 2: Route Conflicts
Two MFEs claim overlapping paths.
```
✅ Governance: assign each team a unique URL prefix namespace
   Team A → /dashboard/*   Team B → /orders/*
```

### Pitfall 3: Deep Linking / Refresh
Refreshing on `/dashboard/reports` must load the shell, then mfe1, then the child route.
```
✅ Server: SPA fallback (serve index.html for all routes)
✅ Shell: lazy-load the matching remote before resolving child route
```

### Pitfall 4: Cross-MFE Navigation
Team A's MFE needs to navigate into Team B's MFE.
```
✅ Navigate by URL (router.navigate(['/orders', id])) — never import
   another MFE's components directly. The URL is the contract.
```

---

## Cross-Framework Composition

When MFEs use different frameworks (React + Angular + Vue), use **Web Components** as the interop boundary:

```typescript
// Wrap an Angular/React MFE as a custom element
// Host mounts it framework-agnostically:
<feature-dashboard user-id="123"></feature-dashboard>
```
- Pass data **down** via attributes/properties
- Communicate **up** via custom DOM events
- Each MFE bootstraps its own framework internally

Tools: Angular Elements, React + `react-to-webcomponent`, Vue `defineCustomElement`.

---

## Loading & Error States

Runtime composition means MFEs can be slow or fail to load. The shell must handle this:

```typescript
// React: error boundary + suspense around remotes
<ErrorBoundary fallback={<MfeUnavailable name="Dashboard" />}>
  <Suspense fallback={<Skeleton />}>
    <RemoteDashboard />
  </Suspense>
</ErrorBoundary>
```
- **Loading:** skeletons/spinners while `remoteEntry.js` + chunks load
- **Error:** isolate failures so one broken MFE doesn't crash the shell
- **Retry / fallback:** offer reload or a degraded experience

> A broken remote should degrade gracefully, never white-screen the whole app.

---

## Mental Models

### Shell = Picture Frame, MFEs = Photos
The shell provides the frame (nav, layout, cross-cutting concerns). MFEs are interchangeable photos slotted into the frame. You can swap a photo (deploy an MFE) without rebuilding the frame.

### URL = The Contract Between Teams
Teams don't import each other's code; they agree on URL prefixes. Navigating to `/orders/42` is an API call to Team B — the URL is the integration contract.

### Routing = Air Traffic Control
The shell router is ATC: it directs each request to the correct runway (MFE). Once landed, the MFE's own router taxis it to the right gate (child route).

---

## Common Mistakes

### Mistake 1: Importing Another MFE's Components
❌ Tight coupling defeats independent deployment
✅ Communicate via URL navigation and events; the URL is the contract

### Mistake 2: No Prefix Namespacing
❌ Route collisions between teams
✅ Assign each team a unique URL prefix

### Mistake 3: Build-Time Composition Called "MFE"
❌ npm packages rebuilt into host → not independent
✅ Use runtime composition for true independent deploy

### Mistake 4: No SPA Fallback
❌ Deep-link refresh → 404
✅ Server serves index.html for all client routes

### Mistake 5: No Error Isolation
❌ One failed remote white-screens the app
✅ Error boundaries + fallback UI per MFE

### Mistake 6: Sharing the Shell's Layout Into MFEs
❌ MFEs re-render header/footer → duplication, drift
✅ Shell owns global chrome; MFEs own only their feature

---

## Interview Questions

### Q1: What are the main micro-frontend composition strategies and their trade-offs?
**Answer:** Four main strategies. Build-time composition bundles MFEs as npm packages into the host — simple and type-safe but not truly independent since you rebuild the host on every change. Server-side composition stitches HTML fragments on the server — great for SEO and first paint but adds server complexity. Client-side composition loads MFEs in the browser at runtime (typically via Module Federation) — enables true independent deployment and rich interactivity at the cost of more JS and runtime coordination. Edge-side composition assembles fragments at the CDN/edge — combines SSR performance with CDN scale but needs edge infrastructure. Most modern MFE setups use client-side composition with an app shell; SSR/edge are chosen when SEO and first-paint are critical.

### Q2: How does routing work across micro-frontends?
**Answer:** With a two-level model. The shell (host) owns top-level routing and routes by URL prefix to the correct MFE — for example `/dashboard/**` loads MFE A and `/orders/**` loads MFE B. Each MFE then owns all child routing under its prefix using its own router (in Angular, `forChild`). The framework router is shared as a singleton so the shell and MFEs cooperate on a single URL state instead of fighting over it. Teams get a namespaced prefix to avoid collisions, and cross-MFE navigation happens by URL (`router.navigate`), never by importing another MFE's components — the URL is the contract.

### Q3: How do you compose micro-frontends built with different frameworks?
**Answer:** Use Web Components (custom elements) as a framework-agnostic interop boundary. Each MFE bootstraps its own framework internally but exposes a custom element like `<feature-dashboard>` that the shell can mount regardless of its own framework. Data flows down via attributes/properties and up via custom DOM events, keeping a clean, standards-based contract. Tools like Angular Elements, react-to-webcomponent, and Vue's defineCustomElement enable this. The trade-off is some overhead and the need to manage multiple framework runtimes, so I'd prefer a single framework when possible and reserve cross-framework composition for genuine multi-team, multi-stack situations.

### Q4: How do you handle deep linking and page refresh in an MFE app?
**Answer:** Two things must work together. On the server, configure an SPA fallback so any deep URL (e.g., `/dashboard/reports`) serves the shell's `index.html` rather than 404ing. In the client, the shell must lazy-load the matching remote for that prefix before resolving the child route, so on refresh it fetches `remoteEntry.js`, mounts the MFE, and the MFE's router resolves the remaining path. Sharing the router as a singleton ensures the URL state is consistent. This guarantees a refresh or shared link reconstructs the exact view across shell and MFE.

### Q5: How do you prevent one failing micro-frontend from breaking the whole app?
**Answer:** Error isolation at the composition boundary. The shell wraps each remote in an error boundary (React) or equivalent guard so a runtime failure in one MFE renders a fallback UI instead of crashing the shell. Combine with Suspense/loading skeletons while remotes load, retry options, and graceful degradation (hide or replace the broken feature). On the network side, handle `remoteEntry.js` load failures explicitly. The principle is that runtime composition introduces partial-failure modes, so the shell must treat every remote as potentially unavailable and contain the blast radius.

### Q6: Why is the URL the "contract" between micro-frontends?
**Answer:** Because micro-frontends must stay decoupled to deploy independently. If Team A imports Team B's components directly, they're build-coupled and lose independence. Instead, teams agree on URL prefixes and navigate between features by URL — navigating to `/orders/42` is effectively an API call into Team B's MFE, which owns how that route renders. This keeps integration loose, lets each team refactor internals freely, and makes the system composable. The URL (plus shared events/state contracts) is the stable, public interface between otherwise independent applications.

---

[← Concepts (Architecture)](./concepts.md) | [Shared State →](./shared-state.md)
