# Generics

The vocabulary of reusable, type-safe code. Every advanced TypeScript pattern — conditional types, mapped types, utility types — uses generics as its foundation.

---

## Navigation
[← Type System](./type-system.md) | [Advanced Types →](./advanced-types.md)

---

## What Generics Are

A generic is a **type parameter** — a placeholder that gets filled in at the call site. It lets you write one implementation that works correctly across many types, without sacrificing type safety.

```typescript
// Without generics: pick one type (too narrow) or use any (unsafe)
function first(arr: number[]): number { return arr[0]; }
function first(arr: any[]): any { return arr[0]; }   // loses type info

// With generics: works for any array, preserves the element type
function first<T>(arr: T[]): T { return arr[0]; }

const n = first([1, 2, 3]);       // T inferred as number → returns number
const s = first(['a', 'b']);      // T inferred as string → returns string
const b = first([true, false]);   // T inferred as boolean → returns boolean
```

> The return type is **the same type as the input** — the relationship is preserved. That's the power of generics: expressing type relationships.

---

## 1. Generic Functions

TypeScript infers type parameters from arguments at the call site — explicit annotation is rarely needed.

```typescript
// Single type parameter
function identity<T>(value: T): T { return value; }

// Multiple type parameters
function pair<A, B>(first: A, second: B): [A, B] {
  return [first, second];
}
const p = pair('hello', 42);   // [string, number]

// Generic arrow function (note the trailing comma in TSX files)
const wrap = <T,>(value: T): { value: T } => ({ value });

// Returning a different but related type
function mapArray<T, U>(arr: T[], fn: (item: T) => U): U[] {
  return arr.map(fn);
}
const lengths = mapArray(['hello', 'world'], s => s.length); // number[]
```

---

## 2. Generic Constraints (`extends`)

Without constraints, TypeScript treats `T` as `unknown` — you can't access any properties. `extends` narrows what `T` can be.

```typescript
// ❌ Without constraint: T is unknown — .length doesn't exist
function getLength<T>(val: T): number { return val.length; } // error

// ✅ Constrain T to types that have .length
function getLength<T extends { length: number }>(val: T): number {
  return val.length;
}
getLength('hello');     // ✅ string has .length
getLength([1, 2, 3]);   // ✅ array has .length
getLength(42);          // ❌ number doesn't have .length
```

```typescript
// Constrain to keys of another type parameter
function getProperty<T, K extends keyof T>(obj: T, key: K): T[K] {
  return obj[key];
}
const user = { id: 1, name: 'Alice', role: 'admin' };
getProperty(user, 'name');   // string ✅
getProperty(user, 'id');     // number ✅
getProperty(user, 'email');  // ❌ 'email' not a key of typeof user
```

---

## 3. Generic Interfaces & Types

```typescript
// Generic interface
interface Repository<T> {
  findById(id: string): Promise<T>;
  save(entity: T): Promise<T>;
  delete(id: string): Promise<void>;
}

// Usage — concrete type substituted at use
class UserRepository implements Repository<User> {
  findById(id: string): Promise<User> { /* ... */ }
  save(user: User): Promise<User> { /* ... */ }
  delete(id: string): Promise<void> { /* ... */ }
}

// Generic type alias
type ApiResponse<T> = {
  data: T;
  status: number;
  message: string;
  timestamp: Date;
};

type UserResponse = ApiResponse<User>;          // { data: User; status: number; ... }
type UsersResponse = ApiResponse<User[]>;       // { data: User[]; ... }
type PaginatedResponse<T> = ApiResponse<{
  items: T[];
  total: number;
  page: number;
}>;
```

---

## 4. Generic Classes

```typescript
class Stack<T> {
  private items: T[] = [];

  push(item: T): void { this.items.push(item); }
  pop(): T | undefined { return this.items.pop(); }
  peek(): T | undefined { return this.items[this.items.length - 1]; }
  get size(): number { return this.items.length; }
}

const numStack = new Stack<number>();
numStack.push(1);
numStack.push('hello');  // ❌ type error — only numbers allowed

const strStack = new Stack<string>();
strStack.push('hello');  // ✅
```

