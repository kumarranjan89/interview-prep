# TypeScript Type System — The Mental Model

The foundational concepts that make everything else in TypeScript click. Understanding *how TypeScript thinks* is more valuable than memorizing syntax.

---

## Navigation
[← TypeScript README](./README.md) | [Generics →](./generics.md)

---

## Why the Mental Model Matters

Most TypeScript bugs and confusing errors come from not internalizing two things:
1. TypeScript uses **structural typing**, not nominal typing
2. Types are **sets of values**, not labels

Everything else — generics, conditional types, mapped types — flows from these.

---

## 1. Structural Typing (The Core Concept)

TypeScript checks **shape**, not **name**. If an object has the required properties, it satisfies the type — regardless of what it's called or how it was declared.

```typescript
type Point = { x: number; y: number };
type Coord = { x: number; y: number };

// These are IDENTICAL to TypeScript — same shape = same type
const p: Point = { x: 1, y: 2 };
const c: Coord = p; // ✅ fine — same structure

// An unrelated object with the right shape also works
function printPoint(pt: Point) { console.log(pt.x, pt.y); }
printPoint({ x: 5, y: 10 });           // ✅ literal
printPoint({ x: 5, y: 10, z: 0 });    // ❌ excess property check (object literals only)

const obj = { x: 5, y: 10, z: 0 };
printPoint(obj);                        // ✅ assigned variable bypasses excess check
```

> **The excess property check** only fires on fresh object literals — a deliberate special case, not structural typing. Assign to a variable first and it passes.

### Contrast with Nominal Typing (Java/C#)
```
Nominal:    TypeA and TypeB are different because they have different names
Structural: TypeA and TypeB are the same if they have the same shape
```

This is why TypeScript allows "duck typing" — if it walks like a duck and quacks like a duck, it IS a duck. No `implements` keyword required.

---

## 2. Types as Sets

A type is a **set of possible values**. This mental model explains unions, intersections, `never`, and `unknown` intuitively.

```
never          = empty set (no value can belong)
unknown        = universal set (any value belongs)
boolean        = { true, false }
'a' | 'b'      = { 'a', 'b' }
number         = all numbers
string & {}    = set of all non-nullish strings
```

### Union = Set Union (OR)
```typescript
type AB = 'a' | 'b';   // {'a'} ∪ {'b'} = {'a', 'b'}
// A value can be ANY member of the set
let x: AB = 'a';        // ✅
let y: AB = 'b';        // ✅
let z: AB = 'c';        // ❌
```

### Intersection = Set Intersection (AND)
```typescript
type Named = { name: string };
type Aged  = { age: number };
type Person = Named & Aged;    // must satisfy BOTH
// { name: string, age: number }
// In object types, & MERGES properties (usually what you want)
```

### `never` = The Empty Set
```typescript
type Impossible = string & number; // no value can be both → never
type N = never | string;           // never | X = X  (adding nothing)
type U = never & string;           // never & X = never (intersect with empty set)
```

### `unknown` = The Universal Set
```typescript
// unknown accepts every value (top type)
let u: unknown = "anything";
u = 42;
u = {};

// But you must narrow before using it
if (typeof u === 'string') { u.toUpperCase(); } // ✅ narrowed
u.toUpperCase();  // ❌ — u might not be a string
```

---

## 3. `type` vs `interface` — The Real Difference

Both define object shapes. They're more alike than different, but the distinctions matter.

```typescript
type User = { name: string; age: number };
interface User { name: string; age: number; }
```

### Key Differences

| Feature | `interface` | `type` |
|---------|------------|--------|
| Declaration merging | ✅ (open, can be augmented) | ❌ (closed) |
| Extends/implements | ✅ `extends` keyword | ✅ via `&` intersection |
| Can represent | Object shapes | Anything (unions, primitives, tuples, functions) |
| Error messages | Typically clearer | Can be verbose |
| Computed/conditional | ❌ | ✅ |

