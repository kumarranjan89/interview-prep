# Networking Basics — What Happens When You Hit Enter

## Scope of This Topic

This is the layer **before** rendering even starts — the browser can't parse a single byte of HTML until this pipeline completes. Classic "type a URL and press enter" question, and the actual foundation under most system-design/architecture discussions.

```
URL entered
    |
    v
[ DNS Resolution ]      → domain name → IP address
    |
    v
[ TCP Handshake ]       → reliable connection established (3-way handshake)
    |
    v
[ TLS Handshake ]       → encryption negotiated (if HTTPS)
    |
    v
[ HTTP Request/Response ] → actual data transfer
    |
    v
Browser starts parsing HTML → Critical Rendering Path begins (see browser-rendering.md)
```

## DNS Resolution

Translates a human-readable domain into an IP address, checked in order until a hit:

```
Browser cache → OS cache → Router cache → ISP resolver
    → (if all miss) Root DNS server → TLD server (.com) → Authoritative server
```

- **TTL (Time To Live)** on each DNS record controls how long it's cached — lower TTL = faster failover/updates but more lookup overhead, higher TTL = fewer lookups but slower to propagate changes.
- **DNS lookup is a real, measurable latency cost** on cold requests (no cache hit) — commonly 20-120ms depending on resolver chain length.

## TCP Handshake (3-way)

```
Client → SYN         → Server
Client ← SYN-ACK      ← Server
Client → ACK          → Server
    (connection established, data transfer can begin)
```

This is **1 full round-trip** before any application data moves — on a high-latency connection (mobile, cross-continent), this alone can cost 100-300ms before a single byte of the actual request is sent.

## TLS Handshake (HTTPS)

Adds encryption negotiation on top of TCP:

- **TLS 1.2**: 2 round-trips to establish
- **TLS 1.3**: 1 round-trip (or **0-RTT** for resumed sessions) — significant latency win, why TLS 1.3 adoption matters at scale

```
Client Hello (supported ciphers) → Server
Server Hello + Certificate       → Client
Client verifies cert, generates session key
    (encrypted channel established)
```

**Certificate chain validation** happens here too — browser walks up to a trusted root CA; a broken chain (missing intermediate cert) is a common real-world outage cause.

## HTTP Request/Response Cycle

Once the connection is secure, the actual request happens. Version matters a lot for performance:

| Version | Connection Model | Key Limitation |
|---|---|---|
| HTTP/1.1 | New connection per request (or limited keep-alive, ~6 per domain) | Head-of-line blocking — requests queue behind each other |
| HTTP/2 | Single multiplexed connection, multiple parallel streams | Still TCP-level head-of-line blocking (one lost packet stalls all streams) |
| HTTP/3 (QUIC) | Built on UDP, independent streams | Solves TCP head-of-line blocking entirely — packet loss on one stream doesn't stall others |

This is why **domain sharding** (splitting assets across multiple subdomains, an HTTP/1.1-era trick to bypass the 6-connection limit) is now an **anti-pattern** under HTTP/2+ — it defeats multiplexing and adds redundant TLS handshakes.

## Caching Layers (in order of proximity to the user)

```
Browser cache (Cache-Control, ETag)
    → Service Worker cache (if registered)
        → CDN edge cache
            → Reverse proxy / origin cache
                → Application/DB cache (Redis etc.)
                    → Origin server
```

- **`Cache-Control: max-age`** — how long browser/CDN can serve without revalidation
- **`ETag`** — conditional revalidation (304 Not Modified) without re-downloading the body
- Each layer you hit *before* origin saves a full round-trip — this stacking is the actual mechanism behind "CDN makes sites fast," not magic.

## Mental Model Summary

- Nothing renders until DNS + TCP + TLS + first HTTP response all complete — this entire chain is pure latency overhead before the Critical Rendering Path even starts.
- TCP/TLS handshakes are round-trip-costly — this is why connection reuse (keep-alive, HTTP/2 multiplexing) matters more than raw bandwidth on most modern connections.
- HTTP/2 fixed app-level head-of-line blocking; HTTP/3/QUIC fixed the remaining TCP-level blocking by dropping TCP entirely.

## Fullstack Angle — What You'd Actually Debug

- **Slow API response, first request only** → likely DNS/TCP/TLS cold-start cost, not your server code — check with browser DevTools Network waterfall (look at "Stalled," "DNS Lookup," "Connecting," "TLS" timing breakdown before "Waiting/TTFB").
- **Repeated identical asset downloads** → missing/misconfigured `Cache-Control` or `ETag` headers.
- **Many small requests feeling slow on HTTP/1.1 but fine on HTTP/2** → confirms multiplexing is doing real work; verify your CDN/server actually negotiates HTTP/2 (`h2` in DevTools protocol column).

## Architect Angle — What You'd Actually Decide

- **CDN placement**: pushing static assets + edge caching close to users cuts DNS+TCP+TLS+RTT cost per region — direct latency/SLA decision, not just a cost optimization.
- **TLS termination point**: terminate at edge/CDN (fast, but origin doesn't see raw TLS) vs terminate at origin (more control, more latency) — a real trade-off in zero-trust/security-sensitive architectures.
- **HTTP/3 adoption**: worth prioritizing for mobile-heavy or high-packet-loss user bases (lossy networks benefit most from QUIC's independent streams); lower priority for stable datacenter-to-datacenter traffic.
- **Connection pooling strategy**: for backend-to-backend calls (microservices), keep-alive connection pools avoid repeated TCP/TLS handshake cost per request — a common overlooked latency source in service-to-service chains.

## Interview Q&A Rapid Fire

**Q: Walk me through what happens when you type a URL and hit enter.**
DNS resolves domain → IP (checking browser/OS/ISP caches first, falling back to root/TLD/authoritative servers) → TCP 3-way handshake establishes a connection → TLS handshake negotiates encryption (1-RTT on TLS 1.3, 0-RTT if resuming) → HTTP request sent, response returned → browser begins parsing HTML and building the DOM.

**Q: Why is HTTP/2 multiplexing better than HTTP/1.1 keep-alive?**
HTTP/1.1 limits parallel requests per domain (~6) and each blocks behind the others on that connection; HTTP/2 uses one connection with independent streams, eliminating that application-level head-of-line blocking.

**Q: Why does HTTP/3 exist if HTTP/2 already solved head-of-line blocking?**
HTTP/2 still runs over TCP, where one lost packet stalls the entire connection (TCP itself is ordered). HTTP/3 runs over QUIC/UDP, where streams are independent — packet loss on one stream doesn't block the others.

**Q: What's the practical difference between `Cache-Control` and `ETag`?**
`Cache-Control` avoids the request entirely within its `max-age` window. `ETag` still makes a request but allows a cheap `304 Not Modified` response (no body transfer) if the resource hasn't changed — useful once the cache window expires but content is often still valid.