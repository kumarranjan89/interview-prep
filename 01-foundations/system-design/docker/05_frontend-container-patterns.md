# Frontend Container Patterns

Location: `01-foundations/system-design/docker/frontend-container-patterns.md`

This is the last planned file in the docker folder — it consolidates all the earlier concepts (Dockerfile, multi-stage builds, compose, networking/volumes) specifically in the context of **frontend apps (React/Angular)**.

---

## 1. Mental Model

Frontend apps come with two fundamentally different "runtime needs":

- **Build-time**: Needs Node.js — transpile, bundle, minify (`npm run build`).
- **Run-time**: Only needs to serve static files — no Node.js required at all.

This mismatch is exactly why multi-stage builds are **especially** important for frontend — the build tool and the runtime tool are different, so keeping only the runtime tool (nginx) in the final image is the most natural fit.

**Key distinction**: SPA (React/Angular, client-side rendered) vs SSR app (Next.js, Angular Universal) — each needs a different container pattern, because an SSR app also needs an actual Node.js process at runtime.

---

## 2. Architecture Mindset

### Pattern A — SPA (client-side rendered, no server needed at runtime)

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build          # React: /app/build, Angular: /app/dist/<project-name>

FROM nginx:alpine
COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**A custom `nginx.conf` is necessary for SPA routing** (so client-side routes like `/dashboard` don't 404 on a direct hit):

```nginx
server {
  listen 80;
  root /usr/share/nginx/html;
  index index.html;

  location / {
    try_files $uri $uri/ /index.html;
  }
}
```

The `try_files ... /index.html` fallback ensures any unknown path serves `index.html`, from where React Router/Angular Router can handle it client-side.

### Pattern B — SSR app (Next.js, Angular Universal — needs Node.js runtime)

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:20-alpine AS runtime
WORKDIR /app
COPY --from=build /app/package*.json ./
RUN npm ci --omit=dev
COPY --from=build /app/.next ./.next
COPY --from=build /app/public ./public
EXPOSE 3000
CMD ["npm", "start"]
```

Here Node.js stays in the final stage too — because SSR means rendering server-side on every request.

### Runtime config injection (environment-specific API URLs)

A frontend build bakes environment variables into the bundle at build-time (e.g. `REACT_APP_API_URL`) — which goes against the "same artifact everywhere" principle for multi-environment deployment. Solutions:

- **Option 1**: A separate build per environment (simplest, but breaks the "same artifact everywhere" principle).
- **Option 2**: Runtime config file — a script generates `env.js` or `config.json` from actual environment variables when the container starts, and the app fetches it at runtime (not baked at build-time).

```dockerfile
# entrypoint.sh generates config.json at runtime, when the container starts
COPY entrypoint.sh /docker-entrypoint.d/40-generate-config.sh
```

This pattern truly enables "one image, many environments" — a subtlety that's often missed for frontend in interviews.

---

## 3. Developer Mindset (Day-to-day usage)

- Don't use the multi-stage/nginx pattern for local dev — there, `docker-compose` + bind mount + dev-server (`npm start` / `ng serve`) with hot-reload is better.
- To test a production build, run `docker build` + `docker run` locally too, and verify static files serve correctly and routes don't 404.
- Decide SPA vs SSR container strategy upfront — this is an architecture decision, expensive to retrofit at deployment time.
- Keep `nginx.conf` in version control like any other source file — it directly controls deployment behavior.

---

## 4. Interview-Prep Angle

- **"How would you Dockerize a React/Angular app for production?"** — multi-stage build (Node for build, nginx for serve) — this is the single most common frontend Docker question.
- **"Why doesn't SPA routing work in a container by default?"** — nginx's default config only matches actual files; client-side routes need a `try_files` fallback to `index.html`.
- **"How would you use the same Docker image across multiple environments (dev/staging/prod) when the API URL differs?"** — runtime config injection pattern (generate env.js/config.json at container start), not build-time baking.
- **"How is an SSR app's container different from an SPA's?"** — SSR needs a runtime Node.js process (request-time rendering), SPA just needs a static file server.
- **"What's the caching strategy for static assets with a container/CDN?"** — hashed filenames (content-based) + long cache headers for assets, short/no-cache for `index.html` (so a new deployment reflects immediately).

---

## 5. Common Mistakes

- Not customizing the nginx config while Dockerizing an SPA — direct routes (`/dashboard` refresh) start 404-ing in production.
- Baking the API URL into a build-time env var, then realizing separate images need to be built for staging/prod — breaks the "one image, many environments" principle.
- Treating an SSR app like an SPA — removing Node.js from the final image when it was actually needed for runtime rendering.
- Setting cache headers wrong — long-caching `index.html` too, so users don't see a new deployment immediately.
- Trying to use the production multi-stage build in the dev workflow too — slows down the feedback loop, when dev really just needed `npm start`/`ng serve` + volume mount.