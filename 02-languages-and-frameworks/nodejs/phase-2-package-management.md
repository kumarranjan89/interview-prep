# Phase 3 — npm & Package Management

> Format: every topic gets **Mental Model → Developer Angle → Architect Angle**. Kept concise — depth without padding.

---

## 1. package.json — The Contract

**Mental model:** the recipe's ingredient list — loose, allows substitution (`^4.2.0` = "any onion, this size or bigger, same brand line").

**Developer angle:**
```json
"dependencies": { "express": "^4.19.2" },
"devDependencies": { "jest": "^29.7.0" },
"peerDependencies": { "react": ">=18.0.0" },
"engines": { "node": ">=20.0.0" }
```
| Symbol | Allows | Use for |
|---|---|---|
| `^4.19.2` | minor+patch bumps, never major | devDeps, most deps |
| `~4.19.2` | patch only | prod deps you want to control tightly |
| `4.19.2` exact | nothing | regulated/high-stakes services |

`peerDependencies` = "host app must provide this" (library expecting the consumer's own React instance — prevents duplicate singleton instances).

**Architect angle:** `engines` should be **enforced in CI**, not just documented — version drift across team/CI is a classic root cause of "works on my machine." `dependencies` size = production attack surface; audit it like a cost center, not a convenience list.

---

## 2. package-lock.json + `npm ci` — Reproducibility

**Mental model:** the exact shopping receipt — brand, size, store, date. Zero ambiguity, unlike the recipe list.

**Developer angle:**
- `npm install` → resolves within semver ranges, can silently update the lock file.
- `npm ci` → deletes `node_modules`, installs **exactly** what's locked, **fails loud** if `package.json`/lock disagree. Faster too (skips resolution).
- **Always `npm ci` in CI/CD, never `npm install`.**

**Architect angle:** lock file carries integrity hashes (`sha512-...`) — your primary defense against a package being tampered with *after* you first installed it. Doesn't protect against a malicious package being legitimately published for the first time. Lock file diffs should be reviewed in PRs like code.

---

## 3. Dependency Resolution & Phantom Dependencies

**Mental model:** npm tries to share one pantry shelf (hoist to top-level `node_modules`) across recipes; only builds a separate shelf (nests) when two recipes need conflicting versions of the same ingredient.

**Developer angle — the trap:** because of hoisting, you can `require('lodash')` successfully even if it's not in *your* `package.json` — it got hoisted there for a sibling dependency. Works until that sibling changes, then breaks with zero warning. **Rule: always declare what you import, even if it "just works."**

**Architect angle:** this hoisting-caused fragility is exactly what **pnpm** was built to fix structurally (see §8) — worth knowing as the "why" behind pnpm adoption conversations.

---

## 4. Script Lifecycle

**Mental model:** npm scripts aren't just "commands you name" — npm has a **fixed set of lifecycle events** it fires automatically at specific moments (install, publish, version bump), and any script matching those exact names runs without you calling it. Think of them as pre-wired hooks in a pipeline, not arbitrary labels.

**Developer angle — the two kinds of hooks:**

1. **Pre/post for YOUR custom scripts** — any script gets free hooks if you prefix it:
```json
"scripts": {
  "pretest": "eslint .",
  "test": "jest",
  "posttest": "echo done"
}
```
Running `npm test` auto-runs `pretest` → `test` → `posttest` in order, no extra config.

2. **Built-in lifecycle events** — npm itself fires these at fixed points, regardless of whether you defined them:

| Event | Fires when | Common use |
|---|---|---|
| `preinstall` | Before any package is installed | Environment checks |
| `install` | During install step | Native module builds (e.g. `node-gyp`) |
| `postinstall` | Right after install completes | Setup scripts, patch-package, husky git hooks |
| `prepare` | After install, **and** before `npm publish`/`npm pack`; also runs on `git install` of a repo | Build step for libraries (compile TS → JS before publish) |
| `prepublishOnly` | Right before publish only (not on plain install) | Final safety checks, lint, test gate before shipping |
| `prepack` / `postpack` | Around tarball creation (`npm pack`/`publish`) | Bundling steps |
| `preversion` / `version` / `postversion` | Around `npm version <bump>` | Run tests before bump, auto-commit changelog after |

**Full install-time order for a fresh `npm install`:**
```
preinstall → install → postinstall → prepare
```

**Architect angle:**
- `prepare` is the one most teams get wrong — it runs on **every consumer's install** of a git-hosted dependency (not just your own publish), so if it's slow or fails, it breaks installs for anyone pulling your package from a git URL. Keep it lean and reliable.
- `prepublishOnly` is your **last safety gate** before code reaches the registry — teams put final lint/test/build-verification here specifically because it does NOT run on a normal `npm install` (unlike `prepare`), so it can't slow down or break consumers, only your own publish step.
- The same `postinstall` risk from §4 applies to **every** lifecycle hook — any of them can execute arbitrary code the moment the trigger fires. `ignore-scripts` in `.npmrc` disables **all** of them, not just `postinstall` — worth knowing precisely, since some teams need `prepare` to still run for legitimate build steps and end up carving out exceptions rather than blanket-disabling.

---

## 5. `.npmrc` — Config Hierarchy

**Mental model:** layered settings, most specific wins — like `.env` files but for the package manager itself.

**Developer angle:** resolution order (highest priority first):
```
project .npmrc  →  user ~/.npmrc  →  global npmrc  →  npm's built-in defaults
```
Common entries:
```ini
registry=https://registry.npmjs.org/
@myorg:registry=https://npm.mycompany.com/
save-exact=true
```

**Architect angle:** this is how **private/scoped registries** get wired in (`@myorg:registry=...`) — routes internal packages to an internal registry (Verdaccio, Artifactory, GitHub Packages) while public packages still hit npmjs. Also how enterprises **pin/cache approved versions** of public packages to reduce exposure to a compromised public registry.

---

## 6. `npx` — Run Without Install

**Mental model:** "borrow a tool for one use, don't buy it."

**Developer angle:** `npx create-react-app my-app` — downloads (if not cached) and runs a package's binary without a permanent local install.

**Architect angle:** real security consideration — `npx some-package` executes arbitrary code from the registry **immediately**, no review step. Typosquatting risk is real (`npx cross-env` vs a malicious lookalike). Don't run unfamiliar `npx` commands from untrusted sources/tutorials blindly.

---

## 7. `exports` Field & the Dual Package Hazard

**Mental model:** `exports` is the pantry's *only* front door — before it existed, anyone could reach into any shelf (`require('pkg/internal/whatever')`); `exports` locks that down to explicitly allowed paths.

**Developer angle:**
```json
"exports": {
  ".": { "import": "./esm/index.js", "require": "./cjs/index.js" }
}
```
Lets one package ship both ESM and CommonJS builds, resolved automatically based on how it's imported.

**Architect angle — dual package hazard:** if a package's ESM and CJS builds each maintain **separate module state** (e.g., a singleton, a cache), and your app accidentally loads *both* builds (common in large dependency trees), you silently get **two different instances** of something meant to be one — a genuinely hard-to-debug production bug class. Worth knowing exists even if you haven't hit it yet.

---

## 8. Beyond npm — pnpm, Yarn, corepack

**Mental model:** npm hoists into one shared shelf (fast but leaky — phantom deps). **pnpm** keeps one global content-addressable store and **symlinks** into each project's `node_modules`, so a package can only see what it actually declared — no phantom deps, and disk space is shared across *all* projects on your machine, not just one.

| | npm | pnpm | Yarn (Berry) |
|---|---|---|---|
| Phantom deps possible? | Yes | **No** (strict by design) | PnP mode: no; classic mode: yes |
| Disk usage across projects | Duplicated per project | Shared global store, symlinked | Similar to npm (classic) |
| Install speed | Baseline | Faster (no re-download/re-copy) | Comparable to pnpm |
| Monorepo support | Workspaces (v7+) | Workspaces, very mature | Workspaces, very mature |

**Architect angle:** **corepack** (ships with Node since 16.9, stable in later LTS) lets you pin the exact package-manager + version per project via `package.json`'s `packageManager` field — so `npm`/`pnpm`/`yarn` version itself becomes reproducible across machines, not just the dependencies. Worth mentioning if asked "how do you guarantee full build reproducibility."

---

## 9. Publishing Workflow (if you ever ship a package)

**Developer angle:**
```bash
npm login
npm version patch        # bumps version, creates git tag
npm publish               # public by default; --access restricted for private
npm publish --access public   # required for scoped packages (@yourorg/pkg) to be public
```

**Architect angle:** enterprise-grade publishing enforces **2FA + provenance** (`npm publish --provenance` links the published package back to the exact CI build/commit that produced it) — this is npm's own answer to the supply-chain trust problem, letting consumers verify a package was built from the source it claims, not injected at publish time.

---

## 10. Architect Risk Summary Table

| Risk | Protected by | Your job |
|---|---|---|
| Non-reproducible builds | lock file + `npm ci` | Enforce `npm ci` in every pipeline |
| Post-publish tampering | integrity hashes | Review lock file diffs in PRs |
| Malicious/typosquat package | nothing automatic | `npm audit`, manual review, prefer trusted packages |
| Arbitrary code via `postinstall`/`npx` | nothing automatic | `ignore-scripts` in sensitive CI; don't blind-run `npx` |
| Phantom dependencies | nothing in npm; structural in pnpm | Declare all imports explicitly, or adopt pnpm |
| Dual package hazard | nothing automatic | Understand `exports` field; test dual-load scenarios for shared-state packages |
| Package-manager version drift | corepack | Pin via `packageManager` field |

---

## 11. Interview Rapid-Fire

**Q: `npm install` vs `npm ci`?**
`npm ci` deletes `node_modules` and installs strictly from the lock file, failing loud if `package.json` and the lock disagree — fully deterministic. `npm install` resolves fresh within semver ranges and can silently rewrite the lock file. Use `ci` in every CI/CD pipeline, never `install`.

**Q: `^` vs `~` — when do you pick one over the other?**
`^` allows minor + patch bumps (npm's default, fine for most `devDependencies`). `~` restricts to patch-only — a more conservative choice for production `dependencies` where you'd rather review minor version changes manually than absorb them automatically.

**Q: What's a phantom dependency and why does it matter?**
An import that works only because npm hoisted it into `node_modules` for a *sibling* package — it's not declared in your own `package.json`. It breaks silently, with no warning, the moment that sibling changes its own dependencies. Fix: always declare what you actually import.

**Q: Why is `postinstall` a security concern?**
It runs automatically for every installed package — including transitive ones you never chose directly — the moment `npm install` finishes, before you've reviewed or used the code. It's a known real-world supply-chain attack vector.

**Q: What does the `exports` field solve, and what risk can it introduce?**
It locks a package's public API down to explicitly allowed entry points (instead of any internal file being reachable). The risk it can introduce is the **dual package hazard**: if a package's ESM and CJS builds both get loaded in the same app and each holds separate module state (e.g. a singleton or cache), you silently end up with two different instances of something meant to be one.

**Q: npm vs pnpm — what's the actual architectural difference, not just "pnpm is faster"?**
npm hoists dependencies into one shared, flat `node_modules`, which is exactly what causes phantom dependencies. pnpm instead keeps one global content-addressable store and symlinks each project's `node_modules` into it — so a package can only resolve what it explicitly declared. That's a structural fix, not just a speed optimization, plus disk space gets shared across every project on the machine.

**Q: How do you guarantee full build reproducibility, not just correct dependency versions?**
Lock file + `npm ci` guarantees *dependency* reproducibility. But the package manager's own version can still drift across machines/CI. **corepack** closes that gap by pinning the exact package-manager version via the `packageManager` field in `package.json`.

---

## 12. Practice Before Phase 4

- [ ] Break the lock file manually, watch `npm ci` fail loud — build the instinct.
- [ ] Run `npm audit`, read one real CVE end-to-end.
- [ ] Add a `postinstall` script locally, observe when/how it fires.
- [ ] Set up npm workspaces with 2 toy packages.
- [ ] Install the same tree with npm vs pnpm, compare `node_modules` structure directly.

---

*File: `03-npm/README.md` — Node.js Learning Journey, Phase 3.* 