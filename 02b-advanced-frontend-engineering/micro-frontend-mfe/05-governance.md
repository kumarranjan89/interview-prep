# MFE Versioning, Deployment & Governance

Operating micro-frontends at scale — **concepts first**, then the mechanisms. This is the part that separates a working demo from a sustainable platform, and it's where architect-level interviews go deep.

---

## Navigation
[← Module Federation / Tooling](./module-federation.md) | [MFE Index →](../../interview-prep-index.md)

---

## PART 1 — CONCEPTS

### Why Governance Is the Hard Part
The technology to load a remote module is easy. Keeping **dozens of independently deployed MFEs** consistent, compatible, observable, and safe over **years** is the real challenge. Governance is the set of **contracts, standards, and processes** that let teams stay autonomous *without* the system fragmenting.

> Without governance, MFEs drift into either chaos (every team different) or a distributed monolith (everyone forced to deploy together). Governance is how you hold the middle.

### The Four Pillars of MFE Governance
```
1. VERSIONING   → how MFEs and shared deps evolve compatibly
2. DEPLOYMENT   → how MFEs ship independently and safely
3. CONSISTENCY  → how UX/quality stays coherent across teams
4. OPERATIONS   → how you observe, debug, and recover at runtime
```

---

## Pillar 1 — Versioning (Concept)

The central question: **how do independently deployed parts stay compatible at runtime?**

### Contract Versioning
Every integration point is a versioned contract:
- **Remote module interfaces** (what a remote exposes)
- **Event payload schemas** (`cart:item-added@v1`)
- **Shared state shape** (session/theme contracts)
- **Shared library APIs** (design system, utilities)

**Principle:** treat these like public APIs. Use **semantic versioning**, and never break a contract without a deprecation path.

### Shared Dependency Versioning (the classic problem)
```
Shell uses framework v16; MFE-A uses v16; MFE-B still on v15
→ Can they share one runtime? Only if compatible.
```
- **Frameworks must be a single instance** (singleton) — so major versions must align across teams.
- **Leaf libraries** can diverge (each MFE bundles its own) at a payload cost.
- **Version skew is inevitable** with many teams; the architecture must tolerate *minor* skew and prevent *major* skew.

### Compatibility Strategies (concept)
- **Backward-compatible contracts** — additive changes only; deprecate before removing.
- **Aligned framework baselines** — org-wide policy on framework major versions and upgrade windows.
- **Independent fallback** — if a remote is incompatible/unavailable, degrade gracefully rather than crash.

---

## Pillar 2 — Deployment (Concept)

The whole point of MFE: **deploy a slice without a global release.**

### Independent Deployability (the litmus test)
```
Can Team A deploy to production WITHOUT:
  - rebuilding other MFEs?      → must be YES
  - coordinating a release train? → must be YES
  - other teams' approval?        → must be YES
If any is NO → you have a distributed monolith, not MFE.
```

### Runtime URL Resolution (concept)
For independent deploy, **the host must discover remote locations at runtime**, not bake them in at build time. A **manifest** (a small config mapping MFE → URL/version) is the standard concept: update the manifest to release, without rebuilding the host.

### Release Safety (concept)
Independent deploy multiplies release frequency, so safety must be built in:
- **Versioned/immutable artifacts** — never overwrite a deployed bundle; publish a new versioned path.
- **Progressive delivery** — canary / percentage rollout per MFE.
- **Instant rollback** — flip the manifest back to the previous version.
- **Feature flags** — decouple *deploy* from *release* (ship dark, enable later).

---

## Pillar 3 — Consistency (Concept)

Autonomy without coherence yields a fragmented product. Consistency is a **contract problem**, not a "tell teams to be careful" problem.

### What Must Stay Consistent
- **Visual / UX** — a shared **design system** + **design tokens** as the single source of truth.
- **Accessibility** — shared standards and audits so a11y doesn't regress per team.
- **Performance budgets** — per-MFE limits (bundle size, Core Web Vitals) so one team can't tank the whole page.
- **Cross-cutting behavior** — auth, error handling, telemetry conventions.

> The design system is the most important consistency contract: it lets teams be autonomous on *behavior* while staying coherent on *appearance and interaction*.

---

## Pillar 4 — Operations (Concept)

MFE is a distributed system in the browser, so it inherits distributed-systems operational concerns.

### Observability Across Boundaries
- **Distributed tracing** — correlate a user action across shell + multiple MFEs (shared correlation/trace ID).
- **Per-MFE attribution** — errors, performance, and logs tagged by MFE and version, so you know *which* team's *which* release broke.
- **Real User Monitoring (RUM)** — per-MFE Core Web Vitals.

### Runtime Resilience
- **Fault isolation** — one failed remote must not white-screen the app (error boundaries + fallback UI).
- **Graceful degradation** — hide/replace a broken MFE; keep the rest usable.
- **Timeouts & retries** — `remoteEntry`/chunk loads can fail; handle them.

---

