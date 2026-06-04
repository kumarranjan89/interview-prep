# MFE Shared State & Communication

How independently deployed micro-frontends coordinate — **concepts first**, then implementation patterns and tools.

---

## Navigation
[← Composition & Routing](./composition-routing.md) | [Module Federation / Tooling →](./module-federation.md)

---

## PART 1 — CONCEPTS (Tool-Agnostic)

### The Core Tension
Micro-frontends exist to **decouple** teams, yet a real product needs them to **coordinate** — the logged-in user, cart count, theme, locale. The architecture's job is to enable coordination **without re-coupling** what decomposition separated.

```
Too little coordination:        Too much coordination:
  duplicated/inconsistent          shared global mutable store →
  user state, broken UX            distributed monolith
              ↘             ↙
       Right balance: minimal, explicit, versioned contracts
```

> **Golden rule:** share as little as possible, through explicit contracts. Prefer **messages over shared mutable memory**, and **URLs over both**.

---

### The Coupling Spectrum (The Mental Backbone)

Every communication choice sits on a spectrum. An architect always reaches for the **loosest** option that satisfies the requirement.

```
LOOSE ───────────────────────────────────────────────► TIGHT
  URL /        Custom        Pub/Sub        Shared       Direct
  routing      DOM events    event bus      state store  import
  (best)       (good)        (good)         (careful)    (avoid)

  loose coupling, independent deploy  →  tight coupling, joint deploy
```

- **Looser = more independent deployment, harder to share rich/live data.**
- **Tighter = easier data sharing, but erodes the independence you built MFE for.**

---

### Conceptual Communication Channels

#### 1. The URL as Contract (loosest)
Navigation *is* communication. Routing to another MFE's path is like calling its public API; state travels via route/query params.
- **Use for:** navigation, deep-linkable state, cross-MFE transitions.
- **Why best:** zero shared code, fully decoupled, survives refresh, debuggable.

#### 2. Events / Messaging (choreography)
Fire-and-forget notifications: "something happened" (user logged out, item added). Publishers don't know subscribers.
- **Use for:** reactive cross-cutting signals.
- **Why good:** no shared types or runtime, no central owner — true choreography.

#### 3. Shared State (orchestration — use sparingly)
A small, **read-mostly** slice of genuinely cross-cutting state: **auth/session, theme, locale, feature flags**.
- **Use for:** data many MFEs need *now* and *live*.
- **Discipline:** treat as a **published contract** with a clear owner; never a free-for-all global store.

#### 4. Direct Import (tightest — avoid)
One MFE imports another's components/modules.
- **Why avoid:** build-time coupling → joint deployment → distributed monolith.
- **Exception:** importing from a **shared library/design system**, which is a deliberately shared, versioned artifact — not another MFE.

---

### State Ownership Model (Who Owns What)

```
┌─────────────────────────────────────────────────────────┐
│ PLATFORM / SHELL STATE  (shared contract, read-mostly)   │
│   auth/session, theme, locale, feature flags, user prefs │
├─────────────────────────────────────────────────────────┤
│ MFE-LOCAL STATE  (private, owned end-to-end by the team) │
│   form state, domain data, view state, caches            │
└─────────────────────────────────────────────────────────┘
```

**Principles:**
- **Default to local.** Most state belongs *inside* one MFE and never leaves.
- **Promote to shared only when truly cross-cutting** — and then give it a single owner (usually the shell/platform).
- **Server state is its own category** — often best synchronized via the **backend + caching** (e.g., each MFE fetches with a shared cache key) rather than passed between MFEs in the browser.

---

### Choreography vs Orchestration

```
Choreography (preferred):          Orchestration:
  MFEs react to events             a central controller tells
  independently; no central        MFEs what to do; shared brain
  brain → loose coupling           → coupling + single bottleneck
```

Prefer **choreography** (events). Reserve light **orchestration** (shell coordinating) for genuine cross-cutting concerns like auth — and keep that surface minimal.

---

### Conceptual Anti-Patterns
- **The God Store** — one global Redux/NgRx store all MFEs read/write → distributed monolith.
- **Chatty MFEs** — boundaries so fine that MFEs constantly exchange state → wrong decomposition.
- **Shared mutable singletons** — implicit coupling no one can see in the dependency graph.
- **Type-coupled events** — events carrying shared TS types → rebuild everyone on change. Use stable, versioned payload schemas instead.

---

## PART 2 — IMPLEMENTATION (How Tools Achieve It)

The concepts above map to concrete mechanisms. Choose the lightest that meets the need.

### Pattern A: URL / Router (implements "URL as contract")
```typescript
// Cross-MFE navigation by URL — never import the other MFE
// Shell shares the framework router as a singleton so URL state is unified.
router.navigate(['/orders', orderId], { queryParams: { ref: 'dashboard' } });
```
- Tooling: framework router shared as a **singleton** (see Module Federation tooling).
- State that must survive refresh/deep-link → put it in the URL.

