# Micro-Frontend Concepts (Architecture)

Tool-agnostic architectural concepts. This is the *why* and *what* — understand these before any tool. Implementation lives in [Module Federation / Tooling](./module-federation.md).

---

## Navigation
[← MFE Index](../../interview-prep-index.md) | [Composition & Routing →](./composition-routing.md)

---

## What Is a Micro-Frontend? (Conceptual)

**Definition:** A micro-frontend is an architectural style where a frontend is **decomposed into independently developed, tested, and deployed units**, each owned end-to-end by a team, then **composed** into a single user experience.

It is the frontend application of the same forces that produced microservices on the backend: **independent deployability** and **team autonomy at scale.**

> Micro-frontends are an **organizational and architectural** pattern first, a **technical** pattern second. The technology (Module Federation, iframes, web components) is just the mechanism. The real driver is how teams ship.

---

## Why Micro-Frontends Exist (The Forces)

Before the *how*, an architect must articulate the *why*. MFEs solve problems that appear at **organizational scale**, not at small-app scale.

```
Monolith frontend pain at scale:
  - One repo, one pipeline → teams block each other on releases
  - One deploy → a bug in any feature blocks ALL features shipping
  - Tight coupling → refactors ripple across teams
  - Shared release train → slowest team sets everyone's pace
  - Onboarding cost grows with codebase size
```

Micro-frontends address these by drawing **deployment and ownership boundaries** inside the frontend.

### The 5 Core Goals
1. **Independent deployability** — a team ships its slice without coordinating a global release.
2. **Team autonomy** — teams choose their own pace, and (within limits) their own internals.
3. **Fault isolation** — one feature failing shouldn't take down the whole UI.
4. **Incremental upgrade** — migrate framework versions or rewrite features piecemeal.
5. **Scalable ownership** — clear "you build it, you run it" boundaries.

---

## Conway's Law (The Architect's Lens)

> *"Organizations design systems that mirror their own communication structure."* — Melvin Conway

Micro-frontends are a deliberate application of the **Inverse Conway Maneuver**: you shape the *architecture* to match the *team structure* you want.

```
If you have 6 autonomous product teams →
  a monolith forces them to coordinate constantly (friction)
  MFEs give each team a deployable boundary that matches ownership
```

**Architect takeaway:** Don't adopt MFE because it's trendy. Adopt it when your **team topology** demands independent deployment. If one team owns the whole frontend, MFE adds cost with little benefit.

---

## When to Use (and When NOT to)

This is the most important architectural judgment — and the most common interview probe.

### Use Micro-Frontends When
- **Multiple autonomous teams** need to ship independently
- The frontend is **large and long-lived** (years, many features)
- You need **incremental migration** (e.g., AngularJS → Angular, or framework upgrades)
- Different parts have **genuinely different release cadences**
- Organizational scaling is the bottleneck, not the code

### Do NOT Use When
- **Single team / small app** — a modular monolith is simpler and faster
- The product is **early-stage** — premature boundaries calcify the wrong design
- The team lacks **platform maturity** (CI/CD, observability, governance)
- You're chasing **technical novelty** rather than solving an org problem

```
Decision heuristic:
  "Is independent DEPLOYMENT the actual bottleneck?"
   Yes → MFE may be justified
   No  → use a modular monolith (libraries/feature modules)
```

> A **modular monolith** (well-bounded feature modules in one deployable) captures most code-organization benefits without the operational cost. MFE's *unique* value is independent **deployment**. If you don't need that, you probably don't need MFE.

---

## Decomposition: How to Draw Boundaries

How you split is the highest-leverage architectural decision. Bad boundaries create chatty, coupled MFEs that are worse than a monolith.

### Decomposition Strategies
| Strategy | Split By | Best For |
|----------|----------|----------|
| **By business domain (DDD)** | Bounded contexts (Orders, Catalog, Billing) | Most cases — aligns with team ownership |
| **By page / route** | Whole pages or sections | Clear page-level ownership |
| **By feature** | Cross-cutting features | Feature teams |
| **By layer** | ❌ UI vs data vs logic | **Anti-pattern** — creates coupling |