```typescript
// Declaration merging (interface only — useful for augmenting libraries)
interface Window { myProp: string; }
interface Window { anotherProp: number; }
// Both declarations merge into one

// type can represent things interface can't
type ID = string | number;
type Pair<T> = [T, T];
type Handler = (event: MouseEvent) => void;
type Nullable<T> = T | null;
```

### When to Use Which
```
interface  → public API shapes, class contracts, when you want mergeability
type       → unions, intersections, tuples, mapped/conditional types, complex aliases
```

> **Architect rule of thumb:** use `interface` for things you'd put in a public API; `type` for everything else. Consistency within a codebase matters more than which you pick.

---

## 4. The Type Hierarchy (Top to Bottom)

```
        unknown           ← top type: accepts everything
           │
      ┌────┴────┐
    object    primitives
      │           │
   class/interface  string, number, boolean, symbol, bigint
      │
   null/undefined  ← assignable to nothing except their own types (strict mode)
      │
     never           ← bottom type: assignable to everything, nothing assignable to it
```

```typescript
// Subtype relationships: narrower types are assignable to wider ones
let u: unknown = "hello";  // ✅ string → unknown (wide)
let s: string = u;          // ❌ unknown → string needs narrowing

let a: 'hello' = 'hello';  // literal type — narrowest
let b: string = a;          // ✅ 'hello' → string (wider)
let c: 'hello' = b;         // ❌ string → 'hello' needs assertion
```

---

## 5. Literal Types & Widening

**Literal types** are the narrowest possible type — a single value.

```typescript
let a = 'hello';        // widened to string (let allows reassignment)
const b = 'hello';      // literal type 'hello' (const can't change)

type Direction = 'north' | 'south' | 'east' | 'west';
```

### Widening
TypeScript **widens** a type when it infers from a mutable context:
```typescript
let x = 'hello';        // TypeScript infers: string (widened from 'hello')
const y = 'hello';      // TypeScript infers: 'hello' (literal, not widened)

// Prevent widening with 'as const'
const config = { env: 'prod', port: 3000 } as const;
//    config: { readonly env: 'prod'; readonly port: 3000 }
//    without as const: { env: string; port: number }
```

```typescript
// as const — powerful for defining lookup tables and discriminated unions
const ROUTES = ['home', 'about', 'dashboard'] as const;
type Route = typeof ROUTES[number];  // 'home' | 'about' | 'dashboard'
```

---

## 6. `typeof` and `keyof`

Two essential type operators:

```typescript
// typeof: get the TYPE of a value
const config = { host: 'localhost', port: 3000 };
type Config = typeof config;    // { host: string; port: number }

function getUser() { return { id: 1, name: 'Alice' }; }
type User = ReturnType<typeof getUser>; // { id: number; name: string }
```

```typescript
// keyof: get a union of an object type's keys
type Config = { host: string; port: number; debug: boolean };
type ConfigKey = keyof Config;   // 'host' | 'port' | 'debug'

function getConfig<K extends keyof Config>(key: K): Config[K] {
  return config[key];  // type-safe property access
}
getConfig('host');   // returns string
getConfig('port');   // returns number
getConfig('blah');   // ❌ type error
```

---

## 7. Indexed Access Types

Access a type's property type using `T[K]`:

```typescript
type User = { id: number; name: string; address: { city: string } };

type UserName = User['name'];           // string
type UserAddress = User['address'];     // { city: string }
type City = User['address']['city'];    // string

// With union of keys
type IdOrName = User['id' | 'name'];   // number | string

// With arrays
type Colors = ('red' | 'blue' | 'green')[];
type Color = Colors[number];           // 'red' | 'blue' | 'green'
```

---

## 8. `any` vs `unknown` vs `never` — The Trinity

```
any     = opt out of type checking entirely (contagious — spreads unsafety)
unknown = I don't know the type YET — must narrow before use (safe)
never   = this should never happen / this code path is unreachable
```

