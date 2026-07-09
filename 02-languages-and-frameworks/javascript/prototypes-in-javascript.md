# Prototypes in JavaScript (Deep Dive)

> Interview prep notes — JavaScript fundamentals series
> Audience: experienced frontend developers refreshing core concepts before interviews
> Companion to: `01-classes.md` (classes are sugar over exactly what's below)

---

## Mental Model

Every object in JavaScript has an internal, hidden link to another object called its **prototype**. When you access a property that doesn't exist directly on an object, the engine doesn't give up — it walks up this link, checks the prototype, then the prototype's prototype, and so on, until it either finds the property or hits `null` (the end of the chain).

Hold onto one sentence for the whole topic: **"Missing property? Ask your prototype."** That's it. Inheritance in JS is not about copying — it's about *delegation* through a chain of lookups. Classes, `extends`, methods on instances — all of it is this one lookup mechanism wearing different syntax.

The second thing to internalize: there are **two different "prototype" words** in JS, and confusing them is the #1 source of prototype bugs:

| Term | What it is |
|---|---|
| `obj.__proto__` / `Object.getPrototypeOf(obj)` | The **actual internal link** an object uses for lookups. Every object has this. |
| `Fn.prototype` | A regular object property that only exists **on functions**, used as a template — it becomes the `__proto__` of any object created with `new Fn()`. |

`Fn.prototype` is the *blueprint*; `obj.__proto__` is the *actual chain link*. `new` is the operation that connects the two.

---

## 1. The Chain, Concretely

```js
function Player(name) {
  this.name = name;
}

Player.prototype.introduce = function () {
  console.log(`Hi, I'm ${this.name}`);
};

const p1 = new Player('Shelly');

p1.introduce();
// "Hi, I'm Shelly"
// p1 doesn't own `introduce` — it's not found on p1 itself.
// The engine looks at p1 -> fails -> checks p1.__proto__ (= Player.prototype) -> found.
```

```js
p1.hasOwnProperty('name');       // true  — set directly in constructor via this.name
p1.hasOwnProperty('introduce');  // false — lives on the prototype, not the instance
'introduce' in p1;               // true  — `in` checks the WHOLE chain, not just own props
```

**What `new Player('Shelly')` actually does, mechanically (this is the real algorithm, and it's worth memorizing):**

1. Create a new plain object: `{}`
2. Set that object's internal `[[Prototype]]` to `Player.prototype`  → `obj.__proto__ = Player.prototype`
3. Call `Player` with `this` bound to that new object
4. If `Player` doesn't explicitly return an object, return `this` (the object built in steps 1–3)

`class` constructors do exactly this — `new` behaves identically whether the "class" is defined with the `class` keyword or as a plain function, because under the hood a `class` **is** a function with some extra restrictions (can't be called without `new`, body is auto-strict-mode, methods are non-enumerable).

---

## 2. Walking the Chain to the Top

Every chain eventually ends at `Object.prototype`, then `null`.

```js
p1.__proto__                          // Player.prototype
p1.__proto__.__proto__                // Object.prototype
p1.__proto__.__proto__.__proto__      // null — end of the line

Object.getPrototypeOf(p1) === Player.prototype   // true (preferred over __proto__)
```

This is why every object — even a `{}` literal — has methods like `.toString()`, `.hasOwnProperty()`, `.valueOf()` available on it "for free": they live on `Object.prototype`, and every chain passes through it.

```js
({}).toString()   // "[object Object]" — found on Object.prototype, not on the literal itself
```

**Functions are objects too**, so functions have their own chain up through `Function.prototype -> Object.prototype -> null`. This is a separate concept from `Fn.prototype` (the template object used for instances) — don't conflate a function's *own* prototype chain with the `.prototype` property it carries for `new`.

---

## 3. `extends` Is Chain-Linking, Nothing More

```js
class Player {
  constructor(name) { this.name = name; }
  introduce() { console.log(`Hi, I'm ${this.name}`); }
}

class Wizard extends Player {
  play() { console.log('WEEEEE'); }
}

const w = new Wizard('Shelly');
```

What `extends` sets up, in plain-prototype terms:

```js
Object.getPrototypeOf(Wizard.prototype) === Player.prototype   // true — instance chain
Object.getPrototypeOf(Wizard) === Player                       // true — static chain (for static methods)
```

So the full lookup chain for `w` is:

```
w  →  Wizard.prototype  →  Player.prototype  →  Object.prototype  →  null
     (has: play)            (has: introduce)      (has: toString, etc.)
