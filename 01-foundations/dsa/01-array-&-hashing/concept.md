# Arrays & Hashing — Concepts

---

## Array

A collection of elements stored at **contiguous memory locations**.  
Index starts at 0.

```
Index:  0     1     2     3     4
       [10]  [20]  [30]  [40]  [50]
```

### Core Operations

| Operation | Time | Notes |
|-----------|------|-------|
| Access by index | O(1) | arr[2] |
| Search (unsorted) | O(n) | loop through |
| Insert at end | O(1) | push() |
| Insert at middle | O(n) | shift elements |
| Delete at end | O(1) | pop() |
| Delete at middle | O(n) | shift elements |

### JavaScript

```js
const arr = [10, 20, 30, 40, 50];

arr[0];          // 10 — O(1)
arr.push(60);    // [10,20,30,40,50,60] — O(1)
arr.pop();       // removes 60 — O(1)
arr.shift();     // removes 10 — O(n) shifts all
arr.unshift(5);  // adds at start — O(n) shifts all
arr.splice(2,1); // removes 1 element at index 2 — O(n)
```

### When to think Array

- Order matters
- Need index-based access
- Iterating all elements

---

## Hash Map

Stores data as **key → value** pairs.  
Uses a hash function to compute index internally.

```
Key      Hash Fn     Index    Value
"name"   --------→   [3]  →  "Rahul"
"age"    --------→   [7]  →  25
"city"   --------→   [1]  →  "Patna"
```

### Core Operations

| Operation | Time | Notes |
|-----------|------|-------|
| Insert | O(1) avg | map.set() |
| Lookup | O(1) avg | map.get() |
| Delete | O(1) avg | map.delete() |
| Search by value | O(n) | no shortcut |

### JavaScript — Map vs Object

```js
// Map — preferred for DSA
const map = new Map();
map.set("name", "Rahul");   // insert
map.get("name");             // "Rahul" — O(1)
map.has("name");             // true — O(1)
map.delete("name");          // O(1)
map.size;                    // number of entries

// Object — also works, simpler syntax
const obj = {};
obj["name"] = "Rahul";
obj["name"];                 // "Rahul"
"name" in obj;               // true
delete obj["name"];
```

### When to use Map vs Object

| | Map | Object |
|--|-----|--------|
| Key type | any (number, obj) | string only |
| Order | insertion order | not guaranteed |
| DSA problems | preferred | fine for simple cases |

### When to think Hash Map

- Need O(1) lookup
- Counting frequency of elements
- Checking if something exists
- Storing seen elements (avoid duplicates)

---

## Arrays + Hashing Together

Most array problems become O(n) instead of O(n²) when you add a hash map.

### Classic Example — Two Sum

**Brute force (O(n²)):**
```js
// Check every pair
for (let i = 0; i < arr.length; i++) {
  for (let j = i + 1; j < arr.length; j++) {
    if (arr[i] + arr[j] === target) return [i, j];
  }
}
```

**With Hash Map (O(n)):**
```js
// Store seen numbers, check complement in O(1)
const map = new Map();
for (let i = 0; i < arr.length; i++) {
  const complement = target - arr[i];
  if (map.has(complement)) return [map.get(complement), i];
  map.set(arr[i], i);
}
```

**Why faster:** Instead of looking back through the array (O(n)), you look up in the map (O(1)).

---

## Recognize This Pattern When

- "Find two numbers that add up to..."
- "Check if duplicate exists"
- "Count frequency of each element"
- "Group elements by some property"
- Brute force is O(n²) — hash map can make it O(n)

---

## Complexity Summary

| | Time | Space |
|--|------|-------|
| Array access | O(1) | — |
| Array search | O(n) | — |
| Hash map lookup | O(1) avg | O(n) |
| Two Sum brute | O(n²) | O(1) |
| Two Sum hash | O(n) | O(n) |

Space trade-off: Hash map costs O(n) extra space but saves time.  
FAANG interviews — time optimization is priority unless space is constrained.