---

## 5. Default Type Parameters

Like default function parameters, but for types:

```typescript
// T defaults to string if not specified
type Container<T = string> = { value: T };

type C1 = Container;          // Container<string>
type C2 = Container<number>;  // Container<number>

// Useful in generic functions too
function createState<T = unknown>(initial?: T): { value: T | undefined } {
  return { value: initial };
}
```

---

## 6. Conditional Constraints with `extends`

The same `extends` keyword used in constraints is also used in conditional types (next file). Recognizing the pattern is key:

```typescript
// Constraint: "T must be assignable to string"
function fn<T extends string>(val: T): T { return val; }

// Conditional type: "if T is assignable to string, use X else Y"
type IsString<T> = T extends string ? 'yes' : 'no';
```

Both read "T extends string" but do different things depending on context — constraint vs. conditional type expression.

---

## 7. Variance (Covariance & Contravariance)

Variance describes how subtype relationships flow through generic types. TypeScript infers this structurally.

```typescript
// Covariant position (return type / output): subtype flows UP
type Producer<T> = () => T;
// Producer<Dog> is assignable to Producer<Animal> (Dog → Animal)
// because returning a Dog satisfies "returns an Animal"

// Contravariant position (parameter / input): subtype flows DOWN
type Consumer<T> = (val: T) => void;
// Consumer<Animal> is assignable to Consumer<Dog>
// because a handler that accepts any Animal can handle a Dog

// Invariant: both input AND output — must match exactly
type ReadWrite<T> = { get(): T; set(val: T): void };
```

```typescript
// Explicit variance annotations (TypeScript 4.7+)
type Covariant<out T>     = () => T;       // T only appears in output
type Contravariant<in T>  = (val: T) => void; // T only appears in input
```

