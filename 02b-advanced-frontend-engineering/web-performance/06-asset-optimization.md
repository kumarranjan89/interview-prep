# Asset Optimization — Images, Fonts & CSS

The heaviest bytes on most pages. Images and fonts dominate payload; CSS gates first paint. Optimize them and LCP/CLS improve directly.

---

## Navigation
[← Network Optimization](./network-optimization.md) | [JavaScript Performance →](./javascript-performance.md)

---

## Why Assets Matter

```
Typical page weight breakdown:
  Images ████████████████ ~50%  (often the LCP element)
  JS     ████████         ~25%
  Fonts  ████             ~10%
  CSS    ███              ~8%
  Other  ██               ~7%
```

Images are usually the **biggest** payload *and* the **LCP element**. Fonts cause **CLS** and text-render delay. CSS is **render-blocking**. Each maps to a Core Web Vital — so asset optimization is high-leverage.

---

## PART 1 — Images (Biggest Win)

### 1. Modern Formats
```
JPEG/PNG (old)  →  WebP (~30% smaller)  →  AVIF (~50% smaller)
SVG for icons/logos/illustrations (vector, tiny, scalable)
```
Serve the best format the browser supports, with fallback:
```html
<picture>
  <source srcset="/hero.avif" type="image/avif" />
  <source srcset="/hero.webp" type="image/webp" />
  <img src="/hero.jpg" alt="..." width="1200" height="600" />
</picture>
```

### 2. Responsive Images (Don't Ship Desktop Images to Phones)
```html
<img
  src="/img-800.webp"
  srcset="/img-400.webp 400w, /img-800.webp 800w, /img-1600.webp 1600w"
  sizes="(max-width: 600px) 100vw, 800px"
  width="800" height="450" alt="..."
/>
```
- `srcset` + `sizes` → browser picks the right size for the device/DPR.
- Huge savings: a phone shouldn't download a 1600px image for a 400px slot.

### 3. Lazy-Load Below-the-Fold (NOT the LCP image)
```html
<!-- Below the fold: defer until near viewport -->
<img src="/photo.webp" loading="lazy" width="800" height="450" alt="..." />

<!-- Above the fold / LCP: eager + high priority -->
<img src="/hero.avif" fetchpriority="high" width="1200" height="600" alt="..." />
```
> **Critical trap:** never `loading="lazy"` the LCP/hero image — it delays LCP.

### 4. Always Set Dimensions (Prevent CLS)
```html
<img src="..." width="800" height="450" alt="..." />   <!-- reserves space -->
```
```css
img { aspect-ratio: 16 / 9; width: 100%; height: auto; } /* fluid + reserved */
```

### 5. Compress & Right-Size
```
- Compress to appropriate quality (often 75–85% is visually lossless)
- Strip metadata; resize to max displayed dimensions
- Tools: sharp, squoosh, imagemin; or an image CDN (Cloudinary,
  imgix, Vercel/Next Image) for on-the-fly format/size/quality
```

> **Architect note:** an **image CDN** that auto-negotiates format/size/quality per request is often the highest-ROI image strategy at scale.

---

## PART 2 — Fonts (CLS + Text Delay)

### The Two Font Problems
```
FOIT (Flash of Invisible Text): text hidden until font loads → blank content
FOUT (Flash of Unstyled Text):  fallback shown, then swaps → layout shift (CLS)
```

### 1. font-display (Control the Swap)
```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter.woff2') format('woff2');
  font-display: swap;      /* show fallback immediately, swap when ready */
}
```
| Value | Behavior | Use |
|-------|----------|-----|
| `swap` | fallback now, swap in font | most text (avoid invisible text) |
| `optional` | use font only if near-instant | best for CLS; may skip the font |
| `fallback` | brief block, short swap window | compromise |
| `block` | invisible up to ~3s | avoid (causes FOIT) |

### 2. Use WOFF2 + Subsetting
```
- WOFF2: best compression, universal support
- Subset to needed characters/languages (latin only? huge savings)
- Only load the weights/styles you actually use
```

### 3. Preload Critical Fonts
```html
<link rel="preload" as="font" href="/fonts/inter.woff2"
      type="font/woff2" crossorigin />
```
- Fonts are discovered late (inside CSS) — preloading the critical one speeds text render.
- `crossorigin` is required even for same-origin font preloads.

### 4. Self-Host (vs Google Fonts CDN)
```
Self-hosting: one fewer origin/connection, full cache control,
              no third-party dependency → often faster + more private
```

### 5. Minimize Layout Shift from Fonts
```css
/* Match fallback metrics to the web font to reduce swap shift */
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter.woff2') format('woff2');
  font-display: swap;
  size-adjust: 100%;
  ascent-override: 90%;   /* tune so fallback ≈ web font dimensions */
}
/* or use a well-matched fallback stack */
body { font-family: 'Inter', system-ui, -apple-system, sans-serif; }
```