```typescript
// any — unsafe, avoid in production code
function parseData(input: any) {
  return input.anything.you.like; // no error — dangerous
}

// unknown — safe boundary for external data
function parseData(input: unknown): string {
  if (typeof input === 'string') return input;   // ✅ narrowed
  throw new Error('Expected string');
}

// never — exhaustiveness checking
type Shape = 'circle' | 'square';
function area(s: Shape): number {
  switch (s) {
    case 'circle': return 3.14;
    case 'square': return 1;
    default:
      const _exhaustive: never = s; // ❌ error if new shape added and not handled
      throw new Error(`Unhandled: ${s}`);
  }
}
```

> **Architect rule:** treat `any` like `// @ts-ignore` — a debt marker. Use `unknown` at system boundaries (API responses, event payloads), `never` for exhaustiveness and impossible paths.

---

## 9. Type Assertions vs Type Guards

```typescript
// Type assertion (as) — YOU tell TS, no runtime check
const input = document.getElementById('input') as HTMLInputElement;

// Double assertion (bypass — escape hatch, risky)
const val = someValue as unknown as TargetType;

// Non-null assertion (!) — assert not null/undefined
const el = document.querySelector('.btn')!;  // you guarantee it exists

// Type guard — runtime check that narrows the type
function isString(val: unknown): val is string {
  return typeof val === 'string';
}
```

> Prefer **type guards** over assertions whenever possible — they're runtime-verified. Assertions are promises to the compiler with no safety net.

---

## Mental Models

### Structural Typing = Fitting a Mold
TypeScript doesn't care about the label on the clay — it only cares that it fits the mold. Any object that fits the shape works, regardless of where it came from.

### Types as Sets = Venn Diagrams
Union (`|`) is the combined area of two circles. Intersection (`&`) is the overlap. `never` is an empty circle. `unknown` is the entire universe.

### `any` vs `unknown` = Keys vs Locked Box
`any` hands you every key with no questions asked. `unknown` gives you a locked box — you must prove you have the right key (narrow the type) before you can use what's inside.

### Literal Types = Pointing at a Specific Dot
`string` is the whole number line. `'hello'` is pointing at one specific dot on it — narrower, more precise.

---

## Common Mistakes

### Mistake 1: Reaching for `any`
❌ Using `any` to silence errors → spreads unsafety through the codebase
✅ Use `unknown` at boundaries, narrow before use

### Mistake 2: Confusing Structural and Nominal
❌ Expecting `type A` and `type B` with same shape to be incompatible
✅ They ARE compatible — TypeScript only checks shape

### Mistake 3: Overusing `as` Assertions
❌ `value as SomeType` to bypass errors → runtime surprises
✅ Use type guards with runtime checks for safe narrowing

### Mistake 4: `keyof` on `any`
❌ `keyof any` = `string | number | symbol` — too wide
✅ `keyof ConcreteType` for precise key unions

### Mistake 5: Forgetting Widening
❌ Expecting `let x = 'hello'` to have type `'hello'`
✅ Use `const` or `as const` to prevent widening

### Mistake 6: Excess Property Check Confusion
❌ Thinking object shape compatibility is broken
✅ Excess check only fires on fresh literals; variable assignment bypasses it

---

## Interview Questions

### Q1: What is structural typing and how does it differ from nominal typing?
**Answer:** TypeScript uses structural typing, which means compatibility is determined purely by shape — the set of properties and their types — not by a type's name or declaration. If two types have the same structure they're interchangeable, even if they're named differently and have no relationship. This contrasts with nominal typing (Java, C#) where a type is only compatible with types it explicitly extends or implements. In practice it means TypeScript naturally supports duck typing — any object with the right shape satisfies a type. It also explains the excess property check: it only fires on fresh object literals as a convenience to catch typos; once assigned to a variable, the extra properties are silently allowed. The structural model underpins why TypeScript interfaces can describe shapes from untyped JS libraries without needing to change them.

