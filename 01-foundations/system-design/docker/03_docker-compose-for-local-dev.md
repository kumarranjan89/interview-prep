# Docker Compose for Local Dev

Location: `01-foundations/system-design/docker/docker-compose-for-local-dev.md`

`multi-stage-builds.md` production image ke liye tha. Ye file local development ke liye hai — jahan goal speed aur convenience hai, size optimization nahi.

---

## 1. Mental Model

Docker Compose ek tool hai **multiple containers ko ek saath define aur run karne ke liye**, ek single YAML file (`docker-compose.yml`) ke through.

**Core idea**: Real app mein sirf ek container nahi hota — frontend, backend, database, cache (Redis), sab alag services hain jo ek saath chalne chahiye. Compose inhe ek command (`docker-compose up`) se orchestrate karta hai.

- Har entry ek **service** hai (jo internally ek container ban jaata hai).
- Services apne **service-name se ek doosre ko resolve** kar sakte hain — built-in DNS ki wajah se (`http://backend:5000`, `localhost` nahi).
- Ye "poore stack ko local machine par ek command se khada karna" problem solve karta hai — naya developer onboard hone par `docker-compose up` chalaye, sab kaam karna shuru.

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
| `services` | Har ek independent container definition |
| `build` vs `image` | `build`: local Dockerfile se banao; `image`: existing registry image use karo (jaise `postgres`) |
| `ports` | `host:container` mapping — host machine se access ke liye |
| `volumes` (bind mount) | Host folder ko container mein mount karna — code change turant reflect (hot-reload) |
| `volumes` (named, top-level) | Persistent data storage — container restart/delete hone par bhi data bacha rahe (jaise DB data) |
| `depends_on` | Startup order define karta hai (lekin readiness guarantee nahi — DB "started" ho sakta hai but "ready to accept connections" nahi) |
| `environment` | Environment variables inject karna, config code se separate rakhna |
| Networking | Default: sab services ek shared network par hote hain, service-name se reachable |

**Bind mount trick for node_modules**: `./frontend:/app` poora host folder mount karta hai, lekin `/app/node_modules` ek separate anonymous volume rakhta hai — isse host ka (potentially incompatible OS-specific) `node_modules` container ke `node_modules` ko overwrite nahi karta.

---

## 3. Developer Mindset (Day-to-day usage)

- `docker-compose up -d` — detached mode mein poora stack chalao.
- `docker-compose logs -f <service-name>` — specific service ke logs live dekho.
- `docker-compose down` — sab containers stop + remove (data volumes by default bache rehte hain, `-v` flag se wo bhi delete hote hain).
- `docker-compose exec <service> sh` — running container ke andar jaake directly debug karo.
- Code change karo → agar bind mount + framework ka hot-reload (Vite, nodemon, Angular CLI) set hai, container restart ki zaroorat nahi, changes live reflect honge.
- `depends_on` sirf start **order** guarantee karta hai, service **readiness** nahi — agar backend DB se turant connect try karta hai aur DB abhi accept nahi kar raha, retry-logic ya `healthcheck` + `condition: service_healthy` add karna padta hai.

---

## 4. Interview-Prep Angle

- **"Multiple services ko local mein kaise run karte ho consistently?"** — `docker-compose.yml` se poora stack ek command mein spin up karna, "works on my machine" problem solve karna.
- **"Compose mein services ek doosre se kaise communicate karte hain?"** — shared Docker network + service-name-based DNS resolution, `localhost` nahi.
- **"`depends_on` kya guarantee karta hai, kya nahi?"** — sirf container start order, service readiness nahi; readiness ke liye healthchecks chahiye.
- **"Development aur production ke liye same Dockerfile use karoge?"** — generally nahi; dev mein bind-mount + hot-reload chahiye hota hai (fast feedback), prod mein multi-stage optimized immutable image (no mounts, no live-editing).
- **"Named volume aur bind mount mein difference?"** — bind mount host filesystem ka specific path map karta hai (dev ke liye, live sync); named volume Docker-managed storage hai, persistence ke liye (DB data), host path irrelevant.

---

## 5. Common Mistakes

- `depends_on` ko readiness guarantee samajh lena — DB abhi start hi hua hota hai, backend fail ho jaata hai connection attempt mein.
- Production mein bhi `docker-compose.yml` ka wahi dev-config use kar lena (bind mounts, exposed DB ports directly) — security aur performance dono risk.
- `node_modules` ko host se bind mount mein include kar dena without anonymous volume trick — native dependencies (jaise `node-sass`, `bcrypt`) OS mismatch ki wajah se crash karte hain.
- Secrets (DB passwords, API keys) ko `docker-compose.yml` mein directly hardcode karke commit kar dena — `.env` file use karo aur usko `.gitignore` mein rakho.
- Named volumes ko `docker-compose down -v` se accidentally delete kar dena — production/important local data loss ho sakta hai agar bina soche `-v` flag use kiya.
- Har service ke liye alag `docker-compose up` chalane ki koshish karna instead of ek hi file mein define karke ek command se poora stack manage karna.