# Performance Budgets & Governance

How to keep an app fast *forever* across many teams and years. The architect's job isn't a one-time fix — it's a sustainable system that prevents regressions.

---

## Navigation
[← Framework Performance](./framework-performance.md) | [Interview Questions →](./interview-questions.md)

---

## Why Governance Is the Real Job

```
One-time optimization:   fast today, slowly rots as features pile on
Governance:              stays fast because regressions are PREVENTED
```

> Performance is not a project, it's a **property** you maintain. Without budgets and process, every new feature, dependency, and team erodes it — "performance entropy."

---

## Performance Budgets (The Foundation)

A **performance budget** is a quantified limit, enforced automatically, that turns "make it fast" into a contract.

### Types of Budgets
```
1. METRIC budgets:     LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1 (at p75)
2. QUANTITY budgets:   JS ≤ 170KB, total ≤ 1MB, ≤ 50 requests
3. RULE budgets:       no render-blocking 3rd-party, images must have dimensions
```

### Setting Realistic Budgets
```
- Base on real users (RUM p75) + device/network targets
- Tie to business goals (competitor benchmarks, conversion targets)
- Set per-route (a dashboard ≠ a landing page)
- Start from current baseline; ratchet down over time (don't regress)
```

> **The 170KB rule of thumb:** keep critical-path JS under ~170KB compressed for a reasonable time-to-interactive on mid-tier mobile.

---

## Enforce Budgets in CI (Automate or It Won't Happen)

Budgets only work if a build **fails** when exceeded — manual vigilance always erodes.

### 1. Bundle-Size Budgets
```json
// angular.json — build fails when bundle exceeds the error threshold
"budgets": [
  { "type": "initial", "maximumWarning": "400kb", "maximumError": "500kb" },
  { "type": "anyComponentStyle", "maximumWarning": "2kb", "maximumError": "4kb" }
]
```
```js
// bundlesize / size-limit (framework-agnostic) in package.json
"size-limit": [{ "path": "dist/main.*.js", "limit": "170 KB" }]
```

### 2. Lighthouse CI (Metric Budgets)
```yaml
# Fail PRs that regress performance metrics
# lighthouserc.json (excerpt)
{
  "ci": {
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "largest-contentful-paint": ["error", { "maxNumericValue": 2500 }],
        "total-blocking-time": ["error", { "maxNumericValue": 200 }],
        "cumulative-layout-shift": ["error", { "maxNumericValue": 0.1 }]
      }
    }
  }
}
```

### 3. The Pipeline
```
PR opened →
  build → bundle-size check → Lighthouse CI (lab metrics) →
  ❌ over budget? → fail the PR with a clear report
  ✅ within budget? → merge
```
> **Catch regressions at the PR**, not in production. This is the single most effective governance practice.

---

## Continuous Monitoring (Field/RUM)

CI catches lab regressions; **RUM catches what real users actually experience.**

```
- Track p75 CWV by route, device, geography (web-vitals.js or a RUM platform)
- Alert on threshold breaches and deploy-correlated regressions
- Dashboards visible to teams (not buried)
- Correlate regressions with releases → fast root cause
```
(Tooling details in [measurement-profiling.md](./measurement-profiling.md).)

```
CI (lab)  → prevents known regressions before merge
RUM (field) → detects real-world regressions + validates fixes
            → both feed back into budgets
```

---

## The Governance Loop

```
1. BASELINE   measure current performance (lab + field)
2. BUDGET     set realistic, per-route budgets
3. ENFORCE    CI gates fail PRs that exceed budgets
4. MONITOR    RUM tracks real users; alert on regressions
5. ATTRIBUTE  correlate regressions to releases/teams
6. IMPROVE    fix, then ratchet budgets tighter
   ↻ repeat
```

---

## Performance Culture (The Human Layer)

Tooling alone fails without culture. At architect level, you build both.

```
- Make performance VISIBLE: dashboards, PR comments, team scorecards
- Shared OWNERSHIP: every team owns their routes' budgets
- Performance in Definition of Done (not an afterthought)
- Education: brown-bags, docs, the "why" (business impact)
- Celebrate wins; review regressions blamelessly
- A platform team provides the paved road (CI templates, RUM, design system)
```

