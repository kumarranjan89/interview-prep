# 🧱 Micro-Frontends — Interview Questions (Architect / 15+ YOE)

MFE-only question bank, calibrated to **architect-level** interviews. Focus: judgment, trade-offs, org/Conway's Law, governance, and failure modes — not just "what is Module Federation."

> **At your level, interviewers probe:** *Should* we use MFE? Where do boundaries go? How do teams stay independent yet coherent? How do you avoid a distributed monolith? How do you operate it for years?

---

## Navigation
[← MFE README](./README.md) | [Concepts](./concepts.md) | [Governance](./governance.md)

---

## How to Answer (Architect Bar)
- **Lead with "it depends" + a decision frame**, never "always use MFE."
- **Tie to the org** — Conway's Law, team topology, independent deployment.
- **Name the trade-off and the cost** — MFE is rarely free; show you know when *not* to.
- **Cite the failure mode** — the distributed monolith — and how you prevent it.
- **Back it with evidence** — a real migration, a boundary you drew, an incident.

---

## SECTION A — Strategy & Judgment (Most Important at Your Level)

### A1. When are micro-frontends the right choice — and when are they the wrong one?
**Answer:** MFEs solve an *organizational scaling* problem, not a code one. They're right when multiple autonomous teams must deploy independently, the app is large and long-lived, you need incremental framework migration, or you need fault isolation across deploys. They're wrong for a single team or small app, early-stage products with unclear domain boundaries, or organizations lacking platform maturity (CI/CD, observability, governance, design system). The litmus test is whether *independent deployment* is the actual bottleneck. If it isn't, a modular monolith delivers most benefits without the operational tax. As an architect, recommending the simpler option when MFE isn't warranted is a sign of maturity, not a lack of ambition.

### A2. How does Conway's Law influence the decision to adopt MFE?
**Answer:** Conway's Law says systems mirror the communication structure of the organization that builds them, so architecture and org design are inseparable. MFE is effectively an Inverse Conway Maneuver — you choose an architecture with independent deployment boundaries to *enable* the autonomous team topology you want. The corollary is that you only get MFE's benefits if the org actually has multiple teams needing to ship independently. If one team owns the whole frontend, imposing MFE adds coordination overhead with no payoff. So I treat MFE as an organizational decision first and a technical one second, and I make sure boundaries map to team ownership.

### A3. A director wants MFE because a competitor uses it. How do you respond?
**Answer:** I'd reframe from technology to outcome: what problem are we solving — slow releases, team coupling, migration, scaling the org? Then I'd assess whether independent deployment is genuinely the bottleneck and whether we have the platform maturity to operate MFE. If the real issue is, say, a slow monolithic pipeline or unclear ownership, a modular monolith plus CI improvements may solve it at a fraction of the cost and risk. I'd present options with trade-offs and a recommendation, possibly a small pilot. The goal is to make a decision aligned to business outcomes, not to adopt a pattern because it's fashionable — and to do so without dismissing the director's underlying concern.

### A4. Modular monolith vs micro-frontends — argue both sides.
**Answer:** A modular monolith — well-bounded feature modules in one deployable — gives clear ownership, lazy loading, and enforceable boundaries with far lower operational cost: one pipeline, one runtime, easy refactors, no version skew, simpler debugging. Its limit is shared deployment: teams still release together. MFE's unique value is independent *deployment* and team autonomy, plus fault isolation and incremental migration — at the cost of operational complexity, payload risk, consistency risk, and distributed-systems problems in the browser. My default is a modular monolith, extracting MFEs only when boundaries are proven and the org truly needs independent release cadences. The decision hinges on deployment independence, team count, and platform maturity.

### A5. What's the single biggest risk in adopting MFE, and how do you mitigate it?
**Answer:** The distributed monolith — MFEs that look independent but must deploy together, share mutable state, and import each other's internals. You pay all the costs of distribution and get none of the independence. I mitigate it with three disciplines: domain-aligned boundaries so changes stay local; loose, contract-based communication (URL and events) instead of shared mutable state or direct imports; and genuine independent deployability proven in CI/CD (each MFE ships on its own pipeline). Versioned contracts and a shared design system handle integration without coupling. The acid test: can a team deploy to prod without rebuilding others or joining a release train? If not, it isn't MFE.

---

## SECTION B — Decomposition & Boundaries

