# Network Optimization

Get the bytes to the user as fast as possible — the first optimization phase, because nothing renders until resources arrive.

---

## Navigation
[← Measurement & Profiling](./measurement-profiling.md) | [Asset Optimization →](./asset-optimization.md)

---

## The Network Is the First Bottleneck

```
Before a single pixel paints:
  DNS → TCP → TLS → request → server → response → download
  ↑ all of this is NETWORK + SERVER latency (TTFB)
```

Network optimization attacks three things:
```
1. DISTANCE   how far the bytes travel        → CDN, edge
2. ROUND TRIPS how many back-and-forths       → HTTP/2-3, hints, caching
3. SIZE       how many bytes                   → compression
```

---

## 1. CDN & Edge (Reduce Distance)

A **CDN** serves assets from edge locations physically close to users.

```
Without CDN:  user (India) → origin (US) = high latency every request
With CDN:     user (India) → edge (Mumbai) = low latency, cached
```

- **Static assets** (JS/CSS/images/fonts) → always serve from CDN.
- **Dynamic/SSR** → edge compute (Cloudflare Workers, Vercel Edge, Lambda@Edge) runs logic close to users.
- **Edge caching** of HTML (with smart invalidation) slashes TTFB.

> **Architect note:** the single biggest TTFB win for a global audience is usually putting a CDN/edge in front of everything.

---

## 2. HTTP Caching (Eliminate Round Trips Entirely)

The fastest request is the one you never make. Caching is governed by HTTP headers.

### Cache-Control (the main lever)
```
Cache-Control: public, max-age=31536000, immutable   ← hashed static assets
Cache-Control: no-cache                               ← revalidate before use
Cache-Control: private, max-age=0, must-revalidate    ← HTML (often)
Cache-Control: public, max-age=0, s-maxage=600        ← CDN caches 10min, browser doesn't
```

| Directive | Meaning |
|-----------|---------|
| `max-age=N` | fresh for N seconds (browser) |
| `s-maxage=N` | fresh for N seconds (shared/CDN cache) |
| `immutable` | never revalidate during freshness (perfect for hashed files) |
| `no-cache` | store but revalidate before using |
| `no-store` | never cache (sensitive data) |
| `public`/`private` | shareable by CDN vs browser-only |
| `stale-while-revalidate` | serve stale instantly, refresh in background |

### The Cache-Busting Pattern (essential)
```
app.a1b2c3.js  ← content hash in filename
  → set Cache-Control: max-age=31536000, immutable
  → on change, the hash changes → new URL → no stale-cache problem

index.html     ← short/no cache (references the hashed files)
  → users always get the latest asset map
```

> **Rule:** hash your static assets and cache them forever (`immutable`); keep HTML short-lived. Best of both worlds — aggressive caching with instant updates.

### Validation (conditional requests)
```
ETag / Last-Modified → browser sends If-None-Match / If-Modified-Since
  → server replies 304 Not Modified (no body) if unchanged
  → saves bandwidth, not the round trip
```

---

## 3. Compression (Reduce Size)

Text assets (JS/CSS/HTML/SVG/JSON) compress dramatically.

```
Gzip:     ~70% reduction, universal
Brotli:   ~15-20% better than gzip for text → prefer for static assets
```

- Enable **Brotli** (`br`) with gzip fallback at the server/CDN.
- **Pre-compress** static assets at build time (`.br`/`.gz`) so the server serves them directly.
- Don't compress already-compressed formats (images, video, woff2) — wasted CPU.

```
Content-Encoding: br
Accept-Encoding: gzip, deflate, br   ← browser advertises support
```

---

## 4. HTTP/2 & HTTP/3 (Reduce Round-Trip Cost)

### HTTP/1.1 problems
```
- Head-of-line blocking: limited parallel connections per origin (~6)
- Each request has overhead; many small files = slow
- Led to hacks: domain sharding, sprite sheets, concatenation
```

