# Docker

Location: `01-foundations/system-design/docker/`

Docker samajhne ka goal yahan sirf commands ratna nahi hai — goal hai ye samajhna ki "code ek machine se doosri machine tak consistently kaise pahunchta hai," jo ki system-design ka hi ek execution-layer extension hai.

---

## 1. Mental Model

Docker ko samajhne ka sabse simple tareeka: **"Container = Process + apna bubble of filesystem, isolated from host."**

- **VM vs Container**: VM apna poora OS kernel carry karta hai (heavy, minutes mein boot hota hai). Container host ke kernel ko share karta hai, sirf apna filesystem/dependencies carry karta hai (light, seconds mein boot hota hai).
- **Image vs Container**: Image = read-only blueprint (class). Container = running instance of that blueprint (object). Ek image se multiple containers spin ho sakte hain.
- **Layers**: Har `Dockerfile` instruction (`RUN`, `COPY`, etc.) ek naya layer banata hai. Layers cache hote hain — isliye Dockerfile mein instruction order matter karta hai (jo cheez kam badalti hai wo upar rakho, jaise `package.json` copy + `npm install`, phir source code copy).
- **Isolation via Linux primitives**: Docker koi jaadu nahi karta — namespaces (process/network/filesystem isolation) aur cgroups (resource limits) ka use karta hai, jo Linux kernel already provide karta hai.

**One-line mindset**: Docker packaging tool hai, virtualization tool nahi. Ye "same environment everywhere" guarantee deta hai, "separate OS everywhere" nahi.

---

## 2. Architecture Mindset

Jab tum Docker ko system design ke lens se dekhte ho, ye questions relevant ho jaate hain:

- **Image size discipline**: Multi-stage builds use karo — build stage mein saara tooling ho, final stage mein sirf runtime artifact + minimal base image (`alpine`, `distroless`). Isse attack surface aur deploy time dono kam hote hain.
- **Statelessness**: Container ko stateless treat karo. Persistent data (DB, uploads) ko named volumes ya bind mounts mein rakho — container delete hone par data nahi udna chahiye.
- **One process per container (mostly)**: Ek container = ek concern (frontend, backend, DB alag-alag containers). Isse scaling, restart, aur debugging independent ho jaate hain.
- **Networking**: `docker-compose` mein services apne service-name se ek doosre ko resolve karte hain (built-in DNS), isliye `localhost` ke bajaye service name use hota hai container-to-container communication mein.
- **Local dev parity**: `docker-compose.yml` se poora stack (frontend + backend + DB + cache) ek command mein spin ho jaana chahiye — "works on my machine" problem yahi solve karta hai.

---

## 3. Developer Mindset (Day-to-day usage)

- Dockerfile likhte waqt sabse pehle socho: "cache kahan invalidate hoga?" — dependency install steps ko source-code copy se pehle rakho.
- `.dockerignore` file zaroor banao (`node_modules`, `.git`, `dist` exclude karo) — warna build context bloated ho jaata hai aur build slow.
- Debugging ke liye `docker exec -it <container> sh` se andar ja kar directly inspect karo, guesswork mat karo.
- `docker-compose up -d` se detached mode mein chalao local dev ke liye, logs `docker-compose logs -f <service>` se dekho.
- Environment-specific config (`.env` files) ko image ke andar bake mat karo — runtime par inject karo (12-factor app principle).

---

## 4. Interview-Prep Angle

Common areas jo principal/staff-level interviews mein touch hote hain:

- **"Docker vs VM"** — clearly differentiate kernel-sharing vs full OS virtualization, aur trade-offs (density, boot time, isolation strength).
- **"How would you reduce image size?"** — multi-stage builds, smaller base images, layer caching, removing build-time dependencies from final image.
- **"How does container networking work?"** — bridge network (default), host network, custom networks, service discovery via DNS in compose/orchestration.
- **"How do you handle secrets/config?"** — env vars at runtime, secret managers (not baked into image, not committed to Dockerfile).
- **"What happens to data when a container restarts/dies?"** — ephemeral by default; volumes needed for persistence. Be ready to explain volume types (named vs bind mount).
- **"Why use Docker in a microservices/frontend context?"** — consistent build/runtime environment across dev/staging/prod, easier onboarding, isolation between services with different dependency versions.

Frontend-specific angle worth mentioning: multi-stage build jahan build stage mein `npm run build` chale (React/Angular), aur final stage mein sirf static output ek lightweight nginx image mein serve ho — ye ek concrete, high-signal example hai discussion mein.

---

## 5. Common Mistakes

- Ek hi container mein multiple unrelated processes chalana (frontend + backend + DB sab ek image mein) — debugging aur scaling dono mushkil ho jaate hain.
- `node_modules` ko host se container mein copy karna instead of container ke andar `npm install` chalane dena — platform mismatch (especially native dependencies) issues create karta hai.
- `.dockerignore` bhool jaana — build context bloat aur accidental secrets/files image mein chale jaana.
- `latest` tag pe depend karna production mein — reproducibility break hoti hai; hamesha specific version tag pin karo.
- Container ko VM jaisa treat karna (SSH karke manually andar changes karna, phir wahi image reuse karna) — container immutable hona chahiye, changes Dockerfile mein hone chahiye.
- Root user se container run karna — security best practice hai non-root user specify karna Dockerfile mein.

---

## Suggested Sub-topics (files to add here as this grows)

- `dockerfile-basics.md`
- `multi-stage-builds.md`
- `docker-compose-for-local-dev.md`
- `networking-and-volumes.md`
- `frontend-container-patterns.md` (Angular/React build → nginx serve pattern)