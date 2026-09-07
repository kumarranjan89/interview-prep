# Networking and Volumes

Location: `01-foundations/system-design/docker/networking-and-volumes.md`

`docker-compose-for-local-dev.md` mein networking aur volumes dono touch hue the practically. Ye file dono concepts ko deeply cover karti hai — kaise kaam karte hain, kitne types hain, aur kab kaunsa use karna hai.

---

## 1. Mental Model

**Networking**: Containers by default isolated hote hain — ek doosre se baat nahi kar sakte jab tak explicitly ek shared network par na ho. Docker networking is isolation ko manage aur bridge karne ka mechanism hai.

**Volumes**: Containers **ephemeral** hote hain — delete/recreate hone par andar ka data gayab ho jaata hai (container ki writable layer temporary hai). Volumes is problem ko solve karte hain — data ko container ke lifecycle se **decouple** karte hain.

**One-line mindset**: "Container = disposable compute. Volume = persistent state. In dono ko kabhi mix mat karo — state hamesha volume mein, compute hamesha replaceable."

---

## 2. Architecture Mindset

### Networking — types

| Network type | Use case |
|---|---|
| `bridge` (default) | Single-host container-to-container communication; Compose automatically ek custom bridge network banata hai jisme services naam se resolve hote hain |
| `host` | Container host ki network directly use karta hai (no isolation) — performance-sensitive cases, but port-conflict risk aur weaker isolation |
| `none` | Networking completely disabled — pure isolated compute (rare, security-sensitive batch jobs) |
| `overlay` | Multi-host networking (Swarm/Kubernetes context) — single-host Docker Compose mein directly relevant nahi |

```bash
docker network create my-network
docker run --network=my-network --name=backend backend-image
docker run --network=my-network --name=frontend frontend-image
```
Ab `frontend` container se `backend` ko `http://backend:<port>` se access kiya ja sakta hai — Docker ka internal DNS resolve karta hai.

**Port mapping vs internal networking**: `-p 3000:3000` sirf **host machine se access** ke liye zaroori hai. Container-to-container communication ke liye port mapping ki zaroorat nahi — wo shared network ke through internal port par directly ho sakta hai.

### Volumes — types

| Volume type | Behavior |
|---|---|
| **Named volume** | Docker manage karta hai storage location; `docker volume create mydata`, phir `-v mydata:/app/data`. Persistence ke liye best (DB data, uploads). |
| **Bind mount** | Host ka specific path directly map hota hai: `-v /host/path:/container/path`. Dev mein live code-sync ke liye use hota hai. |
| **Anonymous volume** | Bina naam ke, Docker-generated ID se. Often `node_modules` jaisa case handle karne ke liye use hota hai (bind mount ke andar exclusion). |
| **tmpfs mount** | Memory mein store hota hai, disk par kabhi nahi likhta — sensitive temporary data (jaise secrets in-flight) ke liye. |

```bash
docker run -v db-data:/var/lib/postgresql/data postgres
docker volume ls
docker volume inspect db-data
```

---

## 3. Developer Mindset (Day-to-day usage)

- Networking debug karte waqt pehle check karo: dono containers **same network** par hain kya? (`docker network inspect <network-name>`)
- `localhost` se container ke andar doosre container ko access karne ki koshish mat karo — service-name use karo (Compose ke context mein) ya container name (`docker run --network` context mein).
- Persistent data (DB, file uploads, cache-that-must-survive-restart) hamesha named volume mein — kabhi container's writable layer par depend mat karo.
- Volumes list/cleanup regularly karo — `docker volume ls`, unused volumes `docker volume prune` se clean karo (production mein caution ke saath).
- `docker inspect <container>` se turant pata chal jaata hai container kaunse networks/volumes se attached hai — debugging ka pehla step.

---

## 4. Interview-Prep Angle

- **"Do containers ek doosre se kaise baat karte hain?"** — shared Docker network + service/container-name based DNS resolution; port mapping sirf external access ke liye hai, internal communication ke liye nahi.
- **"Container restart hone par data kyun gayab ho jaata hai, aur solution kya hai?"** — container ki writable layer ephemeral hai; volumes (named) use karke data ko container lifecycle se independent banate hain.
- **"Named volume aur bind mount mein kab kaunsa choose karoge?"** — bind mount: dev-time live sync (host path control chahiye); named volume: production persistence (Docker-managed, portable, backup-friendly).
- **"`host` network mode kab use karoge?"** — jab network isolation overhead avoid karna ho (performance-critical), trade-off: weaker isolation, port conflicts host ke saath directly.
- **"Multi-container app mein DB data backup kaise loge?"** — named volume ko backup/restore karne ka process (`docker run --rm -v db-data:/data -v $(pwd):/backup alpine tar czf /backup/db-backup.tar.gz /data` jaisa pattern) explain karna.

---

## 5. Common Mistakes

- Container ke andar directly data likhna bina volume mount kiye, phir restart hone par "data kahan gaya" confusion.
- `localhost` use karna container-to-container calls mein (Compose/custom network context mein) — service/container-name use karna chahiye.
- Bind mount aur named volume ko interchangeable samajh lena — bind mount host-path-dependent hai (machine-specific), named volume portable/Docker-managed hai.
- Sensitive production DB volumes ko `docker volume prune` se accidentally delete kar dena bina check kiye kaunse containers use kar rahe hain.
- Multiple unrelated containers ko `host` network mode mein chalana "convenience" ke liye — port conflicts aur security isolation loss dono risk badhate hain.
- Volume mount path typo karna (jaise Postgres ka actual data path `/var/lib/postgresql/data` na hoke kuch aur likh dena) — persistence silently kaam nahi karta, restart par sab reset ho jaata hai.