## PART 2 — IMPLEMENTATION (Mechanisms)

### Versioning in Practice
```jsonc
// mf.manifest.json — runtime mapping of MFE → versioned URL (immutable paths)
{
  "orders":  "https://cdn.example.com/orders/3.4.1/remoteEntry.js",
  "catalog": "https://cdn.example.com/catalog/7.0.0/remoteEntry.js",
  "billing": "https://cdn.example.com/billing/2.2.0/remoteEntry.js"
}
```
- **Deploy = publish a new versioned artifact + update the manifest entry.**
- **Rollback = point the manifest entry back to the previous version.** No host rebuild.

```jsonc
// Shared dependency policy (enforced in CI) — one framework major, aligned
{
  "policy": {
    "@angular/core": { "singleton": true, "strictVersion": true, "allowedMajors": ["16"] },
    "rxjs":          { "singleton": true, "allowedMajors": ["7"] }
  }
}
```

### Event/Contract Versioning in Practice
```typescript
// Version the payload, not just the channel; support N and N-1 during migration.
window.dispatchEvent(new CustomEvent('cart:item-added', {
  detail: { schemaVersion: 1, sku: 'ABC-123', qty: 2 },
}));
// Consumers branch on schemaVersion and deprecate v1 on a published timeline.
```

### Deployment Pipeline (per MFE, independent)
```
Team A pipeline (runs on its own):
  build → test → a11y + perf budget check → publish versioned artifact to CDN
        → canary (5% via manifest) → monitor RUM/errors → promote to 100%
        → (on regression) flip manifest to previous version  [instant rollback]
```

### Consistency Enforcement (automated, not manual)
- **Design system as a versioned shared library** — components + tokens consumed by all MFEs.
- **CI gates per MFE:** bundle-size budget, Lighthouse/CWV thresholds, a11y (axe) checks, shared-dependency policy lint.
- **Contract tests** — verify each MFE honors the event/state/exposed-module contracts before deploy.
- **Visual regression tests** on shared components.

### Operations in Practice
```typescript
// Tag telemetry with MFE name + version for attribution
telemetry.setGlobalContext({ mfe: 'orders', version: '3.4.1', traceId });

// Error isolation boundary in the shell around each remote
<ErrorBoundary fallback={<MfeUnavailable name="orders" />} onError={report}>
  <Suspense fallback={<Skeleton />}><RemoteOrders /></Suspense>
</ErrorBoundary>
```
- Propagate a **correlation ID** from the shell into every MFE for distributed tracing.
- Dashboards/alerts sliced **by MFE and version**.

---

## The Platform Team (Organizational Mechanism)
At scale, a **platform/enablement team** owns the "paved road" so feature teams stay autonomous *and* consistent:
- The shell, manifest service, and remote-loading runtime
- The design system and shared libraries
- Shared CI templates (budgets, a11y, contract tests)
- Observability tooling and conventions

> This is **Team Topologies** in action: a *platform team* reduces the cognitive load of *stream-aligned* (feature) teams. Governance succeeds when the right thing is the easy thing (paved road), not when it's enforced by documents.

---

## Mental Models

### Manifest = DNS for Micro-Frontends
Just as DNS maps a name to a changing IP without callers rebuilding, the manifest maps an MFE name to a changing versioned URL — deploy and rollback become a "DNS update," not a rebuild.

### Contracts = API Versioning for the UI
Every event, shared-state shape, and exposed module is a public API. SemVer them, deprecate gracefully, support N and N-1 during migrations — exactly like backend APIs.

### Governance = Guardrails, Not Gates
Good governance is a paved road (automated budgets, shared design system, CI templates) that makes the consistent choice the easy choice — not a committee that blocks releases.

### Independent Deploy = The Litmus Test
If a team can't ship to prod without rebuilding others or joining a release train, it isn't MFE — it's a distributed monolith wearing an MFE costume.

---

## Common Mistakes

### Mistake 1: Build-Time Remote URLs
❌ URLs baked into the host → host rebuild on every MFE deploy
✅ Runtime manifest with versioned, immutable artifact URLs

### Mistake 2: Mutable/Overwritten Artifacts
❌ Overwriting `latest` → no clean rollback, cache chaos
✅ Immutable versioned paths; rollback = manifest flip

### Mistake 3: No Shared Dependency Policy
❌ Teams drift across framework majors → runtime crashes
✅ CI-enforced singleton + allowed-majors policy, aligned upgrade windows

### Mistake 4: Consistency by Documentation
❌ "Please use our styles" → inevitable drift
✅ Design system as a versioned lib + automated CI gates

### Mistake 5: No Per-MFE Observability
❌ An error with no idea which MFE/version caused it
✅ Telemetry tagged by MFE + version; correlation IDs; per-MFE dashboards

### Mistake 6: Breaking Contracts Without Deprecation
❌ Changing an event payload and breaking consumers silently
✅ Versioned payloads, support N and N-1, deprecate on a timeline