### Principles for Good Boundaries
- **Align with business domains**, not technical layers (Domain-Driven Design).
- **Maximize cohesion within, minimize coupling between** — a boundary should contain everything a team needs to deliver a capability.
- **A boundary should be independently deployable AND independently valuable.**
- **Vertical slices, not horizontal layers** — each MFE owns its UI *and* its data access for its domain.

```
✅ Vertical (by domain):        ❌ Horizontal (by layer):
   [Orders: UI+logic+data]        [Shared UI layer]
   [Catalog: UI+logic+data]       [Shared logic layer]   ← everyone
   [Billing: UI+logic+data]       [Shared data layer]      coupled
```

---

## Integration: The Three Conceptual Models

*Conceptually* (independent of tools), MFEs can be integrated at three moments in the lifecycle. This is the concept; tools just implement one or more of these.

```
        ┌──────────────────────────────────────────────┐
        │  WHEN does integration happen?                │
        │                                               │
        │  BUILD TIME   → combined before shipping      │
        │  SERVER/EDGE  → combined as HTML is served     │
        │  RUN TIME     → combined in the browser        │
        └──────────────────────────────────────────────┘
```

### Build-Time Integration
Units combined during the build (e.g., as packages).
- **Concept:** compile-time composition.
- **Trade-off:** type-safe and fast at runtime, but **sacrifices independent deployment** (rebuild consumers on change). *Often not "true" MFE.*

### Server/Edge-Time Integration
Units combined into HTML on the server or CDN edge before reaching the browser.
- **Concept:** server-side composition of fragments.
- **Trade-off:** excellent first paint and SEO; adds server/edge complexity; interactivity is harder.

### Run-Time Integration
Units loaded and composed in the browser while the app runs.
- **Concept:** the browser assembles the app on demand.
- **Trade-off:** **true independent deployment** and rich interactivity; cost is more client JS, loading states, and runtime coordination.

> Run-time integration is where independent deployment is *fully* realized — which is why it dominates modern MFE. Module Federation is one *implementation* of this concept.

---

## Communication: Conceptual Contracts

MFEs must coordinate without coupling. The architecture defines **contracts**, not shared internals.

```
Coupling spectrum (prefer the left):
  LOOSE  ─────────────────────────────────────  TIGHT
  URL/route   Custom events   Shared store   Direct import
  (best)      (good)          (use sparingly) (avoid)
```

### The Conceptual Communication Channels
- **The URL as contract** — navigating to another MFE's route is like calling its API. The URL is the most stable, loosely-coupled integration point.
- **Events / messaging** — publish/subscribe for "something happened" (cart updated, user logged out). Fire-and-forget, no shared types.
- **Shared minimal state** — only truly cross-cutting state (auth/session, theme, locale). Treat it as a **read-mostly contract**, not a global mutable store.
- **Props / inputs (down), events (up)** — when one MFE embeds another, pass data down, emit events up — like component design, but across deploy boundaries.

> **Principle:** prefer **choreography** (events) over **orchestration** (a central brain). Shared mutable global state is the #1 way teams accidentally rebuild a distributed monolith.

(Implementation patterns for these are in [Shared State](./shared-state.md).)

---

## Cross-Cutting Concerns (Who Owns What)

An architect must decide where shared concerns live. Typically the **shell/platform** owns them so MFEs don't duplicate or diverge:

| Concern | Usually Owned By |
|---------|------------------|
| Global layout (header/nav/footer) | Shell |
| Authentication / session | Shell (shared as contract) |
| Routing (top-level) | Shell |
| Theming / design tokens | Shared design system |
| Telemetry / logging | Platform (with per-MFE context) |
| Error isolation / fallback | Shell |
| Feature domain UI + data | The owning MFE |

---

## The Trade-Offs (Architect's Honest Ledger)

Staff/principal answers are defined by *acknowledging cost*, not selling a silver bullet.

### Benefits
- Independent deployment & team autonomy
- Fault isolation and incremental upgrades
- Tech-stack flexibility (with discipline)
- Scales engineering org, not just code