### HTTP/2 improvements
```
- Multiplexing: many requests over ONE connection (no 6-connection limit)
- Header compression (HPACK)
- Binary protocol, stream prioritization
→ many small files are now OK; sharding/spriting become anti-patterns
```

### HTTP/3 (QUIC)
```
- Runs over UDP (QUIC), not TCP
- Eliminates TCP head-of-line blocking (packet loss doesn't stall all streams)
- Faster connection setup (0-RTT/1-RTT), better on flaky mobile networks
```

> **Architect note:** with HTTP/2-3, **stop bundling everything into one giant file** — fine-grained, cacheable chunks now win (better cache hit rates, parallel download). This pairs with code-splitting (next files).

---

## 5. Resource Hints (Prioritize & Parallelize)

Tell the browser what to fetch early and in what priority. (Mechanics in [rendering-path.md](./rendering-path.md).)

```html
<!-- Warm up a critical third-party origin (DNS+TCP+TLS) -->
<link rel="preconnect" href="https://api.example.com" crossorigin />

<!-- Resolve DNS early for less-critical origins -->
<link rel="dns-prefetch" href="https://cdn.example.com" />

<!-- Fetch a critical, late-discovered resource now -->
<link rel="preload" as="font" href="/fonts/inter.woff2" type="font/woff2" crossorigin />

<!-- Fetch a likely NEXT-page resource at low priority -->
<link rel="prefetch" href="/dashboard.js" />

<!-- Bump the LCP image's priority -->
<img src="/hero.avif" fetchpriority="high" alt="..." />
```

| Hint | When |
|------|------|
| `preconnect` | critical cross-origin (API, font host) — use 2–4 max |
| `dns-prefetch` | other cross-origins |
| `preload` | critical resources the parser finds late (fonts, LCP image, key CSS/JS) |
| `prefetch` | resources for the next likely navigation |
| `fetchpriority` | raise LCP image / lower below-the-fold |
| `modulepreload` | critical ES modules |

> **Caution:** over-using `preload`/`preconnect` causes bandwidth contention and can *hurt* — reserve for genuinely critical resources.

---

## 6. Reduce Requests & Flatten Waterfalls

```
❌ Request waterfall:
   HTML → app.js → (fetch) config.json → (fetch) user.json → render
   (4 serial round trips before content)

✅ Flattened:
   - SSR/stream initial data WITH the HTML
   - preload critical resources in parallel
   - inline tiny critical data
   - combine APIs (BFF/GraphQL) to cut chained calls
```

- Eliminate **client-side fetch chains** — the biggest hidden latency on SPAs.
- A **BFF (Backend-for-Frontend)** can aggregate multiple backend calls into one.

---

## 7. Third-Party Scripts (The Silent Tax)

Third parties (analytics, ads, tags, chat) are a top real-world performance problem.

```
Risks: render-blocking, main-thread hogging, extra connections,
       unpredictable size, single point of failure
```

**Tactics:**
```
- Load async/defer; never render-block on third parties
- Facade pattern: load a lightweight placeholder, hydrate on interaction
  (e.g., a "play" thumbnail that loads the YouTube iframe on click)
- Self-host where licensing allows (fonts, some scripts)
- Use a tag manager budget; audit and remove unused tags
- Subresource Integrity (SRI) + async for safety
- partytown: run third-party JS in a web worker, off the main thread
```

---

## 8. Preloading & Prefetching App Code

Pair with framework routing to speed up navigations:
```
- Preload critical route chunks for the current view
- Prefetch likely-next routes on idle / on link hover / on viewport
- Angular: PreloadAllModules or a custom QuicklinkStrategy
- Frameworks (Next/Nuxt) prefetch in-viewport links automatically
```
```typescript
// Angular: preload lazy routes after initial load
RouterModule.forRoot(routes, { preloadingStrategy: PreloadAllModules });
```

---

## Mapping Problems → Network Levers

