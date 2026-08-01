# JavaScript Engine

## Scope of This Topic

The **engine** is the layer that parses, compiles, and executes JS code — nothing else. It does **not** know what `setTimeout`, `fetch`, or the DOM are; those come from the runtime (next topic). Keep this boundary sharp — it's the most commonly blurred distinction in interviews.

```
[ Your JS Code ]
      |
      v
[ JS Engine ]   ← V8 (Chrome/Node), SpiderMonkey (Firefox), JavaScriptCore (Safari)
  |-- Parser
  |-- Interpreter (Ignition)
  |-- JIT Compiler (TurboFan)
  |-- Call Stack
  |-- Memory Heap
  |-- Garbage Collector
```

## Parsing Pipeline

```
Source Code (string)
      |
      v
[ Tokenizer/Lexer ]  →  Tokens
      |
      v
[ Parser ]           →  AST (Abstract Syntax Tree)
```

```js
let x = 5 + 3;
// Tokens: [let] [x] [=] [5] [+] [3] [;]
// AST: VariableDeclaration → VariableDeclarator → BinaryExpression(+, 5, 3)
```

## JIT Compilation (V8 specifically)

JS is neither purely interpreted nor purely compiled — it's **JIT (Just-In-Time)**: interpret first for fast startup, then optimize hot paths at runtime.

```
AST → [ Ignition: interpreter, generates bytecode ]
         |
      [ Profiler watches for "hot" code ]
         |
      [ TurboFan: optimizing compiler → machine code ]
         |
      [ Deoptimization if assumptions break → back to bytecode ]
```

```js
function add(a, b) { return a + b; }
add(1, 2);       // TurboFan assumes numeric types, optimizes
add("x", "y");   // assumption broken → deoptimize → falls back to bytecode
```

**Practical takeaway:** consistent argument types across calls to the same function keep it optimized. Polymorphic functions (called with wildly different shapes/types) get deoptimized repeatedly — a real perf issue in hot loops.

## Hidden Classes & Inline Caching (common senior gotcha)

V8 creates internal "hidden classes" for objects based on their shape (property names + order). Objects with the same shape share a hidden class, letting V8 use fast property access (inline caches) instead of dictionary lookups.

```js
function Point(x, y) { this.x = x; this.y = y; }
const p1 = new Point(1, 2);
const p2 = new Point(3, 4);   // same hidden class as p1 — fast

p1.z = 10;                     // p1 now has a DIFFERENT hidden class than p2
                                // breaks inline caching, degrades performance
```

**Why this matters:** always initialize all object properties in the constructor, in the same order, rather than adding properties dynamically later. This is a real answer to "why is this code slow" questions.

## Memory: Stack vs Heap

| | Call Stack | Memory Heap |
|---|---|---|
| Stores | Primitives, function frames | Objects, arrays, functions, closures |
| Size | Fixed, limited | Dynamic |
| Access | Fast, LIFO | Slower, reference-based |
| Management | Automatic (frame pop) | Garbage Collector |

```js
let a = 10;             // primitive — stack
let b = { x: 10 };      // reference in stack, object in heap
let c = b;               // c shares b's heap reference
c.x = 99;
console.log(b.x);        // 99 — same underlying object
```

## Garbage Collection — Mark and Sweep

1. **Mark:** starting from roots (globals, active call stack), traverse and mark everything reachable.
2. **Sweep:** anything unmarked is unreachable → freed.

**Generational GC (V8):** new objects go to **Young Generation** (frequent, cheap Minor GC); objects surviving several cycles get promoted to **Old Generation** (less frequent Major GC). This split exists because most objects die young — optimizing for that case is cheaper than scanning everything equally.

