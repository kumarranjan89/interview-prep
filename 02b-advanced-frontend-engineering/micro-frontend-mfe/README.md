# 🧱 Micro-Frontends (MFE) — Reading Guide

This folder covers micro-frontends for **architect / 15+ YOE** interviews. The material is **concept-first**, then **implementation**. Read the files in the order below.

---

## 📖 Read In This Order

| # | File | What it covers | Type |
|---|------|----------------|------|
| 1 | [concepts.md](./concepts.md) | Why MFEs exist, Conway's Law, when (not) to use, decomposition, integration models, communication contracts, trade-offs, decision framework | 🧠 Concept (tool-agnostic) |
| 2 | [composition-routing.md](./composition-routing.md) | How MFEs become one app + cross-team routing — concepts, then Angular/React implementation | 🧠→🛠️ Concept → Tool |
| 3 | [shared-state.md](./shared-state.md) | How MFEs communicate without coupling — coupling spectrum & contracts, then concrete patterns | 🧠→🛠️ Concept → Tool |
| 4 | [module-federation.md](./module-federation.md) | The tooling deep-dive: Webpack Module Federation, shared/singleton, dynamic remotes, Native Federation, Vite | 🛠️ Tooling |
| 5 | [governance.md](./governance.md) | Operating MFEs at scale: versioning, independent deployment, consistency, observability, platform team | 🧠→🛠️ Concept → Ops |

---

## 🗺️ The Learning Path (Why This Order)

```
1. concepts.md          ← understand the WHY and WHAT first (no tools)
        ↓
2. composition-routing  ← how separate apps become one experience
        ↓
3. shared-state         ← how those apps talk without re-coupling
        ↓
4. module-federation    ← HOW to actually build it (the tools)
        ↓
5. governance           ← how to run it at scale, long-term
```

- **Start with `concepts.md`** — everything else assumes you understand boundaries, integration models, and the coupling spectrum.
- **`composition-routing` + `shared-state`** are the two integration dimensions: *structure* (how pieces fit) and *communication* (how pieces talk).
- **`module-federation`** is intentionally **after** the concepts — it's the *implementation* of the run-time integration idea, not the starting point.
- **`governance`** is last because it only matters once you have multiple MFEs in production.

---

## ⏱️ If You're Short on Time

- **30-min refresher:** `concepts.md` only (the architectural judgment + interview Q&A).
- **Interview tomorrow:** `concepts.md` → skim the **Interview Questions** section at the bottom of each file.
- **Hands-on build:** `module-federation.md` (but read `concepts.md` first to avoid building a distributed monolith).

---

## 🎯 What "Good" Looks Like (Architect Bar)

By the end you should be able to:
- Decide **when MFE is justified vs a modular monolith** (and defend it)
- **Draw domain-aligned boundaries** (vertical slices, not layers)
- Explain the **three integration models** and pick one for given constraints
- Choose communication on the **coupling spectrum** (URL → events → shared state)
- Implement run-time integration with **Module Federation / Native Federation**
- Design **versioning, independent deployment, and governance** for many teams
- Recognize and avoid the **distributed monolith**

---

## 🔗 Related Sections
- [Frontend Architecture](../architecture/) — state management, design systems, monorepo, rendering
- [Frontend System Design](../system-design/) — where MFE shows up in design rounds
- [Build & Tooling](../tooling/) — bundler internals behind Module Federation
- [⬆️ Back to Master Index](../../interview-prep-index.md)

---

💡 **Tip:** Read concepts once for understanding, then revisit each file's **Interview Questions** section the day before an interview.