### Costs
- **Operational complexity** — many pipelines, versions, runtime composition
- **Payload risk** — duplicated dependencies inflate bundle size if not shared
- **Consistency risk** — UX/visual drift across teams without a design system
- **Distributed-system problems on the frontend** — partial failures, version skew, debugging across boundaries
- **Governance overhead** — contracts, shared deps, and standards must be actively managed

> **The cardinal failure mode:** the **distributed monolith** — MFEs that must be deployed together, share mutable state, and import each other. You pay all the costs of MFE and get none of the independence.

---

## Architectural Decision Framework

A reusable lens for the interview *and* the real role:

```
1. PROBLEM    What org/deployment problem are we actually solving?
2. BOUNDARIES Can we draw domain-aligned, independently valuable slices?
3. INTEGRATION Which model (build/server/runtime) fits our SEO/latency/autonomy needs?
4. CONTRACTS  What are the URL/event/state contracts between MFEs?
5. PLATFORM   Do we have CI/CD, observability, design system, governance to support it?
6. COST       Is the org benefit worth the operational tax? Would a modular monolith do?
```

If steps 1, 2, and 5 aren't strong, recommend a **modular monolith** instead — a sign of senior judgment.

---

## Mental Models

### MFE = Microservices for the UI
Same goal (independent deployment, team autonomy), same risks (distributed systems, versioning, partial failure). If you wouldn't split a backend into microservices, be skeptical of splitting the frontend.

### Boundaries = Property Lines
Good fences make good neighbors. A boundary should let a team build on their land without asking permission — and without their fence falling on the neighbor.

### The URL = Public API
Each MFE's routes are its public API. Internals can change freely; the URL contract stays stable. Teams integrate through the "API," never by trespassing into each other's code.

### Shared Mutable State = A Shared Bank Account
Convenient, but everyone can drain it and no one's sure who did. Prefer giving each MFE its own account and exchanging *messages* (events) about transactions.

---

## Common Mistakes (Architectural)

### Mistake 1: Adopting MFE Without an Org Driver
❌ Single team splits into MFEs for novelty → pure overhead
✅ Adopt only when independent deployment is the real bottleneck

### Mistake 2: Splitting by Technical Layer
❌ UI / logic / data MFEs → maximal coupling
✅ Split by business domain (vertical slices)

### Mistake 3: Building a Distributed Monolith
❌ MFEs that deploy together and share mutable state
✅ Enforce independent deploy + loose, contract-based communication

### Mistake 4: No Platform Foundation
❌ MFE without CI/CD, observability, design system, governance
✅ Treat the platform as a prerequisite, not an afterthought

### Mistake 5: Ignoring Consistency
❌ Each team reinvents UI → fragmented UX
✅ Shared design system + tokens as a contract

### Mistake 6: Premature Decomposition
❌ Drawing boundaries before the domain is understood
✅ Start modular-monolith; extract MFEs when boundaries are proven

---

## Interview Questions (Architect-Level)

### Q1: What problem do micro-frontends actually solve, and when would you NOT use them?
**Answer:** Micro-frontends solve an *organizational scaling* problem: they let multiple autonomous teams develop, test, and deploy their parts of a frontend independently, removing the shared-release-train bottleneck of a monolith. They also enable fault isolation and incremental framework migration. I would not use them for a single team or small app, in early-stage products where boundaries aren't yet understood, or where the organization lacks the platform maturity (CI/CD, observability, governance) to operate them. The key test is whether *independent deployment* is the real bottleneck — if not, a modular monolith delivers most of the code-organization benefits without the operational tax. Recommending a modular monolith when MFE isn't warranted is itself a sign of architectural maturity.

