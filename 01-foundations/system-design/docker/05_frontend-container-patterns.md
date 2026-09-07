# Frontend Container Patterns

Location: `01-foundations/system-design/docker/frontend-container-patterns.md`

Ye docker folder ka aakhri planned file hai — sab pehle wale concepts (Dockerfile, multi-stage builds, compose, networking/volumes) ko specifically **frontend apps (React/Angular)** ke context mein consolidate karta hai.

---

## 1. Mental Model

Frontend apps do fundamentally different "runtime needs" ke saath aate hain:

- **Build-time**: Node.js chahiye — transpile, bundle, minify (`npm run build`).
- **Run-time**: Sirf static files serve karne hain — Node.js ki zaroorat hi nahi.

Ye mismatch hi hai jo multi-stage build ko frontend ke liye **especially** important banata hai — build tool aur runtime tool alag hain, isliye final image mein sirf runtime tool (nginx) rakhna sabse natural fit hai.

**Key distinction**: SPA (React/Angular, client-side rendered) vs SSR app (Next.js, Angular Universal) — dono ka container pattern different hota hai, kyunki SSR app ko actual Node.js process runtime mein bhi chahiye hota hai.

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

**Custom `nginx.conf` zaroori hai SPA routing ke liye** (client-side routes jaise `/dashboard` direct-hit hone par 404 na aaye):

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

`try_files ... /index.html` fallback ensure karta hai ki koi bhi unknown path `index.html` serve kare, jahan se React Router/Angular Router client-side handle kar le.

### Pattern B — SSR app (Next.js, Angular Universal — Node.js runtime chahiye)

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

Yahan final stage mein bhi Node.js rehta hai — kyunki SSR ka matlab hi hai har request par server-side render hona.

### Runtime config injection (environment-specific API URLs)

Frontend build-time par hi environment variables ko bundle mein bake kar deta hai (jaise `REACT_APP_API_URL`) — jo multi-environment deployment (same image, different config) ke against jaata hai. Solutions:

- **Option 1**: Alag build per environment (simplest, but "same artifact everywhere" principle todta hai).
- **Option 2**: Runtime config file — container start hone par ek script `env.js` ya `config.json` generate kare actual environment variables se, jo app runtime par fetch kare (build-time bake nahi).

```dockerfile
# entrypoint.sh runtime par config.json generate karta hai container start hote hi
COPY entrypoint.sh /docker-entrypoint.d/40-generate-config.sh
```

Ye pattern "one image, many environments" ko truly enable karta hai — frontend ke liye ye subtlety often interview mein miss ki jaati hai.

---

## 3. Developer Mindset (Day-to-day usage)

- Local dev ke liye multi-stage/nginx pattern use mat karo — waha `docker-compose` + bind mount + dev-server (`npm start` / `ng serve`) with hot-reload better hai.
- Production build test karne ke liye locally bhi `docker build` + `docker run` chala kar verify karo ki static files sahi serve ho rahe hain, routes 404 nahi de rahe.
- SPA vs SSR decide karte waqt container strategy pehle se soch lo — ye architecture decision hai, deployment ke time retrofit karna costly hota hai.
- `nginx.conf` ko version control mein rakho jaise koi bhi source file — ye deployment behavior directly control karta hai.

---

## 4. Interview-Prep Angle

- **"React/Angular app ko production ke liye Dockerize kaise karoge?"** — multi-stage build (Node for build, nginx for serve) — ye single sabse common frontend Docker question hai.
- **"SPA routing container mein kaam kyun nahi karta by default?"** — nginx default config sirf actual files ko match karta hai; client-side routes ke liye `try_files` fallback to `index.html` chahiye.
- **"Same Docker image ko multiple environments (dev/staging/prod) mein kaise use karoge jab API URL alag ho?"** — runtime config injection pattern (env.js/config.json generate at container start), build-time baking nahi.
- **"SSR app ka container SPA se kaise different hoga?"** — SSR ko runtime Node.js process chahiye (request-time rendering), SPA ko sirf static file server chahiye.
- **"Static assets ke liye caching strategy kya hoga container/CDN ke saath?"** — hashed filenames (content-based) + long cache headers for assets, short/no-cache for `index.html` (taaki naya deployment turant reflect ho).

---

## 5. Common Mistakes

- SPA ko Dockerize karte waqt nginx config customize na karna — direct routes (`/dashboard` refresh) production mein 404 dene lagte hain.
- API URL ko build-time env var se bake kar dena, phir realize karna ki staging/prod ke liye alag images banani pad rahi hain — "one image, many environments" principle break ho jaata hai.
- SSR app ko SPA ki tarah treat karna — final image se Node.js hata dena, jabki runtime rendering ke liye zaroori tha.
- Cache headers galat set karna — `index.html` ko bhi long-cache kar dena, jisse naya deployment users ko turant nahi dikhta.
- Dev workflow mein bhi production multi-stage build use karne ki koshish karna — feedback loop slow ho jaata hai, jabki dev mein sirf `npm start`/`ng serve` + volume mount chahiye tha.