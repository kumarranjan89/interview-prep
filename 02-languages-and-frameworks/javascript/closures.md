# Closures

## Mental Model

A closure is a **function bundled together with its lexical environment** — the scope in which it was defined.

When a function is defined inside another function, the inner function **remembers the variables of the outer function** even after the outer function has finished executing.

> A function "closes over" its surrounding scope — hence the name **closure**.

Key insight: In JavaScript, functions are first-class citizens. When a function is returned or passed around, it carries its scope chain with it.

---

## Simple Example

```javascript
function outer() {
  let count = 0;          // outer's variable

  function inner() {
    count++;              // inner accesses outer's variable
    console.log(count);
  }

  return inner;
}

const counter = outer();  // outer has finished executing
counter(); // 1           // but count is still remembered
counter(); // 2
counter(); // 3
```

`outer()` has returned — but `count` stays alive in memory because `inner` holds a reference to it. This is a closure.

---

## How It Works Internally

Every function in JavaScript has access to:
1. Its own local scope
2. The scope of any outer functions (scope chain)
3. The global scope

When `outer()` returns `inner`, the JavaScript engine sees that `inner` still references `count`. So it **keeps the variable alive in memory** — it does not get garbage collected.

```
[ Global Scope ]
      |
[ outer() Scope ]  <-- count lives here
      |
[ inner() Scope ]  <-- has reference to outer scope via closure
```

---

## Real World Use Cases

### 1. Data Privacy / Encapsulation

Variables inside a closure are private — they cannot be accessed directly from outside.

```javascript
function createBankAccount(initialBalance) {
  let balance = initialBalance;  // private — not accessible outside

  return {
    deposit:    (amount) => { balance += amount; },
    withdraw:   (amount) => { balance -= amount; },
    getBalance: ()       => balance
  };
}

const acc = createBankAccount(1000);
acc.deposit(500);
console.log(acc.getBalance()); // 1500
console.log(acc.balance);      // undefined — no direct access
```

This is the Module Pattern — one of the most common closure-based design patterns.

### 2. Function Factory

Generate specialized functions from a general one.

```javascript
function multiplier(factor) {
  return (number) => number * factor;  // factor is closed over
}

const double = multiplier(2);
const triple = multiplier(3);

double(5); // 10
triple(5); // 15
```

Each returned function has its own closure with a different `factor`.

### 3. Memoization

Cache expensive computation results using a closure to maintain the cache.

```javascript
function memoize(fn) {
  const cache = {};  // closed over — persists across calls

  return function(n) {
    if (cache[n] !== undefined) return cache[n];
    cache[n] = fn(n);
    return cache[n];
  };
}

const factorial = memoize(function f(n) {
  return n <= 1 ? 1 : n * f(n - 1);
});

factorial(5); // computed
factorial(5); // returned from cache
```

### 4. Event Handlers

Closures allow event handlers to access variables from the enclosing scope.

```javascript
function attachHandler(buttonId, message) {
  const btn = document.getElementById(buttonId);

  btn.addEventListener('click', () => {
    console.log(message);  // message is closed over
  });
}

attachHandler('btn1', 'Hello from Button 1');
attachHandler('btn2', 'Hello from Button 2');
```

Each handler closes over its own `message`.

---

## Classic Interview Trap — Loop + Closure

```javascript
// BROKEN — all callbacks share the same `i`
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 1000);
}
// Output: 3, 3, 3
```

**Why?** `var` is function-scoped, not block-scoped. By the time the callbacks fire, the loop is done and `i` is `3`. All three closures reference the **same** `i`.

**Fix 1 — Use `let` (block-scoped)**
```javascript
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log(i), 1000);
}
// Output: 0, 1, 2 ✅
```

`let` creates a new binding per iteration — each closure captures a different `i`.

**Fix 2 — IIFE to create a new scope**
```javascript
for (var i = 0; i < 3; i++) {
  ((j) => {
    setTimeout(() => console.log(j), 1000);
  })(i);
}
// Output: 0, 1, 2 ✅
```

The IIFE creates a new scope on each iteration and captures the current value of `i` as `j`.

---

## Memory Considerations

Closures keep variables alive as long as the inner function exists. This can cause **memory leaks** if not handled carefully.

```javascript
// Potential memory leak
function heavyLeak() {
  const bigData = new Array(1000000).fill('x');  // large allocation

  return function() {
    console.log(bigData[0]);  // bigData will never be GC'd
  };
}

const fn = heavyLeak();
// bigData stays in memory as long as fn exists
```

**Best practice:** Set large closed-over variables to `null` when no longer needed, or avoid closing over them unnecessarily.

---

## Closures vs Regular Functions

| Aspect | Regular Function | Closure |
|---|---|---|
| Scope access | Own scope + global | Own scope + outer function scope + global |
| Variable lifetime | Ends when function returns | Persists as long as inner function exists |
| State | Stateless between calls | Stateful — remembers previous calls |
| Use case | Pure computation | Encapsulation, factories, callbacks |

---

## Interview Questions & Answers

**Q: What is a closure?**

> A closure is a function that retains access to its lexical scope even after the outer function has returned. In JavaScript, every function forms a closure over the scope in which it was created.

---

**Q: What are practical use cases of closures?**

> Data encapsulation (module pattern), function factories, memoization, maintaining state in event handlers, and partial application / currying.

---

**Q: What is the difference between a closure and a regular function?**

> A regular function only has access to its own scope and the global scope. A closure additionally retains access to the scope of the function it was defined inside, even after that outer function has executed.

---

**Q: How do closures cause memory leaks?**

> Since closures hold a reference to outer variables, those variables cannot be garbage collected as long as the closure exists. If a closure unnecessarily holds a reference to a large object, it will remain in memory longer than expected.

---

**Q: Why does `var` in a loop with `setTimeout` produce unexpected results?**

> `var` is function-scoped, so all iterations share the same variable. By the time the async callbacks fire, the loop has already incremented the variable to its final value. Using `let` (block-scoped) or an IIFE solves this by creating a new binding per iteration.

---

## One-Line Summary

> **A closure is a function that remembers the variables from the place where it was defined, not where it was called.**