---

## PART 3 — CSS (Render-Blocking)

CSS blocks first paint (Chapter: [rendering-path.md](./rendering-path.md)) — so its delivery is critical.

### 1. Critical CSS (Inline Above-the-Fold)
```html
<head>
  <style>/* critical, above-the-fold CSS inlined here */</style>
  <!-- non-critical CSS loaded non-blocking -->
  <link rel="preload" href="/main.css" as="style"
        onload="this.rel='stylesheet'" />
  <noscript><link rel="stylesheet" href="/main.css" /></noscript>
</head>
```
- Inlining critical CSS removes a render-blocking round trip for first paint.
- Tools: `critical`, `critters`, framework plugins auto-extract critical CSS.

### 2. Remove Unused CSS
```
- DevTools Coverage tab → see unused %
- PurgeCSS / built-in purging (Tailwind purges unused utilities)
- Component-scoped CSS (CSS Modules, Angular ViewEncapsulation) limits bloat
```

### 3. Avoid Expensive Patterns
```
- @import chains → serialize requests (use <link> or bundle instead)
- Overly deep/complex selectors → slower style recalculation
- Huge global stylesheets → ship per-route CSS instead
```

### 4. Split CSS by Route
```
Ship only the CSS a route needs (code-split CSS alongside JS chunks)
→ smaller critical CSS, faster first paint per page
```

---

## Mapping Assets → Vitals

```
Images  → LCP (hero), payload, CLS (no dimensions)
Fonts   → CLS (swap), text render delay, payload
CSS     → FCP/LCP (render-blocking), style recalc cost
```

```
Slow LCP from hero image?  → AVIF/WebP + preload + fetchpriority + right size
Big payload on mobile?     → responsive srcset/sizes, image CDN
CLS from images?           → set width/height or aspect-ratio
CLS from fonts?            → font-display optional/swap + size-adjust + preload
Slow first paint?          → inline critical CSS, defer the rest, purge unused
```

---

## Mental Models

### Images = The Heavy Furniture
They're the biggest, heaviest things you move into the room (page). Ship them in the lightest material (AVIF), the right size for the room (responsive), and reserve their floor space first (dimensions) so nothing else has to shuffle (CLS).

### Fonts = A Guest Who's Running Late
You can leave their seat empty and show nothing (FOIT), or seat a stand-in and swap when they arrive (FOUT/swap). Best: pick a stand-in the same size (`size-adjust`) so the table doesn't rearrange when the guest sits down.

### Critical CSS = The Welcome Mat
You inline just enough styling to make the entrance look right immediately, then bring in the rest of the furniture afterward. The visitor sees a finished entryway without waiting for the whole house.

### Image CDN = A Tailor at the Door
Instead of pre-cutting every garment size, a tailor (image CDN) instantly fits each request to the visitor's exact size, device, and preferred fabric (format) — optimal delivery without manual work.

---

## Common Mistakes

### Mistake 1: Lazy-Loading the LCP Image
❌ `loading="lazy"` on the hero → delays LCP
✅ Eager + `fetchpriority="high"` + preload for the LCP element

### Mistake 2: Shipping Oversized Images
❌ One huge image for all devices
✅ Responsive `srcset`/`sizes` or an image CDN

### Mistake 3: Old Formats Only
❌ JPEG/PNG everywhere
✅ AVIF/WebP with `<picture>` fallback; SVG for icons

### Mistake 4: Images/Embeds Without Dimensions
❌ Missing width/height → CLS on load
✅ Set width/height or `aspect-ratio`

### Mistake 5: Font FOIT / Swap Shift
❌ Default `block` (invisible text) or unmatched fallback (CLS)
✅ `font-display: swap`/`optional`, preload, `size-adjust`

### Mistake 6: Render-Blocking, Bloated CSS
❌ One giant blocking stylesheet with lots of unused rules
✅ Inline critical CSS, defer rest, purge unused, split by route

### Mistake 7: Loading Unused Font Weights/Glyphs
❌ Shipping all weights and full character sets
✅ Subset, WOFF2, only the weights you use

---

## Interview Questions

### Q1: How do you optimize images for performance?
**Answer:** Images are usually the largest payload and often the LCP element, so they're high-leverage. I serve modern formats — AVIF or WebP, which are far smaller than JPEG/PNG — using `<picture>` for fallback, and SVG for icons and logos. I ship responsive images with `srcset` and `sizes` so a phone doesn't download a desktop-sized image, or better, use an image CDN that negotiates format, size, and quality per request. I compress to visually-lossless quality and resize to the maximum displayed dimensions. I always set `width`/`height` or `aspect-ratio` to prevent layout shift, lazy-load below-the-fold images with `loading="lazy"`, and crucially eager-load the LCP image with `fetchpriority="high"` and a preload — never lazy-load the hero, which is a common self-inflicted LCP regression.

