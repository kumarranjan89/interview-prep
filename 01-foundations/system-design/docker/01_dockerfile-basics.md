# Dockerfile Basics

Location: `01-foundations/system-design/docker/dockerfile-basics.md`

This file covers the core Dockerfile instructions and, more importantly, the "why" behind each one — the emphasis is less on syntax and more on how each instruction affects the image build process.

---

## 1. Mental Model

A Dockerfile is a **step-by-step recipe** that Docker uses to build an image. Each line creates a new **layer**, and layers are **cached top-to-bottom**.

- If a layer changes, **all layers below it get rebuilt** — the ones above don't.
- So put whatever **changes the least** (dependencies) **near the top**, and whatever **changes most often** (source code) **near the bottom**.

```dockerfile
FROM node:20-alpine       # base image — starting point
WORKDIR /app              # sets working directory inside container
COPY package*.json ./     # copy only dependency manifests first
RUN npm install           # install deps — cached unless package.json changes
COPY . .                  # copy rest of source code
CMD ["npm", "start"]      # default command when container runs
```

---

## 2. Architecture Mindset

Key instructions and their purpose:

| Instruction | Purpose | Notes |
|---|---|---|
| `FROM` | Selects the base image | Smaller is better (`alpine`, `slim` variants) |
| `WORKDIR` | Sets the working directory inside the container | Like `cd`, but declarative |
| `COPY` / `ADD` | Copies files from host into the container | Prefer `COPY`; `ADD`'s extra features (auto-extract, URL fetch) are rarely needed |
| `RUN` | Runs a build-time command | Creates a new layer, baked permanently into the image |
| `CMD` | Default command when the container starts | Can be overridden at runtime (`docker run <image> <other-cmd>`) |
| `ENTRYPOINT` | Fixed executable that always runs | `CMD` becomes its arguments when both are used |
| `EXPOSE` | Documents the intended port | Actual port mapping happens via `docker run -p` |
| `ENV` | Sets an environment variable (build + runtime) | Don't put secrets here — they get baked into the image |
| `ARG` | Build-time-only variable | Different from `ENV` — doesn't persist to runtime |

**Multi-stage build** (production-grade pattern):

```dockerfile
# Stage 1: build
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: serve (only final artifact copied over)
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
```

The final image has no Node.js, dev-dependencies, or source code — just the built static files. This drastically reduces image size.

---

## 3. Developer Mindset (Day-to-day usage)

- While writing a Dockerfile, always ask: "is layer caching actually working here, or am I forcing a full rebuild every time?"
- Never reverse the order: `COPY package*.json ./` → `RUN npm install` → `COPY . .`.
- Always create a `.dockerignore` file (`node_modules`, `.git`, `dist`, `.env`) — keeps the build context small and prevents secrets from accidentally ending up in the image.
- Don't confuse `CMD` vs `ENTRYPOINT`: if the container has one fixed purpose (running a specific binary), use `ENTRYPOINT`. If you want flexibility (a default that's still override-able), use `CMD`.
- Always tag a version when building — `docker build -t myapp:v1 .` — don't rely on `latest`.

---

## 4. Interview-Prep Angle

- **"How does layer caching work, and how does it affect build speed?"** — clearly explain instruction order + cache invalidation, with an example.
- **"Why use multi-stage builds?"** — removing build-time dependencies from the final image, reducing both size and attack surface.
- **"Difference between `CMD` and `ENTRYPOINT`?"** — cover both override-ability and intended use case.
- **"Is it safe to store secrets in `ENV`?"** — no, because `ENV` values get baked into the image and are visible via `docker inspect`/history; inject secrets at runtime instead (orchestrator secrets, a `.gitignore`d `--env-file`, or a secret manager).
- **"How would you reduce the size of an existing Dockerfile's image?"** — smaller base image, multi-stage build, combining unnecessary layers (`&&`-chaining `RUN` commands where sensible), tightening `.dockerignore`.

---

## 5. Common Mistakes

- Copying source code before dependencies — invalidates the cache on every build.
- No `.dockerignore` — `node_modules` or `.git` ends up in the entire build context, slowing builds and bloating the image.
- Splitting `RUN apt-get update` into a separate `RUN` line from `apt-get install` — layer caching can use a stale package list. Always chain: `RUN apt-get update && apt-get install -y <pkg>` in one line.
- Baking secrets (API keys, passwords) into the image via `ENV` or `ARG` — they remain permanently visible in image history.
- Writing a separate `RUN` instruction for every small thing — adds unnecessary layers (modern Docker optimizes this fairly well, but chaining is still better for readability and size).
- Relying on the `latest` tag in production — breaks reproducibility; tomorrow's build could differ from today's.