### Pattern B: Custom DOM Events (implements "events", framework-agnostic)
```typescript
// Publisher (any MFE) — uses the browser, no shared library needed
window.dispatchEvent(new CustomEvent('cart:item-added', {
  detail: { sku: 'ABC-123', qty: 2 },   // stable, versioned payload schema
}));

// Subscriber (any MFE, any framework)
window.addEventListener('cart:item-added', (e: Event) => {
  const { sku, qty } = (e as CustomEvent).detail;
  // react locally
});
```
- **Pro:** zero shared code, works across React/Angular/Vue, naturally decoupled.
- **Contract:** document event names + payload schemas; version them (`cart:item-added@v1`).

### Pattern C: A Tiny Pub/Sub Event Bus (implements "messaging" with structure)
```typescript
// A minimal, shared-library event bus (versioned, typed at the edges)
type Handler<T> = (payload: T) => void;

class EventBus {
  private channels = new Map<string, Set<Handler<any>>>();
  on<T>(event: string, handler: Handler<T>) {
    if (!this.channels.has(event)) this.channels.set(event, new Set());
    this.channels.get(event)!.add(handler);
    return () => this.channels.get(event)!.delete(handler); // unsubscribe
  }
  emit<T>(event: string, payload: T) {
    this.channels.get(event)?.forEach((h) => h(payload));
  }
}
// Exposed once by the shell/platform and shared as a singleton.
export const bus = new EventBus();
```
- Use when you want structured channels, replay, or logging beyond raw DOM events.
- Keep the bus tiny and **owned by the platform**; ship it as a versioned shared lib.

### Pattern D: Shared Observable State (implements "minimal shared state")
```typescript
// Shell-owned, read-mostly session state exposed as an observable contract.
// Consumers SUBSCRIBE; only the owner MUTATES.
import { BehaviorSubject } from 'rxjs';

export interface SessionState { userId: string; roles: string[]; theme: 'light' | 'dark'; }

class SessionStore {
  private state$ = new BehaviorSubject<SessionState | null>(null);
  readonly changes = this.state$.asObservable();      // public: read
  setSession(s: SessionState) { this.state$.next(s); } // owner-only: write
}
export const session = new SessionStore(); // shared as singleton by the shell
```
- MFEs **subscribe** to `session.changes`; they do **not** mutate it.
- Framework-agnostic via RxJS/observables, or a signals-based equivalent.
- This is the *only* place shared mutable-ish state should live — and it's small and owned.

### Pattern E: Web Component Props/Events (implements "down/up" across frameworks)
```html
<!-- Shell passes data DOWN via attributes/props, receives UP via events -->
<feature-orders user-id="123"></feature-orders>
<script>
  const el = document.querySelector('feature-orders');
  el.addEventListener('order:placed', (e) => {/* react */});
</script>
```
- Clean contract when one MFE embeds another, especially cross-framework.

### Pattern F: Server/Backend as the Sync Point (for server state)
```
Each MFE fetches its own data, but they share a cache key / BFF
→ consistency comes from the backend + HTTP cache, not browser state-passing
```
- Often the **cleanest** way to keep domain/server data consistent without frontend coupling.

---

### Choosing a Pattern (Decision Guide)
| Need | Use |
|------|-----|
| Navigate / deep-linkable state | **URL / router** (Pattern A) |
| One-off cross-cutting signal, cross-framework | **Custom DOM events** (B) |
| Structured channels, logging/replay | **Event bus** (C) |
| Live cross-cutting state (auth/theme/locale) | **Shared observable, shell-owned** (D) |
| Embedding another MFE (esp. cross-framework) | **Web component props/events** (E) |
| Consistent server/domain data | **Backend + shared cache / BFF** (F) |

> Anything tighter than these — direct imports of another MFE's internals — should be refactored into a **shared library** or replaced with a contract.

---

## Mental Models

### Shared State = Shared Bank Account
Convenient but dangerous: anyone can drain it, no one knows who did. Give each MFE its own account (local state) and exchange **messages** (events) about transactions instead.

### Events = Radio Broadcast
The publisher broadcasts; it doesn't know or care who's listening. Stations (MFEs) tune in to channels they care about. No direct wiring, no coupling.

### The URL = Public API
An MFE's routes are its public, versioned API. Pass state through it like query/path params and it survives refresh, deep links, and team refactors.

### Shared Lib vs Another MFE
Importing a *design-system button* is fine — it's a deliberately shared, versioned artifact. Importing *another MFE's order page* is not — it's trespassing that forces joint deployment.

---

## Common Mistakes

### Mistake 1: The God Store
❌ One global store all MFEs read/write → distributed monolith
✅ Local-by-default; tiny shell-owned shared slice for cross-cutting only

### Mistake 2: Sharing Mutable State Everywhere
❌ Every MFE mutates shared state → unpredictable, untraceable
✅ Read-mostly contract: owner writes, others subscribe

### Mistake 3: Type-Coupled Events
❌ Events carry shared TS types → rebuild everyone on change
✅ Stable, versioned payload schemas (`event@v1`)

