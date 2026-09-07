# Multi-Stage Builds

Location: `01-foundations/system-design/docker/multi-stage-builds.md`

`dockerfile-basics.md` mein multi-stage build ka concept touch kiya tha — ye file usi ko deeply cover karti hai: kyun zaroori hai, kaise structure karte hain, aur frontend context mein specifically kaise use hota hai.

---

## 1. Mental Model

Bina multi-stage build ke, ek hi Dockerfile mein build tools (compiler, npm, dev-dependencies) aur runtime dono cheezein ek hi image mein reh jaati hain — final image bloated aur insecure hota hai.

**Multi-stage build ka core idea**: Multiple `FROM` statements ek hi Dockerfile mein use karo, har ek apna alag "stage" hai. Sirf jo cheez tumhe chahiye wo ek stage se doosre stage mein `COPY --from=<stage>` se le aao — baaki sab discard ho jaata hai.

**Analogy**: Socho ek kitchen (build stage) jahan poora mess hota hai — raw ingredients, tools, prep waste — aur ek plate (final stage) jo customer ko serve hoti hai. Customer ko sirf plate dikhti hai, kitchen ka mess nahi.

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

Final image mein Node.js runtime, `node_modules`, ya source code — kuch bhi nahi hai. Sirf static HTML/CSS/JS files aur nginx.

**Named stages ka fayda:**
- Stage ko naam do (`AS build`) taaki `COPY --from=build` readable rahe (index number, jaise `--from=0`, ke bajaye).
- Multiple intermediate stages bhi ban sakte hain — jaise ek stage dependencies install kare, doosra test chalaye, teesra build kare, aur sirf final stage runtime ho.

**Build-time targets:**
```bash
docker build --target build -t myapp:debug .
```
Isse tum sirf ek specific stage tak build kar sakte ho — debugging ke liye useful (agar build stage mein issue hai, poora pipeline nahi chalana padta).

**Size impact (real numbers ka sense):**
- Single-stage (Node + source + node_modules + build output): often 900MB-1.2GB+
- Multi-stage (nginx + static files only): often 20-40MB

Ye difference deployment speed, registry storage cost, aur container startup time — teeno ko improve karta hai.

---

## 3. Developer Mindset (Day-to-day usage)

- Jab bhi Dockerfile likho jisme "build karna" aur "run karna" alag steps hain (compile, transpile, bundle) — multi-stage socho by default, single-stage exception honi chahiye.
- Build stage mein saara tooling free-hand use karo (dev-dependencies, compilers) — final stage mein sirf runtime-necessary cheezein copy karo.
- Backend (Node.js API) ke liye bhi pattern applicable hai: build stage mein TypeScript compile karo, final stage mein sirf compiled JS + production `node_modules` (`npm ci --omit=dev`) copy karo.
- Local development ke liye multi-stage build zaroori nahi — wahan `docker-compose` ke saath direct volume-mounted dev image better hai (hot-reload ke liye). Multi-stage mainly **production image** ke liye optimize karta hai.

---

## 4. Interview-Prep Angle

- **"Multi-stage build kya hai aur kyun use karte ho?"** — image size reduction, build tools ko production se separate rakhna, security surface kam karna.
- **"Frontend app (React/Angular) ko Dockerize kaise karoge production ke liye?"** — ye exact two-stage pattern (build with node, serve with nginx) bata sakna high-signal answer hai.
- **"Single-stage aur multi-stage mein trade-off kya hai?"** — multi-stage thoda zyada complex Dockerfile, but drastically chhota aur secure final image. Local dev mein simplicity ke liye single-stage/volume-mount bhi valid choice hai.
- **"Kya ek Dockerfile mein 2 se zyada stages ho sakte hain?"** — haan, jitne chahiye utne; common pattern hai dependencies → test → build → runtime.
- **"Build cache multi-stage mein kaise kaam karta hai?"** — har stage independently cache hoti hai; agar sirf final stage change ho (jaise nginx config), build stage re-run nahi hoga agar upar ke layers unchanged hain.

---

## 5. Common Mistakes

- Poora `node_modules` (including devDependencies) final stage mein copy kar dena — multi-stage ka fayda hi khatam ho jaata hai.
- Build stage ka naam na dena aur numeric index (`--from=0`) use karna — Dockerfile mein stages reorder karne par silently break ho sakta hai.
- Final stage mein bhi `node:20-alpine` jaisा heavy base rakhna jab actual zaroorat sirf static file serving ki ho (nginx/caddy se kaam chal sakta hai) — unnecessary bloat.
- Environment-specific build args (API URLs, etc.) ko build stage mein hardcode karna — runtime config injection (env vars ya config file mounted at container start) better pattern hai for the same image to work across environments.
- Multi-stage build ko local development workflow mein bhi force karna — dev mein ye slow feedback loop create karta hai; dev aur prod Dockerfile/strategy alag rakhna often better hai.