### Q2: How do you decide where to draw boundaries between micro-frontends?
**Answer:** I align boundaries with business domains using Domain-Driven Design — bounded contexts like Orders, Catalog, or Billing — rather than technical layers. The goal is high cohesion within a boundary and low coupling between them, so each MFE owns a vertical slice (its UI, logic, and data access for that domain) and is both independently deployable *and* independently valuable. Splitting by layer (a UI MFE, a data MFE) is an anti-pattern because it forces every feature to span all MFEs, recreating tight coupling. I also consider team topology — boundaries should map to team ownership (Conway's Law) — and I prefer to prove boundaries inside a modular monolith before extracting them.

### Q3: Explain the conceptual integration models and their trade-offs.
**Answer:** Integration can happen at three moments. Build-time integration combines units during compilation (e.g., packages) — type-safe and fast at runtime but it sacrifices independent deployment since consumers must rebuild. Server/edge-time integration assembles HTML fragments before the browser receives them — excellent for first paint and SEO but adds server/edge complexity and complicates interactivity. Run-time integration composes the app in the browser on demand — this fully realizes independent deployment and rich interactivity, at the cost of more client JS, loading/error states, and runtime coordination. Most modern MFE uses run-time integration with an app shell; server/edge models are chosen when SEO and first paint are paramount. The model is a *concept*; tools like Module Federation are specific implementations of run-time integration.

### Q4: How should micro-frontends communicate without becoming coupled?
**Answer:** Through explicit contracts along a coupling spectrum, preferring the loosest option that works. The URL/route is the best contract — navigating into another MFE's route is like calling its API, and its internals stay private. Next is event-based messaging (pub/sub) for "something happened" signals like cart-updated or user-logged-out, which is fire-and-forget with no shared types. Shared state should be limited to genuinely cross-cutting, read-mostly concerns like auth/session, theme, and locale, treated as a contract rather than a global mutable store. Direct imports of another MFE's components should be avoided as they reintroduce build coupling. The principle is choreography over orchestration — shared mutable global state is the fastest path to a distributed monolith.

### Q5: What is a "distributed monolith" and how do you avoid it in MFE?
**Answer:** A distributed monolith is the cardinal MFE failure mode: micro-frontends that *appear* independent but in practice must be deployed together, share mutable global state, and import each other's internals. You pay all the operational costs of distribution while getting none of the independence. To avoid it, I enforce three disciplines: boundaries aligned with domains so changes stay local; loose, contract-based communication (URL and events) instead of shared mutable state or direct imports; and genuine independent deployability validated in CI/CD (each MFE ships on its own pipeline without coordinated releases). Versioned contracts and a shared design system handle integration without coupling. If teams can't deploy independently, it isn't really MFE.

### Q6: How does Conway's Law influence a micro-frontend architecture decision?
**Answer:** Conway's Law says systems mirror the communication structure of the organization that builds them, so architecture and org design are inseparable. Micro-frontends are essentially an Inverse Conway Maneuver — you choose an architecture with independent deployment boundaries to *enable* the autonomous team topology you want, and conversely you only get MFE's benefits if the org actually has multiple teams that need to ship independently. This is why I treat MFE as an organizational decision first: if one team owns the whole frontend, imposing MFE creates coordination overhead with no payoff. The architecture should match — and reinforce — the intended team boundaries, not fight them.

---

## Key Takeaways

- **MFE is an organizational pattern first** — driven by independent deployment and team autonomy
- **Conway's Law is the lens** — match architecture to team topology
- **Don't use MFE without an org driver** — a modular monolith is often the right call
- **Decompose by business domain (vertical slices)**, never by technical layer
- **Three integration models** — build / server-edge / run-time; run-time enables full independence
- **Communicate via contracts** — URL > events > minimal shared state > (avoid) direct imports
- **The cardinal sin is the distributed monolith** — all the cost, none of the independence
- **Platform maturity (CI/CD, observability, design system, governance) is a prerequisite**

---

## What's Next?

Now that the concepts are clear, see how they're **implemented with tools**:
- **[Composition & Routing](./composition-routing.md)** — composition concepts → tool implementation
- **[Shared State](./shared-state.md)** — communication contracts → patterns
- **[Module Federation / Tooling](./module-federation.md)** — the run-time integration deep-dive
- **[Governance](./governance.md)** — operating MFE at scale

---

[← MFE Index](../../interview-prep-index.md) | [Composition & Routing →](./composition-routing.md)
