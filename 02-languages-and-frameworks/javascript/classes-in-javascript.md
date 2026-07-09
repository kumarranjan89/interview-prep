# Classes in JavaScript

> Interview prep notes — JavaScript fundamentals series
> Audience: experienced frontend developers refreshing core concepts before interviews

---

## Mental Model

Before "classes" make sense, you need two pieces of groundwork in place: **reference types** and **`this` / context**. A `class` in JavaScript is not a new kind of object system — it's syntactic sugar over prototypes, functions, and objects that already exist in the language. If you understand the pieces below, `class` is just a cleaner way to write what you were already doing with constructor functions.

The core idea to hold onto: **an instance created with `new` is a plain object, linked via its prototype chain back to the class's `prototype` object.** Everything else (inheritance, `super`, static members, private fields) is built on top of that one fact.

---

## 1. Reference Types

Objects and arrays are **reference types**. Two object literals are never `===` equal, even if they look identical, because equality checks compare *references* (memory addresses), not structural content.

```js
[] === []          // false — two different array objects
[1] === [1]         // false — two different array objects

var object1 = { value: 10 };
var object2 = object1;         // object2 points to the SAME object as object1
var object3 = { value: 10 };   // a NEW, separate object with the same shape

object1 === object2  // true  — same reference
object1 === object3  // false — different reference, even though contents match
```

**Why this matters for classes:** every time you call `new SomeClass()`, you get back a brand-new object reference. Two instances built from identical constructor arguments will never be `===` to each other. This trips people up when they expect value-type behavior (like comparing primitives) but get reference-type behavior instead.

```js
new Player('A', 'Mage') === new Player('A', 'Mage')  // false
```

**Interview angle:** be ready to explain *why* (comparison is by reference, not deep value), and know that `Object.is`, `===`, and `==` all behave the same way here — none of them do structural/deep comparison. Deep equality requires either a manual comparison, `JSON.stringify` (with caveats), or a library like lodash's `isEqual`.

---

## 2. Context (`this`)

`this` is not determined by *where* a function is defined — it's determined by **how a function is called** (its "call site"), with a few exceptions (arrow functions, `bind`/`call`/`apply`, class fields).

```js
function b() {
  let a = 4;
}
// `this` inside a plain function call is undefined (strict mode)
// or the global object (sloppy mode). It has nothing to do with
// where `b` is declared.

const object4 = {
  a: function () {
    console.log(this);
  },
};

object4.a();
// logs `object4` — because `a` was called AS A METHOD on object4.
// The rule: whatever is left of the dot at the call site becomes `this`.
```

**Mental model:** ask "what's immediately to the left of the `.` when this function is *invoked*?" — that's `this`. Not where the function was written, not what it's assigned to, but how it's called.

```js
const fn = object4.a;
fn(); // this is now undefined/global — the object4 "context" was left behind
```

**Why this matters for classes:** every method on a class relies on this exact mechanism. `this.name = name` inside a constructor only works because `new` guarantees `this` is bound to the freshly created instance for the duration of that call. Detach a class method from its instance (e.g. pass `this.introduce` as a callback) and you hit the classic "`this` is undefined" bug — the same bug as `object4.a` above, just wearing a class costume.

**Interview angle:** this is one of the most common "explain `this`" trick questions. Be ready to walk through the four binding rules: default binding, implicit binding (object.method()), explicit binding (`call`/`apply`/`bind`), and `new` binding — plus arrow functions, which ignore all of these and instead lexically inherit `this` from their enclosing scope.

---

## 3. Instantiation

```js
class Player {
  constructor(name, type) {
    console.log('Player: ', this);
    this.name = name;
    this.type = type;
  }

  introduce() {
    console.log(`Hi I am ${this.name}, I'm a ${this.type}`);
  }
}

class Wizard extends Player {
  constructor(name, type) {
    super(name, type);
    console.log('Wizard: ', this);
  }

  play() {
    console.log(`WEEEEE I'm a ${this.type}`);
  }
}

const wizard1 = new Wizard('Shelly', 'Healer');
// > Player:  Wizard {}
// > Wizard:  Wizard {name: 'Shelly', type: 'Healer'}
```

### What actually happens on `new Wizard(...)`, step by step

1. A brand-new, empty object is created. Its internal `[[Prototype]]` is set to `Wizard.prototype`.
2. `Wizard`'s constructor runs with `this` bound to that new object.
3. Because `Wizard extends Player`, `this` is **not usable until `super()` is called** — this is a hard rule in JS classes (not just a convention). Calling `super(name, type)` invokes `Player`'s constructor with the *same* `this`, so `Player`'s constructor logic (`this.name = name`, `this.type = type`) runs against the object being built.
4. Control returns to `Wizard`'s constructor after `super()`, where the rest of its logic executes (here, just the `console.log`).
5. The finished object is returned implicitly from `new`.

### Key things to notice in the log output

- `console.log('Player: ', this)` logs `Wizard {}` — **empty**, because `super()` runs before `this.name`/`this.type` are assigned inside `Player`'s own constructor body. `this` already reports as a `Wizard` (not `Player`), because the object's prototype was set to `Wizard.prototype` *before* any constructor body ran — the "type" of the object was decided at allocation time in step 1, not by which constructor happens to be executing.
- The second log, from `Wizard`'s constructor, shows the fields populated — because it runs *after* `super()` returns.
- `introduce()` is inherited — it's not copied onto every instance. It lives once, on `Player.prototype`, and `wizard1.introduce()` walks up the prototype chain to find it. `play()`, meanwhile, lives on `Wizard.prototype`.

```js
wizard1.introduce();  // "Hi I am Shelly, I'm a Healer" — found on Player.prototype
wizard1.play();       // "WEEEEE I'm a Healer"          — found on Wizard.prototype

Object.getPrototypeOf(wizard1) === Wizard.prototype           // true
Object.getPrototypeOf(Wizard.prototype) === Player.prototype  // true
```

**Interview angle — the "gotcha" question:** *"Why does the object already look like a `Wizard` even before `Wizard`'s own constructor body has run?"* Answer: because `class` prototype-chains at object-creation time, not at constructor-execution time. `instanceof` and prototype identity are about the chain set up in step 1, completely independent of which lines of constructor code have executed so far.

Another common one: *"What happens if you forget `super()` in a subclass constructor?"* Answer: a `ReferenceError` — you can't touch `this` before `super()` runs in a derived class, and if the constructor doesn't call `super()` at all, JS throws when the constructor finishes (or as soon as `this`/an implicit return is needed).

---

## Quick Reference Table

| Concept | One-line takeaway |
|---|---|
| Reference equality | Objects/arrays compare by identity, never by structural value |
| `this` binding | Determined by the call site (what's left of the dot), not by declaration location |
| `new` + `class` | Creates object → links prototype chain → runs constructor with `this` bound to it |
| `extends` / `super` | `super()` must run before `this` is accessible in a subclass constructor |
| Methods on a class | Live once on the prototype, shared across all instances — not per-instance copies |

---

## Related topics to review alongside this note
- Prototypal inheritance without `class` syntax (`Object.create`, constructor functions)
- Static methods/fields (`static` keyword) vs instance methods
- Private class fields (`#field`) and encapsulation
- Getters/setters in classes
- `Object.freeze` / immutability vs reference semantics
- Arrow functions in class fields as a way to auto-bind `this` for callbacks