### Q2: Explain FOIT vs FOUT and how you manage font loading.
**Answer:** FOIT (Flash of Invisible Text) is when text stays invisible until the web font downloads, leaving blank content; FOUT (Flash of Unstyled Text) is when a fallback font shows first then swaps to the web font, which can cause a layout shift if the metrics differ. I manage this primarily with `font-display`: `swap` shows the fallback immediately and avoids invisible text, while `optional` is best for CLS because it only uses the font if it loads almost instantly. I use WOFF2 with subsetting to cut size, load only the weights I actually use, and preload the critical font (with `crossorigin`) since fonts are discovered late inside CSS. To minimize swap-induced shift I match fallback metrics using `size-adjust`/`ascent-override` or a well-matched system fallback stack, and I often self-host to drop a third-party connection.

### Q3: Why is CSS render-blocking and how do you optimize its delivery?
**Answer:** CSS is render-blocking because the browser won't paint until it has the full CSSOM — painting earlier would risk showing unstyled or wrongly-styled content and then repainting. So all CSS referenced in the head delays first paint and affects FCP and LCP. I optimize delivery by extracting and inlining the critical, above-the-fold CSS directly in the document so first paint doesn't wait on a network round trip, and loading the rest non-blocking (preload-then-swap, with a `<noscript>` fallback). I remove unused CSS using the Coverage tab and tools like PurgeCSS (Tailwind purges automatically), scope styles to components to limit bloat, avoid `@import` chains that serialize requests, and split CSS per route so each page ships only what it needs. The goal is a tiny immediate critical payload with everything else deferred.

### Q4: When should you lazy-load images and when should you not?
**Answer:** Lazy-load images that are below the fold or off-screen — content further down the page, images in long lists or carousels not initially visible — using the native `loading="lazy"` attribute, which defers their download until they're near the viewport and saves bandwidth and main-thread work. You should never lazy-load above-the-fold images, especially the LCP element like a hero image, because deferring it pushes back the largest contentful paint and directly worsens LCP — a very common mistake. For the LCP image I do the opposite: load it eagerly, preload it, and set `fetchpriority="high"`. The rule is eager and prioritized for what's immediately visible, lazy for everything else.

### Q5: What's the highest-ROI image strategy at scale, and why?
**Answer:** At scale, an image CDN (Cloudinary, imgix, or framework-integrated solutions like Next/Vercel Image) is usually the highest-ROI approach. Instead of manually pre-generating every format and size, the CDN transforms images on the fly per request: it negotiates the best format the browser supports (AVIF/WebP), resizes to the requested dimensions and device pixel ratio, applies quality compression, strips metadata, and caches the result at the edge. This automates responsive `srcset` generation, guarantees modern formats with fallback, and offloads the work from build pipelines and developers, so it scales across thousands of images and teams without manual effort. The result is consistently optimal delivery — smaller payloads and better LCP — with minimal ongoing maintenance.

### Q6: How do assets relate to the Core Web Vitals?
**Answer:** Each asset type maps to a vital, which makes asset optimization a direct lever on CWV. Images affect LCP when the hero is the largest element, drive overall payload, and cause CLS when they lack reserved dimensions — so modern formats, preloading the LCP image, responsive sizing, and setting width/height address both LCP and CLS. Fonts cause CLS through swap-induced layout shifts and delay text rendering, so `font-display`, preloading, subsetting, and metric-matched fallbacks help stability and perceived speed. CSS is render-blocking, so it affects FCP and LCP — inlining critical CSS and deferring the rest speeds first paint. Knowing these mappings lets me target a failing vital with the specific asset technique that moves it.

---

## Key Takeaways

- **Images are the biggest win** — AVIF/WebP, responsive `srcset`, compress, right-size
- **Never lazy-load the LCP image**; lazy-load below-the-fold only
- **Always set image dimensions** (`width`/`height` or `aspect-ratio`) to prevent CLS
- **An image CDN** is often the highest-ROI strategy at scale
- **Fonts:** WOFF2 + subset, `font-display: swap`/`optional`, preload, `size-adjust`
- **Self-host fonts** to drop a third-party connection and gain cache control
- **CSS is render-blocking** — inline critical, defer rest, purge unused, split by route
- **Each asset maps to a vital** — images→LCP/CLS, fonts→CLS, CSS→FCP/LCP

---

## What's Next?

Assets are lean — now tackle the most expensive resource on modern apps:
- **[JavaScript Performance →](./javascript-performance.md)** — bundles, code splitting, tree shaking

---

[← Network Optimization](./network-optimization.md) | [JavaScript Performance →](./javascript-performance.md)
