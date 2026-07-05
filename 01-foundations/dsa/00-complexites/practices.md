# Big O — Practices

Analyze each snippet. Answer before looking at solution.  
Format your answer as: **Time: O(?) | Space: O(?)**

---

## Set A — Read The Code

### P1
```js
function findMax(arr) {
  let max = -Infinity;
  for (let n of arr) {
    if (n > max) max = n;
  }
  return max;
}
```
<details>
<summary>Answer</summary>

**Time: O(n) | Space: O(1)**  
Single pass, one variable.
</details>

---

### P2
```js
function hasDuplicate(arr) {
  const seen = new Set();
  for (let n of arr) {
    if (seen.has(n)) return true;
    seen.add(n);
  }
  return false;
}
```
<details>
<summary>Answer</summary>

**Time: O(n) | Space: O(n)**  
One pass. Set grows up to n elements.
</details>

---

### P3
```js
function printPairs(arr) {
  for (let i = 0; i < arr.length; i++)
    for (let j = i + 1; j < arr.length; j++)
      console.log(arr[i], arr[j]);
}
```
<details>
<summary>Answer</summary>

**Time: O(n²) | Space: O(1)**  
j starts at i+1, so it's n*(n-1)/2 → still O(n²). Constants dropped.
</details>

---

### P4
```js
function binarySearch(arr, target) {
  let lo = 0, hi = arr.length - 1;
  while (lo <= hi) {
    const mid = Math.floor((lo + hi) / 2);
    if (arr[mid] === target) return mid;
    else if (arr[mid] < target) lo = mid + 1;
    else hi = mid - 1;
  }
  return -1;
}
```
<details>
<summary>Answer</summary>

**Time: O(log n) | Space: O(1)**  
Search space halves each iteration.
</details>

---

### P5
```js
function mergeSort(arr) {
  if (arr.length <= 1) return arr;
  const mid = Math.floor(arr.length / 2);
  const left = mergeSort(arr.slice(0, mid));
  const right = mergeSort(arr.slice(mid));
  return merge(left, right); // merge is O(n)
}
```
<details>
<summary>Answer</summary>

**Time: O(n log n) | Space: O(n)**  
log n levels of recursion × O(n) merge per level.  
Space: O(n) for temp arrays + O(log n) call stack → O(n) dominates.
</details>

---

### P6
```js
function fib(n) {
  if (n <= 1) return n;
  return fib(n - 1) + fib(n - 2);
}
```
<details>
<summary>Answer</summary>

**Time: O(2ⁿ) | Space: O(n)**  
Two recursive calls each time. Call tree doubles at each level.  
Space: O(n) — max depth of call stack at any point is n.
</details>

---

### P7
```js
function fibMemo(n, memo = {}) {
  if (n in memo) return memo[n];
  if (n <= 1) return n;
  memo[n] = fibMemo(n - 1, memo) + fibMemo(n - 2, memo);
  return memo[n];
}
```
<details>
<summary>Answer</summary>

**Time: O(n) | Space: O(n)**  
Each subproblem computed once. memo stores n values.
</details>

---

### P8 — Tricky
```js
function mystery(n) {
  let count = 0;
  for (let i = 1; i < n; i *= 2)
    for (let j = 0; j < n; j++)
      count++;
  return count;
}
```
<details>
<summary>Answer</summary>

**Time: O(n log n) | Space: O(1)**  
Outer loop: i doubles → log n iterations.  
Inner loop: always n iterations.  
Total: O(n log n).
</details>

---

### P9 — Tricky
```js
function sumDigits(n) {
  let sum = 0;
  while (n > 0) {
    sum += n % 10;
    n = Math.floor(n / 10);
  }
  return sum;
}
```
<details>
<summary>Answer</summary>

**Time: O(d) where d = number of digits | Space: O(1)**  
d = log₁₀(n), so technically O(log n).  
Common mistake: saying O(n) — the loop runs `digit count` times, not n times.
</details>