**Leak patterns that actually show up in production:**
```js
// 1. Accidental global (no let/const/var)
function leak() { leakedVar = "attached to global"; }

// 2. Forgotten timers holding closures alive
const data = fetchHeavyData();
setInterval(() => process(data), 1000); // data never freed while interval runs

// 3. Detached DOM nodes still referenced in JS
let btn = document.getElementById('myBtn');
document.body.removeChild(btn);
btn = null; // required — otherwise node stays in memory despite being detached

// 4. Closures capturing more than they need
function outer() {
  const bigArray = new Array(1_000_000).fill(0);
  return () => bigArray[0]; // whole array kept alive just to return index 0
}
```

## Execution Context & Hoisting

Every function call (and the initial script) creates an **Execution Context** with two phases:

**Creation phase** (hoisting happens here):
```js
console.log(x);   // undefined — var hoisted, not yet assigned
console.log(fn);  // [Function: fn] — function declarations hoisted fully
var x = 5;
function fn() {}
```

**`let`/`const` — Temporal Dead Zone:** hoisted but not initialized; accessing before declaration throws, unlike `var`'s silent `undefined`.
```js
console.log(y); // ReferenceError: Cannot access 'y' before initialization
let y = 10;
```

## Call Stack & Stack Overflow

LIFO structure tracking execution frames.

```js
function recurse() { recurse(); }
recurse(); // RangeError: Maximum call stack size exceeded — no base case
```

## Scope Chain (Lexical, not dynamic)

Scope is determined by **where code is written**, not where it's called from.

```js
let name = 'global';
function greet() { console.log(name); } // looks up lexical scope
function wrapper() {
  let name = 'local';
  greet(); // still logs 'global' — lexical scoping, not dynamic/call-time
}
```

## `this` Binding — Priority Order

1. **`new` binding** (highest) — `this` = newly constructed object
2. **Explicit** — `call`/`apply`/`bind`
3. **Implicit** — method call (`obj.method()`, `this` = `obj`)
4. **Default** (lowest) — global/undefined in strict mode

```js
const obj = { name: 'Ranjan', greet() { console.log(this.name); } };
const fn = obj.greet;
fn(); // undefined — lost implicit binding, `this` defaults
const fixed = obj.greet.bind(obj);
fixed(); // 'Ranjan'
```

**Arrow functions** have no own `this` — they close over the enclosing lexical scope's `this`, permanently, regardless of how they're invoked.

## Prototype Chain

Prototypal inheritance — objects inherit directly from other objects, not from classes.

```js
const animal = { breathe() { console.log('breathing'); } };
const dog = Object.create(animal);
dog.bark = function () { console.log('woof'); };

dog.bark();     // own property
dog.breathe();  // found via [[Prototype]] → animal
dog.toString(); // found via [[Prototype]] → Object.prototype
```

`class` is syntactic sugar over this exact mechanism — `Person.prototype.greet` shared across instances is the same thing a `class` method does internally.

## Interview Q&A Rapid Fire

**Q: Engine vs Runtime — one sentence?**
Engine executes JS (parse/compile/run); runtime is engine + host-provided APIs (DOM, timers, I/O) + event loop that together make async and I/O possible.

**Q: Why do hidden classes matter?**
Objects with identical shape share optimized property access; mutating an object's shape after creation (adding/deleting props dynamically) forces V8 to a slower lookup path — a real, measurable perf hit in hot code.

**Q: What causes deoptimization in V8?**
TurboFan compiles assuming stable types/shapes from prior calls; when a function receives a different type/shape than what it was optimized for, V8 discards the optimized code and falls back to bytecode.

**Q: Why is `var` inside a loop with closures a classic bug?**
```js
for (var i = 0; i < 3; i++) { setTimeout(() => console.log(i), 0); } // 3, 3, 3
for (let i = 0; i < 3; i++) { setTimeout(() => console.log(i), 0); } // 0, 1, 2
```
`var` is function-scoped — one shared binding across all iterations, so by the time the callbacks run, `i` is already `3`. `let` creates a **new binding per iteration**, so each closure captures its own `i`.