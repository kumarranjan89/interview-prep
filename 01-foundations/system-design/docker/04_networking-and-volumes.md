# Networking and Volumes

Location: `01-foundations/system-design/docker/networking-and-volumes.md`

`docker-compose-for-local-dev.md` touched networking and volumes practically. This file covers both concepts in depth — how they work, what types exist, and when to use which.

---

## 1. Mental Model

**Networking**: Containers are isolated by default — they can't talk to each other unless they're explicitly placed on a shared network. Docker networking is the mechanism to manage and bridge this isolation.

**Volumes**: Containers are **ephemeral** — data inside disappears when deleted/recreated (a container's writable layer is temporary). Volumes solve this — they **decouple** data from the container's lifecycle.

**One-line mindset**: "Container = disposable compute. Volume = persistent state. Never mix the two — state always lives in a volume, compute is always replaceable."

---

## 2. Architecture Mindset

### Networking — types

| Network type | Use case |
|---|---|
| `bridge` (default) | Single-host container-to-container communication; Compose automatically creates a custom bridge network where services resolve by name |
| `host` | Container directly uses the host's network (no isolation) — for performance-sensitive cases, but with port-conflict risk and weaker isolation |
| `none` | Networking completely disabled — pure isolated compute (rare, security-sensitive batch jobs) |
| `overlay` | Multi-host networking (Swarm/Kubernetes context) — not directly relevant for single-host Docker Compose |

```bash
docker network create my-network
docker run --network=my-network --name=backend backend-image
docker run --network=my-network --name=frontend frontend-image
```
Now the `frontend` container can access `backend` at `http://backend:<port>` — Docker's internal DNS resolves it.

**Port mapping vs internal networking**: `-p 3000:3000` is only needed for **access from the host machine**. Container-to-container communication doesn't need port mapping — it can happen directly over the internal port via the shared network.

### Volumes — types

| Volume type | Behavior |
|---|---|
| **Named volume** | Docker manages the storage location; `docker volume create mydata`, then `-v mydata:/app/data`. Best for persistence (DB data, uploads). |
| **Bind mount** | Maps a specific host path directly: `-v /host/path:/container/path`. Used for live code-sync during dev. |
| **Anonymous volume** | No name, Docker-generated ID. Often used to handle cases like `node_modules` (excluded from within a bind mount). |
| **tmpfs mount** | Stored in memory, never written to disk — for sensitive temporary data (like in-flight secrets). |

```bash
docker run -v db-data:/var/lib/postgresql/data postgres
docker volume ls
docker volume inspect db-data
```

---

## 3. Developer Mindset (Day-to-day usage)

- When debugging networking, check first: are both containers on the **same network**? (`docker network inspect <network-name>`)
- Don't try to access another container using `localhost` — use the service name (in Compose context) or container name (in `docker run --network` context).
- Persistent data (DB, file uploads, cache-that-must-survive-restart) always goes in a named volume — never depend on a container's writable layer.
- Regularly list/clean up volumes — `docker volume ls`, clean unused ones with `docker volume prune` (with caution in production).
- `docker inspect <container>` immediately shows which networks/volumes a container is attached to — a good first debugging step.

---

## 4. Interview-Prep Angle

- **"How do two containers talk to each other?"** — shared Docker network + service/container-name based DNS resolution; port mapping is only for external access, not internal communication.
- **"Why does data disappear on container restart, and what's the solution?"** — a container's writable layer is ephemeral; volumes (named) decouple data from the container's lifecycle.
- **"When would you choose a named volume vs a bind mount?"** — bind mount: dev-time live sync (need host path control); named volume: production persistence (Docker-managed, portable, backup-friendly).
- **"When would you use `host` network mode?"** — when you want to avoid network isolation overhead (performance-critical), trade-off: weaker isolation, port conflicts directly with the host.
- **"How would you back up DB data in a multi-container app?"** — explain the process of backing up/restoring a named volume (a pattern like `docker run --rm -v db-data:/data -v $(pwd):/backup alpine tar czf /backup/db-backup.tar.gz /data`).

---

## 5. Common Mistakes

- Writing data directly inside a container without a volume mount, then being confused about "where did the data go" after a restart.
- Using `localhost` for container-to-container calls (in Compose/custom network context) — should use service/container name instead.
- Treating bind mounts and named volumes as interchangeable — a bind mount is host-path-dependent (machine-specific), a named volume is portable/Docker-managed.
- Accidentally deleting sensitive production DB volumes with `docker volume prune` without checking which containers are using them.
- Running multiple unrelated containers in `host` network mode for "convenience" — increases both port-conflict and security-isolation-loss risk.
- Typo-ing a volume mount path (e.g. not writing Postgres's actual data path `/var/lib/postgresql/data` correctly) — persistence silently fails, everything resets on restart.