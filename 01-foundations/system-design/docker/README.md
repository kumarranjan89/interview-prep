# Docker

Location: `01-foundations/system-design/docker/`

The goal here isn't to memorize commands — it's to understand "how code reaches a machine consistently and reproducibly," which is really an execution-layer extension of system design.

---

## 1. Mental Model

The simplest way to think about Docker: **"Container = Process + its own bubble of filesystem, isolated from the host."**

- **VM vs Container**: A VM carries its entire OS kernel (heavy, boots in minutes). A container shares the host's kernel and only carries its own filesystem/dependencies (lightweight, boots in seconds).
- **Image vs Container**: Image = read-only blueprint (class). Container = a running instance of that blueprint (object). Multiple containers can spin up from one image.
- **Layers**: Every `Dockerfile` instruction (`RUN`, `COPY`, etc.) creates a new layer. Layers are cached — so instruction order matters (put things that change less often near the top, e.g. `COPY package.json` + `npm install` before copying source code).
- **Isolation via Linux primitives**: Docker isn't magic — it uses namespaces (process/network/filesystem isolation) and cgroups (resource limits), both already provided by the Linux kernel.

**One-line mindset**: Docker is a packaging tool, not a virtualization tool. It guarantees "same environment everywhere," not "separate OS everywhere."

---

## 2. Architecture Mindset

Through a system-design lens, these questions become relevant:

- **Image size discipline**: Use multi-stage builds — build stage has all the tooling, final stage has only the runtime artifact + a minimal base image (`alpine`, `distroless`). This reduces both deploy time and attack surface.
- **Statelessness**: Treat containers as stateless. Persistent data (DB, uploads) belongs in named volumes or bind mounts — data shouldn't vanish when a container is deleted.
- **One process per container (mostly)**: One container = one concern (frontend, backend, DB as separate containers). This keeps scaling, restarts, and debugging independent of each other.
- **Networking**: In `docker-compose`, services resolve each other by service name (built-in DNS) — not `localhost` — for container-to-container communication.
- **Local dev parity**: The entire stack (frontend + backend + DB + cache) should spin up with one `docker-compose` command — this is what actually solves the "works on my machine" problem.

---

## 3. Developer Mindset (Day-to-day usage)

- While writing a Dockerfile, always ask first: "where will the cache invalidate?" — put dependency-install steps before copying source code.
- Always create a `.dockerignore` file (`node_modules`, `.git`, `dist` excluded) — otherwise the build context gets bloated and builds slow down.
- For debugging, go inside the container directly with `docker exec -it <container> sh` and inspect — don't guess.
- Run `docker-compose up -d` for detached local dev, check logs with `docker-compose logs -f <service>`.
- Don't bake environment-specific config (`.env` files) into the image — inject it at runtime (12-factor app principle).

---

## 4. Interview-Prep Angle

Common areas that come up in principal/staff-level interviews:

- **"Docker vs VM"** — clearly differentiate kernel-sharing vs full OS virtualization, and the trade-offs (density, boot time, isolation strength).
- **"How would you reduce image size?"** — multi-stage builds, smaller base images, layer caching, removing build-time dependencies from the final image.
- **"How does container networking work?"** — bridge network (default), host network, custom networks, service discovery via DNS in compose/orchestration.
- **"How do you handle secrets/config?"** — env vars at runtime, secret managers (never baked into the image, never committed in a Dockerfile).
- **"What happens to data when a container restarts/dies?"** — ephemeral by default; volumes are needed for persistence. Be ready to explain volume types (named vs bind mount).
- **"Why use Docker in a microservices/frontend context?"** — consistent build/runtime environment across dev/staging/prod, easier onboarding, isolation between services with different dependency versions.

Frontend-specific angle worth mentioning: a multi-stage build where the build stage runs `npm run build` (React/Angular), and the final stage serves only the static output through a lightweight nginx image — a concrete, high-signal example for discussion.

---

## 5. Common Mistakes

- Running multiple unrelated processes in a single container (frontend + backend + DB all in one image) — makes debugging and scaling harder.
- Copying `node_modules` from host into the container instead of letting the container run `npm install` itself — creates platform mismatch issues (especially with native dependencies).
- Forgetting `.dockerignore` — bloats build context and can accidentally ship secrets/files into the image.
- Depending on the `latest` tag in production — breaks reproducibility; always pin a specific version tag.
- Treating a container like a VM (SSH-ing in, manually making changes, then reusing that same image) — containers should be immutable, changes belong in the Dockerfile.
- Running the container as root — specifying a non-root user in the Dockerfile is a security best practice.

---

## Suggested Sub-topics (files to add here as this grows)

- `dockerfile-basics.md`
- `multi-stage-builds.md`
- `docker-compose-for-local-dev.md`
- `networking-and-volumes.md`
- `frontend-container-patterns.md` (Angular/React build → nginx serve pattern)