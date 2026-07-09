# Introduction to Data Structures & Algorithms

> **Data Structures + Algorithms = Programs**  
> — Niklaus Wirth (inventor of Pascal)

---

## What is a Data Structure?

A way to **organize and store data** so it can be accessed and modified efficiently.

Think of it like this:
- A **variable** holds one value
- A **data structure** holds many values — and defines *how* you interact with them

Every data structure answers two questions:
1. **How do I put things in?**
2. **How do I take things out?**

> Data structures are just **tools**. The skill is knowing *which tool fits which problem*.

---

## What is an Algorithm?

A **step-by-step set of instructions** to solve a problem or perform a computation.

If data structures are containers, algorithms are the **actions** you perform on them.

```
Data Structure + Algorithm = Program
```

Example:
- Data structure: unsorted Array
- Algorithm: QuickSort
- Result: sorted Array in O(n log n)

---

## Built-in Data Types in JavaScript

Before custom data structures, JS gives you these primitives and references:

### Primitives — stored by value
```js
42            // Number
'hello'       // String
true          // Boolean
undefined     // Undefined
null          // Null (typeof says 'object' — historical JS bug)
Symbol()      // Symbol (ES6)
BigInt(9007199254740991n)  // BigInt (ES2020)
```

### Reference Types — stored by reference (these ARE data structures)
```js
[]    // Array   — ordered, index-based collection
{}    // Object  — key-value pairs (basis of HashMaps in JS)
```

Everything else you build is on top of these.

---

## Data Structures Used 99% of the Time

Wikipedia lists dozens. In reality — interviews, production systems, FAANG — you need these:

### Linear
| Data Structure | Mental Model | JS Native? |
|---|---|---|
| **Array** | Indexed list | ✅ `[]` |
| **Stack** | Stack of plates — LIFO | ❌ build with array |
| **Queue** | Line at a counter — FIFO | ❌ build with array/LL |
| **Linked List** | Train cars chained together | ❌ build from scratch |

### Non-Linear
| Data Structure | Mental Model | JS Native? |
|---|---|---|
| **Hash Table** | Dictionary — key to value | ✅ `{}` / `Map` |
| **Tree** | Hierarchy — parent → children | ❌ build from scratch |
| **Trie** | Prefix tree — autocomplete | ❌ build from scratch |
| **Graph** | Network — nodes + edges | ❌ build from scratch |

### Algorithms You Must Know
| Category | Topics |
|---|---|
| **Sorting** | Bubble, Merge, Quick, Heap |
| **Searching** | BFS, DFS, Binary Search |
| **Recursion** | Base case, call stack, memoization |
| **Dynamic Programming** | Overlapping subproblems, optimal substructure |

---

## Two Ways to Interact with Any Data Structure

### 1. How to Build One
Understanding the internal implementation — nodes, pointers, array indices.  
Needed for: interviews, writing custom structures, understanding performance.

### 2. How to Use One
Using it as a black box — push, pop, enqueue, dequeue.  
Needed for: day-to-day coding, picking the right tool.

> As a senior dev, you need **both**. Using without understanding = wrong tool choices.

---

## Operations on Data Structures

Every data structure supports some subset of these 6 operations:

| Operation | What it does | Example |
|---|---|---|
| **Access** | Get element at known position | `arr[3]` |
| **Insertion** | Add a new element | `arr.push(5)` |
| **Deletion** | Remove an element | `arr.splice(2, 1)` |
| **Searching** | Find if/where an element exists | `arr.indexOf(5)` |
| **Traversal** | Visit each element exactly once | `arr.forEach(...)` |
| **Sorting** | Reorder elements by a rule | `arr.sort(...)` |

**Not all structures support all operations efficiently.**  
That's exactly why multiple data structures exist.

```
Array   → fast access O(1), slow insert-at-middle O(n)
LinkedList → fast insert O(1), slow access O(n)
HashMap → fast search O(1), no ordering
Tree    → fast search + ordered O(log n)
```

Choosing the wrong structure = writing slow code with correct logic.

---

## How to Think About Choosing a Data Structure

Ask these questions:

```
1. What operations will I do most? (access / insert / search / delete)
2. How large is the data?
3. Does order matter?
4. Do I need uniqueness?
5. Do I need key-value lookup?
```

| Need | Reach for |
|---|---|
| Fast lookup by key | Hash Table |
| Ordered data, fast search | BST / Sorted Array |
| LIFO (undo, backtracking) | Stack |
| FIFO (queue, BFS) | Queue |
| Frequent insert/delete at ends | Linked List |
| Hierarchical data | Tree |
| Network / relationships | Graph |
| Autocomplete / prefix search | Trie |

---

## The Big Picture

```
                    ┌─────────────────────────┐
                    │       PROGRAMS           │
                    └──────────┬──────────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
   ┌──────────▼──────────┐          ┌──────────▼──────────┐
   │   DATA STRUCTURES   │          │     ALGORITHMS       │
   │                     │          │                      │
   │  Arrays             │          │  Sorting             │
   │  Stacks             │          │  Searching (BFS/DFS) │
   │  Queues             │          │  Recursion           │
   │  Linked Lists       │          │  Dynamic Programming │
   │  Trees / Tries      │          │                      │
   │  Graphs             │          │                      │
   │  Hash Tables        │          │                      │
   └─────────────────────┘          └──────────────────────┘
```

---

## What's Coming — Chapter by Chapter

| # | Topic | Type |
|---|---|---|
| 01 | Arrays & Hashing | Data Structure |
| 02 | Two Pointers | Algorithm Pattern |
| 03 | Sliding Window | Algorithm Pattern |
| 04 | Stack | Data Structure |
| 05 | Binary Search | Algorithm |
| 06 | Linked List | Data Structure |
| 07 | Trees | Data Structure |
| 08 | Heap / Priority Queue | Data Structure |
| 09 | Graphs | Data Structure |
| 10 | Dynamic Programming | Algorithm |

Each chapter: `concepts.md` → `practices.md` → `problems.md`

---

## One Line to Remember

> There is no "best" data structure.  
> There is only the **right tool for the right problem**.