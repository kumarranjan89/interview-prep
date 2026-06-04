# Module Federation

The core technology behind modern micro-frontends. Deep dive for staff/principal frontend interviews.

---

## Navigation
[← Shared State](./shared-state.md) | [Governance →](./governance.md)

---

## What Is Module Federation?

**Simple meaning:** Module Federation (MF) is a Webpack 5 feature that lets a JavaScript application **load code from another independently deployed application at runtime** — not at build time.

```
Build-time sharing (old way):       Runtime sharing (Module Federation):
  npm publish → npm install →         App A loads App B's code over the
  rebuild everything                  network, live, no rebuild of A
```

**The key shift:**
> Before MF, sharing code meant publishing npm packages and rebuilding all consumers. With MF, a remote app exposes modules that host apps consume at runtime — each deploys independently.

---

## Core Vocabulary

| Term | Meaning |
|------|---------|
| **Host (Shell)** | The app that consumes remote modules (the container). |
| **Remote** | An app that exposes modules to be consumed. |
| **Exposes** | The modules a remote makes available (e.g., `./Component`). |
| **Remotes** | The map of remote apps a host can load. |
| **Shared** | Dependencies shared between host and remotes (e.g., React, Angular). |
| **Container** | The compiled entry (`remoteEntry.js`) that describes a remote. |
| **Bidirectional** | An app can be both a host AND a remote. |

---

## How It Works (Mental Model)

```
        ┌─────────────────────────────────┐
        │           HOST (Shell)          │
        │   localhost:4200                │
        │                                 │
        │  "I need mfe1's Dashboard"      │
        └───────────────┬─────────────────┘
                        │ fetch remoteEntry.js at runtime
                        ▼
        ┌─────────────────────────────────┐
        │        REMOTE (mfe1)            │
        │   localhost:4201                │
        │   remoteEntry.js                │
        │   exposes: ./Dashboard          │
        └─────────────────────────────────┘

   Shared scope: Angular/React loaded ONCE, reused by both
```

1. The remote builds a **`remoteEntry.js`** manifest describing its exposed modules.
2. The host declares the remote's URL and imports exposed modules dynamically.
3. At runtime, the host fetches `remoteEntry.js`, then loads only the needed chunks.
4. **Shared dependencies** are negotiated so a single copy is used when versions are compatible.

---

## Webpack Configuration

### Remote (`mfe1/webpack.config.js`)
```javascript
const { ModuleFederationPlugin } = require("webpack").container;

module.exports = {
  output: {
    publicPath: "auto",          // critical for correct chunk URLs
  },
  plugins: [
    new ModuleFederationPlugin({
      name: "mfe1",              // unique remote name
      filename: "remoteEntry.js", // the manifest consumers load
      exposes: {
        "./Dashboard": "./src/app/dashboard/dashboard.module.ts",
      },
      shared: {
        "@angular/core": { singleton: true, strictVersion: true, requiredVersion: "auto" },
        "@angular/common": { singleton: true, strictVersion: true, requiredVersion: "auto" },
        "@angular/router": { singleton: true, strictVersion: true, requiredVersion: "auto" },
        rxjs: { singleton: true, requiredVersion: "auto" },
      },
    }),
  ],
};
```

### Host (`app-shell/webpack.config.js`)
```javascript
const { ModuleFederationPlugin } = require("webpack").container;

module.exports = {
  plugins: [
    new ModuleFederationPlugin({
      name: "shell",
      remotes: {
        // static: name → URL of the remoteEntry
        mfe1: "mfe1@http://localhost:4201/remoteEntry.js",
      },
      shared: {
        "@angular/core": { singleton: true, strictVersion: true, requiredVersion: "auto" },
        "@angular/common": { singleton: true, strictVersion: true, requiredVersion: "auto" },
        "@angular/router": { singleton: true, strictVersion: true, requiredVersion: "auto" },
        rxjs: { singleton: true, requiredVersion: "auto" },
      },
    }),
  ],
};
```

---

## Consuming a Remote

### React (dynamic import)
```typescript
// Host: lazy-load a remote component
import React, { lazy, Suspense } from "react";

// "mfe1/Dashboard" = <remoteName>/<exposedKey>
const Dashboard = lazy(() => import("mfe1/Dashboard"));

export function App() {
  return (
    <Suspense fallback={<div>Loading dashboard…</div>}>
      <Dashboard />
    </Suspense>
  );
}
```

