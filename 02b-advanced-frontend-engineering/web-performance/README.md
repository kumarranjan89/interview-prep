# ⚡ Web Performance — Reading Guide

Web performance for **architect / 15+ YOE** interviews and real platform work. **Concept-first**, then measurement, then optimization, then operating it at scale.

> **Architect framing:** performance is a **design constraint and a business metric**, not a late-stage cleanup. The flow below mirrors how you'd actually drive performance: *understand → measure → optimize → govern.*

---

## 📖 Read In This Order

| # | File | What it covers | Phase |
|---|------|----------------|-------|
| 1 | [concepts.md](./concepts.md) | Why performance matters (business impact, UX/perception), perceived vs actual, the mental model | 🧠 Concept |
| 2 | [rendering-path.md](./rendering-path.md) | How the browser turns bytes into pixels: critical rendering path, DOM/CSSOM, render/parse-blocking, the event loop | 🧠 Foundation |
| 3 | [core-web-vitals.md](./core-web-vitals.md) | The metrics that matter: LCP, INP, CLS (+ TTFB, FCP) — what they mean and what drives them | 📊 Measure (what) |
| 4 | [measurement-profiling.md](./measurement-profiling.md) | How to measure: Lighthouse, DevTools, WebPageTest, lab vs field, **RUM**, flame charts | 📊 Measure (how) |
| 5 | [network-optimization.md](./network-optimization.md) | Loading fast: HTTP caching, CDN, compression, HTTP/2-3, preload/prefetch/preconnect, priority hints | 🛠️ Optimize |
| 6 | [asset-optimization.md](./asset-optimization.md) | Images (formats, responsive, lazy), fonts (FOUT/FOIT, `font-display`), CSS delivery | 🛠️ Optimize |
| 7 | [javascript-performance.md](./javascript-performance.md) | The JS cost model: bundle optimization, code splitting, tree shaking, lazy loading, hydration cost | 🛠️ Optimize |
| 8 | [runtime-rendering.md](./runtime-rendering.md) | Smooth at runtime: reflow/repaint, long tasks/INP, list virtualization, web workers, memory leaks | 🛠️ Optimize |
| 9 | [framework-performance.md](./framework-performance.md) | Framework-specific: Angular (OnPush, signals, zoneless, bundle) & React (memo, concurrent, RSC) | 🛠️ Optimize |
| 10 | [budgets-governance.md](./budgets-governance.md) | Make it stick: performance budgets, CI gates, monitoring/alerting, performance culture at scale | 🧠→🛠️ Govern |
| ★ | [interview-questions.md](./interview-questions.md) | **Architect-level performance Q&A** across all of the above | 🎯 Interview |

---

## 🗺️ The Learning Path (Why This Order)

```
UNDERSTAND        1. concepts          why it matters, perception
                  2. rendering-path    how the browser actually works
        ↓
MEASURE           3. core-web-vitals   what to measure
                  4. measurement       how to measure (lab + field/RUM)
        ↓
OPTIMIZE          5. network           get the bytes there fast
                  6. assets            images, fonts, CSS
                  7. javascript        the biggest cost on modern apps
                  8. runtime           keep it smooth (INP, jank)
                  9. framework         Angular/React specifics
        ↓
GOVERN           10. budgets & culture  keep it fast forever
```

- **Understand before optimizing** — you can't fix what you don't understand (rendering path) or can't see (metrics).
- **Measure before optimizing** — avoid guessing; let lab + field data point to the real bottleneck.
- **Optimize in load order** — network → assets → JS → runtime mirrors the actual page lifecycle.
- **Govern last** — budgets and culture are what stop regressions over multi-year, multi-team products.

---

## ⏱️ If You're Short on Time

- **30-min refresher:** `concepts.md` + `core-web-vitals.md`.
- **Interview tomorrow:** `core-web-vitals.md` → `interview-questions.md`, skim `rendering-path.md`.
- **Hands-on tuning:** `measurement-profiling.md` first (find the real bottleneck), then the relevant optimize file.

---

## 🎯 What "Good" Looks Like (Architect Bar)

By the end you should be able to:
- Explain performance's **business impact** and tie it to outcomes
- Walk the **critical rendering path** and connect each stage to a lever
- Define **Core Web Vitals** and what drives each (LCP/INP/CLS)
- Distinguish **lab vs field** data and stand up **RUM**
- Diagnose a slow page methodically (measure → isolate → fix → verify)
- Apply the right lever: **network, assets, JS, runtime, framework**
- Set **performance budgets** and enforce them in **CI**
- Build a **performance culture** across teams (governance, not heroics)

---

## 🔗 Related Sections
- [Browser Internals](../browser-internals/) — deeper on rendering, event loop, networking
- [Build & Tooling](../tooling/) — bundlers behind code-splitting/tree-shaking
- [Micro-Frontends](../mfe/README.md) — per-MFE performance budgets & attribution
- [Frontend Architecture](../architecture/) — rendering strategies (CSR/SSR/SSG/ISR)
- [⬆️ Back to Master Index](../../interview-prep-index.md)

---

💡 **Tip:** Performance is *measure → optimize → verify*, always. Read `measurement-profiling.md` before you touch any optimization in anger.