```

`w.introduce()` walks past `Wizard.prototype` (not found there), finds it on `Player.prototype`. `w.play()` finds it immediately on `Wizard.prototype`. Neither method is ever copied onto `w` itself — there is exactly **one copy** of `introduce` in memory no matter how many `Wizard`/`Player` instances you create. This is the core memory/perf advantage of prototype-based method sharing over, say, defining methods as instance properties inside the constructor (`this.introduce = () => {...}`), which *would* create a new function per instance.

**Interview angle:** *"If I define a method inside a constructor with `this.method = ...` vs on the prototype, what's the difference?"* — instance-property methods are duplicated per object (more memory, but each gets its own closure and auto-bound `this`); prototype methods are shared (one copy, but `this` depends on call site — see `01-classes.md`).

---

## 4. Shadowing

If you assign a property directly onto an instance that has the same name as something up the chain, the instance's own property wins — the chain lookup stops at the first match, it never keeps going to "merge" values.

```js
const w2 = new Wizard('Merlin');
w2.introduce = function () {
  console.log('Custom override, ignoring prototype version');
};

w2.introduce();  // "Custom override..." — own property shadows the prototype one
delete w2.introduce;
w2.introduce();  // back to "Hi, I'm Merlin" — chain lookup resumes once the shadow is removed
```

This is also exactly how overriding works without `extends`/`super` machinery at all — assigning directly onto an instance, or reassigning `SubClass.prototype.method`, is shadowing, full stop.

---

## 5. `Object.create` — Prototypes Without Constructors

`class`/`new` is one way to set up a prototype link. `Object.create` does it directly, with no constructor function involved at all — useful to know because it's the "purest" form of what prototypal inheritance actually is.

```js
const playerProto = {
  introduce() {
    console.log(`Hi, I'm ${this.name}`);
  },
};

const p2 = Object.create(playerProto);
p2.name = 'Direct';
p2.introduce();  // "Hi, I'm Direct"

Object.getPrototypeOf(p2) === playerProto;  // true
```

No `new`, no constructor, no `class` — just: "make an object whose prototype is this other object." This is genuinely how the engine implements `new` internally; `Object.create` just exposes the mechanism directly.

---

## 6. `instanceof`: What It Actually Checks

`instanceof` does **not** check a "type" — it checks whether `Fn.prototype` appears anywhere in the object's prototype chain.

```js
w instanceof Wizard   // true  — Wizard.prototype is in w's chain
w instanceof Player   // true  — Player.prototype is also in w's chain
w instanceof Object   // true  — Object.prototype is at the top of every chain
w instanceof Array    // false — Array.prototype is never in w's chain
```

You can prove this by manually breaking the link:

```js
Object.setPrototypeOf(w, null);
w instanceof Wizard;  // false — the chain link is gone, even though `w` "is still a Wizard" conceptually
```

**Interview angle:** this is why `instanceof` is unreliable across iframes/realms (each realm has its own `Object`, `Array`, etc., so an array from another iframe fails `instanceof Array` in yours) — a classic senior-level gotcha question.

---

## 7. Own vs. Inherited — Enumeration Gotchas

```js
for (const key in w) { console.log(key); }
// iterates OWN + INHERITED enumerable properties (chain included)

Object.keys(w);          // OWN enumerable properties only
Object.getOwnPropertyNames(w);  // OWN properties, enumerable or not

// class methods defined via `class Foo { method() {} }` syntax are
// non-enumerable by default, which is WHY `for...in` on a class
// instance doesn't list its methods, but a manually-assigned
// Fn.prototype.method = function(){} WOULD show up in for...in.
```

This non-enumerability of class methods is a deliberate design choice (`class` syntax was designed after `for...in` foot-guns were already well understood) — one more small but real difference between `class` sugar and hand-rolled constructor-function prototypes.

---

## Quick Reference Table

| Concept | One-line takeaway |
|---|---|
| Prototype chain | Missing property lookups walk `__proto__` links until `Object.prototype`, then `null` |
| `Fn.prototype` vs `obj.__proto__` | `.prototype` is the blueprint on a function; `.__proto__` is the actual link an object uses |
| `new Fn()` | Creates object → links its `__proto__` to `Fn.prototype` → runs `Fn` with `this` = that object |
| `extends` | Chains `Sub.prototype.__proto__` to `Super.prototype` — nothing more exotic than that |
| Shadowing | An own property always wins over one further up the chain; lookup stops at first match |
| `Object.create(proto)` | Builds the prototype link directly, no constructor/class needed |
| `instanceof` | Checks "is `Fn.prototype` anywhere in this object's chain," not "what type is this" |
| Method sharing | Prototype methods = one shared copy; constructor-assigned `this.method` = one copy per instance |

---

## Related topics to review alongside this note
- `01-classes.md` — how `class`/`extends`/`super` map onto everything above
- `Object.freeze` / `Object.seal` and whether they affect the prototype chain (they don't, by default)
- Mixins as an alternative to single-chain inheritance
- Private class fields (`#field`) — notably **not** on the prototype chain at all, a deliberate departure from normal property lookup
- Performance implications of very long prototype chains on property lookup