### Mistake 4: Direct Imports Between MFEs
❌ Build coupling → joint deployment
✅ Communicate via URL/events; extract truly shared code to a versioned lib

### Mistake 5: Putting Server State in Browser-Shared State
❌ Passing fetched domain data between MFEs in memory
✅ Sync via backend/BFF + shared HTTP cache

### Mistake 6: No Owner for Shared State
❌ Ambiguous ownership → drift and conflicts
✅ One clear owner (shell/platform) publishes the contract

---

## Interview Questions

### Q1: How should micro-frontends share state without coupling?
**Answer:** I think in terms of a coupling spectrum and always pick the loosest mechanism that meets the need. Most state should be **local** to a single MFE and never shared. For coordination, I prefer the URL as a contract (navigation and deep-linkable state), then fire-and-forget events for cross-cutting signals. Only genuinely cross-cutting, live state — auth/session, theme, locale, feature flags — goes into a small **shared store owned by the shell**, exposed as a read-mostly contract where the owner writes and others subscribe. I avoid a global mutable store that every MFE reads and writes, since that recreates a distributed monolith. Server/domain data is best kept consistent via the backend and a shared cache rather than passing it between MFEs in the browser.

### Q2: What's the difference between choreography and orchestration here, and which do you prefer?
**Answer:** Choreography means MFEs react independently to events with no central controller — publishers emit, subscribers respond, nobody coordinates. Orchestration means a central brain tells MFEs what to do. I prefer choreography because it preserves loose coupling and independent deployment: there's no shared controller to become a bottleneck or a coupling point. I reserve light orchestration for legitimate cross-cutting concerns the shell must own, like propagating auth/session changes, and I keep that surface as small as possible. Over-orchestrating is a common way teams accidentally rebuild a monolith with extra network hops.

### Q3: Why are custom DOM events a good cross-framework communication mechanism?
**Answer:** Custom DOM events use a browser-native primitive, so they require no shared library or runtime and work identically whether the publisher and subscriber are React, Angular, or Vue. The publisher dispatches an event with a payload and doesn't know who listens, giving true fire-and-forget decoupling. To keep them safe as a contract, I document event names and payload schemas and version them (e.g., `cart:item-added@v1`) so changing a payload doesn't silently break consumers. The main caveats are that they're ephemeral (no replay) and untyped at the boundary, so for structured channels with logging or replay I'd introduce a small shell-owned event bus instead.

### Q4: When is shared state justified, and how do you keep it safe?
**Answer:** Shared state is justified only for data that is genuinely cross-cutting and needed live by multiple MFEs — typically authentication/session, theme, locale, and feature flags. I keep it safe with strict discipline: a single owner (the shell/platform) publishes it as a read-mostly contract, usually an observable or signal; consuming MFEs subscribe but never mutate it; the shape is a versioned contract, not an ad-hoc object; and the surface stays deliberately small. This avoids the "God store" anti-pattern where every MFE reads and writes shared memory, which destroys traceability and independent deployment. Everything else stays local to the owning MFE.

### Q5: How do you keep server/domain data consistent across MFEs?
**Answer:** I avoid passing fetched domain data between MFEs in browser memory, since that couples them and creates stale-data bugs. Instead I treat the backend as the source of truth and synchronize through it: each MFE fetches the data it needs, ideally through a shared cache layer or a Backend-for-Frontend with consistent cache keys and invalidation, so they converge on the same server state. Cross-cutting *events* (e.g., `order:placed`) can prompt MFEs to refetch or invalidate their caches. This keeps consistency a backend concern rather than a fragile frontend state-passing exercise, and it preserves MFE independence.

### Q6: What is the "God store" anti-pattern and how do you prevent it?
**Answer:** The God store is a single global state store (e.g., one shared Redux/NgRx instance) that every micro-frontend reads from and writes to. It feels convenient but it tightly couples all MFEs to a shared schema and to each other's mutations, so they can no longer evolve or deploy independently — the classic distributed monolith. I prevent it by defaulting state to MFE-local, restricting shared state to a tiny, read-mostly, shell-owned contract for cross-cutting concerns, communicating via URL and events instead of shared memory, and extracting any genuinely common logic into a versioned shared library rather than a shared mutable store. The test is whether a team can change its internal state without coordinating with others — if not, the store has become a coupling point.

---

## Key Takeaways

- **Share as little as possible, via explicit contracts** — messages over memory, URLs over both
- **Coupling spectrum:** URL → events → event bus → shared state → (avoid) direct import
- **Default to local state;** promote to shared only for cross-cutting, live data
- **Shared state must be read-mostly with a single (shell) owner** — never a God store
- **Prefer choreography (events) over orchestration** (central brain)
- **Server/domain data syncs via the backend/BFF + cache**, not browser state-passing
- **Version event payloads and shared contracts** to avoid coupling everyone to a change

---

[← Composition & Routing](./composition-routing.md) | [Module Federation / Tooling →](./module-federation.md)