> **Architect's role:** make the fast path the *easy* path. If hitting budgets requires heroics, the system is wrong — provide tooling, defaults, and components that are fast by default.

---

## Performance as a Design Constraint

Shift performance **left** — into design and planning, not just code review.

```
- Budget new features BEFORE building ("this costs X KB / Y ms — worth it?")
- Review heavy dependencies at RFC time, not after merge
- Design rendering strategy (CSR/SSR/SSG) per requirements upfront
- Consider performance in architecture decisions (MFE shared deps, etc.)
```

---

## Governance in Micro-Frontends

(Connects to the [MFE section](../mfe/README.md).)
```
- Per-MFE performance budgets (one team can't tank the shared page)
- Per-MFE + version RUM attribution (which team's release regressed?)
- Shared-dependency policy (avoid duplicate framework copies)
- Design system as a fast-by-default shared library
- Platform team owns the shared performance paved road
```

---

## Mental Models

### Budgets = A Financial Budget
You don't check your bank balance after going broke. A performance budget allocates a fixed "spend" (KB, ms) up front; every feature must fit within it or make a deliberate trade-off. Overspending fails the build, like a declined card.

### CI Gates = A Bouncer at the Door
The bouncer (CI) checks every guest (PR) against the dress code (budget) before entry. Catching a regression at the door is trivial; evicting it after the party (production) is painful.

### Performance Entropy = A Garden
Left alone, a garden (codebase) is overgrown by weeds (regressions). Governance is the regular weeding and fencing that keeps it healthy — a one-time cleanup doesn't last.

### Culture = Paving the Cow Path
If the fast path is hard, people take the easy slow path. Architects pave the fast path (fast-by-default components, CI templates, RUM) so the easy choice and the fast choice are the same.

---

## Common Mistakes

