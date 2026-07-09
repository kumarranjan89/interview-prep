# Big O — Problems

These problems aren't about Big O itself — they're classic problems  
where **choosing the right complexity target** is the actual challenge.

Format: Problem → Brute Force → Optimal

---

## Problem 1 — Contains Duplicate
**Difficulty:** Easy  
**Pattern:** Array + HashSet

### Statement
Given an integer array, return `true` if any value appears more than once.

### Brute Force — O(n²) time, O(1) space
```js
function hasDuplicate(nums) {
  for (let i = 0; i < nums.length; i++)
    for (let j = i + 1; j < nums.length; j++)
      if (nums[i] === nums[j]) return true;
  return false;
}
```

### Optimal — O(n) time, O(n) space
```js
function hasDuplicate(nums) {
  const seen = new Set();
  for (let n of nums) {
    if (seen.has(n)) return true;
    seen.add(n);
  }
  return false;
}
```

### Tradeoff Note
Sorting approach exists: O(n log n) time, O(1) space — middle ground if space is constrained.

---

## Problem 2 — Two Sum
**Difficulty:** Easy  
**Pattern:** HashMap complement lookup

### Statement
Given array `nums` and `target`, return indices of two numbers that add up to `target`.  
Each input has exactly one solution.

### Brute Force — O(n²) time, O(1) space
```js
function twoSum(nums, target) {
  for (let i = 0; i < nums.length; i++)
    for (let j = i + 1; j < nums.length; j++)
      if (nums[i] + nums[j] === target) return [i, j];
}
```

### Optimal — O(n) time, O(n) space
```js
function twoSum(nums, target) {
  const map = new Map(); // value → index
  for (let i = 0; i < nums.length; i++) {
    const need = target - nums[i];
    if (map.has(need)) return [map.get(need), i];
    map.set(nums[i], i);
  }
}
```

### Key Insight
You're trading space for time. The HashMap stores "what have I seen" so you can answer "do I have the complement?" in O(1) instead of scanning again.

---

## Problem 3 — Valid Anagram
**Difficulty:** Easy  
**Pattern:** Frequency count / Sorting

### Statement
Given strings `s` and `t`, return `true` if `t` is an anagram of `s`.

### Approach 1 — Sort — O(n log n) time, O(n) space
```js
function isAnagram(s, t) {
  if (s.length !== t.length) return false;
  return [...s].sort().join('') === [...t].sort().join('');
}
```

### Approach 2 — Frequency Map — O(n) time, O(1) space
```js
function isAnagram(s, t) {
  if (s.length !== t.length) return false;
  const count = {};
  for (let c of s) count[c] = (count[c] || 0) + 1;
  for (let c of t) {
    if (!count[c]) return false;
    count[c]--;
  }
  return true;
}
// Space O(1) — only 26 lowercase letters max in map
```

### Interview Follow-up
"What if inputs contain Unicode characters?"  
→ Map still works (keys are Unicode chars). Space becomes O(k) where k = unique chars.

---

## Problem 4 — Group Anagrams
**Difficulty:** Medium  
**Pattern:** HashMap with sorted-string key

### Statement
Given array of strings, group anagrams together.

### Brute Force — O(n² × k log k) — compare all pairs
Skip this. Go straight to optimal.

### Optimal — O(n × k log k) time, O(n × k) space
```js
function groupAnagrams(strs) {
  const map = new Map();
  for (let str of strs) {
    const key = [...str].sort().join('');
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(str);
  }
  return [...map.values()];
}
// n = number of strings, k = max string length
```

### Alternate Key — O(n × k) time (no sort)
```js
// Use character frequency as key: "a2b1c0...z0"
function groupAnagrams(strs) {
  const map = new Map();
  for (let str of strs) {
    const count = new Array(26).fill(0);
    for (let c of str) count[c.charCodeAt(0) - 97]++;
    const key = count.join(',');
    if (!map.has(key)) map.set(key, []);
    map.get(key).push(str);
  }
  return [...map.values()];
}
```

---

## Problem 5 — Top K Frequent Elements
**Difficulty:** Medium  
**Pattern:** Bucket Sort / Heap

### Statement
Given array `nums` and integer `k`, return `k` most frequent elements.  
Answer must be better than O(n log n).

### Approach 1 — Sort by freq — O(n log n)
```js
function topKFrequent(nums, k) {
  const freq = new Map();
  for (let n of nums) freq.set(n, (freq.get(n) || 0) + 1);
  return [...freq.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, k)
    .map(e => e[0]);
}
// Violates the constraint: must be < O(n log n)
```

### Approach 2 — Bucket Sort — O(n) time, O(n) space
```js
function topKFrequent(nums, k) {
  const freq = new Map();
  for (let n of nums) freq.set(n, (freq.get(n) || 0) + 1);

  // bucket[i] = numbers that appear exactly i times
  const bucket = Array.from({ length: nums.length + 1 }, () => []);
  for (let [num, count] of freq) bucket[count].push(num);

  const result = [];
  for (let i = bucket.length - 1; i >= 0 && result.length < k; i--)
    result.push(...bucket[i]);

  return result.slice(0, k);
}
// Time: O(n) | Space: O(n)
```

### Key Insight
Max frequency can't exceed `n`. So bucket index goes from 1 to n — finite, scannable in O(n).

---

## Problem 6 — Product of Array Except Self
**Difficulty:** Medium  
**Pattern:** Prefix / Suffix product

### Statement
Given array, return array where each element is the product of all other elements.  
**No division. O(n) time. O(1) extra space** (output array doesn't count).

### Approach — Prefix × Suffix — O(n) time, O(1) space
```js
function productExceptSelf(nums) {
  const n = nums.length;
  const result = new Array(n).fill(1);

  // Forward pass: result[i] = product of all nums[0..i-1]
  let prefix = 1;
  for (let i = 0; i < n; i++) {
    result[i] = prefix;
    prefix *= nums[i];
  }

  // Backward pass: multiply suffix product into result
  let suffix = 1;
  for (let i = n - 1; i >= 0; i--) {
    result[i] *= suffix;
    suffix *= nums[i];
  }

  return result;
}
```

### Why This Works
```
nums    = [1, 2, 3, 4]
prefix  = [1, 1, 2, 6]   ← product of everything before i
suffix  = [24,12, 4, 1]   ← product of everything after i
result  = prefix × suffix = [24, 12, 8, 6]
```

---

## Complexity Target Cheatsheet

When interviewer says... | Your target should be
---|---
"Can you do better than O(n²)?" | O(n log n) — try sort. O(n) — try HashMap
"O(1) space?" | Two-pointer, in-place, prefix trick
"Better than O(n log n)?" | O(n) — HashMap, bucket sort, counting sort
"Faster lookup?" | HashMap — O(1) vs array O(n)
"Real-time / streaming data?" | O(1) or O(log n) per operation

---

## Self-Assessment

After solving any problem, answer these before moving on:

- [ ] What's my time complexity? Can I prove it?
- [ ] What's my space complexity? Did I count the call stack?
- [ ] Is there a smarter tradeoff (space for time or vice versa)?
- [ ] What's the brute force and why is mine better?
- [ ] What edge cases break my solution?