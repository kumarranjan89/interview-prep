# Multi-Stage Builds

Location: `01-foundations/system-design/docker/multi-stage-builds.md`

`dockerfile-basics.md` touched on the multi-stage build concept — this file covers it in depth: why it matters, how to structure it, and how it's specifically used in a frontend context.

---

## 1. Mental Model

Without multi-stage builds, build tools (compilers, npm, dev-dependencies) and the runtime both end up in the same final image — bloated and less secure.

**Core idea of multi-stage builds**: Use multiple `FROM` statements in one Dockerfile, each its own "stage." Only bring over what you actually need from one stage to another via `COPY --from=<stage>` — everything else gets discarded.

**Analogy**: Think of a kitchen (build stage) that's a mess — raw ingredients, tools, prep waste — and a plate (final stage) that's served to the customer. The customer only sees the plate, not the kitchen's mess.

---

## 2. Architecture Mindset

**Basic two-stage pattern (frontend app example — React/Angular):**

```dockerfile
# ---- Stage 1: Build ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build          # produces /app/dist or /app/build

# ---- Stage 2: Serve ----
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

The final image has no Node.js runtime, `node_modules`, or source code — just static HTML/CSS/JS files and nginx.

**Benefit of named stages:**
- Name the stage (`AS build`) so `COPY --from=build` stays readable (instead of a numeric index like `--from=0`).
- Multiple intermediate stages are also possible — e.g. one stage installs dependencies, another runs tests, another builds, and only the final stage is the runtime.

**Build-time targets:**
```bash
docker build --target build -t myapp:debug .
```
This lets you build only up to a specific stage — useful for debugging (if there's an issue in the build stage, you don't need to run the entire pipeline).

**Size impact (a sense of real numbers):**
- Single-stage (Node + source + node_modules + build output): often 900MB-1.2GB+
- Multi-stage (nginx + static files only): often 20-40MB

This difference improves deployment speed, registry storage cost, and container startup time — all three.

---

## 3. Developer Mindset (Day-to-day usage)

- Whenever you write a Dockerfile where "building" and "running" are separate steps (compile, transpile, bundle) — default to thinking multi-stage; single-stage should be the exception.
- Freely use all tooling in the build stage (dev-dependencies, compilers) — copy only runtime-necessary things into the final stage.
- The same pattern applies to backend (Node.js API) too: compile TypeScript in the build stage, copy only compiled JS + production `node_modules` (`npm ci --omit=dev`) into the final stage.
- Multi-stage builds aren't necessary for local development — a directly volume-mounted dev image with `docker-compose` (for hot-reload) is better there. Multi-stage is mainly for optimizing the **production image**.

---

## 4. Interview-Prep Angle

- **"What is a multi-stage build and why use it?"** — image size reduction, keeping build tools separate from production, reducing security surface.
- **"How would you Dockerize a frontend app (React/Angular) for production?"** — being able to describe this exact two-stage pattern (build with node, serve with nginx) is a high-signal answer.
- **"What's the trade-off between single-stage and multi-stage?"** — multi-stage is a slightly more complex Dockerfile, but a drastically smaller and more secure final image. Single-stage/volume-mount is still valid for local dev simplicity.
- **"Can a Dockerfile have more than 2 stages?"** — yes, as many as needed; a common pattern is dependencies → test → build → runtime.
- **"How does build cache work with multi-stage?"** — each stage caches independently; if only the final stage changes (e.g. nginx config), the build stage won't re-run if the layers above it are unchanged.

---

## 5. Common Mistakes

- Copying the entire `node_modules` (including devDependencies) into the final stage — defeats the whole purpose of multi-stage.
- Not naming build stages and using a numeric index (`--from=0`) instead — can silently break if stages are reordered in the Dockerfile.
- Keeping a heavy base like `node:20-alpine` in the final stage when the actual need is just static file serving (nginx/caddy would do) — unnecessary bloat.
- Hardcoding environment-specific build args (API URLs, etc.) in the build stage — runtime config injection (env vars or a config file mounted at container start) is the better pattern for the same image to work across environments.
- Forcing multi-stage builds into the local development workflow too — creates a slow feedback loop in dev; it's often better to keep dev and prod Dockerfile/strategy separate.