# JavaScript Module System — CommonJS vs ES6
### How multiple JS files work together (`require` vs `import`)

---

## Mental Model

Every JS file has its own **isolated scope**. Nothing inside a file is visible outside it unless you explicitly `export` it. `require`/`import` do one job: **bring an exported value from one file into another file's scope.**

You already do this daily in Angular (`import { Component } from '@angular/core'`). The only difference in backend work is that you create and export these files yourself — there's no framework doing it for you.

---

## Two Systems — CommonJS (`require`) vs ES Modules (`import`)

Node originally only had CommonJS. ES6 modules came later. Today both exist in real codebases, which is why it gets confusing.

### CommonJS (older, default in Node)
```javascript
// math.js — EXPORTING
function add(a, b) { return a + b; }
function subtract(a, b) { return a - b; }

module.exports = { add, subtract };
// or single export:
// module.exports = add;

// app.js — IMPORTING
const { add, subtract } = require('./math');
console.log(add(2, 3)); // 5
```

### ES6 Modules (`import`/`export`)
```javascript
// math.js — EXPORTING
export function add(a, b) { return a + b; }
export function subtract(a, b) { return a - b; }
export default add; // only one default export per file

// app.js — IMPORTING
import add, { subtract } from './math.js'; // .js extension required here
console.log(add(2, 3)); // 5
```

---

## Key Differences (useful for interviews too)

| | CommonJS | ES Modules |
|---|---|---|
| Loading | **Synchronous** — file loads immediately | Can be **async** (dynamic `import()`) |
| Timing | Resolved at runtime | Resolved at compile time (allows static analysis) |
| `this` at top level | `module.exports` (an object) | `undefined` |
| File extension in import | Optional (`require('./math')`) | Required in Node (`import './math.js'`) |
| Enabling in Node | Default | Needs `"type": "module"` in `package.json`, or `.mjs` extension |

---

## How to Enable ES6 Modules in Node

```json
// package.json
{
  "type": "module"
}
```
Once this is set, `require` stops working across the **entire project** (unless a file is renamed to `.cjs`). This is a project-wide switch, not file-by-file.

In TypeScript, you always write `import/export` syntax. The TS compiler (`tsc`) decides whether the compiled output is CommonJS or ESM, based on the `"module"` setting in `tsconfig.json`. You don't need to think about this at the syntax level — it's a config-level decision.

```json
// tsconfig.json
{
  "compilerOptions": {
    "module": "CommonJS"  // or "ESNext", "ES2020" etc.
  }
}
```

---

## Real Multi-File Example (backend project structure)

```javascript
// db.js
export function connect() { /* ... */ }
export function query(sql) { /* ... */ }

// userService.js
import { query } from './db.js';

export async function getUser(id) {
  const rows = await query(`SELECT * FROM users WHERE id = ${id}`);
  return rows[0];
}

// server.js — the entry point that wires everything together
import express from 'express';
import { getUser } from './userService.js';

const app = express();
app.get('/user/:id', async (req, res) => {
  const user = await getUser(req.params.id);
  res.json(user);
});
app.listen(3000);
```

Notice the **dependency direction**: `server.js` → `userService.js` → `db.js`. Each layer only imports the layer below it, never the layer above. This is similar to the dependency-injection mental model you already use with Angular services/components — just done manually here.

---

## Gotchas (the ones that actually cause bugs)

**1. Circular imports** — if `a.js` imports `b.js`, and `b.js` imports `a.js` back, values can come out `undefined` depending on load order. In backend code this usually happens when services reference each other. Fix: pull the shared logic into a third file.

**2. Default vs named export confusion**
```javascript
export default function() {}       // import myFunc from './file.js'  (any name works)
export function helper() {}        // import { helper } from './file.js'  (name must match exactly)
```

**3. Mixing require and import in the same project** — usually breaks unless carefully configured (Babel/ts-node handle this, but plain Node doesn't mix them well in the same file).

---

## Practical Suggestion

In your `db-learning` or a new Express practice project, use **ES6 `import/export` throughout** (set `"type": "module"`). CommonJS is only worth understanding for reading legacy packages — not for writing new code.

---

## Appendix: All Module Systems — Syntax Quick Reference

### IIFE (legacy workaround, not a real module system)
```javascript
const MathModule = (function () {
  function add(a, b) { return a + b; }
  return { add };
})();
MathModule.add(2, 3);
```

### CommonJS (Node default)
```javascript
// export
module.exports = { add, subtract };
module.exports = add; // single export

// import
const { add, subtract } = require('./math');
const add = require('./math'); // if single export
```

### AMD / RequireJS (dead, browser-only, historical)
```javascript
// define a module with dependencies
define(['./math'], function (math) {
  return { calculate: () => math.add(2, 3) };
});

// require it elsewhere
require(['./calculator'], function (calc) {
  calc.calculate();
});
```

### UMD (wrapper for library authors — rarely hand-written today)
```javascript
(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();               // CommonJS
  } else if (typeof define === 'function' && define.amd) {
    define(factory);                           // AMD
  } else {
    root.MyLibrary = factory();                // browser global
  }
})(this, function () {
  return { add: (a, b) => a + b };
});
```

### ES6 Modules (current standard — write this)
```javascript
// export
export function add(a, b) { return a + b; }
export default add;

// import
import add, { subtract } from './math.js';

// dynamic import (async, code-splitting)
const math = await import('./math.js');
```

### SystemJS (polyfill loader, niche)
```javascript
// registers a module for browsers without native ESM support
System.register(['./math.js'], function (exports) {
  return {
    setters: [(m) => exports('add', m.add)],
    execute: function () {}
  };
});
```

### Quick Decision Table

| Writing... | Use |
|---|---|
| New Node.js backend code | ES6 `import/export` |
| Reading old npm package source | CommonJS `require` |
| Interview question on history | Mention AMD/UMD/IIFE exist, know *why* each was invented |
| Publishing an npm library for wide compatibility | Let Rollup/webpack auto-generate UMD — don't hand-write it |