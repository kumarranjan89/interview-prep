# Docker Compose for Local Dev

Location: `01-foundations/system-design/docker/docker-compose-for-local-dev.md`

`multi-stage-builds.md` was about the production image. This file is about local development — where the goal is speed and convenience, not size optimization.

---

## 1. Mental Model

Docker Compose is a tool for **defining and running multiple containers together**, through a single YAML file (`docker-compose.yml`).

**Core idea**: A real app is never just one container — frontend, backend, database, cache (Redis) are all separate services that need to run together. Compose orchestrates all of them with one command (`docker-compose up`).

- Each entry is a **service** (which internally becomes a container).
- Services can resolve each other **by service name** — thanks to built-in DNS (`http://backend:5000`, not `localhost`).
- This solves the problem of "spin up the whole stack locally with one command" — a new developer runs `docker-compose up` and everything just works.

---

## 2. Architecture Mindset

**Example — frontend + backend + DB stack:**

```yaml
version: "3.9"
services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend:/app
      - /app/node_modules
    depends_on:
      - backend

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb
    volumes:
      - db-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  db-data:
```

**Key concepts:**

| Concept | Purpose |
|---|---|
| `services` | Each entry is an independent container definition |
| `build` vs `image` | `build`: build from a local Dockerfile; `image`: use an existing registry image (e.g. `postgres`) |
| `ports` | `host:container` mapping — for access from the host machine |
| `volumes` (bind mount) | Mounts a host folder into the container — code changes reflect instantly (hot-reload) |
| `volumes` (named, top-level) | Persistent data storage — survives container restart/deletion (e.g. DB data) |
| `depends_on` | Defines startup order (but doesn't guarantee readiness — a DB might be "started" but not yet "ready to accept connections") |
| `environment` | Injects environment variables, keeping config separate from code |
| Networking | By default, all services share a network and are reachable by service name |

**Bind mount trick for node_modules**: `./frontend:/app` mounts the entire host folder, but `/app/node_modules` is kept as a separate anonymous volume — this prevents the host's (potentially OS-incompatible) `node_modules` from overwriting the container's.

---

## 3. Developer Mindset (Day-to-day usage)

- `docker-compose up -d` — run the whole stack in detached mode.
- `docker-compose logs -f <service-name>` — watch a specific service's logs live.
- `docker-compose down` — stop + remove all containers (data volumes survive by default, `-v` flag removes those too).
- `docker-compose exec <service> sh` — go inside a running container to debug directly.
- Make a code change → if bind mount + the framework's hot-reload (Vite, nodemon, Angular CLI) is set up, no container restart needed, changes reflect live.
- `depends_on` only guarantees start **order**, not service **readiness** — if the backend tries to connect to the DB immediately and the DB isn't ready to accept connections yet, you need retry-logic or a `healthcheck` + `condition: service_healthy`.

---

## 4. Interview-Prep Angle

- **"How do you run multiple services locally in a consistent way?"** — spin up the whole stack with one command via `docker-compose.yml`, solving the "works on my machine" problem.
- **"How do services communicate with each other in Compose?"** — shared Docker network + service-name-based DNS resolution, not `localhost`.
- **"What does `depends_on` guarantee, and what doesn't it?"** — only container start order, not service readiness; readiness needs healthchecks.
- **"Would you use the same Dockerfile for development and production?"** — generally no; dev needs bind-mount + hot-reload (fast feedback), prod needs a multi-stage optimized immutable image (no mounts, no live-editing).
- **"What's the difference between a named volume and a bind mount?"** — a bind mount maps a specific host filesystem path (for dev, live sync); a named volume is Docker-managed storage, for persistence (DB data), host path irrelevant.

---

## 5. Common Mistakes

- Assuming `depends_on` guarantees readiness — the DB has literally just started, and the backend fails on its connection attempt.
- Using the same dev `docker-compose.yml` in production too (bind mounts, directly exposed DB ports) — security and performance risk.
- Including `node_modules` in a bind mount without the anonymous-volume trick — native dependencies (like `node-sass`, `bcrypt`) crash due to OS mismatch.
- Hardcoding secrets (DB passwords, API keys) directly in `docker-compose.yml` and committing it — use a `.env` file and `.gitignore` it.
- Accidentally deleting named volumes with `docker-compose down -v` — can cause production/important local data loss if the `-v` flag is used without checking.
- Trying to run a separate `docker-compose up` per service instead of defining everything in one file and managing the whole stack with one command.