### Mistake 1: One-Time Optimization
❌ Fix performance once, then watch it rot
✅ Continuous budgets + monitoring (it's a property, not a project)

### Mistake 2: Budgets Without Enforcement
❌ Documented budgets nobody checks
✅ CI gates that fail PRs over budget

### Mistake 3: No Field Monitoring
❌ Only lab metrics; blind to real users
✅ RUM with alerts; correlate regressions to releases

### Mistake 4: Performance Only at Code Review
❌ Discover cost after the feature is built
✅ Shift left — budget features at design/RFC time

### Mistake 5: Tooling Without Culture
❌ Gates teams resent and bypass
✅ Shared ownership, visibility, education, fast-by-default tooling

### Mistake 6: Unrealistic or Global Budgets
❌ One budget for all routes; arbitrary numbers
✅ Per-route, data-driven budgets; ratchet over time

### Mistake 7: No Regression Attribution
❌ "The site got slow" with no idea why
✅ Per-route (and per-MFE/version) attribution tied to deploys

---

## Interview Questions

### Q1: What is a performance budget and how do you enforce it?
**Answer:** A performance budget is a quantified, enforced limit that turns "make it fast" into a contract — it can be a metric budget (LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1 at p75), a quantity budget (critical JS ≤ ~170KB, total page weight, request count), or a rule budget (no render-blocking third parties, images must declare dimensions). I set them from real-user data and device/network targets, per route since a landing page differs from a dashboard, starting at the current baseline and ratcheting tighter over time. Enforcement is the key: budgets only work if the build fails when exceeded, so I wire them into CI — bundle-size checks (Angular budgets, size-limit) and Lighthouse CI asserting metric thresholds on every PR. Catching regressions at the PR rather than in production is the single most effective governance practice.

### Q2: How do you prevent performance from degrading over time across many teams?
**Answer:** I treat performance as a property to maintain, not a one-time project, and build a governance loop. First a baseline from lab and field data, then realistic per-route budgets. Those budgets are enforced automatically in CI so any PR that regresses bundle size or key metrics fails before merge. In parallel, RUM monitors real users' p75 by route, device, and geography with alerting, and I correlate regressions to specific releases (and in MFE, specific teams/versions) for fast attribution. Crucially I pair tooling with culture: shared ownership where each team owns its routes' budgets, performance in the Definition of Done, visible dashboards, and a platform team providing fast-by-default components and CI templates. The architect's job is making the fast path the easy path so good performance is the default, not a heroic effort.

### Q3: Where does performance budgeting fit in the development lifecycle?
**Answer:** It should shift left — appear at design and planning, not just at code review or after release. At the RFC/design stage I budget new features and heavy dependencies explicitly ("this library adds 200KB — is it worth it, or is there a lighter option?"), choose the rendering strategy (CSR/SSR/SSG) based on requirements, and consider performance in architecture decisions like shared dependencies in micro-frontends. During development, CI gates enforce bundle and metric budgets on every PR. After release, RUM validates real-world impact and feeds back into the budgets. Discovering performance cost only at code review or in production is too late and expensive; budgeting up front makes performance a deliberate design constraint rather than a cleanup phase.

### Q4: What's the difference between lab-based CI gates and RUM monitoring, and why do you need both?
**Answer:** Lab-based CI gates (Lighthouse CI, bundle-size checks) run in a controlled environment on every PR, so they catch known regressions before they merge — they're preventative and deterministic, ideal for blocking a bad change. But they test a single simulated profile, not your actual users. RUM monitoring captures real users' Core Web Vitals across the full spread of devices, networks, and geographies, so it detects regressions that only show up in the field, validates that fixes actually helped real users, and reflects what Google ranks on. I need both: CI to prevent regressions at the door, RUM to know the real-world truth and prioritize. Both feed back into the budgets — if RUM shows we're comfortably under target we can ratchet tighter; if it shows pain, we tighten the gates.

### Q5: How do you build a performance culture, not just tooling?
**Answer:** Tooling without culture gets resented and bypassed, so I build both. I make performance visible — dashboards, PR comments showing budget impact, per-team scorecards — so it's a shared, observable goal rather than a hidden concern. I establish shared ownership where each team owns its routes' budgets, and put performance in the Definition of Done so it's not optional. I invest in education: explaining the business impact (conversion, retention, SEO) so teams understand the "why," running brown-bags, and documenting patterns. Regressions are reviewed blamelessly and wins celebrated. Most importantly, as an architect I make the fast path the easy path — a platform team provides fast-by-default components, CI templates, and RUM — so teams hit budgets without heroics. When the easy choice is also the fast choice, culture follows.

### Q6: How does performance governance change in a micro-frontend architecture?
**Answer:** MFE adds the challenge that multiple independently-deployed teams share one user-facing page, so one team's regression can degrade the whole experience. Governance adapts accordingly: each MFE gets its own performance budget enforced in its own CI pipeline, so no team can silently bloat the shared page. RUM is attributed per-MFE and per-version, so when a metric regresses I know exactly which team's which release caused it. I enforce a shared-dependency policy so frameworks are singletons and not duplicated across MFEs, which is a major payload risk. The design system is shipped as a fast-by-default shared library, and a platform team owns the shared performance paved road — the shell, budgets, RUM, and CI templates. This preserves team autonomy while protecting the collective performance of the composed application.

---

## Key Takeaways

- **Performance is a property to maintain, not a one-time project** — fight entropy
- **Performance budgets** turn "be fast" into enforced contracts (metric/quantity/rule)
- **Enforce in CI** — fail PRs over budget (bundle-size + Lighthouse CI); catch at the PR
- **Monitor with RUM** — real-user p75, alerts, regression-to-release attribution
- **Run the governance loop:** baseline → budget → enforce → monitor → attribute → improve
- **Shift left** — budget features and dependencies at design/RFC time
- **Build culture** — shared ownership, visibility, education, fast-by-default tooling
- **In MFE:** per-MFE budgets + per-version RUM attribution + shared-dep policy

---

## What's Next?

You now have the full performance stack — understand, measure, optimize, and govern. Finish with the consolidated interview prep:
- **[Interview Questions →](./interview-questions.md)** — architect-level performance Q&A across all topics

---

[← Framework Performance](./framework-performance.md) | [Interview Questions →](./interview-questions.md)