### Mistake 7: No Platform Team
❌ Every team reinvents shell/CI/observability → waste + divergence
✅ A platform team owns the paved road

---

## Interview Questions

### Q1: How do you achieve truly independent deployment of micro-frontends?
**Answer:** The litmus test is whether a team can ship to production without rebuilding other MFEs, joining a shared release train, or getting other teams' approval. To enable that, the host must resolve remote locations at **runtime** via a manifest rather than baking URLs in at build time — deploying becomes publishing a new versioned, immutable artifact and updating that MFE's manifest entry, with no host rebuild. I pair this with per-MFE CI/CD pipelines, progressive delivery (canary by percentage), feature flags to separate deploy from release, and instant rollback by flipping the manifest back to the prior version. If any team is forced into coordinated releases, it's a distributed monolith, not MFE.

### Q2: How do you handle shared dependency versioning across teams?
**Answer:** I distinguish frameworks from leaf libraries. Frameworks like Angular or React must run as a single instance (singleton), so their *major* versions have to align across the shell and all MFEs — I enforce this with an org-wide shared-dependency policy (allowed majors, strictVersion) checked in CI, plus coordinated upgrade windows. Leaf libraries can diverge, with each MFE bundling its own copy at a bundle-size cost, which is acceptable for non-global libs. Because version skew is inevitable with many teams, the architecture tolerates *minor* skew through version negotiation and prevents *major* skew through policy and graceful fallback when a remote is incompatible. The aim is one framework runtime, a minimal shared surface, and no silent breakage.

### Q3: How do you keep UX consistent when many autonomous teams own different parts?
**Answer:** Consistency has to be a contract enforced by tooling, not a request. The cornerstone is a **design system** shipped as a versioned shared library — components and design tokens that all MFEs consume — so teams stay autonomous on behavior while coherent on appearance and interaction. I back that with automated CI gates per MFE: bundle-size and Core Web Vitals budgets, accessibility checks (e.g., axe), visual regression tests on shared components, and shared-dependency policy lint. A platform team owns this paved road so the consistent choice is the easy choice. This prevents the fragmentation that otherwise makes a multi-team product feel like several different apps stitched together.

### Q4: How do you observe and debug a micro-frontend system in production?
**Answer:** I treat it as a distributed system in the browser. Every MFE tags its telemetry — errors, logs, performance, RUM/Core Web Vitals — with its name and deployed version, so I can attribute any issue to a specific team's specific release. I propagate a correlation/trace ID from the shell into each MFE to get distributed tracing across a single user action that spans multiple MFEs. Dashboards and alerts are sliced by MFE and version. For resilience, the shell wraps each remote in an error boundary with fallback UI so one failed remote degrades gracefully instead of white-screening the app, and I handle `remoteEntry`/chunk load failures with timeouts and retries. This makes "which MFE/version broke, and what was the user doing" answerable quickly.

### Q5: How do you version the contracts between micro-frontends?
**Answer:** I treat every integration point — exposed module interfaces, event payload schemas, shared-state shapes, and shared-library APIs — as a public API governed by semantic versioning. Changes are additive and backward-compatible by default; breaking changes require a deprecation path where I support both the old and new versions (N and N-1) during a published migration window before removing the old one. For events I version the payload (e.g., a `schemaVersion` field or `cart:item-added@v1`) so consumers branch safely, and I use contract tests in CI to verify each MFE honors the contracts before it deploys. This lets teams evolve independently without silently breaking each other.

### Q6: What role does a platform team play, and how does Team Topologies apply?
**Answer:** At scale, a platform (enablement) team owns the "paved road": the shell, the manifest/remote-loading runtime, the design system and shared libraries, shared CI templates (budgets, a11y, contract tests), and observability tooling and conventions. In Team Topologies terms, this platform team reduces the cognitive load on stream-aligned feature teams, who can then focus on their domain while getting independent deployment, consistency, and observability "for free." This is the organizational mechanism that makes governance sustainable — the right thing becomes the easy thing through tooling and self-service, rather than being enforced by review gates and documents. It also reflects Conway's Law: the platform/feature-team split is deliberately mirrored in the shell/MFE architecture.

---

## Key Takeaways

- **Governance is the hard part of MFE** — four pillars: versioning, deployment, consistency, operations
- **Independent deploy is the litmus test** — runtime manifest, versioned immutable artifacts, no host rebuild
- **Align framework majors (singleton); tolerate minor skew, prevent major skew** via CI-enforced policy
- **Version every contract** (events, state, exposed modules) like a public API; deprecate gracefully
- **Consistency is automated** — design system as a versioned lib + CI budgets/a11y/visual tests
- **Operate it like a distributed system** — per-MFE+version telemetry, correlation IDs, error isolation
- **Deploy safely** — canary, feature flags, instant rollback via manifest
- **A platform team owns the paved road** — Team Topologies makes the consistent choice the easy one

---

[← Module Federation / Tooling](./module-federation.md) | [MFE Index →](../../interview-prep-index.md)
