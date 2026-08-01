# Browser Multi-Process Architecture

## Scope of This Topic

Modern browsers (Chrome, Edge, and Chromium-based browsers) are **not** a single process running everything. Understanding this boundary explains why one tab crashing doesn't kill the browser, why a heavy JS loop in one tab doesn't freeze others, and it's the direct analogy point for microservice/process-isolation architecture discussions.

```
Browser Process (1, coordinates everything)
    |
    |-- Renderer Process (1 per tab/site, sandboxed)
    |     |-- Main thread: JS execution, DOM, layout, paint
    |     |-- Compositor thread: handles compositing, scrolling
    |     |-- Worker threads (if Web Workers used)
    |
    |-- GPU Process (1, shared) — handles actual GPU rendering/compositing
    |
    |-- Network Process (1, shared) — handles all network requests
    |
    |-- Plugin/Utility Processes (as needed)
```

## Why Separate Processes At All

- **Fault isolation**: a renderer crash (e.g. a tab hitting `RangeError` in a tight loop, or a native crash in a plugin) kills *that tab's* renderer process only — browser process and other tabs survive. This is literally why Chrome shows "Aw, Snap!" for one tab instead of the whole browser dying.
- **Security sandboxing**: each renderer process runs in a restricted OS-level sandbox with minimal system access — a compromised renderer (e.g. via a malicious page exploiting a JS engine bug) can't directly touch the file system or other tabs without going through the sandboxed IPC boundary to the browser process.
- **Performance isolation**: a JS-heavy tab maxing out its renderer's main thread doesn't block other tabs' rendering, since each has its own process and thread.

## Site Isolation

Each renderer process is generally scoped to a **single site** (not just a tab) — meaning cross-origin iframes on the same page can run in *different* renderer processes from their parent page.

```
example.com page (renderer process A)
    |
    |-- <iframe src="ads.example-ads.com">  ← different renderer process B
    |-- <iframe src="analytics.tracker.com"> ← different renderer process C
```

This exists specifically to mitigate cross-origin data leaks (Spectre-class side-channel attacks made this critical — pure JS-level origin checks weren't enough once speculative execution could leak memory across a shared process boundary).

## Where "Main Thread" Actually Lives

When people say "don't block the main thread," they mean the **renderer process's main thread** — specific to that tab/site, not the whole browser:

```
Renderer Process (per tab)
    |-- Main thread     ← JS execution, DOM, style calc, layout, paint recording
    |-- Compositor thread ← takes painted layers, positions them, handles scroll/pinch-zoom smoothly even if main thread is busy
    |-- Raster threads  ← convert paint records into actual bitmaps
```

**This is why `transform`/`opacity`-only animations stay smooth even if the main thread is briefly busy** — the compositor thread can still shift already-painted layers around without needing the main thread at all, connecting directly back to the rendering-flow notes.

## Inter-Process Communication (IPC)

Processes are isolated (no shared memory) — the Browser Process and Renderer Processes communicate over **IPC** for anything that crosses the boundary: navigation, resource loading, permission prompts, clipboard access, etc. This adds a small overhead but is the actual security boundary — a renderer literally cannot access the file system directly; it must ask the Browser Process via IPC, which enforces permissions.

## Mental Model Summary

- Browser = one coordinating process + many specialized/sandboxed processes (renderer per site, shared GPU, shared network).
- Renderer crash/freeze is isolated to that process — doesn't take down the browser or unrelated tabs.
- Site Isolation puts cross-origin iframes in separate processes specifically as a security boundary, not just an implementation detail.
- Compositor thread (inside the renderer process) is why some animations stay smooth even under main-thread pressure — ties directly to the `transform`/`opacity` cost discussion in rendering-flow notes.

## Fullstack Angle — What You'd Actually Debug

- **"My animation stutters but only sometimes"** → check if it's using compositor-only properties (`transform`/`opacity`) vs properties that need main-thread layout/paint — main thread contention (heavy JS) won't affect the former.
- **Cross-origin iframe communication issues** (can't directly access iframe's DOM/variables) → this isn't just a JS same-origin-policy quirk, it's often literally a **different OS process** — `postMessage` is the only sanctioned channel for a reason.
- **One tab freezing doesn't freeze the browser** → expected behavior, not a "browser bug" — confirms process isolation is working as designed when explaining behavior to less experienced teammates.

## Architect Angle — What You'd Actually Decide

- **Iframe-based micro-frontend isolation**: Site Isolation gives genuine process-level isolation for embedded micro-frontends from different teams/origins — a stronger boundary than same-process JS module isolation, worth citing when justifying an iframe-based micro-frontend approach over a single-SPA-shell approach.
- **CSP (Content Security Policy) design**: process sandboxing is the OS-level backstop; CSP is the application-level policy layer on top — both matter, and architects should treat CSP misconfiguration as a real attack surface, not boilerplate.
- **Third-party script risk**: an untrusted third-party script (ads, widgets) sharing your page's renderer process (unless it's in a sandboxed iframe) can still access your page's DOM/cookies within that process — informs the decision to sandbox third-party embeds in iframes rather than inline `<script>` tags.
- **Microservices analogy for stakeholder communication**: "renderer-per-site with IPC to a coordinating process" is functionally the same pattern as service-per-domain with an API gateway — useful analogy when explaining browser architecture trade-offs to a team already fluent in backend service isolation.

## Interview Q&A Rapid Fire

**Q: Why doesn't a crashed tab take down the whole browser?**
Each tab/site typically runs in its own sandboxed Renderer Process, separate from the coordinating Browser Process; a crash in one renderer doesn't affect the browser process or other renderers.

**Q: What is Site Isolation and why was it introduced?**
Each renderer process is scoped to a single site, so cross-origin iframes run in separate processes from their parent page — introduced primarily to mitigate Spectre-class speculative execution attacks that could otherwise leak cross-origin memory within a shared process.

**Q: Why can `transform`/`opacity` animations stay smooth even when the main thread is busy?**
Because compositing happens on a separate compositor thread within the renderer process — once a layer is painted, the compositor can reposition/fade it without needing the main thread, unlike layout-triggering properties which require main-thread work every frame.

**Q: How do isolated renderer processes communicate with the browser process?**
Via IPC (Inter-Process Communication) — there's no shared memory; anything requiring system access (file system, network, permissions) goes through IPC to the Browser Process, which enforces the actual permission boundary.