> **Why it matters:** understanding variance explains why `Array<Dog>` is not assignable to `Array<Animal>` (mutable arrays are invariant — you could `.push(new Cat())` into an `Animal[]` that's actually a `Dog[]`), and why callback parameter types work "backwards."

---

## 8. Real-World Patterns

### Pattern: Type-Safe Event Emitter
```typescript
type EventMap = {
  login:  { userId: string; timestamp: Date };
  logout: { userId: string };
  error:  { message: string; code: number };
};

class TypedEmitter<Events extends Record<string, unknown>> {
  on<K extends keyof Events>(event: K, handler: (data: Events[K]) => void): void { /*...*/ }
  emit<K extends keyof Events>(event: K, data: Events[K]): void { /*...*/ }
}

const emitter = new TypedEmitter<EventMap>();
emitter.on('login', ({ userId, timestamp }) => console.log(userId)); // ✅ typed
emitter.emit('login', { userId: '1', timestamp: new Date() });        // ✅
emitter.emit('login', { userId: '1' });                               // ❌ missing timestamp
```

### Pattern: Type-Safe HTTP Client
```typescript
interface ApiClient {
  get<T>(url: string): Promise<T>;
  post<T, B = unknown>(url: string, body: B): Promise<T>;
}

// Usage: caller decides the expected response type
const users = await api.get<User[]>('/users');          // Promise<User[]>
const user  = await api.post<User, CreateUserDto>('/users', dto); // Promise<User>
```

### Pattern: Builder with Type Accumulation
```typescript
// The type grows as methods are called — constrains valid builds
class QueryBuilder<T extends object = {}> {
  private filters: T = {} as T;

  where<K extends string, V>(key: K, value: V): QueryBuilder<T & Record<K, V>> {
    (this.filters as any)[key] = value;
    return this as any;
  }

  build(): T { return this.filters; }
}

const result = new QueryBuilder()
  .where('status', 'active')
  .where('role', 'admin')
  .build();
// type: { status: string } & { role: string }
```

### Pattern: Lookup / Type-Safe Dispatch
```typescript
type ActionHandlers = {
  increment: (amount: number) => void;
  reset: () => void;
  setLabel: (label: string) => void;
};

function dispatch<K extends keyof ActionHandlers>(
  action: K,
  ...args: Parameters<ActionHandlers[K]>
): void {
  // handler[action](...args) — all type-checked
}

dispatch('increment', 5);    // ✅
dispatch('reset');            // ✅
dispatch('setLabel', 'hi');  // ✅
dispatch('increment', 'hi'); // ❌ number expected
```

---

## 9. Generic Gotchas

### Gotcha 1: Inferred vs Explicit — when each matters
```typescript
// Usually let TS infer
const result = first([1, 2, 3]);    // T inferred as number ✅

// Explicitly set when you want a wider type
const ids = first<string | number>(['a', 1]); // force the union
```

### Gotcha 2: `T[]` vs `Array<T>` — identical, pick one style
```typescript
function fn<T>(arr: T[]): T[] { return arr; }      // same as:
function fn<T>(arr: Array<T>): Array<T> { return arr; }
```

### Gotcha 3: Generic constraint vs. conditional — different meaning of `extends`
```typescript
// In a function signature: constraint (T must be string or narrower)
function fn<T extends string>(val: T): T { return val; }

// In a type expression: conditional (evaluated as a ternary)
type IsString<T> = T extends string ? true : false;
```

### Gotcha 4: Type parameter used only once → probably `any` in disguise
```typescript
// T used only once — gives no useful constraint or output typing
function log<T>(val: T): void { console.log(val); } // just use unknown/any
// Generics earn their keep when they create a RELATIONSHIP between types
```

### Gotcha 5: Over-constraining with concrete types
```typescript
// ❌ Too specific — only works with User[]
function first<T extends User>(arr: T[]): T { return arr[0]; }

// ✅ Correct — works for any array
function first<T>(arr: T[]): T { return arr[0]; }
```

---

## Mental Models

### Generics = Template Variables
Like a cookie cutter (template) that works for any dough — the shape is defined once, but the material (`T`) is filled in per use. The cutter doesn't care if it's sugar cookie dough or chocolate; it just stamps the shape.

### Constraints = Qualifications
"You must have a `.length`" is a job qualification. Without it, you can't promise the applicant (`T`) has the skills you need. Constraints are the minimum requirements that make your function's assumptions safe.

### Type Parameters = Placeholders Until Filled
`T` is like a blank in a sentence: "The ___ is large." At the call site, T gets filled in and the whole type becomes concrete, consistent, and checkable.

### Variance = Direction of Trust
Covariance: if a Dog is an Animal, producers of Dogs are producers of Animals — what you produce can be trusted as the wider type. Contravariance: consumers of Animals can handle Dogs — a more general handler is safer for specific inputs.

---

## Common Mistakes

### Mistake 1: Using `any` instead of `T`
❌ `function wrap(val: any): { value: any }` — loses type info
✅ `function wrap<T>(val: T): { value: T }` — preserves type relationship

### Mistake 2: No Constraints When Accessing Properties
❌ `function fn<T>(x: T) { return x.name; }` — error, T is unknown
✅ `function fn<T extends { name: string }>(x: T)` — safe

### Mistake 3: Over-specifying When T Is Used Only Once
❌ `function log<T>(v: T): void {}` — T adds no value here
✅ `function log(v: unknown): void {}` — simpler and equivalent

### Mistake 4: Confusing Constraint `extends` with Conditional `extends`
❌ Thinking `<T extends string>` means "T is exactly string"
✅ It means "T is assignable to string" — `'hello'` also satisfies this

### Mistake 5: Making Arrays Mutable and Covariant
❌ Expecting `Dog[]` to be a `Animal[]` for general APIs
✅ Mutable arrays are invariant; use `readonly T[]` (covariant) when not mutating

---

## Interview Questions

### Q1: What are generics and why are they important?
**Answer:** Generics are type parameters that make a function, class, or type work correctly across many types while preserving type relationships. They're important because they let you write one implementation — a `first<T>(arr: T[]): T` or a `Repository<T>` — that is type-safe for any concrete type, instead of duplicating code per type or surrendering to `any`. The key insight is that generics capture *relationships* between types: "the return type is the same as the input element type," or "the key must exist on the object." Without generics these relationships can't be expressed, so callers lose type information at the boundary. In practice, generics are the building block for all advanced TypeScript patterns and all utility types.

### Q2: What does `extends` mean in a generic constraint, and how does it differ from a conditional type?
**Answer:** In a generic constraint like `<T extends User>`, `extends` means "T must be assignable to User" — it sets a lower bound on what T can be. It's a compile-time check that ensures the type argument satisfies a minimum shape, so inside the function you can safely access User's properties. In a conditional type like `T extends string ? X : Y`, `extends` is a ternary — "if T is assignable to string, evaluate to X, otherwise Y." It's used at the type level to branch based on type relationships rather than constrain a type parameter. Same keyword, two very different meanings depending on context: one is a gate, the other is a condition. Recognizing the difference is important when reading complex library types.

### Q3: Explain variance in generics with an example.
**Answer:** Variance describes how subtype relationships flow through a generic wrapper. Covariance means subtype flows in the same direction: if `Dog` extends `Animal`, then a `Producer<Dog>` (something that returns a Dog) is assignable to a `Producer<Animal>` — returning a Dog satisfies the contract of returning an Animal. Contravariance goes the other direction: a `Consumer<Animal>` (handler for any Animal) is assignable to `Consumer<Dog>` — if you can handle any Animal, you can certainly handle a Dog, making it a safer handler. Arrays are invariant (both producer and consumer) because a mutable `Dog[]` is not safe as an `Animal[]` — you could push a Cat in. This matters when designing callback APIs and explains why TypeScript sometimes flags seemingly compatible function types.

### Q4: How would you design a type-safe generic repository interface?
**Answer:** I'd parameterize the interface on the entity type so all methods consistently use that type. The interface declares `findById(id: string): Promise<T>`, `findAll(): Promise<T[]>`, `save(entity: T): Promise<T>`, `delete(id: string): Promise<void>`. Concrete classes implement it for specific entities — `class UserRepository implements Repository<User>`. This gives callers full type inference: `userRepo.findById('1')` returns `Promise<User>`, not `Promise<any>`. I might extend it with a second type parameter for query filters — `Repository<T, Q = Partial<T>>` — so `findAll(query?: Q)` is also typed. The constraint ensures every implementation honors the same contract and every call site gets proper types without casting.

### Q5: When is a generic type parameter *not* worth using?
**Answer:** A type parameter earns its keep when it creates a *relationship* between types — between input and output, between an object and its key, between handler input and event payload. When a type parameter appears only once and creates no relationship (like `function log<T>(val: T): void`), it adds no value over `unknown` or `any` and just adds noise. Similarly, over-constraining — `<T extends SpecificClass>` when `SpecificClass` would work directly — is needless complexity. And using a generic with a redundant bound like `<T extends any>` or `<T extends object>` when the body doesn't use T's properties is a sign the generic isn't doing real work. The signal to add a generic: "I need the output type, or another argument's type, to reflect something about this input type."

---

## Key Takeaways

- **Generics express type relationships** — the return type matches the input, the key exists on the object, etc.
- **`extends` in constraints** = "T must satisfy this shape" (gate)
- **`extends` in conditionals** = "if T is assignable to..." (ternary — next file)
- **`<T, K extends keyof T>`** = the most common real-world constraint pattern
- **Default type parameters** (`<T = string>`) simplify common cases
- **Variance** — covariant (output), contravariant (input), invariant (both)
- **Generics earn their keep** when they link types together, not when used once
- **Real patterns:** `ApiResponse<T>`, `Repository<T>`, typed event emitters

---

## What's Next?

Generics are the vocabulary — now use them to write **type algebra**: conditional types, mapped types, and `infer`:
- **[Advanced Types →](./advanced-types.md)** — conditional types, mapped types, template literals, `infer`

---

[← Type System](./type-system.md) | [Advanced Types →](./advanced-types.md)