### Q2: When would you use `type` vs `interface` and why?
**Answer:** Both define object shapes and are largely interchangeable, but the distinctions matter. I use `interface` for public API contracts — things libraries or teams will extend, where declaration merging is desirable (e.g., augmenting a third-party interface), and when defining class contracts with `implements`. I use `type` for everything that interfaces can't express: unions (`string | number`), intersections as compositions (`A & B`), tuples, function aliases, and particularly for mapped types, conditional types, and template literal types. `type` is also the only option for aliases of primitives, unions, and cross-cutting utility types like `Nullable<T>`. Consistency within a codebase matters more than which you pick, so I establish a project convention: `interface` for entity/service shapes, `type` for everything compositional.

### Q3: What is `never` and when would you use it?
**Answer:** `never` is the bottom type — the empty set. No value is assignable to `never`, but `never` is assignable to everything. I use it in three scenarios. First, for functions that never return — infinite loops or those that always throw (`function fail(): never { throw new Error(); }`). Second, to represent impossible states — `string & number` resolves to `never` because nothing can be both. Third and most valuably, for exhaustiveness checking in discriminated unions: in a switch/if-else that handles every case, the `default` branch assigns to `never`. If someone later adds a new variant without handling it, TypeScript flags an error at the assignment before it becomes a runtime bug. This makes `never` a compile-time safety net for evolving domain types.

### Q4: What's the difference between `unknown` and `any`?
**Answer:** Both accept any value, but `unknown` is the safe version. `any` completely opts out of type checking — you can access arbitrary properties, call it as a function, and TypeScript never complains, spreading unsafety to everything it touches. `unknown` accepts any value but forces you to narrow the type before using it — TypeScript won't let you call methods or access properties until you've proven the type at runtime with a guard. `any` is the "I give up" escape hatch; `unknown` is "I don't know yet but I'll be safe about it." In production code I use `unknown` at system boundaries — API responses, event data, external config — and narrow it with type guards before use. `any` is a debt marker, acceptable temporarily during migration but banned in established code via `noImplicitAny`.

### Q5: Explain widening and `as const`. When do you need `as const`?
**Answer:** Widening is TypeScript's default behavior of inferring the broadest practical type from a mutable context. `let x = 'hello'` infers `string`, not `'hello'`, because `let` allows reassignment to any string. `const x = 'hello'` infers the literal `'hello'` because the value can't change. `as const` extends this to objects and arrays: without it `{ env: 'prod', port: 3000 }` infers `{ env: string; port: number }`; with it you get `{ readonly env: 'prod'; readonly port: 3000 }` — every value at its literal type, all properties readonly. I need `as const` when I want to use object values as literal types downstream — for route maps, config objects, action-type constants, and particularly for building discriminated unions or deriving string literal unions with `typeof arr[number]`.

### Q6: How does TypeScript's type hierarchy inform error diagnosis?
**Answer:** Understanding the hierarchy — `unknown` at the top, `never` at the bottom, with primitives and object types in between — explains most assignability errors. A narrower type is always assignable to a wider one (a `'hello'` literal to `string`, a `string` to `unknown`) but not vice versa — you need a guard or assertion to go from wide to narrow. "Type X is not assignable to type Y" usually means you're trying to assign a wider type to a narrower one without proof. `never` appearing in a union means some path is impossible; `never` appearing where a real type was expected often means conditional type branches produced an empty intersection. The sets mental model — is the value set of X a subset of Y's? — answers assignability questions faster than consulting documentation.

---

## Key Takeaways

- **Structural typing** — shape, not name, determines compatibility
- **Types are sets** — union is OR, intersection is AND, `never` is empty, `unknown` is universal
- **`type` vs `interface`** — `interface` for mergeable contracts; `type` for unions/compositions/everything else
- **Widening** — `let` widens literals; `const`/`as const` preserves them
- **`any`** is unsafe opt-out; **`unknown`** is safe boundary — always prefer `unknown`
- **`never`** is the empty set — use it for exhaustiveness checks and impossible states
- **Excess property check** only fires on fresh literals, not variables
- **`keyof` / indexed access** are the building blocks of all advanced type utilities

---

## What's Next?

The mental model is set. Now learn the most powerful reuse mechanism in TypeScript:
- **[Generics →](./generics.md)** — write reusable, type-safe code

---

[← TypeScript README](./README.md) | [Generics →](./generics.md)