```
High TTFB globally     → CDN + edge caching + preconnect
Repeat-visit slowness  → HTTP caching (immutable hashed assets)
Big text payloads      → Brotli compression, pre-compress at build
Many small files slow  → HTTP/2-3 multiplexing (stop concatenating)
Late critical resource → preload + fetchpriority
Serial fetch chains    → SSR/stream data, BFF, flatten waterfall
Slow third parties     → defer/facade/partytown/self-host
Slow navigations       → prefetch next routes
```

---

## Mental Models

### CDN = Local Warehouses
Instead of shipping every order from one distant factory, you stock local warehouses near customers. Delivery (latency) drops dramatically because the goods are already nearby.

### Caching = Keeping the Receipt
Once you've fetched something, keep it so you never pay for it again. Hashed filenames are like versioned product codes — a new version gets a new code, so you never confuse old and new stock.

### HTTP/2 Multiplexing = One Truck, Many Packages
HTTP/1.1 sent one truck per package with a 6-truck limit. HTTP/2 loads many packages onto one truck over a single road — so lots of small packages (chunks) is now efficient, not wasteful.

### Resource Hints = A Smart Assistant
You tell the assistant "we'll need the font and hero image first, the dashboard later." They fetch the urgent things now and prep likely-next things during downtime — but overload them and everything slows.

---

## Common Mistakes

### Mistake 1: No CDN for a Global Audience
❌ Serving everything from one origin → high TTFB far away
✅ CDN for static; edge compute for dynamic/SSR

### Mistake 2: Wrong Caching Strategy
❌ No caching, or caching HTML forever (stale app)
✅ Immutable hashed assets cached forever + short-lived HTML

### Mistake 3: Still Concatenating for HTTP/2
❌ One giant bundle defeats caching and parallelism
✅ Fine-grained cacheable chunks (pairs with code-splitting)

### Mistake 4: No Brotli
❌ Shipping uncompressed or gzip-only text
✅ Brotli with gzip fallback; pre-compress at build

### Mistake 5: Over-Preloading
❌ Preloading everything → bandwidth contention, slower LCP
✅ Preload only genuinely critical, late-discovered resources

### Mistake 6: Ignoring Third-Party Cost
❌ Render-blocking tags and heavy widgets tank performance
✅ Defer, facade, partytown, self-host, audit regularly

### Mistake 7: Client-Side Request Waterfalls
❌ Chained fetches before first render
✅ SSR/stream data, BFF aggregation, preload in parallel

---

## Interview Questions

### Q1: How would you design a caching strategy for a web app's assets?
**Answer:** I separate immutable, content-hashed static assets from frequently-changing HTML. Hashed assets (e.g., `app.a1b2c3.js`) get `Cache-Control: public, max-age=31536000, immutable` so browsers and CDNs cache them forever and never revalidate — and because the hash changes when content changes, there's never a staleness problem; the new build simply references a new URL. The HTML that maps to those assets gets a short or no-cache policy (often `no-cache` with revalidation, or a short `s-maxage` at the CDN with `stale-while-revalidate`), so users always pick up the latest asset references quickly. I add ETags for conditional revalidation, serve everything through a CDN with appropriate `s-maxage`, and use `stale-while-revalidate` to keep responses instant while refreshing in the background. This gives aggressive caching with instant deployability.

### Q2: What changed with HTTP/2 and HTTP/3, and how does it affect frontend architecture?
**Answer:** HTTP/1.1 limited browsers to about six parallel connections per origin and suffered head-of-line blocking, which spawned hacks like bundling everything into one file, image sprites, and domain sharding. HTTP/2 introduced multiplexing — many requests over a single connection — plus header compression and stream prioritization, so many small files are now efficient and those old hacks become anti-patterns. HTTP/3 runs over QUIC/UDP, eliminating TCP-level head-of-line blocking so packet loss doesn't stall all streams, with faster connection setup that especially helps flaky mobile networks. Architecturally this means I favor fine-grained, independently cacheable chunks (which pairs perfectly with route-based code-splitting) over one giant bundle, improving cache hit rates and parallel download, and I drop concatenation/sharding hacks.