### B1. How do you decide where to draw micro-frontend boundaries?
**Answer:** I align boundaries with business domains via Domain-Driven Design — bounded contexts like Orders, Catalog, Billing — so each MFE owns a vertical slice (its UI, logic, and data access) and is both independently deployable and independently valuable. The aim is high cohesion within a boundary and low coupling between them. Splitting by technical layer (a UI MFE, a data MFE) is an anti-pattern because every feature then spans all MFEs, recreating tight coupling. Boundaries should also map to team ownership (Conway's Law). I prefer to prove boundaries inside a modular monolith first and extract them once they're stable, since wrong boundaries are expensive to undo.

### B2. Your MFEs have become "chatty" — constantly exchanging state. What's wrong?
**Answer:** Chattiness is a symptom of bad boundaries — the decomposition cut through a cohesive domain, so pieces that change together now live apart and must constantly coordinate. The fix isn't more clever communication; it's redrawing boundaries so related capability lives together (higher cohesion, lower coupling). I'd look at change-coupling data (which MFEs deploy together), consolidate the over-split ones, and ensure each MFE owns a complete vertical slice. If two MFEs can't function without constant shared state, they're probably one MFE. Communication mechanisms are a last resort, not a band-aid for mis-decomposition.

### B3. How small should a micro-frontend be?
**Answer:** As small as a domain that's independently deployable and independently valuable — and no smaller. The unit isn't "a component" or "a page"; it's a business capability a team can own end-to-end. Too granular and you get chatty MFEs, duplicated dependencies, and coordination overhead — a distributed monolith. Too coarse and you lose the autonomy benefit. I size MFEs to team ownership and deployment independence, typically one per bounded context per team, and I resist splitting further unless there's a clear autonomy or scaling reason.

---

## SECTION C — Integration & Composition

### C1. Explain the integration models and their trade-offs.
**Answer:** Three conceptual models by *when* integration happens. Build-time integration combines units during compilation (packages) — type-safe, fast at runtime, but sacrifices independent deployment since consumers rebuild. Server/edge-time integration assembles HTML fragments before the browser — great first paint and SEO, but adds server/edge complexity and complicates interactivity. Run-time integration composes in the browser on demand — fully realizes independent deployment and rich interactivity, at the cost of more client JS, loading/error states, and runtime coordination. Most modern MFE uses run-time integration with an app shell; server/edge models win when SEO and first paint are paramount. Module Federation is one *implementation* of run-time integration.

### C2. How does routing work across independently deployed MFEs?
**Answer:** Two-level routing. The shell owns top-level routing and routes by URL prefix to the correct MFE (e.g., `/orders/**` → Orders MFE), while each MFE owns all child routing under its prefix with its own router. The framework router is shared as a singleton so the shell and MFEs cooperate on a single URL state instead of fighting over it. Teams get namespaced prefixes to avoid collisions, deep links work via an SPA fallback plus lazy-loading the matching remote on refresh, and cross-MFE navigation happens by URL (`router.navigate`), never by importing another MFE's components. The URL is the contract.

### C3. How do you compose MFEs built with different frameworks?
**Answer:** Use Web Components (custom elements) as a framework-agnostic boundary — each MFE bootstraps its own framework internally but exposes a custom element the shell mounts regardless of its stack, with data flowing down via attributes/props and up via custom events. Tools like Angular Elements and Vue's defineCustomElement enable this. That said, at architect level I'd question *why* we have multiple frameworks — it multiplies bundle size, cognitive load, and maintenance. I'd allow it deliberately for incremental migration or genuine multi-team/multi-stack reality, and otherwise standardize on one framework. Heterogeneity is a cost to justify, not a default.

### C4. How do you prevent one failing MFE from taking down the whole app?
**Answer:** Fault isolation at the composition boundary. The shell wraps each remote in an error boundary (or equivalent) so a runtime failure renders a fallback UI instead of white-screening the app, plus loading skeletons, retries, and graceful degradation (hide or replace the broken feature). I handle `remoteEntry`/chunk load failures explicitly with timeouts. The principle is that run-time composition introduces partial-failure modes inherent to distributed systems, so the shell must treat every remote as potentially unavailable and contain the blast radius. This is non-negotiable for production MFE.

---

## SECTION D — Communication & State

### D1. How should MFEs communicate without coupling?
**Answer:** Along a coupling spectrum, choosing the loosest option that works: the URL as a contract for navigation and deep-linkable state; fire-and-forget events (custom DOM events or a small shell-owned bus) for cross-cutting signals; and a tiny shell-owned, read-mostly shared store only for genuinely cross-cutting state like auth/session, theme, and locale. Direct imports of another MFE's internals are avoided since they reintroduce build coupling. Server/domain data is kept consistent via the backend/BFF and cache, not passed in browser memory. I prefer choreography (events) over orchestration (a central brain), because shared mutable global state is the fastest path to a distributed monolith.

### D2. What's the "God store" anti-pattern and how do you prevent it?
**Answer:** A single global state store every MFE reads from and writes to. It's convenient but tightly couples all MFEs to a shared schema and to each other's mutations, so they can no longer evolve or deploy independently — a classic distributed monolith. I prevent it by defaulting state to MFE-local, restricting shared state to a small read-mostly contract owned by the shell for cross-cutting concerns, communicating via URL and events rather than shared memory, and extracting genuinely common logic into a versioned shared library instead of a shared mutable store. The test: can a team change its internal state without coordinating with others? If not, the store has become a coupling point.

### D3. How do you version the contracts between MFEs?
**Answer:** Treat every integration point — exposed module interfaces, event payload schemas, shared-state shapes, shared-library APIs — as a public API under semantic versioning. Changes are additive and backward-compatible by default; breaking changes require a deprecation path supporting old and new (N and N-1) during a published migration window. I version event payloads (e.g., a `schemaVersion` field) so consumers branch safely, and I use contract tests in CI to verify each MFE honors the contracts before deploy. This lets teams evolve independently without silently breaking each other — the same rigor we'd apply to backend API versioning.

---

## SECTION E — Tooling (Be Ready, But Secondary)

### E1. How do shared dependencies and `singleton` work in Module Federation?
**Answer:** The `shared` config lets host and remotes share dependencies instead of each bundling its own; at runtime MF negotiates versions and loads a compatible copy into a shared scope. `singleton: true` forces exactly one instance across all apps — mandatory for frameworks like React or Angular that rely on global state, since multiple React copies cause invalid-hook errors and multiple Angular instances break DI and zone.js. `strictVersion` makes incompatible versions throw rather than silently misbehave, and `requiredVersion: "auto"` reads the needed version from package.json. The architectural implication: frameworks must be singletons, so their *major* versions have to align across teams.

### E2. Static vs dynamic remotes — what would you use in production?
**Answer:** Static remotes bake the remote URL into the host at build time — simple, but the same artifact can't target different environments and relocating a remote forces a host rebuild. Dynamic remotes resolve URLs at runtime from a manifest or env config fetched at bootstrap, so one build serves dev/stage/prod, remotes can move to a CDN, and host releases decouple from remote URL changes. In production I use dynamic remotes with a runtime manifest — it's essential for multi-environment deploys, canary releases, and independent deployment, where deploying or rolling back is just a manifest update, not a host rebuild.

### E3. Webpack Module Federation vs Native Federation — when would you pick which?
**Answer:** Module Federation is mature and battle-tested, deeply tied to Webpack internals. Native Federation (from @angular-architects) provides the same mental model — hosts, remotes, exposes, shared — but is built on web-standard import maps and esbuild/rollup, making it bundler-agnostic and future-proof as Angular moves to esbuild/Vite. For an existing Webpack-based system I'd stay on Module Federation; for new Angular MFEs or a build-tool migration I'd choose Native Federation to avoid coupling our architecture to Webpack-specific APIs. The decision is about ecosystem direction and bundler strategy, not just features.

---

## SECTION F — Governance & Operations

### F1. How do you achieve truly independent deployment?
**Answer:** The litmus test is whether a team can ship to prod without rebuilding other MFEs, joining a release train, or getting other teams' approval. To enable it, the host resolves remote locations at runtime via a manifest rather than baking URLs in — deploying becomes publishing a new versioned, immutable artifact and updating that MFE's manifest entry, with no host rebuild; rollback is flipping the entry back. I pair this with per-MFE pipelines, progressive delivery (canary by percentage), feature flags to separate deploy from release, and instant rollback. If any team is forced into coordinated releases, it's a distributed monolith.

### F2. How do you keep UX consistent across many autonomous teams?
**Answer:** Consistency must be a contract enforced by tooling, not a request. The cornerstone is a versioned design system — components plus design tokens — consumed by all MFEs, so teams stay autonomous on behavior while coherent on appearance and interaction. I back it with automated CI gates per MFE: visual regression, accessibility (axe), and performance budgets, plus shared-dependency policy lint. A platform team owns this paved road so the consistent choice is the easy choice. This prevents the fragmentation that otherwise makes a multi-team product feel like several different apps stitched together.

### F3. How do you observe and debug an MFE system in production?
**Answer:** Treat it as a distributed system in the browser. Each MFE tags telemetry — errors, logs, RUM/Core Web Vitals — with its name and deployed version, so any issue is attributable to a specific team's specific release. I propagate a correlation/trace ID from the shell into each MFE for distributed tracing across a user action that spans multiple MFEs, and slice dashboards/alerts by MFE and version. For resilience, error boundaries with fallback UI contain failures and `remoteEntry`/chunk load failures are handled with timeouts and retries. This makes "which MFE/version broke and what was the user doing" quickly answerable.

### F4. How do you handle framework version skew across teams?
**Answer:** I distinguish frameworks from leaf libraries. Frameworks must run as a single instance, so their *major* versions have to align across shell and MFEs — enforced via an org-wide shared-dependency policy (allowed majors, strictVersion) in CI, plus coordinated upgrade windows. Leaf libraries can diverge, each MFE bundling its own copy at a bundle-size cost, which is fine for non-global libs. Since some skew is inevitable with many teams, the architecture tolerates *minor* skew through version negotiation and prevents *major* skew through policy and graceful fallback when a remote is incompatible. The aim: one framework runtime, minimal shared surface, no silent breakage.

### F5. What role does a platform team play in MFE at scale?
**Answer:** At scale a platform (enablement) team owns the paved road: the shell, the manifest/remote-loading runtime, the design system and shared libraries, shared CI templates (budgets, a11y, contract tests), and observability tooling and conventions. In Team Topologies terms, the platform team reduces the cognitive load on stream-aligned feature teams, who then get independent deployment, consistency, and observability "for free." This is the organizational mechanism that makes governance sustainable — the right thing becomes the easy thing through self-service tooling, rather than being enforced by review gates and documents. It also mirrors Conway's Law deliberately in the shell/MFE split.

---

## SECTION G — Scenario / Design Prompts (Practice Out Loud)

These are open-ended; structure your answer: clarify → boundaries → integration model → contracts → governance → trade-offs.

- **Migrate a 5-year-old Angular monolith (8 teams) to MFE** — sequencing, Strangler Fig, shell, shared deps, rollback.
- **An MFE platform where teams want different frameworks** — should you allow it? interop boundary? cost?
- **Cart count is inconsistent across 3 MFEs** — diagnose (shared state vs events vs boundaries) and fix.
- **A remote intermittently fails to load in production** — resilience, observability, rollback.
- **Two teams keep colliding on routes and shared components** — governance, namespacing, contracts.
- **Leadership wants faster releases; current monolith deploys weekly** — is MFE the answer, or pipeline/modular monolith?

---

## Rapid-Fire (One-Liners)

- **Why MFE?** Independent deployment + team autonomy (org problem, not code).
- **When NOT?** Single team, small/early app, low platform maturity.
- **Boundary rule?** By business domain (vertical slice), never by layer.
- **#1 failure mode?** Distributed monolith.
- **Communication priority?** URL → events → minimal shared state → (avoid) imports.
- **Framework sharing?** Singleton; align majors.
- **Production remotes?** Dynamic, via runtime manifest.
- **Deploy/rollback?** Publish versioned artifact + flip manifest (no host rebuild).
- **Consistency?** Design system + tokens, enforced in CI.
- **Future-proof Angular MFE?** Native Federation (import maps/esbuild).
- **Litmus test?** Can a team deploy without rebuilding others?

---

## Self-Check Before the Interview
- [ ] I can argue **MFE vs modular monolith** both ways and recommend with conviction
- [ ] I can explain **Conway's Law** and the Inverse Conway Maneuver
- [ ] I can describe **how I'd draw boundaries** and detect bad ones
- [ ] I can place any communication need on the **coupling spectrum**
- [ ] I can define and **prevent the distributed monolith**
- [ ] I can explain **independent deployment** mechanics (manifest, versioned artifacts, rollback)
- [ ] I can speak to **governance, consistency, and observability** at scale
- [ ] I have **2–3 real stories** (a migration, a boundary decision, an incident)

---

[← MFE README](./README.md) | [Concepts](./concepts.md) | [Governance](./governance.md)