### Angular (lazy-loaded route with @angular-architects/module-federation)
```typescript
// Host: app-routing.module.ts
import { loadRemoteModule } from "@angular-architects/module-federation";

const routes: Routes = [
  {
    path: "dashboard",
    loadChildren: () =>
      loadRemoteModule({
        type: "module",
        remoteEntry: "http://localhost:4201/remoteEntry.js",
        exposedModule: "./Dashboard",
      }).then((m) => m.DashboardModule),
  },
];
```

### TypeScript typings for remotes
```typescript
// remotes.d.ts — so TS doesn't complain about "mfe1/Dashboard"
declare module "mfe1/Dashboard" {
  const DashboardModule: any;
  export { DashboardModule };
}
```

---

## Shared Dependencies (The Hard Part)

The `shared` config is where most MFE bugs and interview questions live.

### Key Options
| Option | Purpose |
|--------|---------|
| **singleton: true** | Only ONE copy loaded across all apps (mandatory for frameworks like Angular/React). |
| **strictVersion: true** | Throw if versions are incompatible (vs warn). |
| **requiredVersion** | The version the app needs; `"auto"` reads from package.json. |
| **eager: true** | Bundle into the initial chunk instead of loading async (use sparingly). |

### Why `singleton` matters
```
❌ Without singleton:
   Host loads React 18, Remote loads its own React 18
   → two React instances → "Invalid hook call", broken context

✅ With singleton:
   One React instance shared → hooks/context work correctly
```