### Q3: How do you handle the performance cost of third-party scripts?
**Answer:** Third parties — analytics, ads, chat, tag managers — are a leading real-world performance problem because they can render-block, hog the main thread, open extra connections, and fail unpredictably. My tactics: never let them block rendering — load async or defer; apply the facade pattern for heavy embeds, showing a lightweight placeholder (like a video thumbnail) and only loading the real widget on interaction; self-host where licensing allows (fonts, some scripts) to cut connections and gain caching control; and consider Partytown to run third-party JS in a web worker, off the main thread. I also govern them with a budget, audit and remove unused tags, and add Subresource Integrity for safety. The principle is to contain their cost and keep them off the critical path.

### Q4: What are resource hints and when would you use each?
**Answer:** Resource hints tell the browser what to fetch early and at what priority. `dns-prefetch` resolves DNS for cross-origins you'll use; `preconnect` goes further, establishing DNS, TCP, and TLS for critical third-party origins like an API or font host (I limit it to a few since connections aren't free). `preload` fetches a critical resource the parser discovers late — fonts, the LCP image, key CSS or JS — at high priority. `prefetch` grabs resources for a likely next navigation at low priority. `fetchpriority` lets me raise the LCP image or lower below-the-fold assets, and `modulepreload` preloads ES modules. The caveat is restraint: over-preloading causes bandwidth contention and can hurt LCP, so I reserve hints for genuinely critical or highly-likely resources and validate with measurement.

### Q5: A page has a slow TTFB for international users. How do you fix it?
**Answer:** Slow TTFB for distant users is usually a distance-and-server problem. The biggest lever is a CDN with edge locations near those users, serving static assets from cache and, for dynamic or SSR pages, running logic at the edge (edge compute) so requests don't travel to a single far-away origin. I'd cache HTML at the edge where possible with smart invalidation and `stale-while-revalidate`, and use `preconnect` to warm up critical origins early. On the server side I'd reduce processing time (caching, faster queries, streaming SSR so bytes start flowing sooner) and ensure HTTP/2 or HTTP/3 for faster connection setup, which helps high-latency mobile links. I'd verify the improvement with field RUM segmented by geography, since TTFB is best judged on real international users.

### Q6: Why is flattening request waterfalls important, and how do you do it?
**Answer:** A request waterfall is a chain of dependent requests — HTML loads JS, which fetches config, which fetches data, before anything renders — and each link adds a full network round trip, so latency compounds, which is one of the biggest hidden costs in client-rendered SPAs. To flatten it I move critical data fetching to the server with SSR or streaming so initial data arrives with the HTML; I preload critical resources so they download in parallel rather than being discovered late; I aggregate multiple backend calls behind a Backend-for-Frontend or GraphQL so the client makes one round trip instead of several chained ones; and I inline tiny critical data. The goal is to minimize the number of serial round trips on the path to first meaningful render.

---

## Key Takeaways

- **Network attacks distance, round trips, and size** — CDN, caching/HTTP2-3, compression
- **CDN/edge** is usually the biggest global TTFB win
- **Cache hashed assets forever (`immutable`); keep HTML short-lived**
- **Use Brotli** (gzip fallback); pre-compress static text at build
- **HTTP/2-3 multiplexing** means prefer fine-grained chunks over one big bundle
- **Resource hints** prioritize critical resources — but don't over-preload
- **Flatten request waterfalls** — SSR/stream data, BFF aggregation, preload
- **Tame third parties** — defer, facade, partytown, self-host, audit

---

## What's Next?

Bytes arrive fast — now make the bytes themselves smaller and smarter, starting with the heaviest assets:
- **[Asset Optimization →](./asset-optimization.md)** — images, fonts, CSS delivery

---

[← Measurement & Profiling](./measurement-profiling.md) | [Asset Optimization →](./asset-optimization.md)