---

### P10 — Two Arrays
```js
function commonElements(a, b) {
  const setA = new Set(a);
  const result = [];
  for (let x of b) {
    if (setA.has(x)) result.push(x);
  }
  return result;
}
```
<details>
<summary>Answer</summary>

**Time: O(a + b) | Space: O(a)**  
Building Set: O(a). Scanning b: O(b). Set lookup: O(1).  
Space: Set holds all of a.
</details>

---

## Set B — Spot the Mistake

What complexity did the dev claim? What's the real answer?

### B1
```js
// Dev says: "O(n) — only one loop"
function findCommon(arr, map) {
  for (let item of arr) {
    if (map[item]) return item;  // map is a plain JS object
  }
}
```
<details>
<summary>Answer</summary>

Dev is **correct** — O(n).  
Object property access is O(1). One loop = O(n). Space: O(1).  
No mistake here — tests your comfort with HashMap assumption.
</details>

---

### B2
```js
// Dev says: "O(n²) — two nested loops"
function uniquePairs(arr) {
  const seen = new Set();
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      seen.add(`${arr[i]},${arr[j]}`);
    }
  }
  return seen.size;
}
```
<details>
<summary>Answer</summary>

Dev is **correct** — O(n²) time.  
But missed: **Space is O(n²)** too — the Set can hold up to n*(n-1)/2 pairs.
</details>

---

### B3
```js
// Dev says: "O(1) — just returning array length"
function getLength(arr) {
  return arr.length;
}
```
<details>
<summary>Answer</summary>

**Correct — O(1).**  
JS Array `.length` is a stored property, not a computation.
</details>

---

## Set C — Optimize This

### C1 — Rewrite to O(n)
```js
// Current: O(n²)
function twoSum(arr, target) {
  for (let i = 0; i < arr.length; i++)
    for (let j = i + 1; j < arr.length; j++)
      if (arr[i] + arr[j] === target) return [i, j];
}
```
<details>
<summary>O(n) solution</summary>

```js
function twoSum(arr, target) {
  const map = new Map(); // val → index
  for (let i = 0; i < arr.length; i++) {
    const complement = target - arr[i];
    if (map.has(complement)) return [map.get(complement), i];
    map.set(arr[i], i);
  }
}
// Time: O(n) | Space: O(n)
```
</details>

---

### C2 — Reduce Space to O(1)
```js
// Current: O(n) space
function reverseArray(arr) {
  const result = [];
  for (let i = arr.length - 1; i >= 0; i--)
    result.push(arr[i]);
  return result;
}
```
<details>
<summary>O(1) space solution</summary>

```js
function reverseArray(arr) {
  let lo = 0, hi = arr.length - 1;
  while (lo < hi) {
    [arr[lo], arr[hi]] = [arr[hi], arr[lo]];
    lo++; hi--;
  }
  return arr;
}
// Time: O(n) | Space: O(1) — in-place swap
```
</details>

---

## Quick Recall Drill

Cover answers, say them aloud before uncovering:

| Operation | DS | Complexity |
|---|---|---|
| Lookup by key | HashMap | ? |
| Find min | unsorted array | ? |
| Find min | Min-Heap | ? |
| Insert at index 0 | Array | ? |
| Insert at head | Linked List | ? |
| Search | BST (balanced) | ? |
| Sort n elements | best algo | ? |
| All subsets of n elements | brute force | ? |

<details>
<summary>Answers</summary>

| Operation | DS | Complexity |
|---|---|---|
| Lookup by key | HashMap | O(1) |
| Find min | unsorted array | O(n) |
| Find min | Min-Heap | O(1) |
| Insert at index 0 | Array | O(n) |
| Insert at head | Linked List | O(1) |
| Search | BST (balanced) | O(log n) |
| Sort n elements | best algo | O(n log n) |
| All subsets of n elements | brute force | O(2ⁿ) |
</details>