Frameworks with global state (React's reconciler, Angular's DI/zone, Vue's reactivity) **must** be singletons.

### Version Negotiation
```
Host needs react@18.2.0, Remote needs react@18.3.0
→ MF picks the highest compatible version (18.3.0)
→ With strictVersion, a major mismatch (17 vs 18) throws
```

---

## Static vs Dynamic Remotes

### Static (URL baked at build time)
```javascript
remotes: { mfe1: "mfe1@http://localhost:4201/remoteEntry.js" }
```
Simple, but the URL is fixed — bad for multi-environment (dev/stage/prod).

### Dynamic (URL resolved at runtime) — preferred for production
```typescript
// Resolve remote URLs from config/env at runtime
import { loadRemoteModule, setRemoteUrls } from "@angular-architects/module-federation";

// At app bootstrap, fetch a manifest:
const manifest = await fetch("/assets/mf.manifest.json").then((r) => r.json());
// { "mfe1": "https://cdn.example.com/mfe1/remoteEntry.js" }
```
Lets the same build point to different remote URLs per environment — essential for real deployments.

---

## Module Federation 2.0 / Beyond Webpack

- **@module-federation/enhanced** — runtime plugins, type sharing, manifest, better DX.
- **Vite** — `@originjs/vite-plugin-federation` brings MF to Vite/Rollup.
- **Native Federation** (`@angular-architects/native-federation`) — uses **import maps** + esbuild, framework-agnostic, future-proof (not tied to Webpack internals). Recommended for new Angular MFEs.

---

## Mental Models

### Module Federation = Microservices for the Frontend
Backend microservices call each other's APIs at runtime. MF does the same for UI — apps call each other's *components/modules* at runtime, deploy independently, and scale teams.

### remoteEntry.js = A Restaurant Menu
The host doesn't cook the remote's food — it reads the menu (`remoteEntry.js`) to learn what's available, then orders (loads) only the dishes (modules) it needs.

### Shared Scope = A Shared Pantry
Instead of every app bringing its own flour (React/Angular), they share one pantry. `singleton` ensures there's only one bag of flour, so recipes don't conflict.

---

## Common Mistakes

### Mistake 1: Not Making Frameworks Singletons
❌ Multiple React/Angular copies → hooks/DI break
✅ `singleton: true` for all framework packages

### Mistake 2: Hardcoding Remote URLs
❌ Static remotes → can't switch dev/stage/prod
✅ Dynamic remotes resolved from a runtime manifest

### Mistake 3: Forgetting `publicPath: "auto"`
❌ Remote chunks load from the host's origin → 404s
✅ Set `output.publicPath = "auto"` in remotes

### Mistake 4: Over-Sharing Dependencies
❌ Sharing everything → version negotiation hell, larger initial load
✅ Share only frameworks and truly common libs

### Mistake 5: Eager Loading Everything
❌ `eager: true` on big deps → defeats lazy loading
✅ Use eager only when required at startup (rare)

### Mistake 6: Version Drift Between Teams
❌ Remotes on incompatible Angular majors → runtime crashes
✅ Governance + aligned framework versions (see governance.md)

---

## Interview Questions

### Q1: What is Module Federation and what problem does it solve?
**Answer:** Module Federation is a Webpack 5 capability that lets an application load code from another independently built and deployed application at runtime. It solves the problem of sharing UI code across teams without the tight coupling of build-time npm packages, which require rebuilding and redeploying every consumer on each change. With MF, a "remote" exposes modules via a `remoteEntry.js` manifest, and a "host" consumes them dynamically. This enables independent deployment, team autonomy, and runtime composition — effectively microservices for the frontend.

### Q2: How do shared dependencies work, and why is `singleton` important?
**Answer:** The `shared` config declares dependencies that the host and remotes can share rather than each bundling their own copy. At runtime, MF negotiates versions and loads a compatible shared copy into a shared scope. `singleton: true` forces exactly one instance across all apps, which is mandatory for frameworks like React or Angular that rely on global state — multiple React copies cause "invalid hook call" errors, and multiple Angular instances break dependency injection and zone.js. `strictVersion` makes incompatible versions throw instead of silently misbehaving, and `requiredVersion: "auto"` reads the needed version from package.json.

### Q3: Static vs dynamic remotes — which would you use in production and why?
**Answer:** Static remotes bake the remote URL into the host at build time, which is simple but means the same artifact can't point to different URLs across environments. Dynamic remotes resolve URLs at runtime — typically from a manifest or environment config fetched at bootstrap — so one build can target dev, staging, and prod, and remotes can be relocated (e.g., to a CDN) without rebuilding the host. For production I'd use dynamic remotes with a runtime manifest; it's essential for multi-environment deployments, canary releases, and decoupling host releases from remote URL changes.

### Q4: How do you handle version mismatches between micro-frontends?
**Answer:** Several layers. First, the `shared` config negotiates versions and picks the highest compatible one; `strictVersion` surfaces incompatibilities early. Second, organizational governance aligns framework major versions across teams, since cross-major framework sharing (e.g., Angular 15 vs 16) is risky. Third, for unavoidable divergence, you can scope a dependency as non-singleton so each MFE uses its own copy (acceptable for leaf libraries, not frameworks). Finally, contract testing and a shared dependency policy prevent drift. The goal is a single framework instance with carefully managed, minimal shared surface.

### Q5: What is `publicPath: "auto"` and why does it matter?
**Answer:** `publicPath` tells Webpack where to load async chunks from. In a federated remote, if `publicPath` is wrong, the host tries to fetch the remote's lazy chunks from the host's own origin, causing 404s. Setting `output.publicPath = "auto"` makes the remote infer its public path from where `remoteEntry.js` was loaded, so its chunks resolve against the remote's own origin. It's a small but critical setting that prevents one of the most common "works locally, breaks when deployed" MFE failures.

### Q6: How does Native Federation differ from Webpack Module Federation?
**Answer:** Native Federation (from @angular-architects) provides the same mental model — hosts, remotes, exposes, shared — but is built on web-standard **import maps** and esbuild/rollup rather than Webpack internals. This makes it bundler-agnostic and future-proof, decoupling MFE from Webpack-specific APIs (important as Angular moves to esbuild/Vite). It's the recommended path for new Angular micro-frontends, while classic Webpack Module Federation remains widely used in existing React/Angular setups.

---

## Quick Reference

```javascript
// Remote exposes
new ModuleFederationPlugin({
  name: "mfe1",
  filename: "remoteEntry.js",
  exposes: { "./X": "./src/x.ts" },
  shared: { framework: { singleton: true } },
});

// Host consumes
new ModuleFederationPlugin({
  name: "shell",
  remotes: { mfe1: "mfe1@https://.../remoteEntry.js" },
  shared: { framework: { singleton: true } },
});
```

---

[← Shared State](./shared-state.md) | [Governance →](./governance.md)
